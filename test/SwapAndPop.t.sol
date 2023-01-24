// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, Vm} from "forge-std/Test.sol";
import "src/structs/SwapAndPop.sol";

contract SwapAndPop_test is Test {
    using SwapAndPop for SwapAndPop.Box;
    SwapAndPop.Box public box;

    mapping(uint256 => bool) internal _isFind;

    function setUp() public {}

    function testSetBox(uint256 listLength) public {
        box.itemsAmount = listLength;

        assertEq(box.itemsAmount, listLength);
    }

    function testDrawZero() public {
        box.itemsAmount = 100;
        uint256 drawed = box.draw(100);

        assertEq(box.itemsId[0], 99);
        assertEq(drawed, 0);

        drawed = box.draw(0);
        assertEq(box.itemsId[0], 98);
        assertEq(drawed, 99);
    }

    function testPopOnly() public {
        box.itemsAmount = 100;
        uint256 drawed = box.draw(99);

        assertEq(box.itemsId[99], 0);
        assertEq(drawed, 99);

        drawed = box.draw(99);
        assertEq(drawed, 0);
    }

    function testDraw(uint256 randNum) public {
        uint256 initialAmount = type(uint256).max;
        box.itemsAmount = initialAmount;
        uint256 index = randNum % box.itemsAmount;
        uint256 lastItem = box.itemsAmount - 1;

        uint256 drawed = box.draw(randNum); // = index

        assertEq(drawed, index);
        assertEq(box.itemsId[index], index != initialAmount - 1 ? lastItem : 0);
    }

    function testDrawAllItems() public {
        box.itemsAmount = 100;
        uint256 drawed;

        for (uint256 i; i < 100; i++) {
            drawed = box.draw(100 * (i + 10));
            assertFalse(_isFind[drawed], "id finded");
            _isFind[drawed] = true;
        }
        assertEq(box.itemsAmount, 0);

        for (uint256 i; i < 100; i++) {
            assertEq(box.itemsId[i], 0);
        }
    }

    function _printList(uint256 length) internal {
        emit log_string("List:");
        for (uint256 i; i < length; i++) {
            emit log_uint(box.itemsId[i]);
        }
    }
}
