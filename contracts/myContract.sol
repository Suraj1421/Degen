// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract DegenToken is ERC20, Ownable, ERC20Burnable {
    
    struct Item {
        string name;
        uint8 itemId;
        uint256 price;
    }

    mapping(uint8 => Item) private items;
    mapping(address => Item[]) private playerItems;
    uint8 private nextItemId;

    event ItemPurchased(address indexed buyer, uint8 itemId, string itemName, uint256 price);
    event GameOutcome(address indexed player, uint256 num, bool won, string result);

    constructor(address initialOwner, uint256 initialSupply) ERC20("Degen", "DGN") Ownable(initialOwner) {
        transferOwnership(initialOwner);
        mint(initialOwner, initialSupply);
        _initializeItems();
    }

    // Initialize predefined items in the game
    function _initializeItems() internal {
        _addItem("Novice Navigator", 100);
        _addItem("Mythic Maverick", 700);
        _addItem("Celestial Crusher", 1200);
        _addItem("Astral Ace", 2200);
        _addItem("Divine Dominator", 2400);
    }

    // Add an item to the in-game store
    function _addItem(string memory name, uint256 price) internal {
        items[nextItemId] = Item(name, nextItemId, price);
        nextItemId++;
    }

    // Mint new tokens
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Transfer tokens from one account to another
    function transferToken(address recipient, uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _transfer(msg.sender, recipient, amount);
    }

    // Redeem a welcome bonus if the player has no tokens
    function redeemWelcomeBonus() public {
        require(balanceOf(msg.sender) == 0, "Bonus already claimed");
        _mint(msg.sender, 50);
    }

    // Add a new item to the store by the owner
    function addItemToStore(string memory name, uint256 price) public onlyOwner {
        _addItem(name, price);
    }

    // Place a bet on a random number game
    function betOnRandomNumber(bool predictLessThanFive, uint256 betAmount) public {
        require(balanceOf(msg.sender) >= betAmount, "Insufficient balance");
        
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 10;

        if (predictLessThanFive == (randomNumber < 5)) {
            _mint(msg.sender, betAmount * 2);
            emit GameOutcome(msg.sender, randomNumber, true, "You won!");
        } else {
            burn(betAmount);
            emit GameOutcome(msg.sender, randomNumber, false, "You lost!");
        }
    }

    // Purchase an item using tokens
    function purchaseItem(uint8 itemId) external {
        require(items[itemId].price > 0, "Item not found");
        require(balanceOf(msg.sender) >= items[itemId].price, "Insufficient balance");

        burn(items[itemId].price);
        playerItems[msg.sender].push(items[itemId]);

        emit ItemPurchased(msg.sender, itemId, items[itemId].name, items[itemId].price);
    }

    // Get the list of item IDs a user has purchased
    function getUserItems(address user) external view returns (uint8[] memory) {
        Item[] memory itemsList = playerItems[user];
        uint256 length = itemsList.length;

        uint8[] memory itemIds = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            itemIds[i] = itemsList[i].itemId;
        }

        return itemIds;
    }

    // Get details of a specific item
    function getItemDetails(uint8 itemId) external view returns (string memory, uint256) {
        Item memory item = items[itemId];
        return (item.name, item.price);
    }

    // Get the balance of the caller
    function getMyBalance() external view returns (uint256) {
        return balanceOf(msg.sender);
    }

    // Burn a specific amount of tokens
    function burnTokens(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        burn(amount);
    }
}
