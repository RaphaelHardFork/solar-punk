// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

abstract contract Destructible {
    function destruct() external {
        selfdestruct(payable(msg.sender));
    }
}
