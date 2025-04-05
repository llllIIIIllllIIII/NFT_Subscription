// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SubscriptionNFT is ERC721Enumerable, Ownable(msg.sender) {
    struct SubscriptionInfo {
        uint256 expiration;
        uint256 price;
    }

    mapping(uint256 => SubscriptionInfo) public subscriptions;
    address[] public paymentTokens;
    uint256 public duration;
    uint256 public price;
    address public provider;

    event Subscribed(address indexed subscriber, uint256 tokenId, uint256 expiration);
    event SubscriptionUpdated(uint256 newDuration, uint256 newPrice);

    constructor(
        address _provider,
        string memory name,
        string memory symbol,
        uint256 _duration,
        uint256 _price,
        address[] memory _paymentTokens
    ) ERC721(name, symbol) {
        provider = _provider;
        duration = _duration;
        price = _price;
        paymentTokens = _paymentTokens;
    }

    function subscribe(address paymentToken) external payable {
        require(isValidPaymentToken(paymentToken), "Invalid payment token");
        uint256 tokenId = totalSupply() + 1;

        // Transfer payment
        require(IERC20(paymentToken).transferFrom(msg.sender, address(this), msg.value), "Payment failed");

        uint256 expiration = block.timestamp + duration;
        subscriptions[tokenId] = SubscriptionInfo(expiration, msg.value);
        _mint(msg.sender, tokenId);

        emit Subscribed(msg.sender, tokenId, expiration);
    }

    function updateSubscription(uint256 newDuration, uint256 newPrice) external onlyOwner {
        duration = newDuration;
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

    function burnExpired(uint256 tokenId) external {
        require(block.timestamp >= subscriptions[tokenId].expiration, "Subscription not expired");
        address owner = ownerOf(tokenId);
        _burn(tokenId);

        // Release funds to provider
        uint256 amount = subscriptions[tokenId].price;
        delete subscriptions[tokenId];
        payable(provider).transfer(amount);
    }
}