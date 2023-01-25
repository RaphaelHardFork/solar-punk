// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";

abstract contract Roles is Test {
    address internal constant OWNER = address(501);
    address[] internal USERS;

    function _newUsersSet(uint160 offset, uint256 length) internal {
        address[] memory list = new address[](length);

        for (uint160 i; i < length; i++) {
            list[i] = address(i + offset + 1);
            vm.deal(list[i], 10000 ether);
        }
        USERS = list;
    }
}
