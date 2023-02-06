// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {IShape} from "./IShape.sol";
import {HexadecimalColor} from "src/utils/HexadecimalColor.sol";

contract Kiwi is IShape {
    using HexadecimalColor for uint24;

    string public constant name = "Kiwi";
    string public constant description =
        'Kiwi: \\"we are solarpunks because optimism has been stolen from us and we seek to reclaim it.\\"';

    function path(string memory color)
        public
        pure
        override
        returns (string memory)
    {
        return
            string.concat(
                '<path style="fill:',
                color,
                '" d="M373 522s-42-22-38-77c2-53 44-89 86-96 59-8 110 37 124 51 0 0 34-18 58-4 24 13 53 50 17 86l45 107v8c-1-1-58-103-68-107 0 0-14-2-30-14 0 0-3-2-3 1-1 3-20 56-51 56 0 0-42 0-56 23l-10 26c-2 3 0 4 1 6l20 30h35v14h-16v2l13 7-9 11-27-18-5-5-27-41s-1-2 1-7l4-11s2-5-4-5c-4-1-20-13-22-19l-23-12s-3-1-4 2c-1 4-4 5-1 8l13 32h29v13h-13v3l11 6-8 11-26-20-21-44v-4l5-16v-3Zm223-82c4 0 7 3 7 7s-3 7-7 7-7-3-7-7 3-7 7-7Z"/>'
            );
    }

    function path(uint24 color) external pure override returns (string memory) {
        return path(color.toColor());
    }
}
