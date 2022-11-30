// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

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

    constructor(address owner) ERC721("SolarPunk", "SPK") {
        transferOwnership(owner);
    }

    function requestMint(uint256 amount) external payable {
        require(msg.value >= 0.03 ether, "SPK: below minimum cost");

        uint256 discount = _executeMints(amount);
        _createMintRequest(msg.sender);

        // refund
        if (discount > msg.value) discount = msg.value;
        payable(msg.sender).sendValue(discount);
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
    }

    function currentPrincipes() external view returns (uint256) {
        return _currentPrincipesList.length();
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

    function _createMintRequest(address account) internal {
        uint96 targetBlock = uint96(block.number + 10);
        uint256 mintRequest = uint256(
            bytes32(abi.encodePacked(account, uint96(block.number + 10)))
        );

        _queuedMint.add(mintRequest);
        emit MintRequestCreated(account, mintRequest, targetBlock);
    }

    function _executeMints(uint256 amount) internal returns (uint256 discount) {
        if (amount >= 10) {
            amount = 10;
        }
        if (amount > _queuedMint.length()) {
            amount = _queuedMint.length();
        }

        uint256 gas = gasleft();

        uint256 currentBlockNumber = block.number;
        for (uint256 i; i < amount; ) {
            uint256 rawRequest = _queuedMint.at(i);
            (address account, uint96 blockNumber) = (
                address(uint160(rawRequest >> 96)),
                uint96(rawRequest)
            );

            unchecked {
                ++i;
            }

            if (blockNumber < currentBlockNumber - 255) {
                // postpone blocknumber as expired
                uint96 targetBlock = uint96(block.number + 10);
                uint256 mintRequest = uint256(
                    bytes32(
                        abi.encodePacked(account, uint96(block.number + 10))
                    )
                );
                _queuedMint.remove(rawRequest);
                _queuedMint.add(mintRequest);
                emit MintRequestPostponed(
                    account,
                    rawRequest,
                    mintRequest,
                    targetBlock
                );
                continue;
            }

            if (blockNumber >= blockNumber) {
                uint256 tokenId = _drawAndTransform(
                    uint256(blockhash(blockNumber)) * i
                );

                _queuedMint.remove(rawRequest);
                emit MintRequestFilled(account, rawRequest, tokenId);
                _mint(account, tokenId);
            }
        }

        // return value consummed for this operation
        discount = (gas - gasleft()) * tx.gasprice;
    }

    function _drawAndTransform(uint256 randNum) internal returns (uint256) {
        // draw
        uint256 principe = _currentPrincipesList.at(
            randNum % _currentPrincipesList.length()
        );
        uint256 itemId = _principeBoxes[principe].draw(randNum);

        // transform
        return SolarPunkService.transformItemId(principe + 1, itemId);
    }
}
