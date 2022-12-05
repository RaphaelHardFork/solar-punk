// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, Vm} from "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "src/SolarPunk.sol";
import "src/figures/Kiwi.sol";

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

    // KIWI
    /**
    * - mint without exec
    - mint one by one
    - cannot mint request
    - add new principe when empty,full, with few
    - exec his request
    - someone try to buy cheap
    - someone DDOS => pay at request
    - global cost
    - at the end
    - average discount
     */
    function testRequestMint(address user) public {
        vm.assume(
            user != address(0) &&
                user != address(solar) &&
                user != KIWI &&
                user != 0x4e59b44847b379578588920cA78FbF26c0B4956C &&
                user != 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496 &&
                user != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
        );
        vm.prank(OWNER);
        solar.addNewPrincipe(KIWI);
        assertEq(solar.availableItem(), 84);

        vm.deal(user, 1 ether);
        vm.prank(user);
        solar.requestMint{value: PRICE}(0); // no discound
        assertApproxEqAbs(user.balance, (1 ether) - PRICE, 0.00001 ether);
        assertEq(solar.availableItem(), 83);
    }

    function testCannotRequestMint() public {
        vm.expectRevert("SPK: no more mintable item");
        vm.prank(USER);
        solar.requestMint{value: PRICE}(0);

        vm.prank(OWNER);
        solar.addNewPrincipe(KIWI);
        vm.expectRevert("SPK: below minimum cost");
        vm.prank(USER);
        solar.requestMint{value: 10}(0);
    }

    function testMultipleRequestsBlockPerBlock() public {
        vm.prank(OWNER);
        solar.addNewPrincipe(KIWI);

        vm.startPrank(USER);
        for (uint256 i; i < 10; i++) {
            solar.requestMint{value: PRICE}(0);
            vm.roll(block.number + 1);
        }
        assertEq(solar.availableItem(), 74);
    }

    function testCannotRequestMultipleMintInOneBlock() public {
        vm.prank(OWNER);
        solar.addNewPrincipe(KIWI);
        vm.startPrank(USER);
        solar.requestMint{value: PRICE}(0);
        vm.expectRevert("SPK: duplicate request");
        solar.requestMint{value: PRICE}(0);
    }

    function testExecuteWhenRequest() public {
        vm.prank(OWNER);
        solar.addNewPrincipe(KIWI);
        vm.prank(USER);
        solar.requestMint{value: PRICE}(0);
        vm.roll(block.number + 11);

        vm.prank(USER2);
        solar.requestMint{value: PRICE}(1);

        assertEq(solar.totalRemainingItems(), 83);
        assertEq(solar.remainningItemAtPrincipe(1), 83);
        assertEq(solar.balanceOf(USER), 1);
        assertLt(10000 ether - USER2.balance, PRICE); // spend less than price
    }

    function testNotExecuteWhenRequest() public {
        vm.prank(OWNER);
        solar.addNewPrincipe(KIWI);
        vm.prank(USER);
        solar.requestMint{value: PRICE}(0);

        vm.prank(USER2);
        solar.requestMint{value: PRICE}(1);

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemAtPrincipe(1), 84);
        assertEq(solar.balanceOf(USER), 0);
        assertLt(10000 ether - USER2.balance, PRICE); // still less
    }

    function _readPostponeEvent(VmSafe.Log memory _event)
        internal
        returns (
            address account,
            uint256 oldBlock,
            uint256 newBlock
        )
    {
        account = address(uint160(uint256(_event.topics[1])));
        oldBlock = uint256(uint96(uint256(_event.topics[2])));
        newBlock = uint256(uint96(uint256(_event.topics[3])));
        assertEq(account, address(bytes20(_event.topics[2])));
        assertEq(newBlock, uint256(bytes32(_event.data)));
    }

    function testPostponeWhenRequest() public {
        vm.prank(OWNER);
        solar.addNewPrincipe(KIWI);
        vm.prank(USER);
        solar.requestMint{value: PRICE}(0);
        uint256 targetBlock = block.number + 10;
        vm.roll(block.number + 300);

        vm.recordLogs();
        vm.prank(USER2);
        solar.requestMint{value: PRICE}(1);
        VmSafe.Log[] memory events = vm.getRecordedLogs();
        (
            address account,
            uint256 oldBlock,
            uint256 newBlock
        ) = _readPostponeEvent(events[0]);
        assertEq(account, USER);
        assertEq(oldBlock, targetBlock);
        assertEq(newBlock, block.number + 11);

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemAtPrincipe(1), 84);
        assertEq(solar.balanceOf(USER), 0);
    }

    function testPostponeThenFill() public {
        vm.prank(OWNER);
        solar.addNewPrincipe(KIWI);
        vm.prank(USER);
        solar.requestMint{value: PRICE}(0);
        vm.roll(block.number + 300);

        vm.prank(USER2);
        solar.requestMint{value: PRICE}(10);
        vm.roll(block.number + 12);

        vm.prank(USER2);
        solar.requestMint{value: PRICE}(10);

        assertEq(solar.totalRemainingItems(), 83);
        assertEq(solar.remainningItemAtPrincipe(1), 83);
        assertEq(solar.balanceOf(USER), 1);
    }

    function testKiwi() public {
        // vm.prank(OWNER);
        // solar.addNewPrincipe(KIWI);
        // for (uint256 i; i < 82; i++) {
        //     vm.prank(USER);
        //     solar.requestMint{value: 0.03 ether}(2);
        //     vm.roll(25000 + i);
        // }
        // assertEq(solar.balanceOf(USER), 81);
        // emit log_uint(
        //     941915832678243264589206106682993736574453839430997718724049431743894126592 >>
        //         248
        // );
        // // emit log_uint(
        // //     941915832678243264589206106682993736574453839430997718724049431743894126592 <<
        // //         248
        // // );
        // solar.tokenURI(
        //     941915832678243264589206106682993736574453839430997718724049431743894126592
        // );
        // vm.roll(25030);
        // vm.prank(USER);
        // solar.requestMint{value: 0.03 ether}(10);
        // // no discount
        // uint256 balance = USER.balance;
        // vm.prank(USER);
        // solar.requestMint{value: 0.03 ether}(0);
        // assertEq(USER.balance, balance - 0.03 ether);
        // emit log_named_uint("Contract balance", address(solar).balance);
        // emit log_named_uint("Block n", block.number);
        // vm.prank(USER);
        // vm.expectRevert("SPK: no more mintable item");
        // solar.requestMint{value: 0.03 ether}(10);
    }
}
