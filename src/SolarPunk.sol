// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {ERC721Enumerable, ERC721} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {SolarPunkService} from "src/metadata/SolarPunkService.sol";
import {SwapAndPop} from "src/structs/SwapAndPop.sol";

error OutOfBlockRange(uint256 blockNumber);
error ValueBelowExpected(uint256 value);
error NoAvailableItems();
error RequestListTooLong();

error NoRequestToFulfill();
error InexistantIndex(uint256 index);
error InexistantAsset(uint256 index);

contract SolarPunk is ERC721Enumerable, Ownable {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.UintSet;
    using SwapAndPop for SwapAndPop.Box;

    /// @dev count item committed in requests
    uint128 private _availableItems;

    /// @dev used to create unique request for same blockNumber and owner
    uint128 private _lastRequestId;

    mapping(uint256 => address) private _assetByIndex;
    mapping(uint256 => SwapAndPop.Box) private _assetsBoxesByIndex;
    mapping(address => uint256[]) private _itemsToMint;

    EnumerableSet.UintSet private _requestList;
    EnumerableSet.UintSet private _activeIndexList;

    constructor(address owner) ERC721("SolarPunk v0.1", "SPKv0.1") {
        transferOwnership(owner);
    }

    /*////////////////////////////
            PUBLIC FUNCTIONS
    ////////////////////////////*/
    /**
     * @notice Allow users to buy an item, a commit to a future
     * block number hash is used to determine a random value to
     * ensure a fair distribution of items.
     *
     * @param blockNumber future block number committed
     * */
    function requestMint(uint256 blockNumber) external payable {
        // check request meet requirements
        if (blockNumber <= block.number || blockNumber > block.number + 72000)
            revert OutOfBlockRange(blockNumber);
        if (msg.value < 0.03 ether) revert ValueBelowExpected(msg.value);
        if (_requestList.length() > 100) revert RequestListTooLong();
        if (_availableItems == 0) revert NoAvailableItems();

        --_availableItems;
        ++_lastRequestId;

        // commit to a future block
        uint256 request = createRequest(
            msg.sender,
            _lastRequestId,
            blockNumber
        );
        _requestList.add(request);

        // give change
        payable(msg.sender).sendValue(msg.value - 0.03 ether);
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
    function fulfillRequest() external {
        uint256 length = _requestList.length();
        if (length == 0) revert NoRequestToFulfill();

        _fulfillRequests(length);
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
     * WARNING a counter for assets should be set otherwise it override
     * previous `assets` when empty
     * */
    function addAsset(address assetAddr) external onlyOwner {
        // check addr? onlyOwner
        uint256 length = _activeIndexList.length();
        uint256 index;
        if (length != 0) {
            index = _activeIndexList.at(length - 1) + 1;
        } else {
            index = 1;
        }

        _activeIndexList.add(index);
        _assetByIndex[index] = assetAddr;
        _assetsBoxesByIndex[index].itemsAmount = 84;
        _availableItems += 84;
    }

    /*////////////////////////////
                GETTERS
    ////////////////////////////*/

    /// @return requests list (`uint256[] memory`)
    function requestList() external view returns (uint256[] memory) {
        return _requestList.values();
    }

    /// @return list of pending mints of an user (`uint256[] memory`)
    function pendingMints(address account)
        external
        view
        returns (uint256[] memory)
    {
        return _itemsToMint[account];
    }

    /// @return WARN index for assets should be set
    function numberOfAssets() external view returns (uint256) {
        return _activeIndexList.length();
    }

    /// @return number of items available to request (`uint256`)
    function availableItems() external view returns (uint256) {
        return _availableItems;
    }

    /// @return remaining item for a specific `assets` (`uint256`)
    function remainningItemAtIndex(uint256 index)
        external
        view
        returns (uint256)
    {
        if (!_activeIndexList.contains(index)) revert InexistantIndex(index);
        return _assetsBoxesByIndex[index].itemsAmount;
    }

    /// @return totalItem total remaining item among all assets (`uint256`)
    function totalRemainingItems() external view returns (uint256 totalItem) {
        for (uint256 i; i < _activeIndexList.length(); ) {
            totalItem += _assetsBoxesByIndex[_activeIndexList.at(i)]
                .itemsAmount;
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
        address assetAddr = _assetByIndex[index];
        if (assetAddr == address(0)) revert InexistantAsset(index);

        return SolarPunkService.encodedMetadata(tokenId, assetAddr);
    }

    /*////////////////////////////
            INTERNAL FUNCTIONS
    ////////////////////////////*/
    /**
     * @dev First select an assets where to draw an item, then draw it
     * using the {SwapAndPop} library. And finally encode NFT informations
     * into the tokenID
     *
     * @return unique encoded tokenID
     */
    function _drawAndTransform(uint256 randNum) internal returns (uint256) {
        uint256 index = _activeIndexList.at(
            randNum % _activeIndexList.length()
        );
        uint256 itemId = _assetsBoxesByIndex[index].draw(randNum);

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
    function _fulfillRequests(uint256 length) internal {
        uint256 lastBlockhash = block.number - 256;

        for (uint256 i; i < length; ) {
            uint256 request = _requestList.at(i);
            uint256 blockNumber = uint64(request);
            address requestOwner = address(uint160(request >> 96));

            if (blockNumber >= block.number) {
                unchecked {
                    ++i;
                }
                continue;
            }

            if (blockNumber < lastBlockhash) {
                // postpone the request
                ++_lastRequestId;
                uint256 postponedRequest = createRequest(
                    requestOwner,
                    _lastRequestId,
                    block.number + 3000
                );
                _requestList.add(postponedRequest);
                unchecked {
                    ++i;
                }
            } else {
                if (requestOwner == msg.sender) {
                    // mint directly the item
                    _mint(
                        msg.sender,
                        _drawAndTransform(uint256(blockhash(blockNumber)))
                    );
                } else {
                    // add item to the minting list
                    _itemsToMint[requestOwner].push(
                        _drawAndTransform(uint256(blockhash(blockNumber)))
                    );
                }
                --length;
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
