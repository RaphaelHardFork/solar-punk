// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/Base64.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

import {Roles} from "./base/Roles.sol";
import {BaseSolarPunk, SolarPunk} from "./base/BaseSolarPunk.sol";

contract SolarPunk_test is BaseSolarPunk, Roles {
    using Strings for uint256;

    function setUp() public {
        _deploy_solarPunk(OWNER);
        _deploy_kiwi();
        _newUsersSet(50, 5);

        vm.roll(100000);
    }

    function test_constructor_NameAndOwnerShip() public {
        assertEq(solar.name(), "SolarPunk v0.4");
        assertEq(solar.symbol(), "SPKv0.4");
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
                SolarPunk.OutOfBlockRange.selector,
                belowRange
            )
        );
        solar.requestMint(belowRange);

        vm.expectRevert(
            abi.encodeWithSelector(
                SolarPunk.OutOfBlockRange.selector,
                aboveRange
            )
        );
        solar.requestMint(aboveRange);

        vm.expectRevert(
            abi.encodeWithSelector(
                SolarPunk.OutOfBlockRange.selector,
                block.number
            )
        );
        solar.requestMint(block.number);
    }

    function test_requestMint_CannotWhenLessValue() public {
        vm.startPrank(USERS[0]);
        vm.expectRevert(
            abi.encodeWithSelector(SolarPunk.ValueBelowExpected.selector, 0)
        );
        solar.requestMint(block.number + 1);
        vm.expectRevert(
            abi.encodeWithSelector(SolarPunk.ValueBelowExpected.selector, 100)
        );
        solar.requestMint{value: 100}(block.number + 1);
    }

    function test_requestMint_CannotWhenNoItemAvailable() public {
        vm.startPrank(USERS[0]);
        vm.expectRevert(SolarPunk.NoAvailableItems.selector);
        solar.requestMint{value: 0.03 ether}(block.number + 1);
    }

    function test_requestMint_RequestOneMint() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock);

        assertEq(solar.availableItems(), 83);
        uint256[] memory requestList = solar.requestList();
        assertEq(workaround_readRequestOwner(requestList[0]), USERS[0]);
        assertEq(workaround_readRequestBlock(requestList[0]), targetBlock);
    }

    function test_requestMint_RequestSeveralMint() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock + 5);
        solar.requestMint{value: 0.03 ether}(targetBlock + 10);
        solar.requestMint{value: 0.03 ether}(targetBlock + 15);

        assertEq(solar.availableItems(), 80);
        uint256[] memory requestList = solar.requestList();
        for (uint256 i; i < requestList.length; i++) {
            assertEq(workaround_readRequestOwner(requestList[i]), USERS[0]);
            assertEq(
                workaround_readRequestBlock(requestList[i]),
                targetBlock + i * 5
            );
        }
    }

    function test_requestMint_GiveChange() public {
        uint256 balance = USERS[0].balance;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 1 ether}(block.number + 10);

        assertEq(USERS[0].balance, balance - PRICE);
    }

    function test_requestMint_CannotExceedRequestLimit() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(OWNER);
        solar.addAsset(KIWI);

        vm.startPrank(USERS[0]);
        for (uint256 i; i <= 100; i++) {
            solar.requestMint{value: 0.03 ether}(block.number + 10);
        }
        vm.expectRevert(SolarPunk.RequestListTooLong.selector);
        solar.requestMint{value: 0.03 ether}(block.number + 10);
    }

    function test_requestMint_RequestAllItem() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        for (uint256 i; i < 84; i++) {
            solar.requestMint{value: 0.03 ether}(block.number + 10);
        }
        vm.expectRevert(SolarPunk.NoAvailableItems.selector);
        solar.requestMint{value: 0.03 ether}(block.number + 10);
    }

    /*/////////////////////////////////////////////////
                        fulfillRequest()
    /////////////////////////////////////////////////*/
    function test_fulfillRequest_CannotWhenNoRequest() public {
        vm.prank(USERS[0]);
        vm.expectRevert(SolarPunk.NoRequestToFulfill.selector);
        solar.fulfillRequest();
    }

    function test_fulfillRequest_FillOwnRequestAndMint() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 11);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 83);
        assertEq(solar.remainningItemOfShape(1), 83);
        assertEq(solar.balanceOf(USERS[0]), 1);
    }

    function test_fulfillRequest_FillOtherRequest() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 11);
        vm.prank(USERS[1]);
        solar.fulfillRequest();

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
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 300);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemOfShape(1), 84);
        assertEq(solar.balanceOf(USERS[0]), 0);

        uint256[] memory requestList = solar.requestList();
        assertEq(requestList.length, 1);
        assertEq(workaround_readRequestOwner(requestList[0]), USERS[0]);
        assertEq(
            workaround_readRequestBlock(requestList[0]),
            block.number + 3000
        );
    }

    function test_fulfillRequest_PostponeOtherRequest() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 300);
        vm.prank(USERS[1]);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemOfShape(1), 84);
        assertEq(solar.balanceOf(USERS[0]), 0);

        uint256[] memory requestList = solar.requestList();
        assertEq(requestList.length, 1);
        assertEq(workaround_readRequestOwner(requestList[0]), USERS[0]);
        assertEq(
            workaround_readRequestBlock(requestList[0]),
            block.number + 3000
        );
    }

    function test_fulfillRequest_FillSeveralOwnRequestsAndMint() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 11);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 80);
        assertEq(solar.remainningItemOfShape(1), 80);
        assertEq(solar.balanceOf(USERS[0]), 4);
    }

    function test_fulfillRequest_FillSeveralOtherRequests() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.stopPrank();
        vm.roll(block.number + 11);
        vm.prank(USERS[1]);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 80);
        assertEq(solar.remainningItemOfShape(1), 80);
        assertEq(solar.balanceOf(USERS[0]), 0);
    }

    function test_fulfillRequest_PostponeOwnRequests() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock + 5);
        solar.requestMint{value: 0.03 ether}(targetBlock + 10);
        solar.requestMint{value: 0.03 ether}(targetBlock + 15);
        vm.roll(block.number + 300);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemOfShape(1), 84);
        assertEq(solar.balanceOf(USERS[0]), 0);

        uint256[] memory requestList = solar.requestList();
        assertEq(requestList.length, 4);
        for (uint256 i; i < requestList.length; i++) {
            assertEq(workaround_readRequestOwner(requestList[i]), USERS[0]);
            assertApproxEqAbs(
                workaround_readRequestBlock(requestList[i]),
                block.number + 3000,
                10
            );
        }
    }

    function test_fulfillRequest_PostponeOtherRequests() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.stopPrank();
        uint256[] memory requestList = solar.requestList();
        assertEq(requestList.length, 4);

        vm.prank(USERS[1]);
        vm.roll(block.number + 3000);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemOfShape(1), 84);
        assertEq(solar.balanceOf(USERS[0]), 0);

        requestList = solar.requestList();
        assertEq(requestList.length, 4);
        for (uint256 i; i < requestList.length; i++) {
            assertEq(workaround_readRequestOwner(requestList[i]), USERS[0]);
            assertApproxEqAbs(
                workaround_readRequestBlock(requestList[i]),
                block.number + 3000,
                10
            );
        }
    }

    function test_fulfillRequest_LargeNumberOfRequest() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        for (uint256 i; i < 15; i++) {
            vm.prank(USERS[0]);
            solar.requestMint{value: 0.03 ether}(targetBlock);
            vm.prank(USERS[1]);
            solar.requestMint{value: 0.03 ether}(targetBlock);
            vm.prank(USERS[2]);
            solar.requestMint{value: 0.03 ether}(targetBlock);
            vm.prank(USERS[3]);
            solar.requestMint{value: 0.03 ether}(targetBlock);
            vm.prank(USERS[4]);
            solar.requestMint{value: 0.03 ether}(targetBlock);
        }
        uint256[] memory requestList = solar.requestList();
        assertEq(requestList.length, 5 * 15);
        vm.roll(block.number + 11);
        vm.prank(USERS[1]);
        solar.fulfillRequest();

        assertEq(solar.balanceOf(USERS[1]), 15);
        requestList = solar.requestList();
        assertEq(requestList.length, 0);
        assertEq(solar.pendingMints(USERS[0]).length, 15);
        assertEq(solar.pendingMints(USERS[1]).length, 0);
        assertEq(solar.pendingMints(USERS[2]).length, 15);
        assertEq(solar.pendingMints(USERS[3]).length, 15);
        assertEq(solar.pendingMints(USERS[4]).length, 15);
    }

    function test_fulfillRequest_FulfillAndMintAllItem() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USERS[0]);
        for (uint256 i; i < 84; i++) {
            solar.requestMint{value: 0.03 ether}(block.number + 10);
        }
        vm.roll(block.number + 11);
        solar.fulfillRequest();

        assertEq(solar.balanceOf(USERS[0]), 84);
        assertEq(solar.totalRemainingItems(), 0);
        assertEq(solar.remainningItemOfShape(1), 0);
    }

    /*/////////////////////////////////////////////////
                    mintPendingItems()
    /////////////////////////////////////////////////*/
    function test_mintPendingItems_OneItemPending() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 11);
        vm.prank(USERS[1]);
        solar.fulfillRequest();

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
        for (uint256 i; i < 15; i++) {
            vm.prank(USERS[0]);
            solar.requestMint{value: 0.03 ether}(targetBlock);
        }
        vm.roll(block.number + 11);
        vm.prank(USERS[1]);
        solar.fulfillRequest();

        assertEq(solar.balanceOf(USERS[0]), 0);
        assertEq(solar.pendingMints(USERS[0]).length, 15);
        assertEq(solar.totalSupply(), 0);

        vm.prank(USERS[0]);
        solar.mintPendingItems();

        assertEq(solar.balanceOf(USERS[0]), 15);
        assertEq(solar.pendingMints(USERS[0]).length, 0);
    }

    /*/////////////////////////////////////////////////
                        ASSETS RENDERING
    /////////////////////////////////////////////////*/
    function test_tokenURI_CanReachAssetContract() public {
        uint256 targetBlock = block.number + 1;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USERS[0]);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 2);
        vm.prank(USERS[0]);
        solar.fulfillRequest();

        uint256 tokenId = solar.tokenOfOwnerByIndex(USERS[0], 0);
        vm.expectCall(KIWI, abi.encodeWithSignature("name()"));
        solar.tokenURI(tokenId);
    }

    function test_tokenURI_WriteAllURIs() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        // mint all token
        vm.startPrank(USERS[0]);
        for (uint256 i; i < 84; i++) {
            solar.requestMint{value: 0.03 ether}(block.number + 10);
        }
        vm.roll(block.number + 15);
        solar.fulfillRequest();
        assertEq(solar.totalSupply(), 84);

        for (uint256 i; i < 84; i++) {
            uint256 tokenId = solar.tokenOfOwnerByIndex(USERS[0], i);
            vm.writeFile(
                string.concat("cache/metadatas/raw/", i.toString()),
                solar.tokenURI(tokenId)
            );
        }
    }

    /*/////////////////////////////////////////////////
                        WORKAROUNDS
    /////////////////////////////////////////////////*/
    function workaround_readRequestOwner(uint256 request)
        internal
        pure
        returns (address)
    {
        return address(uint160(request >> 96));
    }

    function workaround_readRequestBlock(uint256 request)
        internal
        pure
        returns (uint256)
    {
        return uint64(request);
    }
}
