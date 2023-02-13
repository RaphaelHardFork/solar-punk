// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/Base64.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

import {Roles} from "./base/Roles.sol";
import {BaseSolarPunk, SolarPunk, ISolarPunk} from "./base/BaseSolarPunk.sol";

contract SolarPunk_test is BaseSolarPunk, Roles {
    using Strings for uint256;

    function setUp() public {
        _deploy_solarPunk(OWNER);
        _deploy_kiwi();
        _deploy_dragonfly();
        _deploy_onion();
        _newUsersSet(50, 5);

        vm.roll(100000);
    }

    /*////////////////////////////////////////////////////
                        DEPLOYMENT
    ////////////////////////////////////////////////////*/

    function test_constructor_NameAndOwnerShip() public {
        assertEq(solar.name(), "SolarPunk v0.5");
        assertEq(solar.symbol(), "SPKv0.5");
        assertEq(solar.owner(), OWNER);
    }

    /*////////////////////////////////////////////////////
                    ASSETS DISTRIBUTION
    ////////////////////////////////////////////////////*/

    /*/////////////////////////////////////////////////
                        addAsset()
    /////////////////////////////////////////////////*/
    function test_addAsset_FirstOne() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        assertEq(solar.availableItems(), 84);
        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemOfShape(1), 84);
        assertEq(solar.numberOfShapes(), 1);
    }

    function test_addAsset_Emit() public {
        vm.prank(OWNER);
        vm.expectEmit(false, false, false, true, SOLAR);
        emit AssetAdded(1, KIWI);
        solar.addAsset(KIWI);
    }

    function test_addAsset_SecondOne(address addr) public {
        vm.startPrank(OWNER);
        solar.addAsset(addr);
        solar.addAsset(KIWI);
        assertEq(solar.availableItems(), 84 * 2);
        assertEq(solar.totalRemainingItems(), 84 * 2);
        assertEq(solar.remainningItemOfShape(2), 84);
        assertEq(solar.numberOfShapes(), 2);
    }

    /*/////////////////////////////////////////////////
                        requestMint()
    /////////////////////////////////////////////////*/
    function test_requestMint_CannotWhenWrongBlockRange() public {
        uint256 belowRange = block.number - 1;
        uint256 aboveRange = block.number + 72001;
        vm.startPrank(USERS[0]);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISolarPunk.OutOfBlockRange.selector,
                belowRange
            )
        );
        solar.requestMint(belowRange, 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISolarPunk.OutOfBlockRange.selector,
                aboveRange
            )
        );
        solar.requestMint(aboveRange, 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISolarPunk.OutOfBlockRange.selector,
                block.number
            )
        );
        solar.requestMint(block.number, 1);
    }

    function test_requestMint_CannotWhenLessValue() public {
        vm.startPrank(USERS[0]);
        vm.expectRevert(
            abi.encodeWithSelector(ISolarPunk.ValueBelowExpected.selector, 0)
        );
        solar.requestMint(block.number + 1, 1);
        vm.expectRevert(
            abi.encodeWithSelector(ISolarPunk.ValueBelowExpected.selector, 100)
        );
        solar.requestMint{value: 100}(block.number + 1, 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISolarPunk.ValueBelowExpected.selector,
                PRICE
            )
        );
        solar.requestMint{value: PRICE}(block.number + 1, 2);
    }

    function test_requestMint_CannotWhenNoItemAvailable() public {
        vm.prank(USERS[0]);
        vm.expectRevert(ISolarPunk.NoAvailableItems.selector);
        solar.requestMint{value: 0.03 ether}(block.number + 1, 1);

        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USERS[0]);
        vm.expectRevert(ISolarPunk.NoAvailableItems.selector);
        solar.requestMint{value: PRICE * 85}(block.number + 1, 85);
    }

    function test_requestMint_RequestOneMint() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock, 1);

        assertEq(solar.availableItems(), 83);

        (address[] memory addresses, uint256[] memory blockNumbers) = solar
            .requestList();
        assertEq(addresses[0], USERS[0]);
        assertEq(blockNumbers[0], targetBlock);
    }

    function test_requestMint_RequestSeveralMint() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock, 4);

        assertEq(solar.availableItems(), 80);

        (address[] memory addresses, uint256[] memory blockNumbers) = solar
            .requestList();
        for (uint256 i; i < addresses.length; i++) {
            assertEq(addresses[i], USERS[0]);
            assertEq(blockNumbers[i], targetBlock);
        }
    }

    function test_requestMint_Emit() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.expectEmit(true, false, false, true, SOLAR);
        emit RequestCreated(USERS[0], block.number + 5, 6);

        vm.prank(USERS[0]);
        solar.requestMint{value: PRICE * 6}(block.number + 5, 6);
    }

    function test_requestMint_GiveChange() public {
        uint256 balance = USERS[0].balance;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 1 ether}(block.number + 10, 1);

        assertEq(USERS[0].balance, balance - PRICE);
    }

    function test_requestMint_CannotExceedRequestLimit() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(OWNER);
        solar.addAsset(DRAGONFLY);

        vm.startPrank(USERS[0]);

        vm.expectRevert(ISolarPunk.RequestListTooLong.selector);
        solar.requestMint{value: PRICE * 101}(block.number + 10, 101);
    }

    function test_requestMint_RequestAllItem() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: PRICE * 84}(block.number + 10, 84);
        assertEq(solar.availableItems(), 0);
    }

    /*/////////////////////////////////////////////////
                        fulfillRequest()
    /////////////////////////////////////////////////*/
    function test_fulfillRequest_CannotWhenNoRequest() public {
        vm.prank(USERS[0]);
        vm.expectRevert(ISolarPunk.NoRequestToFulfill.selector);
        solar.fulfillRequest(false);
    }

    function test_fulfillRequest_FillOwnRequestAndMint() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock, 1);
        vm.roll(block.number + 11);
        solar.fulfillRequest(false);

        assertEq(solar.totalRemainingItems(), 83);
        assertEq(solar.remainningItemOfShape(1), 83);
        assertEq(solar.balanceOf(USERS[0]), 1);
    }

    function test_fulfillRequest_FillOtherRequest() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock, 1);
        vm.roll(block.number + 11);
        vm.prank(USERS[1]);
        solar.fulfillRequest(false);

        assertEq(solar.totalRemainingItems(), 83);
        assertEq(solar.remainningItemOfShape(1), 83);
        assertEq(solar.balanceOf(USERS[0]), 0);

        assertEq(solar.pendingMints(USERS[0]).length, 1);
    }

    function test_fulfillRequest_PostponeOwnRequest() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock, 1);
        vm.roll(block.number + 300);
        solar.fulfillRequest(false);

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemOfShape(1), 84);
        assertEq(solar.balanceOf(USERS[0]), 0);

        (address[] memory addresses, uint256[] memory blockNumbers) = solar
            .requestList();
        assertEq(addresses.length, 1);
        assertEq(addresses[0], USERS[0]);
        assertEq(blockNumbers[0], block.number + 3000);
    }

    function test_fulfillRequest_EmitOnPostpone() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(block.number + 5, 1);
        vm.roll(block.number + 300);

        vm.expectEmit(true, false, false, true, SOLAR);
        emit RequestPostponed(USERS[0], block.number + 3000);
        solar.fulfillRequest(false);
    }

    function test_fulfillRequest_PostponeOtherRequest() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock, 1);
        vm.roll(block.number + 300);
        vm.prank(USERS[1]);
        solar.fulfillRequest(false);

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemOfShape(1), 84);
        assertEq(solar.balanceOf(USERS[0]), 0);

        (address[] memory addresses, uint256[] memory blockNumbers) = solar
            .requestList();
        assertEq(addresses.length, 1);
        assertEq(addresses[0], USERS[0]);
        assertEq(blockNumbers[0], block.number + 3000);
    }

    function test_fulfillRequest_FillSeveralOwnRequestsAndMint() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: PRICE * 4}(targetBlock, 4);
        vm.roll(block.number + 11);
        solar.fulfillRequest(false);

        assertEq(solar.totalRemainingItems(), 80);
        assertEq(solar.remainningItemOfShape(1), 80);
        assertEq(solar.balanceOf(USERS[0]), 4);
    }

    function test_fulfillRequest_FillSeveralOtherRequests() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USERS[0]);
        solar.requestMint{value: PRICE * 4}(targetBlock, 4);
        vm.roll(block.number + 11);
        vm.prank(USERS[1]);
        solar.fulfillRequest(false);

        assertEq(solar.totalRemainingItems(), 80);
        assertEq(solar.remainningItemOfShape(1), 80);
        assertEq(solar.balanceOf(USERS[0]), 0);
    }

    function test_fulfillRequest_PostponeOwnRequests() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: PRICE * 4}(targetBlock, 4);
        vm.roll(block.number + 300);
        solar.fulfillRequest(false);

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemOfShape(1), 84);
        assertEq(solar.balanceOf(USERS[0]), 0);

        (address[] memory addresses, uint256[] memory blockNumbers) = solar
            .requestList();
        assertEq(addresses.length, 4);
        for (uint256 i; i < addresses.length; i++) {
            assertEq(addresses[i], USERS[0]);
            assertApproxEqAbs(blockNumbers[i], block.number + 3000, 10);
        }
    }

    function test_fulfillRequest_PostponeOtherRequests() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: PRICE * 4}(targetBlock, 4);

        vm.stopPrank();
        (address[] memory addresses, uint256[] memory blockNumbers) = solar
            .requestList();
        assertEq(addresses.length, 4);

        vm.prank(USERS[1]);
        vm.roll(block.number + 3000);
        solar.fulfillRequest(false);

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemOfShape(1), 84);
        assertEq(solar.balanceOf(USERS[0]), 0);

        (addresses, blockNumbers) = solar.requestList();
        assertEq(addresses.length, 4);
        for (uint256 i; i < addresses.length; i++) {
            assertEq(addresses[i], USERS[0]);
            assertApproxEqAbs(blockNumbers[i], block.number + 3000, 10);
        }
    }

    function test_fulfillRequest_LargeNumberOfRequest() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USERS[0]);
        solar.requestMint{value: PRICE * 15}(targetBlock, 15);
        vm.prank(USERS[1]);
        solar.requestMint{value: PRICE * 15}(targetBlock, 15);
        vm.prank(USERS[2]);
        solar.requestMint{value: PRICE * 15}(targetBlock, 15);
        vm.prank(USERS[3]);
        solar.requestMint{value: PRICE * 15}(targetBlock, 15);
        vm.prank(USERS[4]);
        solar.requestMint{value: PRICE * 15}(targetBlock, 15);
        (address[] memory addresses, uint256[] memory blockNumbers) = solar
            .requestList();
        assertEq(addresses.length, 5 * 15);
        vm.roll(block.number + 11);
        vm.prank(USERS[1]);
        solar.fulfillRequest(false);

        assertEq(solar.balanceOf(USERS[1]), 15);
        (addresses, blockNumbers) = solar.requestList();
        assertEq(addresses.length, 0);
        assertEq(solar.pendingMints(USERS[0]).length, 15);
        assertEq(solar.pendingMints(USERS[1]).length, 0);
        assertEq(solar.pendingMints(USERS[2]).length, 15);
        assertEq(solar.pendingMints(USERS[3]).length, 15);
        assertEq(solar.pendingMints(USERS[4]).length, 15);
    }

    function test_fulfillRequest_OneRequestAmongLargeNumber() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(OWNER);
        solar.addAsset(DRAGONFLY);

        vm.prank(USERS[0]);
        solar.requestMint{value: PRICE * 80}(block.number + 5, 80);
        vm.startPrank(USERS[1]);
        solar.requestMint{value: PRICE}(block.number + 5, 1);
        vm.roll(block.number + 11);
        solar.fulfillRequest(true);

        assertEq(solar.balanceOf(USERS[1]), 1);
        assertEq(solar.pendingMints(USERS[0]).length, 0);
    }

    function test_fulfillRequest_LargeNumberOfOtherRequest() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(OWNER);
        solar.addAsset(DRAGONFLY);

        vm.prank(USERS[0]);
        solar.requestMint{value: PRICE * 100}(block.number + 5, 100);
        vm.roll(block.number + 11);
        vm.prank(USERS[1]);
        solar.fulfillRequest(false);

        assertEq(solar.balanceOf(USERS[0]), 0);
        assertEq(solar.balanceOf(USERS[1]), 0);
        assertEq(solar.pendingMints(USERS[0]).length, 100);
    }

    function test_fulfillRequest_LargeNumberOfPostponedRequest() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(OWNER);
        solar.addAsset(DRAGONFLY);

        vm.prank(USERS[0]);
        solar.requestMint{value: PRICE * 100}(block.number + 5, 100);
        vm.roll(block.number + 300);

        vm.prank(USERS[1]);
        solar.fulfillRequest(false);

        assertEq(solar.balanceOf(USERS[0]), 0);
        assertEq(solar.balanceOf(USERS[1]), 0);
        assertEq(solar.pendingMints(USERS[0]).length, 0);
    }

    function test_fulfillRequest_FulfillAndMintAllItem() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: PRICE * 84}(block.number + 10, 84);

        vm.roll(block.number + 11);
        solar.fulfillRequest(false);

        assertEq(solar.balanceOf(USERS[0]), 84);
        assertEq(solar.totalRemainingItems(), 0);
        assertEq(solar.remainningItemOfShape(1), 0);
    }

    function test_fulfillRequest_FulfillSeveralShapeDistributionOnSameBlock()
        public
    {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(OWNER);
        solar.addAsset(DRAGONFLY);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: PRICE * 50}(block.number + 10, 50);

        vm.roll(block.number + 11);
        solar.fulfillRequest(false);
    }

    /*/////////////////////////////////////////////////
                    mintPendingItems()
    /////////////////////////////////////////////////*/
    function test_mintPendingItems_OneItemPending() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock, 1);
        vm.roll(block.number + 11);
        vm.prank(USERS[1]);
        solar.fulfillRequest(false);

        assertEq(solar.balanceOf(USERS[0]), 0);
        assertEq(solar.pendingMints(USERS[0]).length, 1);
        assertEq(solar.totalSupply(), 0);

        vm.prank(USERS[0]);
        solar.mintPendingItems();

        assertEq(solar.balanceOf(USERS[0]), 1);
        assertEq(solar.pendingMints(USERS[0]).length, 0);
    }

    function test_mintPendingItems_SeveralItemsPending() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USERS[0]);
        solar.requestMint{value: PRICE * 15}(targetBlock, 15);

        vm.roll(block.number + 11);
        vm.prank(USERS[1]);
        solar.fulfillRequest(false);

        assertEq(solar.balanceOf(USERS[0]), 0);
        assertEq(solar.pendingMints(USERS[0]).length, 15);
        assertEq(solar.totalSupply(), 0);

        vm.prank(USERS[0]);
        solar.mintPendingItems();

        assertEq(solar.balanceOf(USERS[0]), 15);
        assertEq(solar.pendingMints(USERS[0]).length, 0);
    }

    /*/////////////////////////////////////////////////
                       withdraw()
    /////////////////////////////////////////////////*/
    function test_withdraw_WithdrawCorrectly() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(OWNER);
        solar.addAsset(DRAGONFLY);

        vm.prank(USERS[0]);
        solar.requestMint{value: PRICE * 50}(block.number + 5, 50);
        assertEq(SOLAR.balance, PRICE * 50);

        vm.prank(OWNER);
        solar.withdraw();

        assertEq(SOLAR.balance, 0);
        assertEq(OWNER.balance, PRICE * 50);
    }

    /*/////////////////////////////////////////////////
                        ASSETS RENDERING
    /////////////////////////////////////////////////*/
    function test_tokenURI_CanReachAssetContract() public {
        uint256 targetBlock = block.number + 1;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock, 1);
        vm.roll(block.number + 2);
        vm.prank(USERS[0]);
        solar.fulfillRequest(false);

        uint256 tokenId = solar.tokenOfOwnerByIndex(USERS[0], 0);
        vm.expectCall(KIWI, abi.encodeWithSignature("name()"));
        solar.tokenURI(tokenId);
    }

    function test_tokenURI_RenderKiwi() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(block.number + 5, 1);
        vm.roll(block.number + 10);
        solar.fulfillRequest(false);

        uint256 tokenId = solar.tokenOfOwnerByIndex(USERS[0], 0);
        (bool success, ) = SOLAR.staticcall(
            abi.encodeWithSignature("tokenURI(uint256)", tokenId)
        );
        assertTrue(success);
    }

    function test_tokenURI_RenderDragonfly() public {
        vm.prank(OWNER);
        solar.addAsset(DRAGONFLY);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(block.number + 5, 1);
        vm.roll(block.number + 10);
        solar.fulfillRequest(false);

        uint256 tokenId = solar.tokenOfOwnerByIndex(USERS[0], 0);
        (bool success, ) = SOLAR.staticcall(
            abi.encodeWithSignature("tokenURI(uint256)", tokenId)
        );
        assertTrue(success);
    }

    function test_tokenURI_RenderOnion() public {
        vm.prank(OWNER);
        solar.addAsset(ONION);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(block.number + 5, 1);
        vm.roll(block.number + 10);
        solar.fulfillRequest(false);

        uint256 tokenId = solar.tokenOfOwnerByIndex(USERS[0], 0);
        (bool success, ) = SOLAR.staticcall(
            abi.encodeWithSignature("tokenURI(uint256)", tokenId)
        );
        assertTrue(success);
    }
}
