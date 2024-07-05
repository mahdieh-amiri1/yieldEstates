# yieldEstates

![yieldEstates](https://path_to_logo/logo.png) <!-- Replace with your project's logo URL -->

## Overview

**yieldEstates** is a decentralized platform revolutionizing real estate investment by tokenizing properties, enabling fractional ownership, and facilitating seamless yield generation through rentals. Leveraging the Frax ecosystem, **yieldEstates** offers a robust marketplace and a comprehensive yield engine, making real estate more accessible, liquid, and efficient.

## Vision

The traditional real estate market faces high entry barriers, limited liquidity, and complex yield management. **yieldEstates** addresses these challenges by:
- Democratizing real estate investment through tokenization.
- Providing liquidity via a dynamic marketplace.
- Simplifying rental and yield management with a robust yield engine.

## Features

- **Tokenize Real Estate**: Fractionalize properties into ERC1155 tokens for multiple owners.
- **Marketplace**: List, buy, and sell real estate tokens, Primary Tokens (PT), and Yield Tokens (YT).
- **Yield Engine**: Manage rentals, collateral, and yield distribution seamlessly.
- **PrimaryToken (ERC20)**: Tradable token representing real estate ownership.
- **YieldToken (ERC20)**: Tradable token representing the right to claim rental yield.
- **Collateral Management**: Secure collateral handling with liquidation mechanisms for non-payment.
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

**Purpose**: Tokenizes real estate into fractional shares allowing multiple ownership.

**Key Functions**:
- `mint`: Creates new real estate tokens.
- `safeTransferFrom`: Enables transfer of fractional shares.

### MarketPlace

**Purpose**: Facilitates listing, buying, and selling of real estate tokens, PTs, and YTs.

**Key Functions**:
- `createOffer`: Lists a real estate token for sale or rent.
- `takeOffer`: Allows users to purchase listed real estate tokens or rental of listed real estate tokens.

### YieldEngine

**Purpose**: Manages rentals, collateral, and yield distribution.

**Key Functions**:
- `stakeRealEstate`: Locks real estate tokens and mints PT and YT.
- `payToVault`: Allows renters to pay rental fees in Frax tokens.
- `claimYield`: Enables YT holders to claim yield.
- `realEstateRedeem`: Allows PT holders to redeem real estate tokens after the rental period.
- `collateralRedeem`: Enables renters to redeem their collateral.
- `liquidateCollateralIfNotPaid`: Liquidates collateral if the renter fails to pay.

### PrimaryToken

**Purpose**: ERC20 token representing real estate ownership.

**Key Functions**:
- `mint`: Creates new PrimaryTokens.
- `burn`: Destroys PrimaryTokens upon redemption.

### YieldToken

**Purpose**: ERC20 token representing the right to claim yield.

**Key Functions**:
- `mint`: Creates new YieldTokens.
- `burn`: Destroys YieldTokens upon yield claim.

### PriceConsumer

**Purpose**: Uses RedStone oracles to retrieve the price of ETH for collateral purposes.

**Key Functions**:
- `getLatestPrice`: Retrieves the latest price of ETH.

## Getting Started

### Prerequisites

- **Foundry**: Ensure you have Foundry installed. Follow the [Foundry installation guide](https://github.com/foundry-rs/foundry) if not already set up.
- **Frax Ecosystem**: Ensure you have access to Frax tokens and utilities.

