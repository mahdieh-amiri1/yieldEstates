// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./token/PrimaryToken.sol";
import "./token/YieldToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./token/ERC1155RealEstate.sol";

contract YieldEngine is Ownable {
    struct RealEstateStake {
        address tokenAddress;
        address staker;
        uint256 tokenId;
        uint256 tokenValue;
    }

    struct CollateralStake {
        address collateral;
        address staker;
        uint256 value;
        uint256 remainedPays;
    }

    address public marketPlace;
    ERC20 public frax;
    PrimaryToken public primaryToken;
    YieldToken public yieldToken;
    uint256 private _stakeIdCounter;

    mapping(uint256 stakeId => uint256 time) private _initTimes;
    mapping(uint256 stakeId => uint256 time) private _redeemTimes;
    mapping(uint256 stakeId => uint256 value) private _yieldVaults;

    mapping(uint256 stakeId => RealEstateStake) private _realEstateStakes;
    mapping(uint256 stakeId => CollateralStake) private _collateralStakes;

    event PrimaryTokenMinted(
        address indexed tokenAddress,
        address indexed to,
        uint256 tokenId,
        uint256 tokenValue
    );
    event YieldTokenMinted(
        address indexed tokenAddress,
        address indexed to,
        uint256 tokenId,
        uint256 tokenValue
    );

    event CollateralLiquidated(uint256 stakeId, address from, uint256 value);

    modifier onlyMarketPlace() {
        require(
            msg.sender == marketPlace,
            "YieldEngine: Caller is not the MarketPlace"
        );
        _;
    }

    constructor(address _marketPlace, address _FRAX) Ownable(msg.sender) {
        require(
            _marketPlace != address(0),
            "YieldEngine: Invalid MarketPlace address"
        );
        marketPlace = _marketPlace;
        frax = ERC20(_FRAX);
        primaryToken = new PrimaryToken("Real Estate Primary Token", "RealPT");
        yieldToken = new YieldToken("Real Estate Yield Token", "RealYT");

        // Transfer ownership of the tokens to the YieldEngine contract
        primaryToken.transferOwnership(address(this));
        yieldToken.transferOwnership(address(this));
    }

    function mintPrimaryToken(
        address tokenAddress,
        address to,
        uint256 tokenId,
        uint256 tokenValue
    ) external onlyMarketPlace returns (uint256 stakeId) {
        stakeId = ++_stakeIdCounter;
        ERC1155RealEstate(tokenAddress).safeTransferFrom(
            to,
            address(this),
            tokenId,
            tokenValue,
            ""
        );
        _initTimes[stakeId] = block.timestamp;
        _redeemTimes[stakeId] = block.timestamp + 360 days;

        _realEstateStakes[stakeId] = RealEstateStake(
            tokenAddress,
            to,
            tokenId,
            tokenValue
        );

        primaryToken.mint(to, tokenValue);
        emit PrimaryTokenMinted(tokenAddress, to, tokenId, tokenValue);
    }

    function mintYieldToken(
        uint256 stakeId,
        uint256 yieldValue
    ) external onlyMarketPlace {
        RealEstateStake memory realEstateStake = _realEstateStakes[stakeId];
        yieldToken.mint(realEstateStake.staker, yieldValue);
        emit YieldTokenMinted(
            realEstateStake.tokenAddress,
            realEstateStake.staker,
            realEstateStake.tokenId,
            yieldValue
        );
    }

    function stakeCollateral(
        uint256 stakeId,
        address collateral,
        address staker,
        uint256 collateralValue,
        uint256 totalPays
    ) external onlyMarketPlace {
        ERC20(collateral).transferFrom(staker, address(this), collateralValue);

        _collateralStakes[stakeId] = CollateralStake(
            collateral,
            staker,
            collateralValue,
            totalPays
        );
    }

    function payToVault(uint256 stakeId, uint256 value) external {
        require(
            _collateralStakes[stakeId].staker == msg.sender,
            "YieldEngine: Only staker can pay to vault"
        );

        frax.transferFrom(msg.sender, address(this), value);
        _yieldVaults[stakeId] += value;

        _collateralStakes[stakeId].remainedPays -= value;
    }

    function claimYield(uint256 stakeId, uint256 yieldValue) external {
        require(
            block.timestamp >= _initTimes[stakeId],
            "YieldEngine: Claim period has not started yet"
        );
        require(
            block.timestamp <= _redeemTimes[stakeId],
            "YieldEngine: Claim period has ended"
        );
        _yieldVaults[stakeId] -= yieldValue;

        yieldToken.burn(msg.sender, yieldValue);
        frax.transfer(msg.sender, yieldValue);
    }

    function realEstateRedeem(uint256 stakeId) external {
        require(
            _realEstateStakes[stakeId].staker == msg.sender,
            "YieldEngine: Only staker can redeem"
        );
        require(
            block.timestamp >= _redeemTimes[stakeId],
            "YieldEngine: Redemption period has not started yet"
        );

        RealEstateStake memory realEstateStake = _realEstateStakes[stakeId];

        primaryToken.burn(msg.sender, realEstateStake.tokenValue);

        ERC1155RealEstate(realEstateStake.tokenAddress).safeTransferFrom(
            address(this),
            realEstateStake.staker,
            realEstateStake.tokenId,
            realEstateStake.tokenValue,
            ""
        );

        // Clean up storage after redemption
        delete _initTimes[stakeId];
        delete _redeemTimes[stakeId];
        delete _realEstateStakes[stakeId];
        delete _yieldVaults[stakeId];
    }

    function collateralRedeem(uint256 stakeId) external {
        require(
            _collateralStakes[stakeId].staker == msg.sender,
            "YieldEngine: Only staker can redeem"
        );

        require(
            block.timestamp >= _redeemTimes[stakeId],
            "YieldEngine: Redemption period has not started yet"
        );

        CollateralStake memory collateralStake = _collateralStakes[stakeId];
        uint256 remainedPays = collateralStake.remainedPays;
        if (remainedPays != 0) {
            _liquidateCollateral(stakeId, remainedPays);
            _collateralStakes[stakeId].value -= remainedPays;
        }

        ERC20(collateralStake.collateral).transfer(
            collateralStake.staker,
            collateralStake.value - remainedPays
        );

        // Clean up storage after redemption
        delete _initTimes[stakeId];
        delete _redeemTimes[stakeId];
        delete _collateralStakes[stakeId];
        delete _yieldVaults[stakeId];
    }

    function _liquidateCollateral(uint256 stakeId, uint256 value) internal {
        require(
            block.timestamp > _redeemTimes[stakeId],
            "YieldEngine: Cannot liquidate before redemption period ends"
        );

        CollateralStake memory collateralStake = _collateralStakes[stakeId];

        ERC20(collateralStake.collateral).transfer(owner(), value);

        _yieldVaults[stakeId] += value;

        emit CollateralLiquidated(stakeId, collateralStake.staker, value);
    }
}
