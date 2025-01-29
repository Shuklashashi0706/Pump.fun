// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20{
    address  payable public  owner;
    address public Creator;
    constructor(address _creator,
    string memory _name,
    string memory _symbol,
    uint256 _totalSupply)
    ERC20(_name,_symbol){
        owner = payable(msg.sender);
        Creator = _creator;
        _mint(msg.sender,_totalSupply);
    }
}