// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title HubXToken
 * @dev Implementation of the HUBX utility token for the FastFitHub ecosystem.
 */
contract HubXToken {
    string public name = "HubX Token";
    string public symbol = "HUBX";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    /**
     * @dev Mints new HUBX tokens.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public {
        // Placeholder for minting logic
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    /**
     * @dev Burns HUBX tokens.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) public {
        // Placeholder for burning logic
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }
}
