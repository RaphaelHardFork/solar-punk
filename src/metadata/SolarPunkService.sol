// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {MetadataEncoder} from "src/utils/MetadataEncoder.sol";
import {SolarPunkProperties} from "src/metadata/SolarPunkProperties.sol";
import {SolarPunkSVGProperties} from "src/vectors/SolarPunkSVG.sol";
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

    function renderLogo() internal pure returns (string memory) {
        return
            MetadataEncoder.encodeMetadata(
                SolarPunkProperties.CONTRACT_NAME,
                SolarPunkProperties.CONTRACT_DESCRIPTION,
                createLogo(),
                SolarPunkProperties.EXTERNAL_URL
            );
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
            " ",
            IShape(shapeAddr).name(),
            " ",
            rarity
        );

        string memory description = string.concat(
            SolarPunkProperties.DESCRIPTION_PRIMER,
            rarityDescrition,
            "  \\n",
            IShape(shapeAddr).description()
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
        svgCode = svgCode.append(SolarPunkSVGProperties.HEADER);
        svgCode = svgCode.append(SolarPunkSVGProperties.BACKGROUND);
        svgCode = svgCode.append(
            data.image.animated
                ? SolarPunkSVGProperties.LAYER_ANIMATED
                : SolarPunkSVGProperties.LAYER_STATIC
        );
        svgCode = svgCode.append(path);
        svgCode = svgCode.append(
            SolarPunkSVGProperties.text(data.tokenId, data.numberOfCopies)
        );
        svgCode = svgCode.append(SolarPunkSVGProperties.defs(true));
        svgCode = svgCode.append(
            SolarPunkSVGProperties.linearGradient(
                true,
                data.image.background.colorA,
                data.image.background.colorB
            )
        );

        if (data.numberOfCopies < 51) {
            svgCode = svgCode.append(
                SolarPunkSVGProperties.linearGradient(
                    false,
                    data.image.layer.colorA,
                    data.image.layer.colorB
                )
            );
        }
        svgCode = svgCode.append(SolarPunkSVGProperties.defs(false));
        svgCode = svgCode.append(SolarPunkSVGProperties.FOOTER);
    }

    function createLogo() internal pure returns (string memory svgCode) {
        svgCode = svgCode.append(SolarPunkSVGProperties.HEADER);
        svgCode = svgCode.append(SolarPunkSVGProperties.BACKGROUND);
        svgCode = svgCode.append(SolarPunkSVGProperties.LAYER_ANIMATED);
        svgCode = svgCode.append(SolarPunkSVGProperties.CONTRACT_LOGO);
        svgCode = svgCode.append(SolarPunkSVGProperties.defs(true));
        svgCode = svgCode.append(
            SolarPunkSVGProperties.linearGradient(true, 0x12ae56, 0xee9944)
        );
        svgCode = svgCode.append(
            SolarPunkSVGProperties.linearGradient(false, 0xaa3377, 0x2244cc)
        );
        svgCode = svgCode.append(SolarPunkSVGProperties.defs(false));
        svgCode = svgCode.append(SolarPunkSVGProperties.FOOTER);
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
            data.image.background.colorA = 0xB1D39C;
            data.image.background.colorB = 0xB1D39C;
        } else if (itemId >= 51 && itemId < 77) {
            // gradient
            itemId = itemId % 51;
            data.tokenId = uint8(itemId + 1);
            data.numberOfCopies = 26;
            data.image.background.colorA = 0xffffff;
            data.image.background.colorB = 0xC85426;
            data.image.layer.colorA = 0x87E990;
            data.image.layer.colorB = 0x63B3E9;
        } else if (itemId >= 77 && itemId < 81) {
            // dark
            itemId = (itemId % 51) % 26;
            data.tokenId = uint8(itemId + 1);
            data.numberOfCopies = 4;
            data.image.background.colorA = 0x108EA6;
            data.image.background.colorB = 0x000000;
            data.image.layer.colorA = 0x612463;
            data.image.layer.colorB = 0x202283;
            data.image.shapeColor = 0xffffff;
        } else if (itemId == 81 || itemId == 82) {
            // elevated
            data.tokenId = itemId == 81 ? 1 : 2;
            data.numberOfCopies = 2;
            data.image.animated = true;
            data.image.background.colorA = 0xDBA533;
            data.image.background.colorB = 0xBB2730;
            data.image.layer.colorA = 0x33CEDB;
            data.image.layer.colorB = 0x5BB252;
        } else {
            // phantom
            data.tokenId = 1;
            data.numberOfCopies = 1;
            data.image.animated = true;
            data.image.background.colorA = 0x5E2463;
            data.image.background.colorB = 0x000000;
            data.image.layer.colorA = 0xFFF4CC;
            data.image.layer.colorB = 0xffffff;
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
