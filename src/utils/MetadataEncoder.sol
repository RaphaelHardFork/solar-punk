// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/Base64.sol";

/**
 * @notice Librairy used to write and encode SolarPunk metadata into the
 * blockchain. It could evolve to create more generic NFT metadata.
 * */
library MetadataEncoder {
    string internal constant HEADER = '"data:application/json;base64,';
    string internal constant PRE_NAME = '{"name":"Solar punk ';
    string internal constant POST_NAME = '",';
    string internal constant DESCRIPTION =
        '"description":"This collection is a set of 22 SolarPunk, declined into 84 edition of each with different rarity.\n\nSolarPunk propose a future were technologies helping increase human being, support SolarPunks!",'; // Should change?
    string internal constant PRE_IMAGE = '"image":"';
    string internal constant POST_IMAGE = '"}';

    function encodeMetadata(
        string memory name,
        string memory rarity,
        string memory svgCode
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    HEADER,
                    Base64.encode(
                        abi.encodePacked(
                            PRE_NAME,
                            name,
                            " ",
                            rarity,
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
