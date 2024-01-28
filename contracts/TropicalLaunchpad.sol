
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TropicalLaunchpad is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    IERC20 public _USDC;
    IERC20 public _papple;
    address payable public _wallet;
    uint public startPRE; 
    uint public startPUB; 
    uint256 public endPRE;
    uint256 public endPUB;
    uint256 public price;
    uint public maxPurchase;
    uint public availableTokens;
    uint public totalUsdcRaisedWL;
    uint public totalUsdcRaisedPublic; 
    uint public totalUsdcRaised;
    uint public totalPappleSold;
    uint8 public whitelistSize;
    bool public liveClaim ;
    bool public pauseStatus; 
    uint public pauseTimerStart; 
    uint public pauseTimerStop;
    uint public pauseTimerToExtend;
    uint public timeClaim;
    uint public totalPublicAvailable;
    uint public totalPreSaleAvailable; 

    address[] public funders;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public addressToUsdcFunded;
    mapping(address => uint256) public addressTo_WL_UsdcFunded;
    mapping(address => uint256) public addressToPapplePurchased;
    mapping(address => uint256) public addressTo_WL_PapplePurchased;
    mapping(address => uint256) public addressToPappleTotalPurchased; 


    struct claimWL {
        bool firstClaim;
        uint256 lastClaim;
        uint256 unlockPerDay;
        uint256 startAmount;
        uint256 totalClaimed;
    }

    struct claimPublic {
        bool firstClaim;
        uint256 lastClaim;
        uint256 unlockPerDay;
        uint256 startAmount;
        uint256 totalClaimed;        
    }

    mapping(address => claimWL) public vault_claimWL;
    mapping(address => claimPublic) public vault_claimPublic;

    event TokensPurchased(address indexed beneficiary, uint256 usdcValue, uint256 tokenAmount);
    event TokensClaimed(address indexed beneficiary, uint256 tokenAmount);

    /*constructor (address payable wallet, IERC20 token, IERC20 usdc) {
        require(wallet != address(0), "Constructor: wallet is the zero address");
        require(address(token) != address(0), "Constructor: token is the zero address");
        require(address(usdc) != address(0), "Constructor: usdc is the zero address");
        
        _wallet = wallet;
        _papple = token;
        _USDC = usdc;
    }*/
    function initialize(
        address payable wallet,
        IERC20 token,
        IERC20 usdc
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        _wallet = wallet;
        _papple = token;
        _USDC = usdc;

        liveClaim = false;

    }


    modifier preActive() {
        require(endPRE > 0 && block.timestamp < endPRE && availableTokens > 0, "Pre-Sale must be active");
        _;
    }
    
    modifier preNotActive() {
        require(endPRE < block.timestamp, "Pre-Sale should not be active");
        _;
    }

    modifier pubActive() {
        require(endPUB > 0 && block.timestamp < endPUB && availableTokens > 0, "Public Sale must be active");
        _;
    }
    
    modifier pubNotActive() {
        require(endPUB < block.timestamp, "Public Sale should not be active");
        _;
    }
    modifier contractIsNotPaused() {
        require(pauseStatus == false, "The contract is paused no deposit allowed"); 
        _;
    }
    // function setPresale(uint timestamp) external onlyOwner preNotActive() pubNotActive() {
        
    // }
    //Start Pre-Sale 
    function startPreSale(uint256 _endHours) public onlyOwner preNotActive() pubNotActive() {
        availableTokens = 1000000 * 1 ether; // 1000.000 $PAPPLE
        totalPreSaleAvailable = availableTokens; 
        price = 100000; // 0.1 USDC
        //maxPurchase = 25000 * 1 ether; // 10.000 $PAPPLE
        maxPurchase = 250000000000000000000000; // 2500 $PAPPLE
        endPRE = block.timestamp + (_endHours * 1 hours); //time in hours  
    }
    
    function stopPreSale() external onlyOwner preActive() contractIsNotPaused() {
        endPRE = 0;
    }

    //Start Public Sale
    function startPublic(uint256 _endHours) external onlyOwner preNotActive() pubNotActive() contractIsNotPaused() {
        availableTokens = totalPreSaleAvailable + 1200000 * 1 ether; // Pre-Sale unsold + 500.000 $PAPPLE
        price = 200000; // 0.20 USDC
        endPUB = block.timestamp + (_endHours * 1 hours); // 96 Hours 
        totalPublicAvailable = availableTokens;
    }
    
    function stopPublic() external onlyOwner pubActive() {
        endPUB = 0;
    }
    
    //Pre-Sale Internal
    function buyPresale(address _sender, uint256 amount) internal preActive() contractIsNotPaused() {
        uint256 purchased = getTokenAmount(amount);
        require(whitelist[_sender], "Address not in Whitelist");
        require((addressTo_WL_PapplePurchased[_sender] + purchased) <= maxPurchase, "Address exceeds purchasing limit");
        require(availableTokens >= purchased, "Amount purchased exceeds avaiable tokens");
        //addressToUsdcFunded[_sender] += amount;
        addressTo_WL_UsdcFunded[_sender] += amount;
        addressTo_WL_PapplePurchased[_sender] += purchased;
        totalUsdcRaisedWL +=amount; 
        totalUsdcRaised += amount;
        totalPappleSold += purchased;
        addressToPappleTotalPurchased[_sender] += purchased;
        totalPreSaleAvailable = availableTokens - purchased;
        availableTokens -= purchased;
        
        emit TokensPurchased(_sender, amount, purchased);
    }

    //Public Sale Internal
    function buyPublic(address _sender, uint256 amount) internal pubActive() contractIsNotPaused() {
        uint256 purchased = getTokenAmount(amount);
        require(availableTokens >= purchased, "Amount purchased exceeds avaiable tokens");
        addressToUsdcFunded[_sender] += amount;
        addressToPapplePurchased[_sender] += purchased;
        addressToPappleTotalPurchased[_sender] += purchased;
        totalUsdcRaisedPublic += amount;
        totalUsdcRaised += amount;
        totalPappleSold += purchased;
        availableTokens -= purchased;
        emit TokensPurchased(_sender, amount, purchased);
    }

    // Universal Buy Function
    function buyTokens(uint _usdcAmount) external payable nonReentrant {
        address beneficiary = msg.sender;
        uint256 amount = _usdcAmount;
        bool addrRegistered = false;
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(amount != 0, "Crowdsale: USDC amount is 0");
        require(_USDC.allowance(msg.sender, address(this)) >= amount, "Insufficient USDC allowance");
        require(_USDC.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");
        if (endPRE > 0 && block.timestamp < endPRE && availableTokens > 0){
            buyPresale(beneficiary, amount);
        } else if (endPUB > 0 && block.timestamp < endPUB && availableTokens > 0){
            buyPublic(beneficiary, amount);
        } else {
            require(false, "Sale is not active");
        }
        for(uint i=0; i<funders.length; i++){
            if(funders[i] == beneficiary){addrRegistered = true;}
        }
        if(addrRegistered == false){funders.push(beneficiary);}
    }

    // Whitelist Functions
    function addToWhitelist(address[] memory _addresses) external onlyOwner {
        require(whitelistSize + _addresses.length <= 100, "Addresses exceeds whitelist capacity");
        for (uint8 i = 0; i < _addresses.length; i++) {
            require(!whitelist[_addresses[i]], "Address is already in whitelist");
            whitelist[_addresses[i]] = true;
            whitelistSize += 1;
        }
    }

    function removeFromWhitelist(address[] memory _addresses) external onlyOwner {
        require(whitelistSize - _addresses.length >= 0, "More addresses than whitelist size");
        for (uint8 i = 0; i < _addresses.length; i++) {
            require(whitelist[_addresses[i]], "Address not in whitelist");
            whitelist[_addresses[i]] = false;
            whitelistSize -= 1;
        }
    }

    // Start Claim
    function startClaim() external onlyOwner preNotActive() pubNotActive() contractIsNotPaused(){
        liveClaim = true;
        timeClaim = block.timestamp;
    }

    // Claim
    function claimPapple() external payable nonReentrant preNotActive() pubNotActive() contractIsNotPaused() {
        address sender = msg.sender;
        uint256 claimAmount;
        uint256 startAmount;
        uint256 totalClaimAmount;
        uint256 totalUnlocked;
        require(liveClaim, "Claim is not active");
        require(addressTo_WL_PapplePurchased[sender] > 0 || addressToPapplePurchased[sender] > 0, "Your $PAPPLE balance is 0");
        if (addressTo_WL_PapplePurchased[sender] > 0){
            if (!vault_claimWL[sender].firstClaim){
                startAmount = addressTo_WL_PapplePurchased[sender]; // Save start amount
                claimAmount = addressTo_WL_PapplePurchased[sender] * 50 / 100; // 50% First claim
                addressTo_WL_PapplePurchased[sender] -= addressTo_WL_PapplePurchased[sender] * 50 / 100; // Update Balance
                uint256 unlockPerDay = addressTo_WL_PapplePurchased[sender] / 1; // 30 days
                vault_claimWL[sender] = claimWL({
                    firstClaim: true,
                    lastClaim: timeClaim,
                    unlockPerDay: unlockPerDay,
                    startAmount: startAmount,
                    totalClaimed: claimAmount
                });
                totalClaimAmount += claimAmount;
                claimAmount = 0; // Reset variable
            }
            totalUnlocked = vault_claimWL[sender].unlockPerDay * (block.timestamp -  vault_claimWL[sender].lastClaim) / 86400; // Total Unlocked from last claim
            if (totalUnlocked > (vault_claimWL[sender].startAmount - vault_claimWL[sender].totalClaimed)){totalUnlocked = vault_claimWL[sender].startAmount - vault_claimWL[sender].totalClaimed;}
            addressTo_WL_PapplePurchased[sender] -= totalUnlocked; // Update balance
            claimAmount += totalUnlocked; // Claim
            vault_claimWL[sender].totalClaimed += claimAmount;
            vault_claimWL[sender].lastClaim = block.timestamp; // Update structure
            totalClaimAmount += claimAmount;
            claimAmount = 0; // Reset variable
        }

        if (addressToPapplePurchased[sender] > 0){
             if (!vault_claimPublic[sender].firstClaim){
                 startAmount = addressToPapplePurchased[sender]; // Save start amount
                 //claimAmount = addressToPapplePurchased[sender] * 60 / 100; // 60% First claim
                 claimAmount = addressToPapplePurchased[sender]; // 60% First claim
                 //addressToPapplePurchased[sender] -= addressToPapplePurchased[sender] * 60 / 100; // Update Balance
                 addressToPapplePurchased[sender] = 0; // Update Balance
                 uint256 unlockPerDay = addressToPapplePurchased[sender]; 
                 vault_claimPublic[sender] = claimPublic({
                     firstClaim: true,
                     lastClaim: timeClaim,
                     unlockPerDay: unlockPerDay,
                     startAmount: startAmount,
                     totalClaimed: claimAmount
                 });

                //totalClaimAmount += addressToPapplePurchased[sender];
                totalClaimAmount += startAmount;
                claimAmount = 0; // Reset variable

                 }
       //      totalUnlocked = vault_claimPublic[sender].unlockPerDay * (block.timestamp -  vault_claimPublic[sender].lastClaim) / 86400; // Total Unlocked from last claim
       //         if (totalUnlocked > (vault_claimPublic[sender].startAmount - vault_claimPublic[sender].totalClaimed)){totalUnlocked = vault_claimPublic[sender].startAmount - vault_claimPublic[sender].totalClaimed;}
       //             addressToPapplePurchased[sender] -= totalUnlocked; // Update balance
       //             claimAmount += totalUnlocked; // Claim
       //             vault_claimPublic[sender].totalClaimed += claimAmount;
       //             vault_claimPublic[sender].lastClaim = block.timestamp; // Update structure
       //             totalClaimAmount += claimAmount;
        //            claimAmount = 0; // Reset variable
                    
               
                }
                require(_papple.transfer(sender, totalClaimAmount), "$PAPPLE transfer failed");
                emit TokensClaimed(sender, totalClaimAmount);

    }

    // VIEW

    function getTokenAmount(uint256 usdcAmount) public view returns(uint256) {
        uint256 purchased = usdcAmount / price;
        purchased = purchased * 1 ether; // Conversion to 18 decimals
        return purchased;
    }

    function viewFunders() external view returns(address[] memory _funders){
        return funders;
    }

    // ONLY OWNER

    // function setPrice(uint256 newPrice) external onlyOwner {
    //     price = newPrice;
    // }
    
    function setAvailableTokens(uint256 amount) external onlyOwner {
        availableTokens = amount;
        totalPublicAvailable = amount; 
    }
    
    function setWalletReceiver(address payable newWallet) external onlyOwner{
        _wallet = newWallet;
    }
    
    function setMaxPurchase(uint256 value) external onlyOwner{
        maxPurchase = value;
    }
    
    function setLiveClaim(bool set) external onlyOwner{
        liveClaim = set;
    }

    function withdrawETH() external onlyOwner preNotActive() pubNotActive() contractIsNotPaused(){
         require(address(this).balance > 0, "Contract has no ETH");
        _wallet.transfer(address(this).balance);    
    }
    
    function withdrawTokens(IERC20 tokenAddress) external onlyOwner preNotActive() pubNotActive() contractIsNotPaused(){
        IERC20 wToken = tokenAddress;
        uint256 tokenAmt = wToken.balanceOf(address(this));
        require(tokenAmt > 0, "Token balance is 0");
        wToken.transfer(_wallet, tokenAmt);
    }
    function setPause() external onlyOwner contractIsNotPaused(){
        pauseTimerStart = block.timestamp;
        pauseStatus=true; 
    }
    function unSetPause() external onlyOwner {
        pauseTimerStop = block.timestamp; 
        pauseTimerToExtend= pauseTimerStop - pauseTimerStart; 
        pauseStatus=false; 
    }
    function emergency() external onlyOwner nonReentrant {
        for (uint i = 0; i < funders.length; i++) {
        uint amountAvailableForUserInWL = addressTo_WL_UsdcFunded[funders[i]];
        uint amountAvailableForUser = addressToUsdcFunded[funders[i]];
        

        _USDC.transfer(funders[i], amountAvailableForUser);
        _USDC.transfer(funders[i], amountAvailableForUserInWL);
        }
        uint pappleAmount = _papple.balanceOf(address(this));
        
        burnPapple(pappleAmount);
    }
    
     function burnRemainingPapple() external onlyOwner nonReentrant preNotActive pubNotActive{
        uint remainingAmount = _papple.balanceOf(address(this) )- totalPappleSold;
        //_papple.approve(address(this),remainingAmount);
        burnPapple(remainingAmount);

    }
        function burnPapple(uint256 amount) private  {
        (bool success, ) = address(_papple).call(
            abi.encodeWithSignature("burn(uint256)", amount)
        );
        require(success, "Failed to burn Papple tokens");
    }


    function extendPreSale(uint _hours) external onlyOwner {
        require(pauseStatus == true, 'Contract needs to be paused');
         endPRE = endPRE + (_hours * 1 hours);
    }
    function extendPublicSale(uint _hours) external onlyOwner{
        require(pauseStatus == true, 'contract needs to be paused');
        endPUB = endPUB + (_hours * 1 hours);
    }
    function payoutProject() external onlyOwner preNotActive() pubNotActive() contractIsNotPaused(){
        uint256 tokenAmt = _USDC.balanceOf(address(this));
        require(tokenAmt > 0, "Token balance is 0");
        _USDC.transfer(_wallet, tokenAmt);
    }
}