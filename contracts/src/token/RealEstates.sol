// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
 


/**
 * @title FractionalizedNFT
 * @dev ERC1155 token with fractional ownership, pausability, burnable, and role-based access control.
 */
contract ERC1155RealEstate is
    ERC1155,
    ERC1155URIStorage,
    ERC1155Pausable,
    ERC1155Supply,
    AccessControl
{
    function setURI(string memory baseURI) external {
        _setURI(baseURI); // See {ERC1155-_setURI}
        _setBaseURI(baseURI); // See {ERC1155URIStorage-_setBaseURI}
    }

    function setURI(uint256 id, string uri) external {
        _setURI(id, uri); // See {ERC1155URIStorage-_setURI}
    }

    function setURIBatch(uint256[] memory ids, string[] memory uris) external {
        require(
            ids.length == uris.length,
            "RWAir: ids and uris length mismatch"
        );

        _setURIBatch(ids, uris);
    }

    function mint(
        address to,
        uint256 id,
        uint256 value,
        string memory uri,
        uint256 totalSupply,
        bytes memory data
    ) external {
        _mint(to, id, value, data);
        _setURI(id, uri); // See {ERC1155URIStorage-_setURI}
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        string[] memory uris,
        uint256[] memory totalSupplies,
        bytes memory data
    ) external {
        _mintBatch(to, ids, values, data);
        _setURIBatch(ids, uris);
    }

    function _setURIBatch(uint256[] memory ids, string[] memory uris) internal {
        for (uint256 i = 0; i < ids.length; i++) {
            _setURI(ids[i], uris[i]); // See {ERC1155URIStorage-_setURI}
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    // Roles
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Constants
    uint256 public constant MAX_TOKEN_AMOUNT = 10_000;

    // Structs
    // struct ApproveData {
    //     address[] approvals;
    //     mapping(address => uint256) allowances;
    // }

    // Ownership and ownership related mappings
    // Token ID to percentage ownership mapping
    mapping(uint256 => mapping(address => uint256)) private ownership;
    // Token ID to oweners list
    // mapping(uint256 => address[]) private owners;
    // Owner address ot owned tokens
    // mapping(address => uint256[]) private ownedTokens;

    // Token ID to approved amounts
    // mapping(uint256 => ApproveData) private approvedAmounts;

    // Events
    // Event emitted when a new token is minted
    // event TokenMinted(uint256 indexed tokenId, address account);

    // Event emitted when an owner removed from token owners list
    // event OwnershipRemoved(uint256 indexed tokenId, address account);

    // Event emitted when an approval is setted
    // event AmountApproved(
    //     uint256 indexed tokenId,
    //     address indexed operator,
    //     uint256 amount
    // );

    // Event emitted when ownership is transferred
    event AmountTransferred(
        uint256 tokenId,
        address from,
        address to,
        uint256 amount
    );

    /**
     * @dev Constructor
     * @param defaultAdmin Default admin address with all roles
     * @param baseUri Base URI for token metadata
     */
    constructor(
        address defaultAdmin,
        // address _reserver,
        string memory baseUri
    ) ERC1155(baseUri) {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, defaultAdmin);
        _grantRole(URI_SETTER_ROLE, defaultAdmin);

        // reserver = Reserver(_reserver);
    }

    // /**
    //  * @dev Set the Reserver contract address
    //  * @param _reserver New Reserver contract address
    //  */
    // function setReserver(
    //     address _reserver
    // ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    //     reserver = Reserver(_reserver);
    // }

    /**
     * @dev Mint a new token with a specific amount as totalAmount
     * @param account Address to receive the minted tokens
     * @param tokenId ID of the token to be minted
     * @param metadata Metadata associated with the token
     * @param data Additional data for minting
     */
    function mint(
        address account,
        uint256 tokenId,
        string memory metadata,
        uint256 totlaSupply,
        bytes memory data
    ) external /*onlyRole(MINTER_ROLE)*/ {
        require(owners[tokenId].length == 0, "Invalid token ID");

        // if (reservable) {
        //     require(reserver.isReserved(tokenId), "Asset is not reserved yet");
        //     reserverPricingUSD[tokenId] = reserver.getAssetPricing(tokenId);
        // }

        _mint(account, tokenId, totlaSupply, data);
        metadatas[tokenId] = metadata;
        // totalAmount[tokenId] = amount;
        ownership[tokenId][account] = totlaSupply;
        owners[tokenId].push(account);
        ownedTokens[account].push(tokenId);
        totlaSupplies[tokenId] = totlaSupply;
        emit TokenMinted(tokenId, account);
    }

    function batchMint(
        address[] memory account,
        uint256[] memory tokenId,
        string[] memory metadata,
        uint256[] memory supply,
        bytes memory data
    ) external /*onlyRole(MINTER_ROLE)*/ {
        require(
            account.length == tokenId.length &&
                tokenId.length == metadata.length,
            "Invalid lengths"
        );

        for (uint256 i = 0; i < account.length; i++) {
            require(owners[tokenId[i]].length == 0, "Invalid token ID");

            // if (reservable) {
            //     require(
            //         reserver.isReserved(tokenIds),
            //         "Asset is not reserved yet"
            //     );
            //     reserverPricingUSD[tokenIds] = reserver.getAssetPricing(
            //         tokenIds
            //     );
            // }

            _mint(account[i], tokenId[i], supply[i], data);
            metadatas[tokenId[i]] = metadata[i];
            // totalAmount[tokenIds[i]] = amount;
            ownership[tokenId[i]][account[i]] = supply[i];
            owners[tokenId[i]].push(account[i]);
            ownedTokens[account[i]].push(tokenId[i]);
            totlaSupplies[tokenId] = totlaSupply;

            emit TokenMinted(tokenId[i], account[i]);
        }
    }

    /**
     * @dev Approve an operator to spend a specific amount of tokens on behalf of the owner
     * @param tokenId ID of the token
     * @param operator Address to approve
     * @param amount Amount of fractions to approve
     */
    function approve(
        uint256 tokenId,
        address operator,
        uint256 amount
    ) external {
        require(
            ownership[tokenId][msg.sender] >= amount,
            "Insufficient allowance"
        );
        require(msg.sender != operator, "Approval to current owner");

        // approveAmounts(tokenId, operator, amount);
        // if (amount == MAX_TOKEN_AMOUNT) {
        setApprovalForAll(operator, true);
        // }

        ApproveData storage approveData = approvedAmounts[tokenId];
        // If have any allowance before
        if (approveData.allowances[operator] == 0) {
            approveData.approvals.push(operator);
        }
        approveData.allowances[operator] = amount;
        emit AmountApproved(tokenId, operator, amount);
    }

    /**
     * @dev Remove approval for an operator on a specific token
     * @param operator Address to remove approval from
     * @param tokenId ID of the token
     */
    function removeApproval(address operator, uint256 tokenId) external {
        require(
            ownership[tokenId][msg.sender] > 0,
            "Invalid ownership amount to remove approval"
        );
        uint256 currentAllowance = allowance(tokenId, operator);
        require(currentAllowance > 0, "Insufficient operator allowance");
        spendAllowance(operator, tokenId, currentAllowance);

        setApprovalForAll(operator, false);
    }

    /**
     * @dev Transfer tokens on behalf of an owner to another address
     * @param from Owner address
     * @param to Address to receive the tokens
     * @param tokenId ID of the token
     * @param amount Amount of fractions to transfer
     * @param data Additional data for the transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external {
        uint256 currentAllowance = allowance(tokenId, msg.sender);
        require(currentAllowance >= amount, "Insufficient allowance");
        spendAllowance(msg.sender, tokenId, amount);

        // Call transfer fuction of this contract
        transfer(from, to, tokenId, amount, data);
    }

    /**
     * @dev Transfer ownership of a specific amount of tokens from one address to another
     * @param from Address from which the tokens are transferred
     * @param to Address to which the tokens are transferred
     * @param tokenId ID of the token
     * @param amount Amount of fractions to transfer
     * @param data Additional data for the transfer
     */
    function transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public {
        require(
            ownership[tokenId][from] >= amount,
            "Insufficient ownership balance"
        );

        ownership[tokenId][from] -= amount;
        // _transfer(from, to, tokenId, amount);
        super.safeTransferFrom(from, to, tokenId, amount, data);

        ownership[tokenId][to] += amount;

        owners[tokenId].push(to);
        ownedTokens[to].push(tokenId);

        // Remove ownership if account 'from' doesn't have any amounts of the token now
        if (ownership[tokenId][from] == 0) {
            removeOwner(tokenId, from);
        }

        emit AmountTransferred(tokenId, from, to, amount);
    }

    /**
     * @dev Get the metadata associated with a token
     * @param tokenId ID of the token
     * @return Metadata string
     */
    function getMetadata(
        uint256 tokenId
    ) external view returns (string memory) {
        return metadatas[tokenId];
    }

    /**
     * @dev Get the reserver USD pricing for each token fraction
     * @param tokenId ID of the token
     * @return Price of the token in USD
     */
    function getReserverPricingUSD(
        uint256 tokenId
    ) external view returns (uint256) {
        // USD Price with 6 decimals
        return reserverPricingUSD[tokenId] / MAX_TOKEN_AMOUNT;
    }

    /**
     * @dev Get the ownership amount of a specific account for a specific token
     * @param account Address of the account
     * @param tokenId ID of the token
     * @return Amount of ownership for the account
     */
    function getOwnershipAmount(
        address account,
        uint256 tokenId
    ) external view returns (uint256) {
        return ownership[tokenId][account];
        // Equal to:
        // return balanceOf(account, tokenId);
    }

    /**
     * @dev Get the list of all accounts that own a specific token
     * @param tokenId ID of the token
     * @return Array of addresses that own the token
     */
    function getOwners(
        uint256 tokenId
    ) external view returns (address[] memory) {
        return owners[tokenId];
    }

    /**
     * @dev Get the percentage ownership of an account for a specific token
     * @param account Address of the account
     * @param tokenId ID of the token
     * @return Percentage ownership of the account for the token
     */
    function getOwnershipPercentage(
        address account,
        uint256 tokenId
    ) external view returns (uint256) {
        return (ownership[tokenId][account] * 100) / MAX_TOKEN_AMOUNT;
    }

    /**
     * @dev Get the list of tokens owned by a specific account
     * @param account Address of the account
     * @return Array of token IDs owned by the account
     */
    function getOwnedTokens(
        address account
    ) external view returns (uint256[] memory) {
        return ownedTokens[account];
    }

    /**
     * @dev Get the allowance for a specific operator on a token
     * @param tokenId ID of the token
     * @param operator Address of the operator
     * @return Allowance amount
     */
    function allowance(
        uint256 tokenId,
        address operator
    ) public view returns (uint256) {
        return approvedAmounts[tokenId].allowances[operator];
    }

    /**
     * @dev Check if a contract supports a specific interface
     * @param interfaceId Interface identifier
     * @return Boolean indicating whether the contract supports the interface
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Pause the contract, preventing transfers and approvals
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract, allowing transfers and approvals
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Spend the allowance of a specific operator on a token
     * @param operator Address of the operator
     * @param tokenId ID of the token
     * @param amount Amount to spend from the allowance
     */
    function spendAllowance(
        address operator,
        uint256 tokenId,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(tokenId, operator);
        require(currentAllowance >= amount, "Insufficient allowance");

        approvedAmounts[tokenId].allowances[operator] -= amount;
    }

    /**
     * @dev Remove an account from token owners list and remove the token from its owned tokens list
     * @param tokenId ID of the token
     * @param account Address to remove from ownership
     */
    function removeOwner(uint256 tokenId, address account) internal {
        // Storage pointer to access owners list
        address[] storage _owners = owners[tokenId];
        uint _ownersCount = _owners.length;

        for (uint i; i < _ownersCount - 1; i++) {
            if (_owners[i] == account) {
                // Replace with last owner in list
                owners[tokenId][i] = _owners[_ownersCount - 1];
            }
        }
        // Remove last owner
        owners[tokenId].pop();

        // Storage pointer to access tokens list
        uint256[] storage _tokens = ownedTokens[account];
        uint _tokensCount = _tokens.length;

        for (uint i; i < _tokensCount - 1; i++) {
            if (_tokens[i] == tokenId) {
                // Replace with last owner in list
                ownedTokens[account][i] = _tokens[_tokensCount - 1];
            }
        }
        // Remove last token
        ownedTokens[account].pop();

        emit OwnershipRemoved(tokenId, account);
    }

    /**
     * @dev Internal function to update the balance of multiple accounts and tokens
     * @param from Address from which the tokens will be transferred
     * @param to Address to which the tokens will be transferred
     * @param ids Array of token IDs
     * @param values Array of amounts to transfer
     */
    // function _update(
    //     address from,
    //     address to,
    //     uint256[] memory ids,
    //     uint256[] memory values
    // ) internal override(ERC1155, ERC1155Pausable) {
    //     super._update(from, to, ids, values);
    // }
}