import { atob } from "buffer"
import { readFileSync, writeFileSync } from "fs"

// metadatas/raw
// metadatas/json
// metadatas/svg

const sampleSize = 50

const kiwi = [0, 0, 0, 0, 0]
const dragonfly = [0, 0, 0, 0, 0]

const main = () => {
  for (let i = 0; i < sampleSize; i++) {
    const { svg, json } = readRawDataAndWrite(i)
    let rarityArray
    switch (json.name.split(" ")[2]) {
      case "Kiwi":
        rarityArray = kiwi
        break
      case "Dragonfly":
        rarityArray = dragonfly
        break
      default:
        console.log("Exit because name is not find", json.name)
        process.exit(1)
    }

    // all assets details
    addAssetInRarity(svg, rarityArray)
  }
  console.log("Kiwi", kiwi)
  console.log("Dragonfly", dragonfly)
}

const addAssetInRarity = (svg, rarityArray) => {
  const start = svg.indexOf('34px">') + 6
  const end = svg.indexOf("</text>")
  const list = svg.slice(start, end).split("/")

  // nb of rarity²
  switch (list[1]) {
    case "51":
      rarityArray[0]++
      break
    case "26":
      rarityArray[1]++
      break
    case "4":
      rarityArray[2]++
      break
    case "2":
      rarityArray[3]++
      break
    case "1":
      rarityArray[4]++
      break
  }
  if (Number(list[0]) > Number(list[1]))
    console.log("Warning", list[0], list[1])
}

const readRawDataAndWrite = (i) => {
  const raw = readFileSync("cache/metadatas/raw/" + i, "utf-8")

  // decrypt raw data
  const encodedJson = raw.slice(raw.indexOf(",") + 1)
  writeFileSync("cache/metadatas/json/" + i + ".json", atob(encodedJson))

  // read JSON
  const json = JSON.parse(atob(encodedJson))

  // write descritpion
  writeFileSync("cache/metadatas/md/" + i + ".md", json.description)

  // decrypt image
  const encodedSvg = json.image.slice(json.image.indexOf(",") + 1)

  // write SVG
  writeFileSync("cache/metadatas/svg/" + i + ".svg", atob(encodedSvg))

  return { svg: atob(encodedSvg), json }
}

const readRawDataAndWriteContractURI = () => {
  const raw = readFileSync("cache/metadatas/raw/contract", "utf-8")
  const encodedJson = raw.slice(raw.indexOf(",") + 1)
  const jsonStr = atob(encodedJson)
  writeFileSync("cache/metadatas/json/contract.json", jsonStr)
  const json = JSON.parse(jsonStr)
  writeFileSync("cache/metadatas/md/contract.md", json.description)
  const encodedSvg = json.image.slice(json.image.indexOf(",") + 1)
  const svg = atob(encodedSvg)
  writeFileSync("cache/metadatas/svg/contract.svg", svg)
}

// launch
main()
