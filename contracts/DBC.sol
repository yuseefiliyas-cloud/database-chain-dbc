// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DatabaseChainToken is ERC20, ERC20Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 500_000_000 * 10**18; // 500 Million DBC
    uint256 public constant FO/UNDER_ALLOCATION = (MAX_SUPPLY * 20) / 100; // 100 Million DBC (20%)
    uint256 public constant ECOSYSTEM_ALLOCATION = MAX_SUPPLY - FOUNDER_ALLOCATION; // 400 Million DBC (80%)

    constructor(address _founderWallet, address _ecosystemWallet)
        ERC20("Database Chain", "DBC")
        Ownable(msg.sender)
    {
        require(_founderWallet != address(0), "Invalid founder address");
        require(_ecosystemWallet != address(0), "Invalid ecosystem address");

        _mint(_founderWallet, FOUNDER_ALLOCATION);
        _mint(_ecosystemWallet, ECOSYSTEM_ALLOCATION);
    }
}
