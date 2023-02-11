// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/Strings.sol";

import "src/utils/HexadecimalColor.sol";

/**
 * @title Used to construct SolarPunk frame, it could evolve
 * to a more generic librairy to construct SVGs.
 * */
library SolarPunkSVGProperties {
    using Strings for uint8;
    using HexadecimalColor for uint24;

    // constant svg elements
    string internal constant HEADER =
        '<svg xmlns="http://www.w3.org/2000/svg" style="fill-rule:evenodd;" viewBox="0 0 1000 1000">';

    string internal constant BACKGROUND =
        '<path d="M0 0h1000v1000H0z" style="fill:url(#a)"/>';

    string internal constant LAYER_STATIC =
        '<path d="M0 0h1000v1000H0z" style="fill:url(#b);fill-opacity:.75"/>';

    string internal constant CONTRACT_LOGO =
        '<text x="251px" y="809px" style="font-family:&quot;Poiret One&quot;;font-size:819px;">?</text>';

    string internal constant LAYER_ANIMATED =
        '<path d="M0 0h1000v1000H0z" style="fill:url(#b);fill-opacity:0"><animate attributeName="fill-opacity" values="0; 1; 0" dur="20s" repeatCount="indefinite"/></path>';

    string internal constant FOOTER = "</svg>";

    function defs(bool opening) internal pure returns (string memory) {
        return opening ? "<defs>" : "</defs>";
    }

    // elements with parameters
    function text(uint8 tokenId, uint8 rarityAmount)
        internal
        pure
        returns (string memory)
    {
        string memory color = rarityAmount == 4 || rarityAmount == 1
            ? ";fill:#FFF"
            : "";
        return
            string.concat(
                '<text text-anchor="middle" x="50%" y="946" style="font-family:&quot;Poiret One&quot;',
                color,
                ';font-size:34px">',
                tokenId.toString(),
                "/",
                rarityAmount.toString(),
                "</text>"
            );
    }

    function linearGradient(
        bool isBackground,
        uint24 color1,
        uint24 color2
    ) internal pure returns (string memory) {
        return
            string.concat(
                // first part
                "<linearGradient id=",
                isBackground ? '"a"' : '"b"',
                ' x1="0" x2="1" y1="0" y2="0" gradientUnits="userSpaceOnUse" gradientTransform="matrix',
                isBackground
                    ? "(-1000,-1000,1000,-1000,1000,1000)"
                    : "(-1000,1000,-1000,-1000,1000,0)",
                '">',
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
