// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";
import "forge-std/StdJson.sol";

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract logs is Script, Test {
    using Strings for uint256;
    using stdJson for string;

    function run() public {
        // uint256 pk = vm.envUint(string.concat("ATTACKER_PRIVATE_KEY"));
        // address ATTACKER = vm.addr(pk);
        // vm.label(INSTANCE, "INSTANCE");
        // vm.label(address(ethernaut), "ETHERNAUT");
        // vm.label(ATTACKER, "ATTACKER");
        // emit log_named_uint("Balance: ", ATTACKER.balance);
        // vm.startPrank(ATTACKER);
        // ---
        bool success;
        bytes memory data;
        // ---

        emit log_named_bytes32("blockhash", blockhash(block.number - 257));
    }
}
