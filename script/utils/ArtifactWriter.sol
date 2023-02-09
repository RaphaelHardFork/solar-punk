// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "forge-std/StdJson.sol";
import "forge-std/Vm.sol";

/// @notice JSON structure
// network/contractName.json
//  - version
//      - deployer address
//      - deployed address
//      - constructor args
//      - isProxy
//      - implAddress

/// @notice Utils contract still in development
/// Reading broadcated call could be way more useful
/// GOAL keep simple JSON file to track deployments

abstract contract ArtifactWriter {
    using Strings for uint256;
    using stdJson for string;

    Vm private constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function writeArtifact(
        string memory contractName,
        address deployer,
        address contractAddr,
        bytes memory constructorArgs,
        bool isProxy,
        address implementationAddr
    ) internal {
        // assign file path
        string memory path = string.concat(
            "cache/",
            _findNetworkAlias(),
            ".",
            contractName,
            ".json"
        );

        // check if file exist
        bool isExist;
        try vm.readFile(path) {
            isExist = true;
        } catch {}

        // reserialize and get last version id
        uint256 versionId;
        string memory contractInfo;

        if (isExist) {
            (versionId, contractInfo) = _reserializeAndGetLastVersion(path);
        }

        // serialize contract version informations
        string memory version;
        string memory index = "version";
        version = index.serialize("deployer", deployer);
        version = index.serialize("address", contractAddr);
        version = index.serialize("constructorArgs", constructorArgs);
        version = index.serialize("isProxy", isProxy);
        version = index.serialize("implementationAddr", implementationAddr);

        index = "contract";
        contractInfo = index.serialize(
            string.concat("v", (versionId).toString()),
            version
        );

        // write file
        contractInfo.write(path);
    }

    /**
     * @dev Add networks names here
     * NOTE chainID can also be used for the file name
     */
    function _findNetworkAlias() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        if (chainId == 5) {
            return "goerli";
        } else if (chainId == 31337) {
            return "anvil";
        } else {
            return "unknown";
        }
    }

    function _reserializeAndGetLastVersion(string memory path)
        internal
        returns (uint256 i, string memory contractInfo)
    {
        string memory contractIndex = "contract";
        string memory file = vm.readFile(path);

        for (i; i < 100; i++) {
            string memory lastVersionPath = string.concat("v", i.toString());
            bytes memory lastVersion = file.parseRaw(lastVersionPath);

            // return lastVersionId and serialized old version
            if (lastVersion.length == 0) {
                return (i, contractInfo);
            }

            // serialize version info
            string memory version;
            string memory index = "version";
            version = index.serialize(
                "deployer",
                file.readAddress(string.concat(lastVersionPath, ".deployer"))
            );
            version = index.serialize(
                "address",
                file.readAddress(string.concat(lastVersionPath, ".address"))
            );
            version = index.serialize(
                "constructorArgs",
                file.readBytes(
                    string.concat(lastVersionPath, ".constructorArgs")
                )
            );
            version = index.serialize(
                "isProxy",
                file.readBool(string.concat(lastVersionPath, ".isProxy"))
            );
            version = index.serialize(
                "implementationAddr",
                file.readAddress(
                    string.concat(lastVersionPath, ".implementationAddr")
                )
            );

            // serialize contract info
            contractInfo = contractIndex.serialize(
                string.concat("v", i.toString()),
                version
            );
        }
    }
}
