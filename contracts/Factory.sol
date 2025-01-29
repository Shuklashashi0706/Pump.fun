// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;
import {Token} from "./Token.sol";

contract Factory {
    uint256 public constant TARGET = 3 ether;
    uint256 public constant TOKEN_LIMIT = 500_000 ether;
    uint256 public immutable fee;
    address public owner;
    address[] public tokens;
    uint256 public totalTokens;

    mapping(address => TokenSale) public tokentoSale;

    struct TokenSale {
        address token;
        string name;
        address creator;
        uint256 sold;
        uint256 raised; //how much ether was raised
        bool isOpen;
    }

    event Created(address indexed token);
    event Buy(address indexed token, uint256 amount);

    constructor(uint256 _fee) {
        fee = _fee;
        owner = msg.sender;
    }
    function getTokenSale(
        uint256 _index
    ) public view returns (TokenSale memory) {
        return tokentoSale[tokens[_index]];
    }
    function getCost(uint256 _sold) public pure returns (uint256) {
        uint256 floor = 0.0001 ether;
        uint256 step = 0.0001 ether;
        uint256 increment = 10000 ether;
        uint256 cost = (step * (_sold / increment)) + floor;
        return cost;
    }
    function create(
        string memory _name,
        string memory _symbol
    ) external payable {
        // Make sure that the fee is correct
        require(msg.value >= fee, "Factory : Creator fee not met");
        //create new token
        Token token = new Token(msg.sender, _name, _symbol, 1_000_000 ether);
        //save the token
        tokens.push(address(token));
        totalTokens++;
        //list the token for sale
        TokenSale memory sale = TokenSale(
            address(token),
            _name,
            msg.sender,
            0,
            0,
            true
        );
        tokentoSale[address(token)] = sale;
        //tell people its live
        emit Created(address(token));
    }
    function buy(address _token, uint256 _amount) external payable {
        TokenSale storage sale = tokentoSale[_token];
        //check conditions
        require(sale.isOpen == true, "Factory:Buying closed");
        require(_amount >= 1 ether, "Factory:Amount too low");
        require(_amount <= 10000 ether, "Factory:Amount exceeded");
        //calculate the price of 1 token based upon total bought
        uint256 cost = getCost(sale.sold);
        uint256 price = cost * (_amount / 10 ** 18);

        //Make sure enough eth is sent
        require(msg.value >= price, "Factory:Insufficient ETH recieved");
        //update the sale
        sale.sold += _amount;
        sale.raised += price;
        //make sure fund raising goal isnt met
        if (sale.sold >= TOKEN_LIMIT || sale.raised >= TARGET) {
            sale.isOpen = false;
        }
        Token(_token).transfer(msg.sender, _amount);
        //emit an event
        emit Buy(_token, _amount);
    }
    function deposit(address _token) external {
        //the remaining token balance and the eth raised
        // would go into liquidity pool like uniswap v3
        //For simplicity we will just transfer remaining
        //tokens and ETH raised to the creator
        Token token = Token(_token);
        TokenSale memory sale = tokentoSale[_token];
        require(sale.isOpen == false, "Factory: Target not reached ");
        //transfer tokens
        token.transfer(sale.creator, token.balanceOf(address(this)));
        //Transfer eth raised
        (bool success, ) = payable(sale.creator).call{value: sale.raised}("");
        require(success, "Factory:ETH transfer failed");
    }
    function withdraw(uint256 _amount) external {
        require(msg.sender == owner, "Factory:Not owner");
        (bool success, ) = payable(owner).call{value: _amount}("");
        require(success, "Factory:ETH transfer failed");
    }
}
