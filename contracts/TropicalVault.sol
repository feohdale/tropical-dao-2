// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//owner must be dao 

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./TropicalShares.sol";

contract TropicalVault is Initializable, OwnableUpgradeable, UUPSUpgradeable,ReentrancyGuardUpgradeable { 

    address public papple; 
    address public dao; 
    TropicalShares private tropicalShares;
    address[] tropicalSharesMembers; 
    /*constructor(TropicalShares _tropicalShares, address _papple ){
        
        tropicalShares = _tropicalShares;
        papple = _papple;
    }*/
    function initialize(TropicalShares _tropicalShares, address _papple) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        tropicalShares = _tropicalShares;
        papple = _papple;
    }
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function getTropicalShareHolders() public view returns(address[] memory) {
    return tropicalShares.listShareHolders();
    }
    function getTotalShares() public view returns(uint){
        return tropicalShares.totalSupply();
    }


    



    // Fonction pour retirer des tokens ERC20
    function withdrawERC20(address to, IERC20 token, uint256 amount) external onlyOwner nonReentrant{
        require(token.transfer(to, amount), "Transfer failed");
    }

    // Fonction pour retirer des tokens ERC721
    function withdrawERC721(address to, IERC721 token, uint256 tokenId) external onlyOwner nonReentrant{
        token.transferFrom(address(this), to, tokenId);
    }

    // Permettre au contrat de recevoir des tokens natifs (Ether)
    receive() external payable {}
    function depositEther() external payable {
        
    }
    // Fonction pour retirer des tokens natifs (Ether)
    function withdrawEther(address to, uint256 amount) external onlyOwner nonReentrant{
        require(amount <= address(this).balance, "Insufficient balance");
        payable(to).transfer(amount);
    }
    function withdrawPapple(address to, uint256 amount) external onlyOwner nonReentrant{
         IERC20 token = IERC20(papple);
        require(token.transfer(to, amount), "Transfer failed");
    }

    // Vérification des soldes
    function getERC20Balance(IERC20 token) public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getERC721Balance(IERC721 token, uint256 tokenId) public view returns (bool) {
        return token.ownerOf(tokenId) == address(this);
    }

    function getEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // function distributeMemberERC20(IERC20 token, uint256 totalAmount) public onlyOwner {
    //     address[] memory shareholders = tropicalShares.listShareHolders();
    //         uint256 totalShares = tropicalShares.totalSupply();
    //         require(totalAmount <= token.balanceOf(address(this)), "Insufficient balance");

    //         for (uint256 i = 0; i < shareholders.length; i++) {
    //             address shareholder = shareholders[i];
    //             uint256 shareholderBalance = tropicalShares.balanceOf(shareholder);
    //             uint256 amountPerShareholder = (totalAmount * shareholderBalance) / totalShares;

    //             if (amountPerShareholder > 0) {
    //                 token.transfer(shareholder, amountPerShareholder);
    //             }
    //         }
    // }

    // function distributeMemberPapple(uint256 totalAmount) public onlyOwner {
    //     IERC20 token = IERC20(papple);
    //     address[] memory shareholders = tropicalShares.listShareHolders();
    //             uint256 totalShares = tropicalShares.totalSupply();
    //             require(totalAmount <= token.balanceOf(address(this)), "Insufficient balance");

    //             for (uint256 i = 0; i < shareholders.length; i++) {
    //                 address shareholder = shareholders[i];
    //                 uint256 shareholderBalance = tropicalShares.balanceOf(shareholder);
    //                 uint256 amountPerShareholder = (totalAmount * shareholderBalance) / totalShares;

    //                 if (amountPerShareholder > 0) {
    //                     token.transfer(shareholder, amountPerShareholder);
    //                 }
    //             }
    //     }



    // function distributeEther(uint256 totalAmount) public onlyOwner {
    // address[] memory shareholders = tropicalShares.listShareHolders();
    // uint256 totalShares = tropicalShares.totalSupply();
    // require(totalAmount <= address(this).balance, "Insufficient Ether balance");

    //     for (uint256 i = 0; i < shareholders.length; i++) {
    //         address payable shareholder = payable(shareholders[i]);
    //         uint256 shareholderBalance = tropicalShares.balanceOf(shareholder);
    //         uint256 amountPerShareholder = (totalAmount * shareholderBalance) / totalShares;

    //         if (amountPerShareholder > 0) {
    //             (bool success, ) = shareholder.call{value: amountPerShareholder}("");
    //             require(success, "Ether transfer failed");
    //         }
    //     }
    // }     

  function burnPapple(uint256 amount) public onlyOwner {
        (bool success, ) = papple.call(abi.encodeWithSignature("burn(uint256)", amount));
        require(success, "Failed to burn Papple tokens");
    }
     function addDaoAddress(address _dao) public onlyOwner{
        dao = _dao; 
    }
        function transferOwnershipFromDAO(address newOwner) public {
        require(msg.sender == dao, "Only DAO can perform this action");
        _transferOwnership(newOwner);
    }
}
