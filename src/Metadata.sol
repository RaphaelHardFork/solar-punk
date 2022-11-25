// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/Base64.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

import "./HexadecimalColor.sol";

contract Metadata {
    using Strings for uint8;
    using HexadecimalColor for uint24;

    /*//////////////////
          METADATA
    //////////////////*/
    string internal pre_encoded_metadata = '"data:application/json;base64,';
    string internal pre_name = '{"name":"Solar punk '; // Kiwi #TokenId (see if not too long or just number in copie)
    string internal post_name = '",';
    string internal description = '"description":"Solar punk show the way",'; // Should change?
    string internal pre_image = '"image":"';
    string internal post_image = '"}';

    /*//////////////////
            SVG
    //////////////////*/
    string internal header =
        '<svg xmlns="http://www.w3.org/2000/svg" style="fill-rule:evenodd;" viewBox="0 0 1000 1000">';

    // background frame
    string internal background =
        '<path d="M0 0h1000v1000H0z" style="fill:url(#a)"/>';

    // layer frame
    string internal static_layer =
        '<path d="M0 0h1000v1000H0z" style="fill:url(#b);fill-opacity:.4"/>';
    string internal animated_layer =
        '<path d="M0 0h1000v1000H0z" style="fill:url(#b);fill-opacity:.2"><animate attributeName="fill-opacity" values="0.2; 1; 0.2" dur="20s" repeatCount="indefinite"/></path>';

    // open defs
    string internal start_defs = "<defs>";

    // close defs
    string internal close_defs = "</defs>";

    // footer
    string internal footer = "</svg>";

    constructor() {
        // immutable
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory image = _createImage();
        return
            string(
                abi.encodePacked(
                    pre_encoded_metadata,
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                pre_name,
                                "Kiwi #10",
                                post_name,
                                description,
                                pre_image,
                                image,
                                post_image
                            )
                        )
                    )
                )
            );
    }

    function _createImage() internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            header,
                            background,
                            animated_layer,
                            _getFigure(1),
                            _getNumbers(5, 51),
                            start_defs,
                            _createGradient(true, 0xffaa76, 0xee33aa),
                            _createGradient(false, 0xeeaa11, 0x55ff99),
                            close_defs,
                            footer
                        )
                    )
                )
            );
    }

    function _getFigure(uint256) internal pure returns (string memory) {
        return
            '<path style="fill:#000" d="M373 522s-42-22-38-77c2-53 44-89 86-96 59-8 110 37 124 51 0 0 34-18 58-4 24 13 53 50 17 86l45 107v8c-1-1-58-103-68-107 0 0-14-2-30-14 0 0-3-2-3 1-1 3-20 56-51 56 0 0-42 0-56 23l-10 26c-2 3 0 4 1 6l20 30h35v14h-16v2l13 7-9 11-27-18-5-5-27-41s-1-2 1-7l4-11s2-5-4-5c-4-1-20-13-22-19l-23-12s-3-1-4 2c-1 4-4 5-1 8l13 32h29v13h-13v3l11 6-8 11-26-20-21-44v-4l5-16v-3Zm223-82c4 0 7 3 7 7s-3 7-7 7-7-3-7-7 3-7 7-7Z"/>';
    }

    function _getNumbers(uint8 tokenId, uint8 rarityAmount)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                '<text text-anchor="middle" x="50%" y="946" style="font-family:&quot;Poiret One&quot;;font-size:34px">',
                tokenId.toString(),
                "/",
                rarityAmount.toString(),
                "</text>"
            );
    }

    function _createGradient(
        bool isBackground,
        uint24 color1,
        uint24 color2
    ) internal pure returns (string memory) {
        return
            string.concat(
                // first part
                "<linearGradient id=",
                isBackground ? '"a"' : '"b"',
                ' x1="0" x2="1" y1="0" y2="0" gradientUnits="userSpaceOnUse" gradientTransform="rotate(',
                isBackground ? "45" : "135",
                ') scale(1414)">',
                // second part
                '<stop offset="0" style="stop-color:',
                color1.toColor(),
                ';"/>',
                '<stop offset="1" style="stop-color:',
                color2.toColor(),
                ';"/>',
                "</linearGradient>"
            );
    }
}
