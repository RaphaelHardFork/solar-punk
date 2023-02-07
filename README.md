# Solar Punk

TODO:

- [x] Document code, explain function and library
- [x] Review naming for `assets` and add index for it
- [x] Review SwapAndPop test suite
- [x] Write scripts for deployment on testnet
- [x] Contract URI + image (design it)
- [x] Deploy,test,destruct on Goerli
- [x] Randomness on same block requested
- [ ] ~~ForkTest with a marketplace (transfer and listing)~~
- [ ] Events in contract
- [ ] Explain technical choice in README
- [ ] Explain and test how SVG lib can be re used
- [ ] Verify contract on IPFS
- [ ] Change design and deploy on mainnet

IMPROVMENT:

- [x] Request several mint
- [x] Next blocks request released (instead of request list or +)
- [ ] Request list length???
- [ ] Fill request at request mint
- [ ] Allow to fill only sender requests
- [ ] Refund gas for filling request of others
- [ ] Alone test for gas snapshot??

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

## Descriptions

**Contract description:**
Discover the Solar Punk collection!

A collection of 1848 unique asset living on Optimism ethereum layer 2, this collection promotes an optimist vision as Solar Punks do.

The collection consists of 22 shapes x 84 assets including 5 different rarities, each assets are distributed randomly. NFTs metadata consist of SVG on-chain, encoded into the `tokenID` and rendered with the `tokenURI` function. The contract is verified on explorers and IPFS, so you can mint your asset wherever you want.

**General assets description:**
This NFT belongs to the Solar Punk collection. Solar Punks promotes an optimist vision of the future, they don't warn of futures dangers but propose solutions to avoid that the dystopias come true. Solar Punks holds 22 principles that defines they're vision and mission.

**Description Uni:**
Unis are the most common edition this collection, but this not mean they are worthless.
**Description Gradient**:
Gradients are less common in this collection. They shine as the mission of SolarPunks.
**Description Dark**:
Darks are rare in this collection, the living proofs of existence of Lunar Punks, even if missions of Solar Punks are obstructed, they continue to act discretely.
**Description Elevated**:
This is one of the two Elevated Solar Punks holding this principle, their charisma radiates everywhere and inspires people by their actions.
**Description Phantom**:
Each principle is held by a Phamtom, this one always acting in the shadows to serve the light.

**Principles:**

1. Kiwi: "we are solarpunks because optimism has been stolen from us and we seek to reclaim it."
2. Dragonfly: "We are solarpunks because the only other options are denial and despair."
3. L’essence du Solarpunk est une vision de l’avenir qui incarne le meilleur de ce que l’humanité peut accomplir : un monde post-pénurie, post-hiérarchie, post-capitalisme où l’humanité se considère comme une partie de la nature et où les énergies propres remplacent les combustibles fossiles.
4. Le “punk” de Solarpunk désigne la rébellion, la contre-culture, le post-capitalisme, le décolonialisme et l’enthousiasme. Il s’agit d’aller dans une autre direction que la conventionnelle, qui est de plus en plus alarmante.
5. Le Solarpunk est un mouvement autant qu’un genre : il s’agit non seulement des histoires, mais aussi de la manière de les rendre réelles.
6. Le Solarpunk embrasse diverses tactiques : il n’y a pas une manière unique d’être solarpunk. À la place, diverses communautés de par le monde en ont adopté le nom et les idées et ont bâti des petites niches de révolutions autonomes.
7. Le Solarpunk fournit une nouvelle perspective précieuse, un paradigme et un vocabulaire avec lesquels nous pouvons décrire un futur possible. Au lieu d’embrasser le rétrofuturisme, le Solarpunk se tourne entièrement vers l’avenir. Pas un futur alternatif, mais un futur possible.
8. Notre futurisme n’est pas nihiliste comme le Cyberpunk et évite les tendances potentiellement quasi-réactionnaires du Steampunk : il traite d’ingéniosité, de générativité, d’indépendance et de communauté.
9. Le Solarpunk met l’accent sur la durabilité environnementale et la justice sociale.
10. Le Solarpunk cherche à trouver des façons de rendre la vie plus belle pour nous maintenant, mais aussi pour les générations qui vont nous succéder.
11. Notre avenir suppose la réutilisation de ce que nous possédons déjà et, si nécessaire, sa transformation pour lui donner une autre utilisation. Imaginez les “villes intelligentes” être abandonnées à la faveur d’une citoyenneté intelligente.
12. Le Solarpunk reconnait l’influence historique que la politique et la science-fiction ont eu l’une sur l’autre.
13. Le Solarpunk reconnait la science-fiction non seulement comme un divertissement mais aussi comme une forme d’activisme.
14. Le Solarpunk veut contrer les scénarios d’une terre mourante, d’un insurmontable fossé entre riches et pauvres, et d’une société contrôlée par les corporations. Pas dans des centaines d’années, mais maintenant.
15. Le Solarpunk c’est la culture maker de la jeunesse, c’est des réseaux et solutions énergétiques locaux, c’est des façons de créer des systèmes autonomes qui fonctionnent. C’est un amour du monde.
16. La culture Solarpunk inclut toutes les cultures, religions, aptitudes, sexes, genres et identités sexuelles.
17. Le Solarpunk est l’idée d’une humanité qui atteindrait une évolution sociale qui n’embrasserait pas seulement une simple tolérance, mais également une compassion et une acceptation plus complètes.
18. Les esthétiques visuelles du Solarpunk sont ouvertes et évolutives. En l’état, c’est un mashup de :
    - L’âge de la voile et le mythe de la Frontière des années 1800 (mais avec plus de bicyclettes)
    - La réutilisation créative d’infrastructures existantes (parfois post-apocalyptiques, parfois contemporaines-étranges)
    - Une technologie appropriée
    - L’Art Nouveau
    - Hayao Miyazaki
    - Des innovations dans le style Jugaad provenant du monde - non-Occidental
    - Des back-ends des techniques de pointe avec des résultats simples et élégants
19. Le Solarpunk se passe dans un futur bâti en suivant les principes du nouvel urbanisme ou du nouveau piétonnisme ainsi que de la durabilité environnementale.
20. Le Solarpunk conçoit un environnement construit adapté de manière créative pour tirer parti de l’énergie solaire en utilisant, entre autres, différentes technologies. L’objectif est de promouvoir l’autosuffisance et la vie dans les limites naturelles.
21. Dans le Solarpunk, nous avons réussi à faire machine arrière juste à temps pour arrêter la lente destruction de notre planète. Nous avons appris à utiliser la science avec sagesse, pour l’amélioration de notre condition de vie en tant que partie de notre planète. Nous ne sommes plus des chef•fe•s suprêmes. Nous sommes des soigneur•se•s. Nous sommes des jardinier•ère•s.
22. Le Solarpunk :
    - est diversifié
    - a de la place pour que spiritualité et science puissent coexister
    - est beau
    - peut arriver. Maintenant.
