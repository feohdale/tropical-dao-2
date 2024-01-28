// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TropicalShares is ERC20Upgradeable, OwnableUpgradeable {

    uint256 public constant MAX_SUPPLY = 100 * 10**2;
    mapping(address=> bool) isKnown; 
    address[] public shareHolders; 

   /* constructor() ERC20("Tropical Shares", "TRPS") {
       
    }*/

    function initialize() public initializer {
        __ERC20_init("Tropical Shares", "TRPS");
        __Ownable_init();
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        if(isKnown[to] == false){
            shareHolders.push(to);
            isKnown[to]=true;
        }
        _mint(to, amount);
    }

     function approveTransfer(address from, address to, uint256 amount) public onlyOwner {
        _transfer(from, to, amount);
    }
    function transfer(address, uint256) public virtual override returns (bool) {
        revert("Transfer is disabled");
    }

    function transferFrom(address, address, uint256) public virtual override returns (bool) {
        revert("TransferFrom is disabled");
    }

    function approvedTransfer(address from, address to, uint256 amount) public onlyOwner {
        if(isKnown[to] == false){
            shareHolders.push(to);
            isKnown[to]=true;
            }
        _transfer(from, to, amount);
    }
    function numberOfShareHolders() public view returns(uint){
        return shareHolders.length;
    }
    
    function listShareHolders() public view returns( address[] memory){
        address[] memory listOfShareHolders = new address[](shareHolders.length); 
        for(uint i=0; i<shareHolders.length; i++)
        {
            listOfShareHolders[i]=shareHolders[i];
        }
        return listOfShareHolders;
    }

}