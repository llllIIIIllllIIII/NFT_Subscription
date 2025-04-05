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

    event Subscribed(address indexed subscriber, uint256 tokenId, uint256 expiration);
    event SubscriptionUpdated(uint256 newDuration, uint256 newPrice);

    constructor(
        address _provider,
        string memory name,
        string memory symbol,
        uint256 _duration,
        uint256 _price,
        address[] memory _paymentTokens
    ) ERC721(name, symbol) Ownable(msg.sender) {
        provider = _provider;
        duration = _duration;
        price = _price;
        paymentTokens = _paymentTokens;
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

    function isExpired(uint256 tokenId) external view returns (bool) {
        return block.timestamp >= subscriptions[tokenId].expiration;
    }

    function burnExpired(uint256 tokenId) external {
        require(block.timestamp >= subscriptions[tokenId].expiration, "Subscription not expired");

        address owner = ownerOf(tokenId);
        require(owner != address(0), "Invalid owner");

        _burn(tokenId);

        uint256 amount = subscriptions[tokenId].price;
        delete subscriptions[tokenId];

        payable(provider).transfer(amount);
    }

    function totalSupply() public view returns (uint256) {
        return _currentTokenId;
    }
}