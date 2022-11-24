// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Metadata.sol";

contract Metadata_test is Test {
    Metadata internal metadata;

    function setUp() public {
        metadata = new Metadata();
    }

    function testTokenURI() public {
        emit log_string(metadata.tokenURI(1));
    }
}
