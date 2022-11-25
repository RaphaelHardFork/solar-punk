const main = () => {
  let a = 0
  let b = 0

  for (let i = 0; i < 1848; i++) {
    // console.log(Math.floor(i / 84))
    // console.log(Math.floor(i % 84))

    a = i % 84
    b = 51
    if (a < b) {
      console.log(`(${Math.floor(i / 84)}) Uni ${(a % b) + 1}/51`)
      continue
    }

    a %= b
    b = 27
    if (a < b) {
      console.log(`(${Math.floor(i / 84)}) Gradient ${(a % b) + 1}/27`)
      continue
    }

    a %= b
    b = 4
    if (a < b) {
      console.log(`(${Math.floor(i / 84)}) Dark ${(a % b) + 1}/4`)
      continue
    }

    a %= b
    b = 1
    if (a < b) {
      console.log(`(${Math.floor(i / 84)}) Gradient+ ${(a % b) + 1}/1`)
      continue
    }

    a %= b
    console.log(`(${Math.floor(i / 84)}) Phantom ${(a % b) + 1}/1`)
  }
}

main()
