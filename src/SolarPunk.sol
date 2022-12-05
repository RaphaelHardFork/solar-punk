// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";

import "src/metadata/SolarPunkService.sol";
import "src/boxes/SwapAndPop.sol";

contract SolarPunk is ERC721Enumerable, Ownable {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.UintSet;
    using SwapAndPop for SwapAndPop.Box;

    event MintRequestCreated(
        address indexed account,
        uint256 indexed mintRequest,
        uint256 targetBlock
    );
    event MintRequestPostponed(
        address indexed account,
        uint256 indexed oldMintRequest,
        uint256 indexed mintRequest,
        uint256 targetBlock
    );
    event MintRequestFilled(
        address indexed account,
        uint256 indexed mintRequest,
        uint256 tokenId
    );

    struct MintRequest {
        address account;
        uint96 blockNumber;
    }

    mapping(uint256 => address) private _figuresByPrincipes;
    mapping(uint256 => SwapAndPop.Box) private _principeBoxes;
    EnumerableSet.UintSet private _currentPrincipesList;
    EnumerableSet.UintSet private _queuedMint;

    uint256 private _availableItems;

    constructor(address owner) ERC721("SolarPunk", "SPK") {
        transferOwnership(owner);
    }

    /*////////////////////////////
            PUBLIC FUNCTIONS
    ////////////////////////////*/
    /**
     * @notice Create and store a mint request, decrease the
     * available number of item.
     * User can execute request for others user, this operation
     * is refunded
     */
    function requestMint(uint256 amount) external payable {
        require(msg.value >= 0.03 ether, "SPK: below minimum cost");

        // execute requests and return discount amount
        uint256 discount = _executeRequests(amount);

        // create and queue mint request
        require(_availableItems > 0, "SPK: no more mintable item");
        --_availableItems;
        uint96 targetBlock = uint96(block.number + 10);
        uint256 mintRequest = _packRequest(msg.sender, targetBlock);
        _queueRequest(mintRequest);

        emit MintRequestCreated(msg.sender, mintRequest, targetBlock);

        // refund
        payable(msg.sender).sendValue(
            discount > msg.value ? msg.value : discount
        );
    }

    /**
     * @notice Allow users to fill any requests
     */
    function fillMintRequests(uint256[] memory requests) external {
        for (uint256 i; i < requests.length; ) {
            _tryFillRequest(requests[i], block.number, i + 1);
            unchecked {
                ++i;
            }
        }
    }

    function addNewPrincipe(address figureAddr) external onlyOwner {
        uint256 length = _currentPrincipesList.length();
        uint256 index;
        if (length != 0) {
            index = _currentPrincipesList.at(length - 1) + 1;
        } else {
            index = 1;
        }

        _currentPrincipesList.add(index);
        _figuresByPrincipes[index] = figureAddr;
        _principeBoxes[index].itemsAmount = 84;
        _availableItems += 84;
    }

    /*////////////////////////////
                GETTERS
    ////////////////////////////*/
    function currentPrincipes() external view returns (uint256) {
        return _currentPrincipesList.length();
    }

    function availableItem() external view returns (uint256) {
        return _availableItems;
    }

    function remainningItemAtPrincipe(uint256 principe)
        external
        view
        returns (uint256)
    {
        require(
            _currentPrincipesList.contains(principe),
            "SPK: inexistant principe"
        );
        return _principeBoxes[principe].itemsAmount;
    }

    function totalRemainingItems() external view returns (uint256 totalItem) {
        for (uint256 i; i < _currentPrincipesList.length(); ) {
            totalItem += _principeBoxes[_currentPrincipesList.at(i)]
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
        address figureAddr = _figuresByPrincipes[uint8(tokenId >> 248)];
        require(figureAddr != address(0), "SPK: inexistant figure");

        return SolarPunkService.encodedMetadata(tokenId, figureAddr);
    }

    event log(uint256 a);

    /*////////////////////////////
            INTERNAL FUNCTIONS
    ////////////////////////////*/
    function _executeRequests(uint256 amount)
        internal
        returns (uint256 discount)
    {
        amount = Math.min(10, _queuedMint.length());
        uint256 initialGasAmount = gasleft();

        // loop among queued request
        for (uint256 i; i < amount; ) {
            uint256 rawRequest = _queuedMint.at(i);
            unchecked {
                ++i;
            }
            _tryFillRequest(rawRequest, block.number, i);
        }

        // return value consummed for this operation
        discount = amount == 0
            ? 0
            : (initialGasAmount - gasleft()) * tx.gasprice;
    }

    /**
     * @notice To be use in a loop, either fill or postpone or
     * nothing
     */
    function _tryFillRequest(
        uint256 rawRequest,
        uint256 currentBlockNumber,
        uint256 i
    ) internal {
        (address account, uint96 blockNumber) = _readRawRequest(rawRequest);
        require(account != address(0), "SPK: zero address in request");

        // too early
        if (currentBlockNumber < blockNumber) return; // exit

        // can execute
        if (currentBlockNumber - blockNumber <= 255) {
            uint256 tokenId = _drawAndTransform(
                uint256(blockhash(blockNumber)) * i
            );
            _queuedMint.remove(rawRequest);
            _mint(account, tokenId);
            emit MintRequestFilled(account, rawRequest, tokenId);
        } else {
            // request need to be postponed
            uint96 targetBlock = uint96(block.number + 10 + i);
            uint256 mintRequest = _packRequest(account, targetBlock);
            _queuedMint.remove(rawRequest);
            _queueRequest(rawRequest);
            emit MintRequestPostponed(
                account,
                rawRequest,
                mintRequest,
                targetBlock
            );
        }
    }

    /**
     * @notice Take an item from available item and return
     * NFT metadata packed into an `uint256`
     */
    function _drawAndTransform(uint256 randNum) internal returns (uint256) {
        // draw
        uint256 principe = _currentPrincipesList.at(
            randNum % _currentPrincipesList.length()
        );
        uint256 itemId = _principeBoxes[principe].draw(randNum);

        // transform
        return SolarPunkService.transformItemId(principe + 1, itemId);
    }

    function _queueRequest(uint256 rawRequest) internal {
        require(!_queuedMint.contains(rawRequest), "SPK: duplicate request");
        _queuedMint.add(rawRequest);
    }

    /*////////////////////////////
            INTERNAL GETTERS
    ////////////////////////////*/
    function _packRequest(address account, uint96 targetBlock)
        internal
        pure
        returns (uint256)
    {
        return uint256(bytes32(abi.encodePacked(account, targetBlock)));
    }

    function _readRawRequest(uint256 rawRequest)
        internal
        pure
        returns (address, uint96)
    {
        return (address(uint160(rawRequest >> 96)), uint96(rawRequest));
    }
}
