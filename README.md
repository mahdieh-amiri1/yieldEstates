# [yieldEstates](https://yield-estates.vercel.app/)
Pendle protocol but for real estates!
---

## Overview

**yieldEstates** is a decentralized platform revolutionizing real estate investment by tokenizing properties, enabling fractional ownership, and facilitating seamless yield generation through rentals. Leveraging the Frax ecosystem, **yieldEstates** offers a robust marketplace and a comprehensive yield engine, making real estate more accessible, liquid, and efficient.

## Vision

The traditional real estate market faces high entry barriers, limited liquidity, and complex yield management. **yieldEstates** addresses these challenges by:
- Democratizing real estate investment through tokenization.
- Providing liquidity via a dynamic marketplace.
- Simplifying rental and yield management with a robust yield engine.

## Features

- **Tokenize Real Estate**: Fractionalize properties into ERC1155 tokens for multiple owners.
- **Marketplace**: List, buy, sell and rent asset-backed real estate tokens, Primary Tokens (PT), and Yield Tokens (YT).
- **Yield Engine**: Manage rentals, collateral, primary tokens, yield tokens and yield distribution seamlessly.
- **PrimaryToken (ERC20)**: Tradable token representing real estate ownership.
- **YieldToken (ERC20)**: Tradable token representing the right to claim rental yield.
- **Collateral Management**: Secure collateral handling with liquidation mechanisms for non-payment penalty.
- **Oracle Integration**: Real-time price feeds for ETH used as collateral.

## Table of Contents

- [Contracts](#contracts)
  - [ERC1155RealEstate](#erc1155realestate)
  - [MarketPlace](#marketplace)
  - [YieldEngine](#yieldengine)
  - [PrimaryToken](#primarytoken)
  - [YieldToken](#yieldtoken)
  - [PriceConsumer](#priceconsumer)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Deployment](#deployment)
- [Usage](#usage)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Contracts
  
### ERC1155RealEstate

***Address on Fraxtal mainnet: [0xba892672522726e09711300F1A193ff0F2F00222](https://fraxscan.com/address/0xba892672522726e09711300f1a193ff0f2f00222)***

***Address on Fraxtal testnet: [0xFc499e7D593aB1E81a817ad3a2BF00cFB0e1D1b1](https://holesky.fraxscan.com/address/0xFc499e7D593aB1E81a817ad3a2BF00cFB0e1D1b1)***

**Purpose**: Tokenizes real estate into fractional shares allowing multiple ownership.

**Key Functions**:
- `mint`: Creates new real estate tokens.
- `safeTransferFrom`: Enables transfer of fractional shares.

---

### MarketPlace

***Address on Fraxtal mainnet: [0xe70AA5B26D0B7ce07aFc5C76f6045af24D9ad726](https://fraxscan.com/address/0xe70AA5B26D0B7ce07aFc5C76f6045af24D9ad726)***

***Address on Fraxtal testnet: [0xb338208a5c07CA09262a0bf514e87207DAce4Ce4](https://holesky.fraxscan.com/address/0xb338208a5c07CA09262a0bf514e87207DAce4Ce4)***

**Purpose**: Facilitates listing, buying, and selling of real estate tokens, PTs, and YTs.

**Key Functions**:
- `createOffer`: Lists a real estate token for sale or rent.
- `takeOffer`: Allows users to purchase listed real estate tokens or rental of listed real estate tokens.

---
### YieldEngine

***Address on Fraxtal mainnet: [0x5bfca951E55Fed1750e65a5F63A646A83F009e92](https://fraxscan.com/address/0x5bfca951e55fed1750e65a5f63a646a83f009e92)***

***Address on Fraxtal testnet: [0x242a13efb6e4e2e131923f2Aa8df2B4Bde620c86](https://holesky.fraxscan.com/address/0x242a13efb6e4e2e131923f2Aa8df2B4Bde620c86)***

**Purpose**: Manages rentals, collateral, and yield distribution.

**Key Functions**:
- `stakeRealEstate`: Locks real estate tokens and mints PT and YT.
- `payToVault`: Allows renters to pay rental fees in Frax tokens.
- `claimYield`: Enables YT holders to claim yield.
- `realEstateRedeem`: Allows PT holders to redeem real estate tokens after the rental period.
- `collateralRedeem`: Enables renters to redeem their collateral.
- `liquidateCollateralIfNotPaid`: Liquidates collateral if the renter fails to pay.

---
### PrimaryToken

***Address on Fraxtal mainnet: [0xEb5454475d33Bc710Eae4b13E94A441eb49b7981](https://fraxscan.com/address/0xeb5454475d33bc710eae4b13e94a441eb49b7981)***

***Address on Fraxtal testnet: [0x4fdc83425E7655C0a8BAD945819eAc0F186F2E04](https://holesky.fraxscan.com/address/0x4fdc83425E7655C0a8BAD945819eAc0F186F2E04)***

**Purpose**: ERC20 token representing real estate ownership.

**Key Functions**:
- `mint`: Creates new PrimaryTokens.
- `burn`: Destroys PrimaryTokens upon redemption.

---
### YieldToken

***Address on Fraxtal mainnet: [0x0CeABE52f989FaCEd0D6Fee3dF37FeFE5A9DCEeC](https://fraxscan.com/address/0x0ceabe52f989faced0d6fee3df37fefe5a9dceec)***

***Address on Fraxtal testnet: [0x4a07774aB95614a24F979F44571f2A3e15a94f7d](https://holesky.fraxscan.com/address/0x4a07774aB95614a24F979F44571f2A3e15a94f7d)***

**Purpose**: ERC20 token representing the right to claim yield.

**Key Functions**:
- `mint`: Creates new YieldTokens.
- `burn`: Destroys YieldTokens upon yield claim.

---
### PriceConsumer

***Address on Fraxtal mainnet: [0x0092eA01cE547A2Fc236004f26603D3c044dfF74](https://fraxscan.com/address/0x0092ea01ce547a2fc236004f26603d3c044dff74)***

***Address on Fraxtal testnet: [0x5bfca951E55Fed1750e65a5F63A646A83F009e92](https://holesky.fraxscan.com/address/0x5bfca951E55Fed1750e65a5F63A646A83F009e92)***

**Purpose**: Uses RedStone oracles to retrieve the price of ETH for collateral purposes.

**Key Functions**:
- `getLatestPrice`: Retrieves the latest price of ETH.

## Getting Started

### Prerequisites

- **Foundry**: Ensure you have Foundry installed. Follow the [Foundry installation guide](https://github.com/foundry-rs/foundry) if not already set up.
- **Frax Ecosystem**: Ensure you have access to Frax tokens and utilities.

