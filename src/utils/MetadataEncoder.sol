// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {MetadataProperties} from "src/metadata/MetadataProperties.sol";

/// @title Librairy used to write and encode on-chain metadata
library MetadataEncoder {
    using MetadataEncoder for string;

    function encodeMetadata(
        string memory name,
        string memory description,
        string memory image,
        string memory externalUrl
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    MetadataProperties.HEADER,
                    Base64.encode(
                        _jsonFile(
                            name,
                            description,
                            encodeSVG(image),
                            externalUrl
                        )
                    )
                )
            );
    }

    function _jsonFile(
        string memory name,
        string memory description,
        string memory image,
        string memory externalUrl
    ) internal pure returns (bytes memory) {
        string memory jsonString;
        jsonString = jsonString.append(MetadataProperties.OPEN_JSON);
        jsonString = jsonString.append(MetadataProperties.PRE_NAME);
        jsonString = jsonString.append(name);
        jsonString = jsonString.append(MetadataProperties.NEXT_ATTRIBUTE);
        jsonString = jsonString.append(MetadataProperties.PRE_DESCRIPTION);
        jsonString = jsonString.append(description);
        jsonString = jsonString.append(MetadataProperties.NEXT_ATTRIBUTE);
        jsonString = jsonString.append(MetadataProperties.PRE_IMAGE);
        jsonString = jsonString.append(image);
        jsonString = jsonString.append(MetadataProperties.NEXT_ATTRIBUTE);
        jsonString = jsonString.append(MetadataProperties.PRE_EXTERNAL_URL);
        jsonString = jsonString.append(externalUrl);
        jsonString = jsonString.append(MetadataProperties.CLOSE_JSON);
        return abi.encodePacked(jsonString);
    }

    function encodeSVG(string memory svgCode)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    MetadataProperties.SVG_HEADER,
                    Base64.encode(bytes(svgCode))
                )
            );
    }

    function append(string memory baseString, string memory element)
        internal
        pure
        returns (string memory)
    {
        return string.concat(baseString, element);
    }
}
