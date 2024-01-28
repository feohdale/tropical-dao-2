// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./TropicalShares.sol";

import "./TropicalShares.sol";

contract PaymentSplitter is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    TropicalShares private tropicalShares;
    address tropicalShare;
    IERC20 papple;
    address pappleAddress;
    address usdcAddress;
    IERC20 usdc;
    address public dao;

    /* constructor(
        TropicalShares _tropicalShares,

        address _papple,
        address _usdc
    )   {
        tropicalShares = _tropicalShares;

        papple = IERC20(_papple);
        pappleAddress = _papple;
        usdcAddress = _usdc;
        usdc = IERC20(_usdc);
    }*/
    function initialize(
        TropicalShares _tropicalShares,
        address _papple,
        address _usdc
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        tropicalShares = _tropicalShares;
        papple = IERC20(_papple);
        pappleAddress = _papple;
        usdcAddress = _usdc;
        usdc = IERC20(_usdc);
    }
    function _authorizeUpgrade(address) internal override onlyOwner {}
    modifier onlyTropicalShareHolder() {
        require(
            tropicalShares.balanceOf(msg.sender) > 0,
            "Caller must own TropicalShares"
        );
        _;
    }

    // distribute any  ERC20
    function distributeERC20(
        IERC20 token
    ) public onlyTropicalShareHolder nonReentrant {
        uint256 totalShares = tropicalShares.totalSupply();
        require(totalShares > 0, "No shares exist");
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to distribute");

        address[] memory shareholders = tropicalShares.listShareHolders();
        for (uint i = 0; i < shareholders.length; i++) {
            uint256 shareholderBalance = tropicalShares.balanceOf(
                shareholders[i]
            );
            uint256 payment = (balance * shareholderBalance) / totalShares;
            if (payment > 0) {
                token.transfer(shareholders[i], payment);
            }
        }
    }

    // Distribute  Ether
    function distributeEther()
        public
        payable
        onlyTropicalShareHolder
        nonReentrant
    {
        // require(tropicalShares.balanceOf(msg.sender) > 0, "Caller must own TropicalShares");

        uint256 totalShares = tropicalShares.totalSupply();
        require(totalShares > 0, "No shares exist");
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to distribute");

        address[] memory shareholders = tropicalShares.listShareHolders();
        for (uint i = 0; i < shareholders.length; i++) {
            uint256 shareholderBalance = tropicalShares.balanceOf(
                shareholders[i]
            );
            uint256 payment = (balance * shareholderBalance) / totalShares;
            if (payment > 0) {
                payable(shareholders[i]).transfer(payment);
            }
        }
    }

    function burnPapple(uint256 amount) public onlyOwner {
        (bool success, ) = pappleAddress.call(
            abi.encodeWithSignature("burn(uint256)", amount)
        );
        require(success, "Failed to burn Papple tokens");
    }

    // Fonction pour recevoir des Ether
    receive() external payable {}

    function distributePappleForAll()
        public
        onlyTropicalShareHolder
        nonReentrant
    {
        uint256 totalPapple = papple.balanceOf(address(this));
        require(totalPapple > 0, "No Papple tokens to distribute");

        _distributePapple(totalPapple);
    }

    function distributePartialPapple(
        uint256 totalAmount
    ) public onlyTropicalShareHolder nonReentrant {
        require(
            totalAmount <= papple.balanceOf(address(this)),
            "Insufficient Papple balance"
        );

        _distributePapple(totalAmount);
    }

    function _distributePapple(uint256 totalAmount) internal {
        uint256 totalShares = tropicalShares.totalSupply();
        address[] memory shareholders = tropicalShares.listShareHolders();

        for (uint i = 0; i < shareholders.length; i++) {
            uint256 shareholderBalance = tropicalShares.balanceOf(
                shareholders[i]
            );
            uint256 payment = (totalAmount * shareholderBalance) / totalShares;
            if (payment > 0) {
                papple.transfer(shareholders[i], payment);
            }
        }
    }

    function distributeUSDCForAll()
        public
        onlyTropicalShareHolder
        nonReentrant
    {
        uint256 totalUsdc = usdc.balanceOf(address(this));
        require(totalUsdc > 0, "No Usdc tokens to distribute");

        _distributeUsdc(totalUsdc);
    }

    function distributePartialUsdc(
        uint256 totalAmount
    ) public onlyTropicalShareHolder nonReentrant {
        require(
            totalAmount <= usdc.balanceOf(address(this)),
            "Insufficient Papple balance"
        );

        _distributeUsdc(totalAmount);
    }

    function _distributeUsdc(uint256 totalAmount) internal {
        uint256 totalShares = tropicalShares.totalSupply();
        address[] memory shareholders = tropicalShares.listShareHolders();

        for (uint i = 0; i < shareholders.length; i++) {
            uint256 shareholderBalance = tropicalShares.balanceOf(
                shareholders[i]
            );
            uint256 payment = (totalAmount * shareholderBalance) / totalShares;
            if (payment > 0) {
                usdc.transfer(shareholders[i], payment);
            }
        }
    }

    function addDaoAddress(address _dao) public onlyOwner {
        dao = _dao;
    }

    function transferOwnershipFromDAO(address newOwner) public {
        require(msg.sender == dao, "Only DAO can perform this action");
        _transferOwnership(newOwner);
    }
}
