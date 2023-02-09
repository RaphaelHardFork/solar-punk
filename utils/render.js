import { atob } from "buffer"
import { readFileSync, writeFileSync, readdirSync, mkdirSync } from "fs"

// assets/raw
// assets/json
// assets/svg

const kiwi = [0, 0, 0, 0, 0]
const dragonfly = [0, 0, 0, 0, 0]
const phantom = []
const elevated = []
const dark = []
const gradient = []

const main = () => {
  let sampleSize = 0
  // read cache file
  try {
    const raws = readdirSync("cache/assets/raw", "utf-8")
    sampleSize = raws.length === 0 ? 0 : raws.length - 1
  } catch {
    mkdirSync("cache/assets/raw", { recursive: true })
    mkdirSync("cache/assets/json")
    mkdirSync("cache/assets/md")
    mkdirSync("cache/assets/svg")
    writeFileSync("cache/assets/raw/0", "")
    console.log(
      'Path "cache/assets/" with folder "raw", "json", "md" and "svg" created'
    )
    process.exit(1)
  }

  console.log("Assets sample size: ", sampleSize)

  // Write JSON, SVG and MD of assets and check the distribution
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
    addAssetInRarity(svg, rarityArray, i)
  }
  console.log("\nAssets distribution:")
  console.log("Shape [Uni, Gradient, Dark, Elevated, Phantom]")
  console.log("Kiwi", kiwi)
  console.log("Dragonfly", dragonfly)
  console.log("\nID by rarity:")
  console.log("Phantom", phantom)
  console.log("Elevated", elevated)
  console.log("Dark", dark)
  console.log("Gradient", gradient)

  // check contract URI assets
  if (sampleSize) {
    readRawDataAndWriteContractURI()
  }
}

const addAssetInRarity = (svg, rarityArray, i) => {
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
      gradient.push(i)
      break
    case "4":
      rarityArray[2]++
      dark.push(i)
      break
    case "2":
      rarityArray[3]++
      elevated.push(i)
      break
    case "1":
      rarityArray[4]++
      phantom.push(i)
      break
  }
  if (Number(list[0]) > Number(list[1]))
    console.log("Warning", list[0], list[1])
}

const readRawDataAndWrite = (i) => {
  const raw = readFileSync("cache/assets/raw/" + i, "utf-8")

  // decrypt raw data
  const encodedJson = raw.slice(raw.indexOf(",") + 1)
  writeFileSync("cache/assets/json/" + i + ".json", atob(encodedJson))

  // read JSON
  const json = JSON.parse(atob(encodedJson))

  // write descritpion
  writeFileSync("cache/assets/md/" + i + ".md", json.description)

  // decrypt image
  const encodedSvg = json.image.slice(json.image.indexOf(",") + 1)

  // write SVG
  writeFileSync("cache/assets/svg/" + i + ".svg", atob(encodedSvg))

  return { svg: atob(encodedSvg), json }
}

const readRawDataAndWriteContractURI = () => {
  const raw = readFileSync("cache/assets/raw/contract", "utf-8")
  const encodedJson = raw.slice(raw.indexOf(",") + 1)
  const jsonStr = atob(encodedJson)
  writeFileSync("cache/assets/json/contract.json", jsonStr)
  const json = JSON.parse(jsonStr)
  writeFileSync("cache/assets/md/contract.md", json.description)
  const encodedSvg = json.image.slice(json.image.indexOf(",") + 1)
  const svg = atob(encodedSvg)
  writeFileSync("cache/assets/svg/contract.svg", svg)
}

// launch
main()
