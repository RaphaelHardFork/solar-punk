# Solar Punk Collection

![](https://img.shields.io/badge/Audits-no%20review-red) ![](https://img.shields.io/badge/Tests%20coverage-90%25-green)

_Solar Punk is a collection on ERC721 deployed on Optimism with on-chain metadata and a partial randomness generation. Solar Punk is a small project training for using a free source of randomness and fully decentralized metadata._

## Mint a Solar Punk

Here the steps to mint a Solar Punk:

1. Go to any explorer or the dApp
2. Send value and commit to a future block with `requestMint(uint256,uint256)`:
   - **value:** 0.005 ether by requested asset to mint
   - **blockNumber:** choose a block in the range `[block.number + 1 : block.number + 36000)`
   - **amount:** number of requested asset to mint
3. Wait until the committed block is reached and call `fulfillRequest(bool)`:
   - **onlyOwnerRequest:** true if you want to fulfill only your request (token of others are not minted)

If your request is expired, the request is postponed to `block.number + 3000` when calling `fulfillRequest`. Once a request is done number of available assets decrement so you can request an asset and take the risk to not mint a token then.

### ⚠️ Note on breaking changes since Optimism Bedrock

Optimism network was chosen for his relatively slow block time, average of 12 second per block (pretty the same as the Ethereum mainnet). But this affirmation not stand with the Bedrock upgrade, this new version comes with a faster block time (less than 2s, actually closer from 0.5s per block).

Let's say 0.5s/block, minting a SolarPunk offer a window of 2min to mint the assets once the block is reached, otherwise the block is postponed to 20~25min later. So be quick for minting the assets once the block is reached.

## Deployments

| Contracts            | Optimism mainnet                                                                                                                      | Contracts size (kB) | Metadata hash (IPFS)                           |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ---------------------------------------------- |
| `SolarPunk` (ERC721) | [0x7582963C68B6187919d9Eb311f3343bA7777149d](https://optimistic.etherscan.io/address/0x7582963c68b6187919d9eb311f3343ba7777149d#code) | 18.267              | QmTxnWhDN2txnCqGD2eXB4BAGWWEXi62o8WRyuwkEpqSGc |
| `Kiwi`               | [0xa4c949d74fbEfDf4fFFFe03b70143A5cC0fc2717](https://optimistic.etherscan.io/address/0xa4c949d74fbefdf4ffffe03b70143a5cc0fc2717#code) | 1.899               | QmQuwG3q3yggEuDSVVMyZXebe2qoYKx2VaKtzKmsDR5d8B |
| `Dragonfly`          | [0xb1f2773c2aBfd7CF884320C6719edf0086514e16](https://optimistic.etherscan.io/address/0xb1f2773c2abfd7cf884320c6719edf0086514e16#code) | 2.609               | QmYkerZrhLSvEMJd4GSzHDFkzwsBNCDmR42TDHCQiRTJxs |
| `Onion`              | [0xf3786Ed209Ec11DE832B44DC85c0b5a953D5fb68](https://optimistic.etherscan.io/address/0xf3786ed209ec11de832b44dc85c0b5a953d5fb68#code) | 2.726               | QmcoVtvG4q9MRCDjJgRUQbt9pqb73WvfZHQt3BwK417YxZ |

SolarPunk on testnet: [Goerli Optimism](0x7582963C68B6187919d9Eb311f3343bA7777149d) | [Goerli](0xc3793ecC3A0aa3B5a0f7b23A375b0c92df72DA25)

## Technical choices

### Source of randomness

To generate a random number before minting a token the blockhash of a future block is used. The smart contract asks the user to commit a block in the future (`[block.number + 1 : block.number + 36000)`), 36000 blocks correspond to approximatively 5 days on Optimism network. Once the targeted block is reached, the user can mint the token using the blockhash to draw among available assets.

**Advantage of commiting to a future blockhash:**

1. This randomness allows an unpredictability of the blockhash, as this latter is not stated at the commitment.
2. This process leverages on-chain data, which is totally free.
3. Moreover the randomness generation is transparent, meaning that any actor can verify the random generation process.

**Weakness of this randomness:**

1. The block proposer can manipulate the block body (order of transaction for example) to manipulate the blockhash and thus try to get the rarest asset.
2. Using the `blockhash` OPCODE is also problematic because we can't access blockhash older than 256 blocks, so the commitment can expire. Once the target block reached users have a window of 256 blocks to call the reveal function otherwise the commitment is expired and, in `SolarPunk` contract postponed to 3000 blocks in the future. Optimism network was chosen to expand this window as block a produced in average each 12s (like Ethereum), which give a window of time of approximatively 50 min.

### On-chain metadata

Using on-chain metadata is not recommended as it increase considerably the size of stored data in the blockchain. It's preferable to use decentralized and immutable storage like IPFS.

Here light svg asset were chosen to minimize the size storage on the blockchain. To optimize the size of SVG asset code the awesome [SVGOMG](https://jakearchibald.github.io/svgomg/) tool was used.

All SVG and metadata properties are stored in the blockchain into the `SolarPunk` contract and SVG path of assets with their description and name are stored on separate contracts which share the `IShape` interface. This allows to add new shape even after the contract deployment.

Then SVG asset are rendered when the `tokenURI` function is called. Information to render SVGs are encoded into the token ID, which is a `uint256` (see [ERC721](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol#L30)). As it's an `uint256` (32 x `uint8`) the token ID can hold a certain amount of data, data are encoded following the struct `TokenID` in `SolarPunkService`, here the encoding format of a token ID:

| bytes32(tokenID) | Data name and type         | Description                               |
| ---------------- | -------------------------- | ----------------------------------------- |
| 0x               | /                          | /                                         |
| 00               | Shape index `uint8`        | Shape contract address index              |
| 01               | Token id `uint8`           | ID of the token among number of copies    |
| 02               | Number of copies `uint8`   | Number of copies for one rarity           |
| 03               | Animated `bool`            | Flag for svg animation                    |
| 04               | Shape color `uint24`       | Color of the shape                        |
| 07               | Background colorA `uint24` | Starting color of the background gradient |
| 10               | Background colorB `uint24` | End color of the background gradient      |
| 13               | Layer colorA `uint24`      | Starting color of the layer gradient      |
| 16               | Layer colorB `uint24`      | End color of the layer gradient           |

**Encoding colors:**
Colors are encoded in `uint24` (3 x `uint8`) to represent an hexadecimal color (`0xaaeebb` => ![](https://img.shields.io/badge/%23AAEEBB-AAEEBB)). The convertion to the string representation with `#` is done with `HexadecimalColor.sol` which is an adaptation of the `Strings.sol` library from OZ.

With these data, the `tokenURI` function will fetch data to create the svg code and asset metadata:

1. Shape index is used to get the contract address `IShape(shapeAddr)`
2. `IShape(shapeAddr).path(uint24)` and `SolarPunkSVGProperties` are used to create the SVG code of the image
3. SVG code is encoded with the OZ library `Base64`
4. `IShape(shapeAddr).name()`, `IShape(shapeAddr).description()` and `SolarPunkProperties` are used to create the asset metadata
5. As well as the image, metadata are also Base64 encoded and returned to the `tokenURI` function.

**Advantage and potential:**
With this method, no third parties storage system is required to associate image with an NFT. Moreover data for rendering the image can be modified to make a dynamical NFT which can evolve with a DAO, a reputation system and so on. If we want to leverage this feature in this contract, we must store data for the rendering elsewhere than the token ID.

**Drawbacks:**
The main drawback is the size of the contract we deploy to create dynamically on-chain svg asset, thus we use a lot of gas at deployment and clutter up the blockchain which is not designed for that.
Also the code to render the svg asset is complex because Solidity and the EVM are not designed to manage `string` (long `string` in case of SVG), especially to concatenate many elements, the `stack too deep error` can be very limiting (here the workaround for this error is to `append` the svg code string, see [`MetadataEncoder::append`]())

## Improvements

- [ ] Minting process in one TX using Epoch commit/reveal for randomness and random metadata generation. See [@\_MouseDev thread](https://twitter.com/_MouseDev/status/1623044314983964682?s=20&t=rAHEvrVJr-7GwI_q6nG7Tw).
- [ ] Allow shape (or frames) to evolve based on a reputation system for example (Dynamical metadata).

---

# Using

Make sure you have installed [Rust](https://www.rust-lang.org/fr/learn/get-started) & [Foundry](https://book.getfoundry.sh/getting-started/installation)

```
forge install
yarn
```

## Build contracts

```
forge build
```

## Extract IPFS hash appended to the bytecode

```
forge build
node utils/ipfsAppended.js <contract_name>
```

## Testing contracts

```
forge test
```

## Check assets rendering and distribution

```
node utils/render.js
forge script assets
node utils/render.js
```

You can view SVG in `cache/assets/svg`, sample size is set in `assets.s.sol` with `NUMBER_OF_TOKEN`

## Deploy contracts

Make sure the `.env` file is set following the `.env.example`

### On local blockchain

```
anvil (in another terminal)
forge script deploy --rpc-url anvil --broadcast
```

### On mainnet/testnet

Always dry-run without `--broadcast` to test your script

```
forge script deploy --rpc-url <network_alias>
```

Then execute with `--broadcast`

## Verify contract

**Sourcify:**

```
forge verify-contract <address> <contract_name> --chain <chain_id> --verifier sourcify
```

**Etherscan:**
Make sure you have set the `ETHERSCAN_KEY` in `.env`

```
source .env
forge verify-contract <address> <contract_name> --chain <network_alias | chain_id> $ETHERSCAN_KEY --watch
```

If the contract has been deployed with arguments:

```
cast abi-encode "constructor(address,uint256)" 0xdaab... 500000
```

Then add the flag `--constructor-args` with the above result to the `forge verify-contract` command
