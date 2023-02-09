import { readFileSync, writeFileSync } from "fs"
import { decode } from "@ethereum-sourcify/bytecode-utils"

const main = async (name) => {
  let metadata
  try {
    metadata = JSON.parse(readFileSync(`out/${name}.sol/${name}.json`, "utf-8"))
  } catch (e) {
    if (!name) {
      console.log("Usage: `node utils/ipfsAppended.js <NameOfCOntract>`")
    } else {
      console.log(e.message)
    }
    process.exit(1)
  }

  console.log("Raw metadata file to upload on IPFS writen in cache/\n")
  writeFileSync(`cache/${name}.rawMetadata.json`, metadata.rawMetadata)

  console.log("\nContracts sources to upload on IPFS:")
  Object.keys(metadata.metadata.sources).map((source) => {
    console.log(source)
  })

  const bytecode = metadata.bytecode.object
  const metadataHash = decode(bytecode)

  console.log("\n\nIPFS hash appended to the bytecode:")
  console.log(metadataHash.ipfs)
}

main(process.argv[2])
