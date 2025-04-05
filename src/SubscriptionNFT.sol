// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SubscriptionNFT is ERC721, ERC721Burnable, Ownable {
    struct SubscriptionInfo {
        uint256 startTime;
        uint256 expiration;
        uint256 price;
    }

    mapping(uint256 => SubscriptionInfo) public subscriptions;
    address[] public paymentTokens;
    uint256 public duration;
    uint256 public price;
    address public provider;

    uint256 private _currentTokenId;
    address private _owner;

    event Subscribed(address indexed subscriber, uint256 tokenId, uint256 expiration);
    event SubscriptionUpdated(uint256 newDuration, uint256 newPrice);

    constructor(
        string memory _name,
        string memory _symbol,
        address _provider,
        uint256 _duration,
        uint256 _price,
        address[] memory _paymentTokens
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        provider = _provider;
        duration = _duration;
        price = _price;
        paymentTokens = _paymentTokens;
        _owner = msg.sender;
    }

    function subscribe(address paymentToken) external payable {
        require(isValidPaymentToken(paymentToken), "Invalid payment token");

        uint256 tokenId = ++_currentTokenId;

        require(IERC20(paymentToken).transferFrom(msg.sender, address(this), msg.value), "Payment failed");

        uint256 expiration = block.timestamp + duration;
        subscriptions[tokenId] = SubscriptionInfo(block.timestamp, expiration, msg.value);
        _mint(msg.sender, tokenId);

        emit Subscribed(msg.sender, tokenId, expiration);
    }

    function updateSubscription(uint256 newDuration, uint256 newPrice) external onlyOwner {
        duration = newDuration;
        price = newPrice;
        emit SubscriptionUpdated(newDuration, newPrice);
    }

    function isValidPaymentToken(address token) public view returns (bool) {
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            if (paymentTokens[i] == token) {
                return true;
            }
        }
        return false;
    }

    function isExpired(uint256 tokenId) external  returns (bool) {
        if (subscriptions[tokenId].expiration < block.timestamp) {
            _burn(tokenId);
            return false; // Token does not exist
        }
        return block.timestamp >= subscriptions[tokenId].expiration;
    }

    function burnExpired(uint256 tokenId) external {
        require(block.timestamp >= subscriptions[tokenId].expiration, "Subscription not expired");

        address owner = ownerOf(tokenId);
        require(owner != address(0), "Invalid owner");

        _burn(tokenId);

        delete subscriptions[tokenId];


    }

    function totalSupply() public view returns (uint256) {
        return _currentTokenId;
    }

    function getSubscriptionInfo(uint256 tokenId) external view returns (SubscriptionInfo memory) {
        require(_ownerOf(tokenId)!= address(0), "Token does not exist");
        require(_ownerOf(tokenId) == msg.sender || msg.sender == _owner, "Not the owner of the token or this contract");
        return subscriptions[tokenId];
    }
}