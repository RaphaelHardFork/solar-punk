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
    address internal constant USER3 = address(102);
    address internal constant USER4 = address(103);
    address internal constant USER5 = address(104);

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
        vm.deal(USER3, 10000 ether);
        vm.deal(USER4, 10000 ether);
        vm.deal(USER5, 10000 ether);
        vm.roll(100000);
    }

    function test_constructor_NameAndOwnerShip() public {
        assertEq(solar.name(), "SolarPunk v0.1");
        assertEq(solar.symbol(), "SPKv0.1");
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

    /*/////////////////////////////////////////////////
                        requestMint()
    /////////////////////////////////////////////////*/
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

        vm.expectRevert(
            abi.encodeWithSelector(OutOfBlockRange.selector, block.number)
        );
        solar.requestMint(block.number);
    }

    function test_requestMint_CannotWhenLessValue() public {
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSelector(ValueBelowExpected.selector, 0));
        solar.requestMint(block.number + 1);
        vm.expectRevert(
            abi.encodeWithSelector(ValueBelowExpected.selector, 100)
        );
        solar.requestMint{value: 100}(block.number + 1);
    }

    function test_requestMint_CannotWhenNoItemAvailable() public {
        vm.startPrank(USER);
        vm.expectRevert(NoAvailableItems.selector);
        solar.requestMint{value: 0.03 ether}(block.number + 1);
    }

    function test_requestMint_RequestOneMint() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USER);
        solar.requestMint{value: 0.03 ether}(targetBlock);

        assertEq(solar.availableItems(), 83);
        uint256[] memory requestList = solar.requestList();
        assertEq(workaround_readRequestOwner(requestList[0]), USER);
        assertEq(workaround_readRequestBlock(requestList[0]), targetBlock);
    }

    function test_requestMint_RequestSeveralMint() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USER);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock + 5);
        solar.requestMint{value: 0.03 ether}(targetBlock + 10);
        solar.requestMint{value: 0.03 ether}(targetBlock + 15);

        assertEq(solar.availableItems(), 80);
        uint256[] memory requestList = solar.requestList();
        for (uint256 i; i < requestList.length; i++) {
            assertEq(workaround_readRequestOwner(requestList[i]), USER);
            assertEq(
                workaround_readRequestBlock(requestList[i]),
                targetBlock + i * 5
            );
        }
    }

    function test_requestMint_GiveChange() public {
        uint256 balance = USER.balance;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USER);
        solar.requestMint{value: 1 ether}(block.number + 10);

        assertEq(USER.balance, balance - 0.03 ether);
    }

    function test_requestMint_CannotExceedRequestLimit() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(OWNER);
        solar.addAsset(FIGURE1);

        vm.startPrank(USER);
        for (uint256 i; i <= 100; i++) {
            solar.requestMint{value: 0.03 ether}(block.number + 10);
        }
        vm.expectRevert(RequestListTooLong.selector);
        solar.requestMint{value: 0.03 ether}(block.number + 10);
    }

    function test_requestMint_RequestAllItem() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USER);
        for (uint256 i; i < 84; i++) {
            solar.requestMint{value: 0.03 ether}(block.number + 10);
        }
        vm.expectRevert(NoAvailableItems.selector);
        solar.requestMint{value: 0.03 ether}(block.number + 10);
    }

    /*/////////////////////////////////////////////////
                        fulfillRequest()
    /////////////////////////////////////////////////*/
    function test_fulfillRequest_CannotWhenNoRequest() public {
        vm.prank(USER);
        vm.expectRevert(NoRequestToFulfill.selector);
        solar.fulfillRequest();
    }

    function test_fulfillRequest_FillOwnRequestAndMint() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USER);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 11);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 83);
        assertEq(solar.remainningItemAtIndex(1), 83);
        assertEq(solar.balanceOf(USER), 1);
    }

    function test_fulfillRequest_FillOtherRequest() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USER);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 11);
        vm.prank(USER2);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 83);
        assertEq(solar.remainningItemAtIndex(1), 83);
        assertEq(solar.balanceOf(USER), 0);

        assertEq(solar.pendingMints(USER).length, 1);
    }

    function test_fulfillRequest_PostponeOwnRequest() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USER);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 300);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemAtIndex(1), 84);
        assertEq(solar.balanceOf(USER), 0);

        uint256[] memory requestList = solar.requestList();
        assertEq(requestList.length, 1);
        assertEq(workaround_readRequestOwner(requestList[0]), USER);
        assertEq(
            workaround_readRequestBlock(requestList[0]),
            block.number + 3000
        );
    }

    function test_fulfillRequest_PostponeOtherRequest() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USER);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 300);
        vm.prank(USER2);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemAtIndex(1), 84);
        assertEq(solar.balanceOf(USER), 0);

        uint256[] memory requestList = solar.requestList();
        assertEq(requestList.length, 1);
        assertEq(workaround_readRequestOwner(requestList[0]), USER);
        assertEq(
            workaround_readRequestBlock(requestList[0]),
            block.number + 3000
        );
    }

    function test_fulfillRequest_FillSeveralOwnRequestsAndMint() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USER);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 11);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 80);
        assertEq(solar.remainningItemAtIndex(1), 80);
        assertEq(solar.balanceOf(USER), 4);
    }

    function test_fulfillRequest_FillSeveralOtherRequests() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USER);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.stopPrank();
        vm.roll(block.number + 11);
        vm.prank(USER2);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 80);
        assertEq(solar.remainningItemAtIndex(1), 80);
        assertEq(solar.balanceOf(USER), 0);
    }

    function test_fulfillRequest_PostponeOwnRequests() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USER);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock + 5);
        solar.requestMint{value: 0.03 ether}(targetBlock + 10);
        solar.requestMint{value: 0.03 ether}(targetBlock + 15);
        vm.roll(block.number + 300);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemAtIndex(1), 84);
        assertEq(solar.balanceOf(USER), 0);

        uint256[] memory requestList = solar.requestList();
        assertEq(requestList.length, 4);
        for (uint256 i; i < requestList.length; i++) {
            assertEq(workaround_readRequestOwner(requestList[i]), USER);
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
        vm.startPrank(USER);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.stopPrank();
        uint256[] memory requestList = solar.requestList();
        assertEq(requestList.length, 4);

        vm.prank(USER2);
        vm.roll(block.number + 3000);
        solar.fulfillRequest();

        assertEq(solar.totalRemainingItems(), 84);
        assertEq(solar.remainningItemAtIndex(1), 84);
        assertEq(solar.balanceOf(USER), 0);

        requestList = solar.requestList();
        assertEq(requestList.length, 4);
        for (uint256 i; i < requestList.length; i++) {
            assertEq(workaround_readRequestOwner(requestList[i]), USER);
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
            vm.prank(USER);
            solar.requestMint{value: 0.03 ether}(targetBlock);
            vm.prank(USER2);
            solar.requestMint{value: 0.03 ether}(targetBlock);
            vm.prank(USER3);
            solar.requestMint{value: 0.03 ether}(targetBlock);
            vm.prank(USER4);
            solar.requestMint{value: 0.03 ether}(targetBlock);
            vm.prank(USER5);
            solar.requestMint{value: 0.03 ether}(targetBlock);
        }
        uint256[] memory requestList = solar.requestList();
        assertEq(requestList.length, 5 * 15);
        vm.roll(block.number + 11);
        vm.prank(USER2);
        solar.fulfillRequest();

        assertEq(solar.balanceOf(USER2), 15);
        requestList = solar.requestList();
        assertEq(requestList.length, 0);
        assertEq(solar.pendingMints(USER).length, 15);
        assertEq(solar.pendingMints(USER2).length, 0);
        assertEq(solar.pendingMints(USER3).length, 15);
        assertEq(solar.pendingMints(USER4).length, 15);
        assertEq(solar.pendingMints(USER5).length, 15);
    }

    function test_fulfillRequest_FulfillAndMintAllItem() public {
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.startPrank(USER);
        for (uint256 i; i < 84; i++) {
            solar.requestMint{value: 0.03 ether}(block.number + 10);
        }
        vm.roll(block.number + 11);
        solar.fulfillRequest();

        assertEq(solar.balanceOf(USER), 84);
        assertEq(solar.totalRemainingItems(), 0);
        assertEq(solar.remainningItemAtIndex(1), 0);
    }

    /*/////////////////////////////////////////////////
                    mintPendingItems()
    /////////////////////////////////////////////////*/
    function test_mintPendingItems_OneItemPending() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USER);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 11);
        vm.prank(USER2);
        solar.fulfillRequest();

        assertEq(solar.balanceOf(USER), 0);
        assertEq(solar.pendingMints(USER).length, 1);
        assertEq(solar.totalSupply(), 0);

        vm.prank(USER);
        solar.mintPendingItems();

        assertEq(solar.balanceOf(USER), 1);
        assertEq(solar.pendingMints(USER).length, 0);
    }

    function test_mintPendingItems_SeveralItemsPending() public {
        uint256 targetBlock = block.number + 10;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        for (uint256 i; i < 15; i++) {
            vm.prank(USER);
            solar.requestMint{value: 0.03 ether}(targetBlock);
        }
        vm.roll(block.number + 11);
        vm.prank(USER2);
        solar.fulfillRequest();

        assertEq(solar.balanceOf(USER), 0);
        assertEq(solar.pendingMints(USER).length, 15);
        assertEq(solar.totalSupply(), 0);

        vm.prank(USER);
        solar.mintPendingItems();

        assertEq(solar.balanceOf(USER), 15);
        assertEq(solar.pendingMints(USER).length, 0);
    }

    /*/////////////////////////////////////////////////
                        ASSETS RENDERING
    /////////////////////////////////////////////////*/
    function test_tokenURI_CanReachAssetContract() public {
        uint256 targetBlock = block.number + 1;
        vm.prank(OWNER);
        solar.addAsset(KIWI);
        vm.prank(USER);
        solar.requestMint{value: 0.03 ether}(targetBlock);
        vm.roll(block.number + 2);
        vm.prank(USER);
        solar.fulfillRequest();

        uint256 tokenId = solar.tokenOfOwnerByIndex(USER, 0);
        vm.expectCall(KIWI, abi.encodeWithSignature("name()"));
        solar.tokenURI(tokenId);
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
