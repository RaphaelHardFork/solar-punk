// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, Vm} from "forge-std/Test.sol";
import {SwapAndPop} from "src/structs/SwapAndPop.sol";

contract SwapAndPop_test is Test {
    using SwapAndPop for SwapAndPop.Reserve;
    SwapAndPop.Reserve public reserve;

    mapping(uint256 => bool) internal _isFind;

    function setUp() public {}

    // cannot draw
    // change stock in route

    function test_setup_SetEmptyBox(uint256 listLength) public {
        reserve.stock = listLength;

        assertEq(reserve.stock, listLength);
    }

    /// @notice SHOULD NOT happen, add error
    function test_setup_SetNotEmptyBox(uint256 itemAmount) public {
        reserve.stock = itemAmount;
        assertEq(reserve.stock, itemAmount);
    }

    function test_draw_CannotWhenEmpty() public {
        vm.expectRevert(SwapAndPop.Empty.selector);
        reserve.draw(5);
    }

    function test_draw_DrawZero() public {
        reserve.stock = 100;
        uint256 drawed = reserve.draw(100);

        assertEq(reserve.itemsId[0], 99);
        assertEq(drawed, 0);

        drawed = reserve.draw(0);
        assertEq(reserve.itemsId[0], 98);
        assertEq(drawed, 99);
    }

    function test_draw_PopOnly() public {
        reserve.stock = 100;
        uint256 drawed = reserve.draw(99);

        assertEq(reserve.itemsId[99], 0);
        assertEq(drawed, 99);

        drawed = reserve.draw(99);
        assertEq(drawed, 0);
    }

    function test_draw_DrawRandom(uint256 randNum) public {
        uint256 initialAmount = type(uint256).max;
        reserve.stock = initialAmount;
        uint256 index = randNum % reserve.stock;
        uint256 lastItem = reserve.stock - 1;

        uint256 drawed = reserve.draw(randNum); // = index

        assertEq(drawed, index);
        assertEq(
            reserve.itemsId[index],
            index != initialAmount - 1 ? lastItem : 0
        );
    }

    function test_draw_DrawAllItems() public {
        reserve.stock = 100;
        uint256 drawed;

        for (uint256 i; i < 100; i++) {
            drawed = reserve.draw(100 * (i + 10));
            assertFalse(_isFind[drawed], "id finded");
            _isFind[drawed] = true;
        }
        assertEq(reserve.stock, 0);

        for (uint256 i; i < 100; i++) {
            assertEq(reserve.itemsId[i], 0);
        }
    }

    function workaround_printReserve(uint256 length) internal {
        emit log_string("List:");
        for (uint256 i; i < length; i++) {
            emit log_uint(reserve.itemsId[i]);
        }
    }
}
