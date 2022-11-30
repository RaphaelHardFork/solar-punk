// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract CounterScript is Script, Test {
    function setUp() public {}

    function run() public {
        emit log_address(msg.sender);
        vm.broadcast();
    }
}
