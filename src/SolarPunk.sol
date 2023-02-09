// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ERC721Enumerable, ERC721} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {SolarPunkService} from "src/metadata/SolarPunkService.sol";
import {SwapAndPop} from "src/structs/SwapAndPop.sol";
import {ISolarPunk} from "src/ISolarPunk.sol";

/**
 * @title ERC721 collection with on-chain metadata
 */
contract SolarPunk is ERC721Enumerable, Ownable, ISolarPunk {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.UintSet;
    using SwapAndPop for SwapAndPop.Reserve;

    /// @return cost for requesting a mint
    uint256 public immutable cost;

    /// @dev count items committed in requests
    uint128 private _availableItems;

    /// @dev counter for creating unique request for the same block number and owner
    uint128 private _lastRequestId;

    /// @dev counter for indexing shape contracts addresses
    uint256 private _lastShapeId;

    /// @dev track shape contracts addresses
    mapping(uint256 => address) private _shapesAddr;

    /// @dev track remainning itemID for a specific shape
    mapping(uint256 => SwapAndPop.Reserve) private _reserveOf;

    /// @dev track tokenID to mint for users
    mapping(address => uint256[]) private _itemsToMint;

    /// @dev list of mint request
    EnumerableSet.UintSet private _requestList;

    /// @dev list of shape contracts addresses index with remainning item inside
    EnumerableSet.UintSet private _activeShapeList;

    /// @param owner address of owner of the contract
    constructor(address owner) ERC721("SolarPunk v0.5", "SPKv0.5") {
        if (msg.sender != owner) transferOwnership(owner);
        cost = 0.000003 ether;
    }

    /*/////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    /////////////////////////////////////////////////////////////*/

    /**
     * @notice Allow users to request one or several assets, users
     * must determine a block number in the future in which the
     * blockchash will be used to randomly choose assets to mint.
     *
     * @param blockNumber future block number committed (RANGE=[block.number+1:block.number + 72000))
     * @param amount number of asset to request
     * */
    function requestMint(uint256 blockNumber, uint256 amount) external payable {
        // check inputs
        if (blockNumber <= block.number || blockNumber > block.number + 72000)
            revert OutOfBlockRange(blockNumber);
        if (msg.value < cost * amount) revert ValueBelowExpected(msg.value);
        if (_requestList.length() > 100) revert RequestListTooLong();
        if (_availableItems < amount) revert NoAvailableItems();

        // decrement available items
        unchecked {
            _availableItems -= uint128(amount);
        }

        // store requests
        for (uint256 i; i < amount; ) {
            unchecked {
                ++_lastRequestId;
                ++i;
            }
            uint256 request = createRequest(
                msg.sender,
                _lastRequestId,
                blockNumber
            );
            _requestList.add(request);
        }

        emit RequestCreated(msg.sender, blockNumber, amount);

        // give change
        payable(msg.sender).sendValue(msg.value - cost * amount);
    }

    /**
     * @notice Allow users to fulfill requests, any users could
     * fulfill requests. If the request is owned by the user the
     * item is minted. The request can be erroned, in this case
     * the request is postponed.
     *
     * TODO reward fulfilling of others AND give choice to fulfill
     * only owned request
     * */
    function fulfillRequest(bool onlyOwnerRequest) external {
        uint256 length = _requestList.length();
        if (length == 0) revert NoRequestToFulfill();

        _fulfillRequests(length, onlyOwnerRequest);
    }

    /**
     * @notice Allow users to mint item in their pending
     * list. This latter is filled when an user fulfill request
     * of others.
     * */
    function mintPendingItems() external {
        uint256[] memory pendingItem = _itemsToMint[msg.sender];
        for (uint256 i; i < pendingItem.length; ) {
            _mint(msg.sender, pendingItem[i]);
            unchecked {
                ++i;
            }
        }
        delete _itemsToMint[msg.sender];
    }

    /**
     * @notice Allow owner to add a new `assets` contract, which
     * should be a new design.
     *
     * TODO maybe the contract impl should be checked AND the maximal
     * amount of `assets` must be caped to 22.
     * */
    function addAsset(address assetAddr) external onlyOwner {
        unchecked {
            ++_lastShapeId;
        }
        uint256 index = _lastShapeId;
        _activeShapeList.add(index);

        _shapesAddr[index] = assetAddr;
        _reserveOf[index].stock = 84;
        _availableItems += 84;
        emit AssetAdded(index, assetAddr);
    }

    /**
     * @notice Allow only-owner to with the contract balance.
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }

    /*/////////////////////////////////////////////////////////////
                                GETTERS
    /////////////////////////////////////////////////////////////*/

    /// @return addresses list of request owner
    /// @return blocksNumber list of block number
    function requestList()
        external
        view
        returns (address[] memory addresses, uint256[] memory blocksNumber)
    {
        uint256 length = _requestList.length();
        addresses = new address[](length);
        blocksNumber = new uint256[](length);

        for (uint256 i; i < length; ) {
            uint256 request = _requestList.at(i);
            addresses[i] = address(uint160(request >> 96));
            blocksNumber[i] = uint64(request);
            unchecked {
                ++i;
            }
        }
    }

    /// @return list of pending mints of an user (`uint256[] memory`)
    function pendingMints(address account)
        external
        view
        returns (uint256[] memory)
    {
        return _itemsToMint[account];
    }

    /// @return number of shapes released
    function numberOfShapes() external view returns (uint256) {
        return _lastShapeId;
    }

    /// @return number of items available to request (`uint256`)
    function availableItems() external view returns (uint256) {
        return _availableItems;
    }

    /// @return remaining item for a specific shape (`uint256`)
    function remainningItemOfShape(uint256 index)
        external
        view
        returns (uint256)
    {
        if (_shapesAddr[index] == address(0)) revert InexistantIndex(index);
        return _reserveOf[index].stock;
    }

    /// @return totalItem total remaining item among all assets (`uint256`)
    function totalRemainingItems() external view returns (uint256 totalItem) {
        for (uint256 i; i < _activeShapeList.length(); ) {
            totalItem += _reserveOf[_activeShapeList.at(i)].stock;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice This function return the NFT metadata as base64 encoded string
     *
     * @dev When the function is called the base64 encoded string is created
     * with information encoded in the tokenID. The result should be cached
     * to avoid long rendering.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 index = uint8(tokenId >> 248);
        address shapeAddr = _shapesAddr[index];
        if (shapeAddr == address(0)) revert InexistantAsset(index);

        return SolarPunkService.renderMetadata(tokenId, shapeAddr);
    }

    function contractURI() external pure returns (string memory) {
        return SolarPunkService.renderLogo();
    }

    /*/////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    /////////////////////////////////////////////////////////////*/

    /**
     * @dev First select a shape where to draw an item, then draw it
     * from the Reserve. And finally encode NFT informations
     * into the tokenID
     *
     * @return unique encoded tokenID
     */
    function _drawAndTransform(uint256 randNum) internal returns (uint256) {
        uint256 index = _activeShapeList.at(
            randNum % _activeShapeList.length()
        );
        uint256 itemId = _reserveOf[index].draw(randNum);
        if (_reserveOf[index].stock == 0) _activeShapeList.remove(index);

        return SolarPunkService.transformItemId(index, itemId);
    }

    /**
     * @dev Fulfill the request if the blockNumber is in the
     * range `[(block.number - 256):block.number)`.
     * A fulfilled request is either minted if the request owner
     * is the `sender`, or `drawed` and stored in the request owner's
     * pending mint list.
     *
     * If a requets is erroned (more than 256 block passed), the request is postponed.
     * As {EnumarableSet} use the swap and pop method the postponed request
     * replace the erroned one. Thus the loop just need to increase index
     */
    function _fulfillRequests(uint256 length, bool onlyOwnerRequest) internal {
        uint256 lastBlockhash = block.number - 256;
        uint256 lastRandomNumber = 1;

        for (uint256 i; i < length; ) {
            uint256 request = _requestList.at(i);
            uint256 blockNumber = uint64(request);
            address requestOwner = address(uint160(request >> 96));

            unchecked {
                ++i;
            }

            if (onlyOwnerRequest && requestOwner != msg.sender) continue;
            if (blockNumber >= block.number) continue;

            if (blockNumber < lastBlockhash) {
                // postpone the request
                uint256 postponedRequest = createRequest(
                    requestOwner,
                    ++_lastRequestId,
                    block.number + 3000
                );
                _requestList.add(postponedRequest);
                emit RequestPostponed(requestOwner, block.number + 3000);
            } else {
                unchecked {
                    lastRandomNumber =
                        lastRandomNumber +
                        uint256(blockhash(blockNumber));
                    --length;
                    --i;
                }
                uint256 tokenId = _drawAndTransform(lastRandomNumber);
                if (requestOwner == msg.sender) {
                    // mint directly the item
                    _mint(msg.sender, tokenId);
                } else {
                    // add item to the minting list
                    _itemsToMint[requestOwner].push(tokenId);
                }
                emit RequestFulfilled(requestOwner, tokenId);
            }
            _requestList.remove(request);
        }
    }

    /**
     * @dev workaround to pack request information into an `uint256`
     *
     * @param owner address of the request owner
     * @param lastRequestId request counter
     * @param blockNumber future block
     *
     * @return request as packed `uint256`
     */
    function createRequest(
        address owner,
        uint256 lastRequestId,
        uint256 blockNumber
    ) internal pure returns (uint256) {
        return
            uint256(
                bytes32(
                    abi.encodePacked(
                        uint160(owner),
                        uint32(lastRequestId),
                        uint64(blockNumber)
                    )
                )
            );
    }
}
