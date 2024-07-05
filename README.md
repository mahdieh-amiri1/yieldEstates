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
- `transfer`: Enables transfer of fractional shares.

### MarketPlace

**Purpose**: Facilitates listing, buying, and selling of real estate tokens, PTs, and YTs.

**Key Functions**:
- `listProperty`: Lists a real estate token for sale or rent.
- `buyProperty`: Allows users to purchase listed real estate tokens.
- `rentProperty`: Enables rental of listed real estate tokens.

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

- **Node.js** and **npm**: Ensure you have [Node.js](https://nodejs.org/) and [npm](https://www.npmjs.com/) installed.
- **Hardhat**: Install Hardhat for Ethereum development.

```bash
npm install --save-dev hardhat

Fraxtal Ecosystem: Ensure you have access to Fraxtal tokens and utilities.
Installation
Clone the repository:
bash
Copy code
git clone https://github.com/yourusername/yieldEstates.git
cd yieldEstates
Install dependencies:
bash
Copy code
npm install
Deployment
Configure environment: Create a .env file based on .env.example and add your configuration.
Compile contracts:
bash
Copy code
npx hardhat compile
Deploy contracts:
bash
Copy code
npx hardhat run scripts/deploy.js --network your_network
Usage
Mint Real Estate Tokens: Use ERC1155RealEstate to mint tokens.
List on MarketPlace: List tokens for sale or rent using MarketPlace.
Stake and Generate Yield: Utilize YieldEngine to stake tokens, pay rental fees, claim yield, and redeem collateral.
Testing
Run tests:
bash
Copy code
npx hardhat test
Check coverage:
bash
Copy code
npx hardhat coverage
Contributing
Fork the repository.
Create a feature branch:
bash
Copy code
git checkout -b feature/your-feature
Commit your changes:
bash
Copy code
git commit -m 'Add new feature'
Push to the branch:
bash
Copy code
git push origin feature/your-feature
Open a Pull Request.
License
This project is licensed under the MIT License - see the LICENSE file for details.

Contact
Project Maintainer: Your Name - your.email@example.com
GitHub: https://github.com/yourusername/yieldEstates
yaml
Copy code

---

### Notes:
- Replace placeholders like `yourusername`, `your_network`, and email with actual values.
- Update the URL to your logo if available.
- Ensure the contact details and deployment scripts match your actual setup.
- Add any additional details or configurations specific to your project's needs.

This `README.md` provides a comprehensive overview of the project, along with instructions for setup, usage, and contribution, making it easier for others to understand and engage with your project.

