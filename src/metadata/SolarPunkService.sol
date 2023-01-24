// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

/// @notice manage tokenID to metadata

import {MetadataEncoder} from "src/utils/MetadataEncoder.sol";
import {SolarPunkFrameSVG} from "src/vectors/SolarPunkSVG.sol";
import {IAsset} from "src/vectors/assets/IAsset.sol";

library SolarPunkService {
    using SolarPunkFrameSVG for string;

    struct Frame {
        uint24 colorA;
        uint24 colorB;
    }

    struct Draw {
        bool animated;
        uint24 figureColor;
        Frame background;
        Frame layer;
    }

    struct TokenID {
        uint8 principe;
        uint8 tokenId;
        uint8 numberOfCopies;
        Draw draw;
    }

    function encodedMetadata(uint256 tokenId, address figureAddr)
        internal
        view
        returns (string memory)
    {
        TokenID memory data = decodeTokenId(tokenId);

        return
            MetadataEncoder.encodeMetadata(
                IAsset(figureAddr).name(),
                createImage(
                    data,
                    IAsset(figureAddr).path(data.draw.figureColor)
                )
            );
    }

    /**
     * @notice Using multiple `append` instead of one big
     * `string.concat` to avoid the `Stack too deep` error
     */
    function createImage(TokenID memory data, string memory path)
        internal
        pure
        returns (string memory svgCode)
    {
        svgCode = svgCode.append(SolarPunkFrameSVG.HEADER);
        svgCode = svgCode.append(SolarPunkFrameSVG.BACKGROUND);
        svgCode = svgCode.append(
            data.draw.animated
                ? SolarPunkFrameSVG.LAYER_ANIMATED
                : SolarPunkFrameSVG.LAYER_STATIC
        );
        svgCode = svgCode.append(path);
        svgCode = svgCode.append(
            SolarPunkFrameSVG.text(data.tokenId, data.numberOfCopies)
        );
        svgCode = svgCode.append(SolarPunkFrameSVG.defs(true));
        svgCode = svgCode.append(
            SolarPunkFrameSVG.linearGradient(
                true,
                data.draw.background.colorA,
                data.draw.background.colorB
            )
        );

        if (data.numberOfCopies > 51) {
            svgCode = svgCode.append(
                SolarPunkFrameSVG.linearGradient(
                    false,
                    data.draw.layer.colorA,
                    data.draw.layer.colorB
                )
            );
        }
        svgCode = svgCode.append(SolarPunkFrameSVG.defs(false));
        svgCode = svgCode.append(SolarPunkFrameSVG.FOOTER);
    }

    function transformItemId(uint256 principe, uint256 itemId)
        internal
        pure
        returns (uint256)
    {
        TokenID memory data;
        data.principe = uint8(principe);

        // Rarity
        if (itemId < 51) {
            // common
            data.tokenId = uint8(itemId + 1);
            data.numberOfCopies = 51;
            data.draw.background.colorA = 0x223344;
            data.draw.background.colorB = 0x223344;
        } else if (itemId >= 51 && itemId < 78) {
            // uncommon
            itemId = itemId % 51;
            data.tokenId = uint8(itemId + 1);
            data.numberOfCopies = 27;
            data.draw.background.colorA = 0xaabb44;
            data.draw.background.colorB = 0x22ccdd;
            data.draw.layer.colorA = 0xee55aa;
            data.draw.layer.colorB = 0xaa0000;
        } else if (itemId >= 78 && itemId < 82) {
            // dark rare
            itemId = (itemId % 51) % 27;
            data.tokenId = uint8(itemId + 1);
            data.numberOfCopies = 4;
            data.draw.background.colorA = 0x114444;
            data.draw.background.colorB = 0x226633;
            data.draw.layer.colorA = 0x224477;
            data.draw.layer.colorB = 0xaa22aa;
            data.draw.figureColor = 0xffffff;
        } else if (itemId == 82) {
            // gradient super rare
            data.tokenId = 1;
            data.numberOfCopies = 1;
            data.draw.animated = true;
            data.draw.background.colorA = 0xaabb44;
            data.draw.background.colorB = 0x22ccdd;
            data.draw.layer.colorA = 0xee55aa;
            data.draw.layer.colorB = 0xaa0000;
        } else {
            // phantom super rare
            data.tokenId = 1;
            data.numberOfCopies = 1;
            data.draw.animated = true;
            data.draw.background.colorA = 0x114444;
            data.draw.background.colorB = 0x226633;
            data.draw.layer.colorA = 0x224477;
            data.draw.layer.colorB = 0xaa22aa;
            data.draw.figureColor = 0xffffff;
        }

        return
            uint256(
                bytes32(
                    abi.encodePacked(
                        data.principe,
                        data.tokenId,
                        data.numberOfCopies,
                        data.draw.animated,
                        data.draw.figureColor,
                        data.draw.background.colorA,
                        data.draw.background.colorB,
                        data.draw.layer.colorA,
                        data.draw.layer.colorB
                    )
                )
            );
    }

    function decodeTokenId(uint256 tokenId)
        internal
        pure
        returns (TokenID memory data)
    {
        data.principe = uint8(tokenId >> 248);
        data.tokenId = uint8(tokenId >> 240);
        data.numberOfCopies = uint8(tokenId >> 232);
        data.draw.animated = uint8(tokenId >> 224) == 0 ? false : true;
        data.draw.figureColor = uint24(tokenId >> 200);
        data.draw.background.colorA = uint24(tokenId >> 176);
        data.draw.background.colorB = uint24(tokenId >> 152);
        data.draw.layer.colorA = uint24(tokenId >> 128);
        data.draw.layer.colorB = uint24(tokenId >> 104);
    }
}
