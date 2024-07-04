// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./token/ERC1155RealEstate.sol";


contract MarketPlace is AccessControl, ReentrancyGuard, Pausable {
    enum TokenType {
        NOTALLOWED,
        REALESTATE,
        ERC20TOKEN
    }

    mapping(uint256 => uint256) private prices;
    mapping(uint256 => uint256) private amounts;
    mapping(uint256 => address) private offerTokens;
    mapping(uint256 => address) private buyerTokens;
    mapping(uint256 => address) private sellers;
    mapping(uint256 => address) private buyers;
    mapping(address => TokenType) private tokenTypes;
    uint256 private offerCount;
    uint256 public fee; // fee in basis points

    mapping(uint256 => uint256) private offerBlockNumbers;

    /**
     * @dev Emitted after an offer is updated
     * @param tokens the token addresses
     **/
    event TokenWhitelistWithTypeToggled(
        address[] indexed tokens,
        TokenType[] indexed types
    );

    /**
     * @dev Emitted after an offer is created
     * @param offerToken the token you want to sell
     * @param buyerToken the token you want to buy
     * @param offerId the Id of the offer
     * @param price the price in baseunits of the token you want to sell
     * @param amount the amount of tokens you want to sell
     **/
    event OfferCreated(
        address indexed offerToken,
        address indexed buyerToken,
        address seller,
        address buyer,
        uint256 indexed offerId,
        uint256 price,
        uint256 amount
    );

    /**
     * @dev Emitted after an offer is updated
     * @param offerId the Id of the offer
     * @param oldPrice the old price of the token
     * @param newPrice the new price of the token
     * @param oldAmount the old amount of tokens
     * @param newAmount the new amount of tokens
     **/
    event OfferUpdated(
        uint256 indexed offerId,
        uint256 oldPrice,
        uint256 indexed newPrice,
        uint256 oldAmount,
        uint256 indexed newAmount
    );

    /**
     * @dev Emitted after an offer is deleted
     * @param offerId the Id of the offer to be deleted
     **/
    event OfferDeleted(uint256 indexed offerId);

    /**
     * @dev Emitted after an offer is accepted
     * @param offerId The Id of the offer that was accepted
     * @param seller the address of the seller
     * @param buyer the address of the buyer
     * @param price the price in baseunits of the token
     * @param amount the amount of tokens that the buyer bought
     **/
    event OfferAccepted(
        uint256 indexed offerId,
        address indexed seller,
        address indexed buyer,
        address offerToken,
        address buyerToken,
        uint256 price,
        uint256 amount
    );

    /**
     * @dev Emitted after an offer is deleted
     * @param oldFee the old fee basic points
     * @param newFee the new fee basic points
     **/
    event FeeChanged(uint256 indexed oldFee, uint256 indexed newFee);

    modifier onlyWhitelistTokenWithType(address token_) {
        require(
            tokenTypes[token_] != TokenType.NOTALLOWED,
            "Token is not whitelisted"
        );
        _;
    }

    constructor() {
        address defaultAdmin = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    function toggleWhitelistWithType(
        address[] calldata tokens_,
        TokenType[] calldata types_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = tokens_.length;
        require(types_.length == length, "Lengths are not equal");
        for (uint256 i = 0; i < length; ) {
            tokenTypes[tokens_[i]] = types_[i];
            ++i;
        }
        emit TokenWhitelistWithTypeToggled(tokens_, types_);
    }

    function createOffer(
        address offerToken,
        address buyerToken,
        address buyer,
        uint256 price,
        uint256 amount
    ) public whenNotPaused {
        // If the offerToken is a RealToken, isTransferValid need to be checked
        if (tokenTypes[offerToken] == TokenType.REALESTATE) {
            require(
                _isTransferValid(offerToken, msg.sender, msg.sender, amount),
                "Seller can not transfer tokens"
            );
        }
        _createOffer(offerToken, buyerToken, buyer, price, amount);
    }

    function buy(
        uint256 offerId,
        uint256 price,
        uint256 amount
    ) external whenNotPaused {
        _buy(offerId, price, amount);
    }

    function updateOffer(
        uint256 offerId,
        uint256 price,
        uint256 amount
    ) external whenNotPaused {
        _updateOffer(offerId, price, amount);
    }

    function deleteOffer(uint256 offerId) public whenNotPaused {
        require(
            sellers[offerId] == msg.sender,
            "only the seller can delete offer"
        );
        _deleteOffer(offerId);
    }

    function deleteOfferBatch(
        uint256[] calldata offerIds
    ) external whenNotPaused {
        uint256 length = offerIds.length;
        for (uint256 i = 0; i < length; ) {
            deleteOffer(offerIds[i]);
            ++i;
        }
    }

    function deleteOfferByAdmin(
        uint256[] calldata offerIds
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = offerIds.length;
        for (uint256 i = 0; i < length; ) {
            _deleteOffer(offerIds[i]);
            ++i;
        }
    }

    function getOfferCount() external view returns (uint256) {
        return offerCount;
    }

    function getTokenType(address token) external view returns (TokenType) {
        return tokenTypes[token];
    }

    function tokenInfo(
        address tokenAddr
    ) external view returns (uint256, string memory, string memory) {
        ERC20 tokenInterface = ERC20(tokenAddr);
        return (
            tokenInterface.decimals(),
            tokenInterface.symbol(),
            tokenInterface.name()
        );
    }

    function getInitialOffer(
        uint256 offerId
    )
        external
        view
        returns (address, address, address, address, uint256, uint256)
    {
        return (
            offerTokens[offerId],
            buyerTokens[offerId],
            sellers[offerId],
            buyers[offerId],
            prices[offerId],
            amounts[offerId]
        );
    }

    function showOffer(
        uint256 offerId
    )
        external
        view
        returns (address, address, address, address, uint256, uint256)
    {
        // get offerTokens balance and allowance, whichever is lower is the available amount
        uint256 availableBalance = ERC20(offerTokens[offerId]).balanceOf(
            sellers[offerId]
        );
        uint256 availableAllow = ERC20(offerTokens[offerId]).allowance(
            sellers[offerId],
            address(this)
        );
        uint256 availableAmount = amounts[offerId];

        if (availableBalance < availableAmount) {
            availableAmount = availableBalance;
        }

        if (availableAllow < availableAmount) {
            availableAmount = availableAllow;
        }

        return (
            offerTokens[offerId],
            buyerTokens[offerId],
            sellers[offerId],
            buyers[offerId],
            prices[offerId],
            availableAmount
        );
    }

    function pricePreview(
        uint256 offerId,
        uint256 amount
    ) external view returns (uint256) {
        ERC20 offerTokenInterface = ERC20(offerTokens[offerId]);
        return
            (amount * prices[offerId]) /
            (uint256(10) ** offerTokenInterface.decimals());
    }

    function saveLostTokens(
        address token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC20 tokenInterface = ERC20(token);
        tokenInterface.transfer(
            msg.sender,
            tokenInterface.balanceOf(address(this))
        );
    }

    function setFee(uint256 fee_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit FeeChanged(fee, fee_);
        fee = fee_;
    }

    /**
     * @notice Creates a new offer or updates an existing offer (call this again with the changed price + offerId)
     * @param _offerToken The address of the token to be sold
     * @param _buyerToken The address of the token to be bought
     * @param _price The price in base units of the token to be sold
     * @param _amount The amount of tokens to be sold
     **/
    function _createOffer(
        address _offerToken,
        address _buyerToken,
        address _buyer,
        uint256 _price,
        uint256 _amount
    )
        private
        onlyWhitelistTokenWithType(_offerToken)
        onlyWhitelistTokenWithType(_buyerToken)
    {
        // if no offerId is given a new offer is made, if offerId is given only the offers price is changed if owner matches
        uint256 _offerId = offerCount;
        offerCount++;
        if (_buyer != address(0)) {
            buyers[_offerId] = _buyer;
        }
        sellers[_offerId] = msg.sender;
        offerTokens[_offerId] = _offerToken;
        buyerTokens[_offerId] = _buyerToken;
        prices[_offerId] = _price;
        amounts[_offerId] = _amount;
        offerBlockNumbers[_offerId] = block.number;

        emit OfferCreated(
            _offerToken,
            _buyerToken,
            msg.sender,
            _buyer,
            _offerId,
            _price,
            _amount
        );
    }

    /**
     * @notice Creates a new offer or updates an existing offer (call this again with the changed price + offerId)
     * @param _offerId The address of the token to be sold
     * @param _price The address of the token to be bought
     * @param _amount The price in base units of the token to be sold
     **/
    function _updateOffer(
        uint256 _offerId,
        uint256 _price,
        uint256 _amount
    ) private {
        require(
            sellers[_offerId] == msg.sender,
            "only the seller can change offer"
        );
        emit OfferUpdated(
            _offerId,
            prices[_offerId],
            _price,
            amounts[_offerId],
            _amount
        );
        prices[_offerId] = _price;
        amounts[_offerId] = _amount;
    }

    /**
     * @notice Deletes an existing offer
     * @param _offerId The Id of the offer to be deleted
     **/
    function _deleteOffer(uint256 _offerId) private {
        delete sellers[_offerId];
        delete buyers[_offerId];
        delete offerTokens[_offerId];
        delete buyerTokens[_offerId];
        delete prices[_offerId];
        delete amounts[_offerId];
        emit OfferDeleted(_offerId);
    }

    /**
     * @notice Accepts an existing offer
     * @notice The buyer must bring the price correctly to ensure no frontrunning / changed offer
     * @notice If the offer is changed in meantime, it will not execute
     * @param _offerId The Id of the offer
     * @param _price The price in base units of the offer tokens
     * @param _amount The amount of offer tokens
     **/
    function _buy(uint256 _offerId, uint256 _price, uint256 _amount) private {
        if (buyers[_offerId] != address(0)) {
            require(buyers[_offerId] == msg.sender, "private offer");
        }

        address seller = sellers[_offerId];
        address offerToken = offerTokens[_offerId];
        address buyerToken = buyerTokens[_offerId];

        ERC20 offerTokenInterface = ERC20(offerToken);
        ERC20 buyerTokenInterface = ERC20(buyerToken);

        // Check if the offer is validated in the last block
        require(
            block.number > offerBlockNumbers[_offerId],
            "can not buy in the same block as offer creation"
        );

        // given price is being checked with recorded data from mappings
        require(prices[_offerId] == _price, "offer price wrong");

        // calculate the price of the order
        require(_amount <= amounts[_offerId], "amount too high");
        require(
            _amount * _price > (uint256(10) ** offerTokenInterface.decimals()),
            "amount too low"
        );
        uint256 buyerTokenAmount = (_amount * _price) /
            (uint256(10) ** offerTokenInterface.decimals());

        // some old erc20 tokens give no return value so we must work around by getting their balance before and after the exchange
        uint256 oldBuyerBalance = buyerTokenInterface.balanceOf(msg.sender);
        uint256 oldSellerBalance = offerTokenInterface.balanceOf(seller);

        // Update amount in mapping
        amounts[_offerId] = amounts[_offerId] - _amount;

        // finally do the exchange
        buyerTokenInterface.transferFrom(msg.sender, seller, buyerTokenAmount);
        offerTokenInterface.transferFrom(seller, msg.sender, _amount);

        // now check if the balances changed on both accounts.
        // we do not check for exact amounts since some tokens behave differently with fees, burnings, etc
        // we assume if both balances are higher than before all is good
        require(
            oldBuyerBalance > buyerTokenInterface.balanceOf(msg.sender),
            "buyer error"
        );
        require(
            oldSellerBalance > offerTokenInterface.balanceOf(seller),
            "seller error"
        );

        emit OfferAccepted(
            _offerId,
            seller,
            msg.sender,
            offerToken,
            buyerToken,
            _price,
            _amount
        );
    }

    /**
     * @notice Returns true if the transfer is valid, false otherwise
     * @param _token The token address
     * @param _from The sender address
     * @param _to The receiver address
     * @param _amount The amount of tokens to be transferred
     * @return Whether the transfer is valid
     **/
    function _isTransferValid(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) private view returns (bool) {
        // Generalize verifying rules (for example: 11, 1, 12)
        bool isTransferValid = ERC1155RealEstate(_token).canTransfer(
            _from,
            _to,
            _amount
        );

        // If everything is fine, return true
        return isTransferValid;
    }

    function createOfferBatch(
        address[] calldata _offerTokens,
        address[] calldata _buyerTokens,
        address[] calldata _buyers,
        uint256[] calldata _prices,
        uint256[] calldata _amounts
    ) external whenNotPaused {
        uint256 length = _offerTokens.length;
        require(
            _buyerTokens.length == length &&
                _buyers.length == length &&
                _prices.length == length &&
                _amounts.length == length,
            "length mismatch"
        );
        for (uint256 i = 0; i < length; ) {
            createOffer(
                _offerTokens[i],
                _buyerTokens[i],
                _buyers[i],
                _prices[i],
                _amounts[i]
            );
            ++i;
        }
    }

    function updateOfferBatch(
        uint256[] calldata _offerIds,
        uint256[] calldata _prices,
        uint256[] calldata _amounts
    ) external whenNotPaused {
        uint256 length = _offerIds.length;
        require(
            _prices.length == length && _amounts.length == length,
            "length mismatch"
        );
        for (uint256 i = 0; i < length; ) {
            _updateOffer(_offerIds[i], _prices[i], _amounts[i]);
            ++i;
        }
    }

    function buyOfferBatch(
        uint256[] calldata _offerIds,
        uint256[] calldata _prices,
        uint256[] calldata _amounts
    ) external whenNotPaused {
        uint256 length = _offerIds.length;
        require(
            _prices.length == length && _amounts.length == length,
            "length mismatch"
        );
        for (uint256 i = 0; i < length; ) {
            _buy(_offerIds[i], _prices[i], _amounts[i]);
            ++i;
        }
    }
}
