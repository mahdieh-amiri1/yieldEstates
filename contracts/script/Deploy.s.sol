// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/token/ERC1155RealEstate.sol";
import "../src/MarketPlace.sol";
import "../src/PriceConsumerV3.sol";
import "../test/mocks/MockFraxToken.sol";

contract Deploy is Script {
    function run() external {
        // Load environment variables
        string memory baseURI = "https://ipfs/";
        address priceConsumerAddress;
        address mockFraxTokenAddress;
        address realEstateAddress;

        // Start broadcasting the transaction
        vm.startBroadcast();

        // Deploy PriceConsumerV3
        PriceConsumerV3 priceConsumer = new PriceConsumerV3();
        priceConsumerAddress = address(priceConsumer);
        console.log("Deployed PriceConsumerV3 at", priceConsumerAddress);

        // Deploy the mock token
        MockFraxToken fraxToken = new MockFraxToken(1e6 * 10 ** 18);
        mockFraxTokenAddress = address(fraxToken);
        console.log("Deployed MockFraxToken at", mockFraxTokenAddress);

        // Deploy ERC1155RealEstate
        ERC1155RealEstate realEstate = new ERC1155RealEstate(baseURI);
        realEstateAddress = address(realEstate);
        console.log("Deployed ERC1155RealEstate at", realEstateAddress);

        // Deploy MarketPlace
        MarketPlace marketplace = new MarketPlace(
            priceConsumerAddress,
            mockFraxTokenAddress,
            realEstateAddress
        );
        console.log("Deployed MarketPlace at", address(marketplace));

        // Deploy the PrimaryToken contract
        PrimaryToken primaryToken = new PrimaryToken("PrimaryToken", "PT");
        console.log("Deployed PrimaryToken at", address(primaryToken));

        // Deploy the YieldToken contract
        YieldToken yieldToken = new YieldToken("YieldToken", "YT");
        console.log("Deployed YieldToken at", address(yieldToken));

        // Deploy the YieldEngine contract with the MarketPlace address
        YieldEngine yieldEngine = new YieldEngine(
            address(marketplace),
            mockFraxTokenAddress
        );
        console.log("Deployed YieldEngine at", address(yieldEngine));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
