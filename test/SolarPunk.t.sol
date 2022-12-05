// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, Vm} from "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "src/SolarPunk.sol";
import "src/figures/Kiwi.sol";
import "src/figures/IFigure.sol";

contract MockFigure is IFigure {
    string public name = "name";

    function path(string memory) public pure override returns (string memory) {
        return "path";
    }

    function path(uint24) external pure override returns (string memory) {
        return path("path");
    }
}

contract SolarPunk_test is Test {
    SolarPunk internal solar;

    uint256 internal GAS_PRICE;
    uint256 internal PRICE;
    address internal KIWI;

    address internal constant OWNER = address(501);
    address internal constant USER = address(100);
    address internal constant USER2 = address(101);

    address internal constant FIGURE1 = address(1);
    address internal constant FIGURE2 = address(2);
    address internal constant FIGURE3 = address(3);
    address internal constant FIGURE4 = address(4);
    address internal constant FIGURE5 = address(5);

    function setUp() public {
        solar = new SolarPunk(OWNER);
        KIWI = address(new Kiwi());

        GAS_PRICE = tx.gasprice;
        PRICE = 0.03 ether;

        vm.deal(USER, 10000 ether);
        vm.deal(USER2, 10000 ether);
        vm.roll(100000);
    }

    function testAddNewPrincipe() public {
        vm.prank(OWNER);
        solar.addNewPrincipe(KIWI);

        assertEq(solar.availableItem(), 84);
        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemAtPrincipe(1), 84);
        assertEq(solar.currentPrincipes(), 1);
    }

    function testMintSolar() public {
        vm.prank(OWNER);
        solar.addNewPrincipe(KIWI);

        vm.prank(USER);
        solar.mintSolar{value: PRICE}();

        assertEq(solar.availableItem(), 83);
        assertEq(solar.totalRemainingItems(), 83);
        assertEq(solar.remainningItemAtPrincipe(1), 83);

        assertEq(solar.totalSupply(), 1);
        assertEq(solar.balanceOf(USER), 1);

        solar.tokenURI(solar.tokenOfOwnerByIndex(USER, 0));
    }

    function testCannotMintSolar() public {
        //     require(msg.value >= 0.03 ether, "SPK: below minimum cost");
        // require(_availableItems > 0, "SPK: no more mintable item");
    }

    function testMintAllSolar() public {
        //
    }

    function testManipulatePseudorandomMint(uint256 mintedItem) public {
        // try multiple pk created by USER one for each case of available items
        // mint the ultrarare and the superrare
    }
}
