// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/Base64.sol";

/**
 * @title Simple metadata properties for on-chain NFT
 * @dev Do not include `attributes`
 */

library MetadataProperties {
    // UTILS
    string internal constant HEADER = "data:application/json;base64,";
    string internal constant OPEN_JSON = "{";
    string internal constant NEXT_ATTRIBUTE = '",';
    string internal constant CLOSE_JSON = '"}';

    // PROPERTIES
    string internal constant PRE_NAME = '"name":"';
    string internal constant PRE_DESCRIPTION = '"description":"';
    string internal constant PRE_IMAGE = '"image":"';
    string internal constant PRE_EXTERNAL_URL = '"external_url":"';
    string internal constant PRE_BACKGROUND_COLOR = '"background_color":"';

    // IMAGE UTILS
    string internal constant SVG_HEADER = "data:image/svg+xml;base64,";
}
