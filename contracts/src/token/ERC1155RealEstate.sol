// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * @title ERC1155RealEstate
 * @dev ERC1155 token with fractional ownership, pausability, burnable, and role-based access control.
 */
contract ERC1155RealEstate is
    ERC1155,
    ERC1155URIStorage,
    ERC1155Pausable,
    ERC1155Supply,
    AccessControl
{
    /**
     * @dev Indicates an array length mismatch between ids and uris in a setURIBatch operation.
     * Used in batch uri sets.
     * @param idsLength Length of the array of token identifiers
     * @param uirsLength Length of the array of token uris
     */
    error RealEstateInvalidArrayLength(uint256 idsLength, uint256 uirsLength);
    error RealEstateMintValueExceedsMaxSupply(uint256 value, uint256 maxSupply);

    error RealEstateNonexistentToken(uint256 id);

    uint256 private _idCounter;

    mapping(uint256 id => uint256) private _maxSupply;

    // Ownership and ownership related mappings
    mapping(uint256 id => address[] accounts) private _owners;
    mapping(address account => uint256[] ids) private _tokens;

    mapping(address account => mapping(address operator => mapping(uint256 id => uint256 value)))
        private _operatorApprovals;

    // Roles
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event TokenMinted(address to, uint256 id, uint256 value);

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 id,
        uint256 value,
        bool approved
    );

    event OwnershipRemoved(address indexed from, uint256 indexed id);

    /**
     * @dev Constructor
     * @param baseURI Base URI for token metadata
     */
    constructor(string memory baseURI) ERC1155(baseURI) {
        address defaultAdmin = _msgSender();
        _setBaseURI(baseURI);
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, defaultAdmin);
        _grantRole(URI_SETTER_ROLE, defaultAdmin);
    }

    function mint(
        address to,
        uint256 id,
        uint256 value,
        string memory uri_,
        uint256 maxSupply_,
        bytes memory data
    ) external {
        if (exists(id)) {
            if (totalSupply(id) + value > _maxSupply[id])
                revert RealEstateMintValueExceedsMaxSupply(
                    value,
                    _maxSupply[id]
                );
        } else {
            id = ++_idCounter;
            _maxSupply[id] = maxSupply_;
            _setURI(id, uri_); // See {ERC1155URIStorage-_setURI} emits URI(uri(tokenId), tokenId)
        }

        if (balanceOf(to, id) == 0) {
            _owners[id].push(to);
            _tokens[to].push(id);
        }
        _mint(to, id, value, data);
        emit TokenMinted(to, id, value);
    }

    function maxSupply(uint256 id) external view returns (uint256) {
        return _maxSupply[id];
    }

    //TO DO
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        string[] memory uris,
        // uint256[] memory fixedTotalSupplies,
        bytes memory data
    ) external {
        _mintBatch(to, ids, values, data);
        _setURIBatch(ids, uris);
    }

    //TO DO: Test who can burn - owner or isApproved; Why to burn?
    function burn(address from, uint256 id, uint256 value) external {
        _burn(from, id, value);
    }

    //TO DO: Test who can burn - owner or isApproved; Why to burn?
    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) external {
        _burnBatch(from, ids, values);
    }

    function setURI(string memory baseURI) external {
        _setURI(baseURI); // See {ERC1155-_setURI}
        _setBaseURI(baseURI); // See {ERC1155URIStorage-_setBaseURI}
    }

    function setURI(uint256 id, string memory uri_) external {
        _setURI(id, uri_); // See {ERC1155URIStorage-_setURI} emits URI(uri(tokenId), tokenId)
    }

    function setURIBatch(uint256[] memory ids, string[] memory uris) external {
        if (ids.length != uris.length) {
            revert RealEstateInvalidArrayLength(ids.length, uris.length);
        }
        _setURIBatch(ids, uris);
    }

    function setApproval(
        address operator,
        uint256 id,
        uint256 value,
        bool approved
    ) external virtual {
        address owner = _msgSender();
        if (operator == address(0)) {
            revert ERC1155InvalidOperator(address(0));
        }
        _operatorApprovals[owner][operator][id] = value;

        emit Approval(owner, operator, id, value, approved);
    }

    function ownersOf(uint256 id) external view returns (address[] memory) {
        if (_owners[id].length == 0) {
            revert RealEstateNonexistentToken(id);
        }
        return _owners[id];
    }

    function tokensOf(
        address account
    ) external view returns (uint256[] memory) {
        return _tokens[account];
    }

    function approval(
        address account,
        address operator,
        uint256 id
    ) external view returns (uint256) {
        return _operatorApprovals[account][operator][id];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public override {
        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            if (_operatorApprovals[from][sender][id] < value) {
                revert ERC1155MissingApprovalForAll(sender, from);
            }
            _operatorApprovals[from][sender][id] -= value;
        }

        _safeTransferFrom(from, to, id, value, data);

        // if(balanceOf(from, id) == 0){
        //     _removeOwnership(from, id);
        // }

        // emits TransferSingle(operator, from, to, id, value);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public override {
        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            for (uint256 i; i < ids.length; i++) {
                if (_operatorApprovals[from][sender][ids[i]] < values[i])
                    revert ERC1155MissingApprovalForAll(sender, from);

                _operatorApprovals[from][sender][ids[i]] -= values[i];
                // if (balanceOf(from, ids[i]) - values[i] == 0) {
                //     _removeOwnership(from, ids[i]);
                // }
            }
        }
        _safeBatchTransferFrom(from, to, ids, values, data);
        // emits TransferBatch(operator, from, to, ids, values);
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
     * @dev Check if a contract supports a specific interface
     * @param interfaceId Interface identifier
     * @return Boolean indicating whether the contract supports the interface
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function uri(
        uint256 id
    ) public view override(ERC1155, ERC1155URIStorage) returns (string memory) {
        return super.uri(id);
    }

    function _setURIBatch(uint256[] memory ids, string[] memory uris) internal {
        for (uint256 i = 0; i < ids.length; i++) {
            _setURI(ids[i], uris[i]); // See {ERC1155URIStorage-_setURI} emits URI(uri(tokenId), tokenId)
        }
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._update(from, to, ids, values);
    }

    /**
     * @dev Remove an account from token owners list and remove the token from its owned tokens list
     * @param id ID of the token
     * @param from Address to remove from ownership
     */
    function _removeOwnership(address from, uint256 id) internal {
        // Storage pointer to access owners list
        address[] storage owners = _owners[id];
        uint256 ownersCount = owners.length;

        for (uint i; i < ownersCount - 1; i++) {
            if (owners[i] == from) {
                // Replace with last owner in list
                _owners[id][i] = owners[ownersCount - 1];
            }
        }
        // Remove last owner
        _owners[id].pop();

        // Storage pointer to access tokens list
        uint256[] storage tokens = _tokens[from];
        uint256 tokensCount = tokens.length;

        for (uint i; i < tokensCount - 1; i++) {
            if (tokens[i] == id) {
                // Replace with last owner in list
                _tokens[from][i] = tokens[tokensCount - 1];
            }
        }
        // Remove last token
        _tokens[from].pop();

        emit OwnershipRemoved(from, id);
    }
}
