import { atob } from "buffer"
import { readFileSync, writeFileSync } from "fs"

// metadatas/raw
// metadatas/json
// metadatas/svg

const rarities = [0, 0, 0, 0, 0]

const main = () => {
  for (let i = 0; i < 84; i++) {
    const raw = readFileSync("cache/metadatas/raw/" + i, "utf-8")

    // decode JSON
    const encodedJson = raw.slice(raw.indexOf(",") + 1)
    const jsonStr = atob(encodedJson)
    writeFileSync("cache/metadatas/json/" + i + ".json", jsonStr)

    // read JSON
    const json = JSON.parse(jsonStr)
    writeFileSync("cache/metadatas/md/" + i + ".md", json.description)

    // read SVG
    const encodedSvg = json.image.slice(json.image.indexOf(",") + 1)
    const svg = atob(encodedSvg)
    writeFileSync("cache/metadatas/svg/" + i + ".svg", svg)

    // all assets details
    checkDistribution(svg)
  }
}

const checkDistribution = (svg) => {
  const start = svg.indexOf('34px">') + 6
  const end = svg.indexOf("</text>")
  const list = svg.slice(start, end).split("/")

  // nb of rarity²
  switch (list[1]) {
    case "51":
      rarities[0]++
      break
    case "26":
      rarities[1]++
      break
    case "4":
      rarities[2]++
      break
    case "2":
      rarities[3]++
      break
    case "1":
      rarities[4]++
      break
  }
  if (Number(list[0]) > Number(list[1])) console.log(list[0], list[1])

  console.log(rarities)
}

main()
