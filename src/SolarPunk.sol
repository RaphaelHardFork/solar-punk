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

    mapping(uint256 => address) private _figuresByPrincipes;
    mapping(uint256 => SwapAndPop.Box) private _principeBoxes;
    EnumerableSet.UintSet private _currentPrincipesList;

    uint256 private _availableItems;

    constructor(address owner) ERC721("SolarPunk", "SPK") {
        transferOwnership(owner);
    }

    /*////////////////////////////
            PUBLIC FUNCTIONS
    ////////////////////////////*/
    /**
     * @notice Mint a Solar with a pseudorandom number based on
     * sender address and curent available items
     *
     * TODO penalize large gas price? to avoid front-running on
     * one item
     */
    function mintSolar() external payable {
        require(msg.value >= 0.03 ether, "SPK: below minimum cost");
        require(_availableItems > 0, "SPK: no more mintable item");
        --_availableItems;

        uint256 tokenId = _drawAndTransform(
            uint256(
                keccak256(
                    bytes.concat(bytes20(msg.sender), bytes32(_availableItems))
                )
            )
        );
        _mint(msg.sender, tokenId);
        payable(msg.sender).sendValue(msg.value - 0.03 ether);
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

    /*////////////////////////////
            INTERNAL FUNCTIONS
    ////////////////////////////*/
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
        return SolarPunkService.transformItemId(principe, itemId);
    }
}
