// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/SolarPunk.sol";
import "src/figures/Kiwi.sol";

contract SolarPunk_test is Test {
    SolarPunk internal solars;

    address internal KIWI;

    address internal constant OWNER = address(501);
    address internal constant USER = address(100);

    address internal constant FIGURE1 = address(1);
    address internal constant FIGURE2 = address(2);
    address internal constant FIGURE3 = address(3);
    address internal constant FIGURE4 = address(4);
    address internal constant FIGURE5 = address(5);

    function setUp() public {
        solars = new SolarPunk(OWNER);
        KIWI = address(new Kiwi());

        vm.deal(USER, 10000 ether);
        vm.roll(25000);
    }

    function testMintRequest() public {
        vm.startPrank(OWNER);
        solars.addNewPrincipe(KIWI);
        assertEq(solars.totalRemainingItems(), 84);
        vm.stopPrank();

        // test
        vm.prank(USER);
        solars.requestMint{value: 1 ether}(0);

        vm.roll(25030);
        vm.prank(USER);
        solars.requestMint{value: 1 ether}(2);

        vm.roll(26000);
        vm.prank(USER);
        solars.requestMint{value: 1 ether}(2);

        // emit log_string(
        //     solars.tokenURI(
        //         484302442900641723227132053990577840975135510140212408570553425609105604608
        //     )
        // );
    }
}
