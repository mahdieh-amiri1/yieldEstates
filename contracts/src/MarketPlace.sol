// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./token/ERC1155RealEstate.sol";
import {PriceConsumerV3} from "./PriceConsumerV3.sol";

contract MarketPlace is AccessControl, ReentrancyGuard, Pausable {
    error MarketPlaceInvalidArrayLength(
        uint256 tokensLength,
        uint256 typesLength
    );
    error MarketPlaceInvalidLister(
        address sender,
        address tokenAddress,
        address from,
        uint256 tokanId
    );

    error MarketPlaceNotAllowedToken(address tokanAddress);

    error MarketPlaceInvalidTokenValue(
        address tokenAddress,
        address from,
        uint256 tokenId,
        uint256 tokenValue
    );

    error MarketPlaceInvalidUpdater(uint256 offerId, address sender);
    error MarketPlaceInvalidOfferTaker(uint256 offerId, address sender);
    error MarketPlaceInvalidOfferStatus(uint256 offerId);

    enum TokenType {
        NOTALLOWED,
        REALESTATE,
        YIELD,
        PRIMARY,
        ALLOWEDBUYER
    }

    enum OfferStatus {
        INVALID,
        PENDING,
        VALID
    }

    enum OfferType {
        INVALID,
        RENT,
        SELL
    }

    struct Offer {
        address tokenAddress;
        TokenType tokenType;
        uint256 tokenId;
        uint256 tokenValue;
        address buyerToken; // Optional: If set as address(0) => All allowed tokens are acceptable
        uint256 price;
        OfferStatus offerStatus;
        OfferType offerType;
        address privateOfferTaker; // Optional
    }
    mapping(uint256 offerId => Offer) private _offers;
    mapping(uint256 offerId => mapping(address owner => bool)) private _listers;
    mapping(uint256 offerId => address seller) private _seller;
    mapping(address => TokenType) private _tokenTypes;

    uint256 private _offersCount;
    uint256 public fee; // fee in basis points
    PriceConsumerV3 public priceConsumerV3;

    mapping(uint256 => uint256) private offerBlockNumbers;

    /**
     * @dev Emitted after an offer is updated
     * @param tokens the token addresses
     **/
    event TokenTypesToggled(
        address[] indexed tokens,
        TokenType[] indexed types
    );

    event RealEstateListed(
        uint256 indexed offerId,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event MarketPlaceListerJoined(uint256 offerId, address from);

    event OfferUpdated(
        uint256 indexed offerId,
        uint256 tokenValue,
        address buyerToken,
        uint256 price,
        address privateOfferTaker
    );

    /**
     * @dev Emitted after an offer is deleted
     * @param offerId the Id of the offer to be deleted
     **/
    event OfferDeleted(uint256 indexed offerId);

    event SellOfferFilled(
        uint256 indexed offerId,
        address indexed seller,
        address indexed buyer
    );

    /**
     * @dev Emitted after an offer is deleted
     * @param oldFee the old fee basic points
     * @param newFee the new fee basic points
     **/
    event FeeChanged(uint256 indexed oldFee, uint256 indexed newFee);

    constructor(address _priceConsumerV3) {
        address defaultAdmin = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        priceConsumerV3 = PriceConsumerV3(_priceConsumerV3);
    }

    function toggleTokenTypes(
        address[] calldata tokens_,
        TokenType[] calldata types_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokens_.length != types_.length) {
            revert MarketPlaceInvalidArrayLength(tokens_.length, types_.length);
        }

        for (uint256 i = 0; i < tokens_.length; i++) {
            _tokenTypes[tokens_[i]] = types_[i];
        }
        emit TokenTypesToggled(tokens_, types_);
    }

    function createOffer(
        address tokenAddress,
        address from,
        uint256 tokenId,
        uint256 tokenValue, //Must be total owned accounts for rent offer
        address buyerToken,
        uint256 price,
        OfferType offerType,
        address privateOfferTaker
    )
        external
        // , OfferType offerType // can be RENT, SELL, etc.
        whenNotPaused
    {
        if (
            _tokenTypes[tokenAddress] != TokenType.REALESTATE ||
            _tokenTypes[buyerToken] != TokenType.ALLOWEDBUYER
        ) revert MarketPlaceNotAllowedToken(tokenAddress);

        if (
            !ERC1155RealEstate(tokenAddress).isApproved(
                from,
                msg.sender,
                tokenId,
                tokenValue
            )
        )
            revert MarketPlaceInvalidLister(
                msg.sender,
                tokenAddress,
                from,
                tokenId
            );

        if (offerType == OfferType.RENT)
            if (
                tokenValue !=
                ERC1155RealEstate(tokenAddress).balanceOf(from, tokenId)
            )
                revert MarketPlaceInvalidTokenValue(
                    tokenAddress,
                    from,
                    tokenId,
                    tokenValue
                );

        _createOffer(
            tokenAddress,
            from,
            tokenId,
            tokenValue,
            buyerToken,
            price,
            offerType,
            privateOfferTaker
        );
    }

    // Only for RENT offers
    function joinOffer(
        uint256 offerId,
        address from,
        uint256 tokenValue
    ) external whenNotPaused {
        Offer memory offer = _offers[offerId];

        if (offer.offerType != OfferType.RENT) revert();
        // Check is approved
        if (
            _listers[offerId][from] ||
            !ERC1155RealEstate(offer.tokenAddress).isApproved(
                from,
                msg.sender,
                offer.tokenId,
                tokenValue
            ) // Check it's not redandant lister
        )
            revert MarketPlaceInvalidLister(
                msg.sender,
                offer.tokenAddress,
                from,
                offer.tokenId
            );

        _joinOffer(offerId, from, tokenValue);
    }

    // Approve contract before calling this
    function takeOffer(
        uint256 offerId,
        uint256 value,
        address buyerToken
    ) external whenNotPaused {
        Offer memory offer = _offers[offerId];

        if (offer.offerStatus != OfferStatus.VALID)
            revert MarketPlaceInvalidOfferStatus(offerId);
        address buyer = msg.sender;
        if (
            offer.privateOfferTaker != address(0) &&
            buyer != offer.privateOfferTaker
        ) revert MarketPlaceInvalidOfferTaker(offerId, buyer);

        if (
            offer.buyerToken == address(0) &&
            _tokenTypes[buyerToken] != TokenType.ALLOWEDBUYER
        ) revert MarketPlaceNotAllowedToken(buyerToken);

        if (offer.buyerToken != address(0)) {
            buyerToken = offer.buyerToken;
        }

        ERC1155RealEstate realEstateToken = ERC1155RealEstate(
            offer.tokenAddress
        );

        if (offer.offerType == OfferType.SELL) {
            uint256 totalPrice = offer.price * offer.tokenValue;
            address seller = _seller[offerId];
            if (ERC20(buyerToken).balanceOf(buyer) < totalPrice) {
                revert(); // Low balance
            }

            // uint256 maxSupply = realEstateToken.maxSupply(offer.tokenId);

            ERC20(buyerToken).transferFrom(
                msg.sender,
                _seller[offerId],
                totalPrice
            );

            realEstateToken.safeTransferFrom(
                seller,
                buyer,
                offer.tokenId,
                offer.tokenValue,
                ""
            );

            emit SellOfferFilled(offerId, seller, buyer);
        } else if (offer.offerType == OfferType.RENT) {
            // Implement renting logic here

            address[] memory tokenOwners = realEstateToken.ownersOf(
                offer.tokenId
            );

            for (uint256 i; i < tokenOwners.length; i++) {
                uint256 ownerShare = realEstateToken.balanceOf(
                    tokenOwners[i],
                    offer.tokenId
                ) * offer.price;

                // Mint PT and YT for owners based on their owned shares of the RealEstateToken
                // Lock callaterall from renter to the vault
            }
        }

        // _takeOffer(offerId, price, amount);
    }

    function updateOffer(
        uint256 offerId,
        uint256 tokenValue,
        address buyerToken,
        uint256 price,
        address privateOfferTaker
    ) external whenNotPaused {
        if (!_listers[offerId][msg.sender]) {
            revert MarketPlaceInvalidUpdater(offerId, msg.sender);
        }

        _updateOffer(offerId, tokenValue, buyerToken, price, privateOfferTaker);
    }

    function deleteOffer(uint256 offerId) external whenNotPaused {
        if (!_listers[offerId][msg.sender]) {
            revert MarketPlaceInvalidUpdater(offerId, msg.sender);
        }
        _deleteOffer(offerId);
    }

    function deleteOfferByAdmin(
        uint256[] calldata offerIds
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = offerIds.length;
        for (uint256 i = 0; i < length; i++) {
            _deleteOffer(offerIds[i]);
        }
    }

    function getOffersCount() external view returns (uint256) {
        return _offersCount;
    }

    function getTokenType(
        address tokenAddress
    ) external view returns (TokenType) {
        return _tokenTypes[tokenAddress];
    }

    function tokenInfo(
        address tokenAddress
    ) external view returns (uint256, string memory, string memory) {
        ERC20 tokenInterface = ERC20(tokenAddress);
        return (
            tokenInterface.decimals(),
            tokenInterface.symbol(),
            tokenInterface.name()
        );
    }

    function getOffer(uint256 offerId) external view returns (Offer memory) {
        return _offers[offerId];
    }

    function pricePreview(
        uint256 offerId,
        uint256 value
    ) external view returns (uint256) {
        Offer memory offer = _offers[offerId];
        return (value * offer.price) * ERC20(offer.buyerToken).decimals();
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

    function _createOffer(
        // initializing the offer. to make it valid must call updateOffer or...
        address tokenAddress,
        address from,
        uint256 tokenId,
        uint256 tokenValue,
        address buyerToken,
        uint256 price,
        OfferType offerType,
        address privateOfferTaker
    ) private {
        // if no offerId is given a new offer is made, if offerId is given only the offers price is changed if owner matches
        uint256 offerId = _offersCount++;
        // _offersCount++;
        // if (_buyer != address(0)) {
        // buyers[_offerId] = _buyer;
        // }

        OfferStatus offerStatus = OfferStatus.VALID;

        if (offerType == OfferType.RENT) {
            if (
                tokenValue != ERC1155RealEstate(tokenAddress).maxSupply(tokenId)
            ) {
                offerStatus = OfferStatus.PENDING;

                _listers[offerId][from] = true;

                emit MarketPlaceListerJoined(offerId, from);
            } else {
                _listers[offerId][from] = true;
                emit RealEstateListed(offerId, tokenAddress, tokenId, price);
            }
        } else if (offerType == OfferType.SELL) {
            _seller[offerId] = from;
            emit RealEstateListed(offerId, tokenAddress, tokenId, price);
        }

        _offers[offerId] = Offer(
            tokenAddress,
            TokenType.REALESTATE,
            tokenId,
            tokenValue,
            buyerToken,
            price,
            offerStatus,
            offerType,
            privateOfferTaker
        );

        offerBlockNumbers[offerId] = block.number;
    }

    function _joinOffer(
        uint256 offerId,
        address from,
        uint256 tokenValue
    ) private {
        Offer memory offer = _offers[offerId];

        if (
            offer.tokenValue + tokenValue ==
            ERC1155RealEstate(offer.tokenAddress).maxSupply(offer.tokenId)
        ) {
            _offers[offerId].offerStatus = OfferStatus.VALID;
            emit RealEstateListed(
                offerId,
                offer.tokenAddress,
                offer.tokenId,
                offer.price
            );
        } else {
            emit MarketPlaceListerJoined(offerId, from);
        }

        _offers[offerId].tokenValue += tokenValue;
        _listers[offerId][from] = true;
    }

    function _updateOffer(
        uint256 offerId,
        uint256 tokenValue,
        address buyerToken,
        uint256 price,
        address privateOfferTaker
    ) private {
        if (_offers[offerId].offerType == OfferType.SELL) {
            _offers[offerId].tokenValue = tokenValue;
        }
        _offers[offerId].buyerToken = buyerToken;

        _offers[offerId].price = price;

        emit OfferUpdated(
            offerId,
            _offers[offerId].tokenValue,
            buyerToken,
            price,
            privateOfferTaker
        );
    }

    function _deleteOffer(uint256 offerId) private {
        delete _offers[offerId];
    }

    // function _buy(uint256 _offerId, uint256 _price, uint256 _amount) private {
    //     if (buyers[_offerId] != address(0)) {
    //         require(buyers[_offerId] == msg.sender, "private offer");
    //     }

    //     address seller = sellers[_offerId];
    //     address offerToken = offerTokens[_offerId];
    //     address buyerToken = buyerTokens[_offerId];

    //     ERC20 offerTokenInterface = ERC20(offerToken);
    //     ERC20 buyerTokenInterface = ERC20(buyerToken);

    //     // Check if the offer is validated in the last block
    //     require(
    //         block.number > offerBlockNumbers[_offerId],
    //         "can not buy in the same block as offer creation"
    //     );

    //     // given price is being checked with recorded data from mappings
    //     require(prices[_offerId] == _price, "offer price wrong");

    //     // calculate the price of the order
    //     require(_amount <= amounts[_offerId], "amount too high");
    //     require(
    //         _amount * _price > (uint256(10) ** offerTokenInterface.decimals()),
    //         "amount too low"
    //     );
    //     uint256 buyerTokenAmount = (_amount * _price) /
    //         (uint256(10) ** offerTokenInterface.decimals());

    //     // some old erc20 tokens give no return value so we must work around by getting their balance before and after the exchange
    //     uint256 oldBuyerBalance = buyerTokenInterface.balanceOf(msg.sender);
    //     uint256 oldSellerBalance = offerTokenInterface.balanceOf(seller);

    //     // Update amount in mapping
    //     amounts[_offerId] = amounts[_offerId] - _amount;

    //     // finally do the exchange
    //     buyerTokenInterface.transferFrom(msg.sender, seller, buyerTokenAmount);
    //     offerTokenInterface.transferFrom(seller, msg.sender, _amount);

    //     // now check if the balances changed on both accounts.
    //     // we do not check for exact amounts since some tokens behave differently with fees, burnings, etc
    //     // we assume if both balances are higher than before all is good
    //     require(
    //         oldBuyerBalance > buyerTokenInterface.balanceOf(msg.sender),
    //         "buyer error"
    //     );
    //     require(
    //         oldSellerBalance > offerTokenInterface.balanceOf(seller),
    //         "seller error"
    //     );

    //     emit OfferAccepted(
    //         _offerId,
    //         seller,
    //         msg.sender,
    //         offerToken,
    //         buyerToken,
    //         _price,
    //         _amount
    //     );
    // }
}
