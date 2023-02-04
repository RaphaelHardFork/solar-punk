// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {MetadataEncoder} from "src/utils/MetadataEncoder.sol";
import {SolarPunkProperties} from "src/metadata/SolarPunkProperties.sol";
import {SolarPunkFrameSVG} from "src/vectors/SolarPunkSVG.sol";
import {IShape} from "src/vectors/shapes/IShape.sol";

/// @title SolarPunkService
/// @notice Library to construct SolarPunks on-chain SVG image and metadata
library SolarPunkService {
    using MetadataEncoder for string;

    struct Gradient {
        uint24 colorA;
        uint24 colorB;
    }

    struct Image {
        bool animated;
        uint24 shapeColor;
        Gradient background;
        Gradient layer;
    }

    struct TokenID {
        uint8 shapeId;
        uint8 tokenId;
        uint8 numberOfCopies;
        Image image;
    }

    function renderMetadata(uint256 tokenId, address shapeAddr)
        internal
        view
        returns (string memory)
    {
        TokenID memory data = decodeTokenId(tokenId);
        (string memory rarity, string memory rarityDescrition) = rarityDetails(
            data.numberOfCopies
        );

        // render name & description
        string memory name = string.concat(
            SolarPunkProperties.NAME_PRIMER,
            IShape(shapeAddr).name(),
            rarity
        );

        string memory description = string.concat(
            SolarPunkProperties.DESCRIPTION_PRIMER,
            rarityDescrition
        );

        return
            MetadataEncoder.encodeMetadata(
                name,
                description,
                createImage(
                    data,
                    IShape(shapeAddr).path(data.image.shapeColor)
                ),
                SolarPunkProperties.EXTERNAL_URL
            );
    }

    /**
     * @dev Using multiple `append` instead of one big
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
            data.image.animated
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
                data.image.background.colorA,
                data.image.background.colorB
            )
        );

        if (data.numberOfCopies < 51) {
            svgCode = svgCode.append(
                SolarPunkFrameSVG.linearGradient(
                    false,
                    data.image.layer.colorA,
                    data.image.layer.colorB
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
        data.shapeId = uint8(principe);

        // Rarity
        if (itemId < 51) {
            // uni
            data.tokenId = uint8(itemId + 1);
            data.numberOfCopies = 51;
            data.image.background.colorA = 0x223344;
            data.image.background.colorB = 0x223344;
        } else if (itemId >= 51 && itemId < 77) {
            // gradient
            itemId = itemId % 51;
            data.tokenId = uint8(itemId + 1);
            data.numberOfCopies = 26;
            data.image.background.colorA = 0xaabb44;
            data.image.background.colorB = 0x22ccdd;
            data.image.layer.colorA = 0xee55aa;
            data.image.layer.colorB = 0xaa0000;
        } else if (itemId >= 77 && itemId < 81) {
            // dark
            itemId = (itemId % 51) % 26;
            data.tokenId = uint8(itemId + 1);
            data.numberOfCopies = 4;
            data.image.background.colorA = 0x114444;
            data.image.background.colorB = 0x226633;
            data.image.layer.colorA = 0x224477;
            data.image.layer.colorB = 0xaa22aa;
            data.image.shapeColor = 0xffffff;
        } else if (itemId == 81 || itemId == 82) {
            // elevated
            data.tokenId = itemId == 81 ? 1 : 2;
            data.numberOfCopies = 2;
            data.image.animated = true;
            data.image.background.colorA = 0xaabb44;
            data.image.background.colorB = 0x22ccdd;
            data.image.layer.colorA = 0xee55aa;
            data.image.layer.colorB = 0xaa0000;
        } else {
            // phantom
            data.tokenId = 1;
            data.numberOfCopies = 1;
            data.image.animated = true;
            data.image.background.colorA = 0x114444;
            data.image.background.colorB = 0x226633;
            data.image.layer.colorA = 0x224477;
            data.image.layer.colorB = 0xaa22aa;
            data.image.shapeColor = 0xffffff;
        }

        return
            uint256(
                bytes32(
                    abi.encodePacked(
                        data.shapeId,
                        data.tokenId,
                        data.numberOfCopies,
                        data.image.animated,
                        data.image.shapeColor,
                        data.image.background.colorA,
                        data.image.background.colorB,
                        data.image.layer.colorA,
                        data.image.layer.colorB
                    )
                )
            );
    }

    function decodeTokenId(uint256 tokenId)
        internal
        pure
        returns (TokenID memory data)
    {
        data.shapeId = uint8(tokenId >> 248);
        data.tokenId = uint8(tokenId >> 240);
        data.numberOfCopies = uint8(tokenId >> 232);
        data.image.animated = uint8(tokenId >> 224) == 0 ? false : true;
        data.image.shapeColor = uint24(tokenId >> 200);
        data.image.background.colorA = uint24(tokenId >> 176);
        data.image.background.colorB = uint24(tokenId >> 152);
        data.image.layer.colorA = uint24(tokenId >> 128);
        data.image.layer.colorB = uint24(tokenId >> 104);
    }

    function rarityDetails(uint256 numberOfCopies)
        internal
        pure
        returns (string memory, string memory)
    {
        if (numberOfCopies == 51)
            return ("Uni", SolarPunkProperties.DESCRIPTION_UNI);
        if (numberOfCopies == 26)
            return ("Gradient", SolarPunkProperties.DESCRIPTION_GRADIENT);
        if (numberOfCopies == 4)
            return ("Dark", SolarPunkProperties.DESCRIPTION_DARK);
        if (numberOfCopies == 2)
            return ("Elevated", SolarPunkProperties.DESCRIPTION_ELEVATED);
        return ("Phantom", SolarPunkProperties.DESCRIPTION_PHANTOM);
    }
}
