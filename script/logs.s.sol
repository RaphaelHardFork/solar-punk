// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/Test.sol";
import "forge-std/StdJson.sol";

import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract logs is Script, Test {
    using Strings for uint256;
    using stdJson for string;

    function run() public {
        emit log_string("Hello SolarPunk");
    }
}
