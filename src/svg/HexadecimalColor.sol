//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library HexadecimalColor {
    bytes16 private constant _HEX_SYMBOLS = "0123456789ABCDEF";

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toColor(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "#000000";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 1);
        buffer[0] = "#";
        for (uint256 i = 2 * length; i > 0; ) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
            unchecked {
                --i;
            }
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
