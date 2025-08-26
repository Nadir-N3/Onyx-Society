// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * ONYX Society – Luxury Membership Black Card (ERC721)
 * Features:
 * - Allowlist mint with Merkle proofs (variable allowance per address)
 * - Public mint
 * - EIP-2981 global royalties
 * - Pausable, Ownable, Reentrancy-guarded
 * - Perk claiming via events (on-chain receipt, flexible off-chain fulfillment)
 * - Revenue withdrawal to an OpenZeppelin PaymentSplitter (optional)
 *
 * Built to feel "1M-budget" classy: minimal, audited building blocks, clean API.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

interface IPaymentSplitter {
    function release(address payable account) external;
    function totalReleased() external view returns (uint256);
}

contract LuxeBlackCard is ERC721, ERC2981, Pausable, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    // ----- Immutable collection parameters -----
    uint256 public immutable maxSupply;

    // ----- Mutable sale config -----
    uint256 public mintPrice; // in wei
    string private _baseTokenURI;
    bytes32 public merkleRoot; // allowlist root: leaf = keccak256(abi.encodePacked(addr, maxAllowance))

    bool public allowlistActive;
    bool public publicSaleActive;

    // ----- Accounting -----
    uint256 public totalMinted;
    mapping(address => uint256) public allowlistMinted;
    address payable public paymentSplitter;

    // ----- Perks (on-chain receipts) -----
    mapping(uint256 => mapping(bytes32 => bool)) public perkClaimed; // tokenId => perkId => claimed

    event AllowlistMint(address indexed minter, uint256 quantity, uint256 paid);
    event PublicMint(address indexed minter, uint256 quantity, uint256 paid);
    event PerkClaimed(uint256 indexed tokenId, bytes32 indexed perkId, address indexed claimer, string details);
    event BaseURIUpdated(string newBaseURI);
    event MintPriceUpdated(uint256 newPrice);
    event SaleStateUpdated(bool allowlist, bool publicSale);
    event RoyaltyUpdated(address receiver, uint96 feeNumerator);
    event PaymentSplitterUpdated(address splitter);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 maxSupply_,
        uint256 mintPriceWei_,
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_ // 500 = 5%
    ) ERC721(name_, symbol_) {
        require(maxSupply_ > 0, "maxSupply=0");
        _baseTokenURI = baseURI_;
        maxSupply = maxSupply_;
        mintPrice = mintPriceWei_;
        _setDefaultRoyalty(royaltyReceiver_, royaltyFeeNumerator_);
    }

    // ------------------ Admin ------------------
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function setMintPrice(uint256 newPriceWei) external onlyOwner {
        mintPrice = newPriceWei;
        emit MintPriceUpdated(newPriceWei);
    }

    function setSaleState(bool allowlist_, bool public_) external onlyOwner {
        allowlistActive = allowlist_;
        publicSaleActive = public_;
        emit SaleStateUpdated(allowlist_, public_);
    }

    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit RoyaltyUpdated(receiver, feeNumerator);
    }

    function setPaymentSplitter(address payable splitter_) external onlyOwner {
        paymentSplitter = splitter_;
        emit PaymentSplitterUpdated(splitter_);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // ------------------ Minting ------------------

    /// @notice Allowlist mint with per-address allowance.
    /// @param quantity number to mint
    /// @param maxAllowance max quantity the address is allowed to mint (encoded in the Merkle leaf)
    /// @param proof Merkle proof for leaf = keccak256(abi.encodePacked(msg.sender, maxAllowance))
    function mintAllowlist(uint256 quantity, uint256 maxAllowance, bytes32[] calldata proof)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(allowlistActive, "allowlist off");
        require(quantity > 0, "qty=0");
        require(totalMinted + quantity <= maxSupply, "sold out");
        require(msg.value == mintPrice * quantity, "wrong ETH");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, maxAllowance));
        require(proof.verify(merkleRoot, leaf), "invalid proof");
        require(allowlistMinted[msg.sender] + quantity <= maxAllowance, "exceeds allowance");

        _mintMany(msg.sender, quantity);
        allowlistMinted[msg.sender] += quantity;

        emit AllowlistMint(msg.sender, quantity, msg.value);
    }

    /// @notice Public mint.
    function mintPublic(uint256 quantity)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(publicSaleActive, "public off");
        require(quantity > 0, "qty=0");
        require(totalMinted + quantity <= maxSupply, "sold out");
        require(msg.value == mintPrice * quantity, "wrong ETH");

        _mintMany(msg.sender, quantity);
        emit PublicMint(msg.sender, quantity, msg.value);
    }

    function _mintMany(address to, uint256 quantity) internal {
        unchecked {
            for (uint256 i = 0; i < quantity; i++) {
                _safeMint(to, totalMinted + 1);
                totalMinted += 1;
            }
        }
    }

    // ------------------ Perks ------------------

    /// @notice Claim a perk with on-chain receipt (event + idempotent flag).
    /// @param tokenId Your membership token id
    /// @param perkId A unique identifier for the perk (e.g. keccak256("2025-Conrad-Bali-Suite"))
    /// @param details Optional plaintext (e.g. booking ref, concierge notes)
    function claimPerk(uint256 tokenId, bytes32 perkId, string calldata details) external whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "not owner");
        require(!perkClaimed[tokenId][perkId], "claimed");
        perkClaimed[tokenId][perkId] = true;
        emit PerkClaimed(tokenId, perkId, msg.sender, details);
    }

    // ------------------ Funds ------------------

    /// @notice Withdraw contract balance to PaymentSplitter if set, else to owner.
    function withdraw() external nonReentrant {
        uint256 bal = address(this).balance;
        require(bal > 0, "no funds");
        if (paymentSplitter != address(0)) {
            (bool ok, ) = paymentSplitter.call{value: bal}("");
            require(ok, "splitter transfer failed");
        } else {
            (bool ok, ) = payable(owner()).call{value: bal}("");
            require(ok, "owner transfer failed");
        }
    }

    // ------------------ Internals ------------------

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
