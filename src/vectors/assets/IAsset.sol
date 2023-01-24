// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IAsset {
    function name() external view returns (string memory);

    function path(string memory color) external view returns (string memory);

    function path(uint24 color) external view returns (string memory);
}
