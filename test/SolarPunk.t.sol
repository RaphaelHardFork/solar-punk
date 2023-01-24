// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, Vm} from "forge-std/Test.sol";

import "src/SolarPunk.sol";
import "src/vectors/assets/Kiwi.sol";
import "src/vectors/assets/IAsset.sol";

contract MockFigure is IAsset {
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

    function test_constructor_NameAndOwnerShip() public {
        assertEq(solar.name(), "SolarPunk");
        assertEq(solar.symbol(), "SPK");
        assertEq(solar.owner(), OWNER);
    }

    function test_addAsset_FirstOne() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        assertEq(solar.availableItems(), 84);
        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemAtIndex(1), 84);
        assertEq(solar.numberOfAssets(), 1);
    }

    function test_addAsset_SecondOne() public {
        vm.startPrank(OWNER);
        solar.addAsset(FIGURE1);
        solar.addAsset(KIWI);
        assertEq(solar.availableItems(), 84 * 2);
        assertEq(solar.totalRemainingItems(), 84 * 2);
        assertEq(solar.remainningItemAtIndex(2), 84);
        assertEq(solar.numberOfAssets(), 2);
    }

    function test_addAsset_AllowRandomAddr(address addr) public {
        vm.prank(OWNER);
        solar.addAsset(addr);
        assertEq(solar.availableItems(), 84);
        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemAtIndex(1), 84);
        assertEq(solar.numberOfAssets(), 1);
    }

    function test_requestMint_CannotWhenWrongBlockRange() public {
        uint256 belowRange = block.number - 1;
        uint256 aboveRange = block.number + 72001;
        vm.startPrank(USER);
        vm.expectRevert(
            abi.encodeWithSelector(OutOfBlockRange.selector, belowRange)
        );
        solar.requestMint(belowRange);

        vm.expectRevert(
            abi.encodeWithSelector(OutOfBlockRange.selector, aboveRange)
        );
        solar.requestMint(aboveRange);
    }

    function test_requestMint_CannotWhenLessValue() public {}

    function test_requestMint_CannotWhenNoItemAvailable() public {}
}
