# Solar Punk

TODO:

- [x] Document code, explain function and library
- [x] Review naming for `assets` and add index for it
- [x] Review SwapAndPop test suite
- [x] Write scripts for deployment on testnet
- [ ] Deploy,test,destruct on Goerli
- [ ] ForkTest with a marketplace (transfer and listing)
- [ ] Explain technical choice in README
- [ ] Verify contract on IPFS
- [ ] Explain and test how SVG lib can be re used
- [ ] Change design and deploy on mainnet

IMPROVMENT:

- [ ] Allow to fill only sender requests
- [ ] Refund gas for filling request of others

## Unit

- 22 Figures:
  - 5 raretés:
    - Phantom (x1)
    - Gradient animated (x1)
    - Dark (x5)
    - Gradient (x20)
    - Uni (x50)

| Rarété   | Nombre | Background         | Layer              | Animated | Figure |
| -------- | ------ | ------------------ | ------------------ | -------- | ------ |
| Phantom  | 1      | #000000 -> #aaaaaa | #000000 -> #aaaaaa | yes      | white  |
| Elevated | 2      | #000000 -> #aaaaaa | #000000 -> #aaaaaa | yes      | black  |
| Dark     | 4      | #000000 -> #aaaaaa | #000000 -> #aaaaaa | No       | white  |
| Gradient | 26     | #000000 -> #aaaaaa | #000000 -> #aaaaaa | No       | black  |
| Uni      | 51     | #aaaaaa            | None               | No       | black  |

**Encode metadata:**

Adapted for dynamics metadata: create a struct like this

| Bytes32 | Data                |
| ------- | ------------------- |
| 0x      |                     |
| 00      | TokenId             |
| 01      | Number of copies    |
| 02      | Background color1:R |
| 03      | G                   |
| 04      | B                   |
| 05      | Background color2:R |
| 06      | G                   |
| 07      | B                   |
| 08      | Layer color1:R      |
| 09      | G                   |
| 10      | B                   |
| 11      | Layer color2:R      |
| 12      | G                   |
| 13      | B                   |
| 14      | Animated            |
| 15      | Figure color(B/W)   |
| 16      | Solar Punk Principe |
| 17      | B                   |
| 18      | B                   |
| 19      | B                   |

Adopted structure: run 0->1848 encode above informations in struct, compare encoding gas, tokenId & decoding gas

| Bytes32 | Data                | Execute                   |
| ------- | ------------------- | ------------------------- |
| 0x      |                     |
| 01      | TokenId             |
| 02      | Rarity              | Frames & number of copies |
| 03      | Solar Punk Principe | Name & Path               |

## Graphic
