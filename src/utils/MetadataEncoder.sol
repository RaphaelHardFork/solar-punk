// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/Base64.sol";

library MetadataEncoder {
    string internal constant HEADER = '"data:application/json;base64,';
    string internal constant PRE_NAME = '{"name":"Solar punk '; // Kiwi #TokenId (see if not too long or just number in copie)
    string internal constant POST_NAME = '",';
    string internal constant DESCRIPTION =
        '"description":"Solar punk show the way",'; // Should change?
    string internal constant PRE_IMAGE = '"image":"';
    string internal constant POST_IMAGE = '"}';

    function encodeMetadata(string memory name, string memory svgCode)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    HEADER,
                    Base64.encode(
                        abi.encodePacked(
                            PRE_NAME,
                            name,
                            POST_NAME,
                            DESCRIPTION,
                            PRE_IMAGE,
                            encodeImage(svgCode),
                            POST_IMAGE
                        )
                    )
                )
            );
    }

    function encodeImage(string memory svgCode)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(svgCode))
                )
            );
    }
}
