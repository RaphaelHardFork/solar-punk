// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/Base64.sol";

/// @title Constants properties of SolarPunks
library SolarPunkProperties {
    // ASSETS PROPERTIES
    string internal constant NAME_PRIMER = "Solar Punk ";
    string internal constant DESCRIPTION_PRIMER =
        "This NFT belongs to the Solar Punk collection. Solar Punks promotes an optimist vision of the future, they don't warn of futures dangers but propose solutions to avoid that the dystopias come true. Solar Punks holds 22 principles that defines they're vision and mission.";
    string internal constant DESCRIPTION_UNI =
        "Unis are the most common edition this collection, but this not mean they are worthless.";
    string internal constant DESCRIPTION_GRADIENT =
        "Gradients are less common in this collection. They shine as the mission of SolarPunks.";
    string internal constant DESCRIPTION_DARK =
        "Darks are rare in this collection, the living proofs of existence of Lunar Punks, even if missions of Solar Punks are obstructed, they continue to act discretely.";
    string internal constant DESCRIPTION_ELEVATED =
        "This is one of the two Elevated Solar Punks holding this principle, their charisma radiates everywhere and inspires people by their actions.";
    string internal constant DESCRIPTION_PHANTOM =
        "Each principle is held by a Phamtom, this one always acting in the shadows to serve the light.";

    // COLLECTIONS PROPERTIES
    string internal constant CONTRACT_NAME = "Solar Punk Collection";
    string internal constant CONTRACT_DESCRIPTION =
        "Discover the Solar Punk collection!\\nA collection of 1848 unique asset living on Optimism ethereum layer 2, this collection promotes an optimist vision as Solar Punks do.\\nThe collection consists of 22 shapes x 84 assets including 5 different rarities, each assets are distributed randomly. NFTs metadata consist of SVG on-chain, encoded into the `tokenID` and rendered with the `tokenURI` function. The contract is verified on explorers and IPFS, so you can mint your asset wherever you want.";
    string internal constant CONTRACT_IMAGE = "";
    string internal constant EXTERNAL_URL = "https://github.com";
}
