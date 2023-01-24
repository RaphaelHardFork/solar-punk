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
error RequestAlreadyExist(uint256 blockNumber);

error NoRequestToFulfill();
error InexistantIndex(uint256 index);
error InexistantAsset(uint256 index);

contract SolarPunk is ERC721Enumerable, Ownable {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.UintSet;
    using SwapAndPop for SwapAndPop.Box;

    uint256 private _availableItems;

    mapping(uint256 => address) private _assetByIndex;
    mapping(uint256 => SwapAndPop.Box) private _assetsBoxesByIndex;
    mapping(address => uint256[]) private _itemsToMint;
    EnumerableSet.UintSet private _activeIndexList;
    EnumerableSet.UintSet private _requestList;

    constructor(address owner) ERC721("SolarPunk", "SPK") {
        transferOwnership(owner);
    }

    /*////////////////////////////
            PUBLIC FUNCTIONS
    ////////////////////////////*/
    function requestMint(uint256 blockNumber) external payable {
        // check input value
        if (blockNumber <= block.number || blockNumber > block.number + 72000)
            revert OutOfBlockRange(blockNumber);
        if (msg.value < 0.03 ether) revert ValueBelowExpected(msg.value);
        if (_availableItems == 0) revert NoAvailableItems();
        --_availableItems;

        // commit to a block
        uint256 request = uint256(
            bytes32(abi.encodePacked(uint160(msg.sender), uint96(blockNumber)))
        );
        if (_requestList.contains(request))
            revert RequestAlreadyExist(blockNumber);
        _requestList.add(request);

        // TODO fulfill request for discount

        // refund overdue
        payable(msg.sender).sendValue(msg.value - 0.03 ether);
    }

    function fulfillRequest() external {
        uint256 length = _requestList.length();
        if (length == 0) revert NoRequestToFulfill();

        _fulfillRequests(length);
    }

    /// @dev avoid big list!
    function mintPendingItems() external {
        uint256[] memory pendingItem = _itemsToMint[msg.sender];
        for (uint256 i; i < pendingItem.length; ) {
            _mint(msg.sender, pendingItem[i]);
        }
        delete _itemsToMint[msg.sender];
    }

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
    function requestList() external view returns (uint256[] memory) {
        return _requestList.values();
    }

    function pendingMints(address account)
        external
        view
        returns (uint256[] memory)
    {
        return _itemsToMint[account];
    }

    function numberOfAssets() external view returns (uint256) {
        return _activeIndexList.length();
    }

    function availableItems() external view returns (uint256) {
        return _availableItems;
    }

    function remainningItemAtIndex(uint256 index)
        external
        view
        returns (uint256)
    {
        if (!_activeIndexList.contains(index)) revert InexistantIndex(index);
        return _assetsBoxesByIndex[index].itemsAmount;
    }

    function totalRemainingItems() external view returns (uint256 totalItem) {
        for (uint256 i; i < _activeIndexList.length(); ) {
            totalItem += _assetsBoxesByIndex[_activeIndexList.at(i)]
                .itemsAmount;
            unchecked {
                ++i;
            }
        }
    }

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
     * @notice Take an item from available item and return
     * NFT metadata packed into an `uint256`
     */
    function _drawAndTransform(uint256 randNum) internal returns (uint256) {
        // draw
        uint256 index = _activeIndexList.at(
            randNum % _activeIndexList.length()
        );
        uint256 itemId = _assetsBoxesByIndex[index].draw(randNum);

        // transform
        return SolarPunkService.transformItemId(index, itemId);
    }

    function _fulfillRequests(uint256 length) internal {
        uint256 lastBlockhash = block.number - 256;
        uint256[] memory requestToClean = new uint256[](length);

        for (uint256 i; i < length; ) {
            uint256 request = _requestList.at(i);
            uint256 blockNumber = uint96(request);
            address requestOwner = address(uint160(request >> 96));

            if (blockNumber < lastBlockhash) {
                // request should be postponed
                requestToClean[i] = request;
                _requestList.add(
                    uint256(
                        bytes32(
                            abi.encodePacked(
                                uint160(requestOwner),
                                uint96(block.number + 3000 + i)
                            )
                        )
                    )
                );
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
            }

            unchecked {
                ++i;
            }
        }

        // clean erroned requests in the list
        for (uint256 i; i < length; ) {
            if (requestToClean[i] != 0) {
                _requestList.remove(requestToClean[i]);
            }
            unchecked {
                ++i;
            }
        }
    }
}
