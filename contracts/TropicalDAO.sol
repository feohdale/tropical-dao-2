// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./TropicalShares.sol";

contract TropicalDAO is OwnableUpgradeable {
    TropicalShares public token;
    uint nextProposalId;
    uint256 public quorumPercentage;
    address tropicalVaultAddress;
    address pappleToken;
    address usdcToken;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    enum ProposalStatus {
        Pending,
        Active,
        Defeated,
        Succeeded,
        Executed
    }

    struct Proposal {
        uint256 id;
        string description;
        address targetContract;
        bytes callData;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        ProposalStatus status;
    }

    Proposal[] public proposals;

    event VoteCasted(
        address indexed voter,
        uint256 indexed proposalId,
        bool voteFor,
        uint256 voteWeight
    );
    event ProposalExecuted(uint256 indexed proposalId);

    /*constructor(
        TropicalShares _token,
        address _pappleToken,
        address _usdcToken
    ) {
        token = _token;
        pappleToken = _pappleToken;
        usdcToken = _usdcToken;
    }*/
    function initialize(
        TropicalShares _token,
        address _pappleToken,
        address _usdcToken
    ) public initializer {
        __Ownable_init();
        token = _token;
        pappleToken = _pappleToken;
        usdcToken = _usdcToken;
        quorumPercentage = 51; //
        // Autres initialisations si nécessaire
    }
    


   

    function createProposal(
        address targetContract,
        bytes memory callData,
        string memory description,
        uint256 EndTimeStamp
    ) public returns (uint256 proposalId) {
        uint256 voterBalance = token.balanceOf(msg.sender);
        require(voterBalance > 0, "No voting rights");
        proposalId = nextProposalId++;
        uint256 startTime = block.timestamp;
        uint256 endTime = EndTimeStamp;

        proposals.push(
            Proposal({
                id: proposalId,
                description: description,
                targetContract: targetContract,
                callData: callData,
                startTime: startTime,
                endTime: endTime,
                votesFor: 0,
                votesAgainst: 0,
                executed: false,
                status: ProposalStatus.Pending
            })
        );

       
    }

    

    function voteOnProposal(uint256 proposalId, bool voteFor) public {
        require(proposalId < nextProposalId, "Proposal does not exist");
        require(!hasVoted[proposalId][msg.sender], "Voter has already voted");

        Proposal storage proposal = proposals[proposalId];
        require(
            block.timestamp >= proposal.startTime &&
                block.timestamp <= proposal.endTime,
            "Voting period is not active"
        );

        uint256 voterBalance = token.balanceOf(msg.sender);
        require(voterBalance > 0, "No voting rights");

        if (voteFor) {
            proposal.votesFor += voterBalance;
        } else {
            proposal.votesAgainst += voterBalance;
        }

        hasVoted[proposalId][msg.sender] = true;
        emit VoteCasted(msg.sender, proposalId, voteFor, voterBalance);
    }

    function executeProposal(uint256 proposalId) public {
        uint256 voterBalance = token.balanceOf(msg.sender);
        require(voterBalance > 0, "No voting rights");
        require(proposalId < nextProposalId, "Proposal does not exist");
        Proposal storage proposal = proposals[proposalId];

        require(
            block.timestamp > proposal.endTime,
            "Voting period not yet ended"
        );
        require(!proposal.executed, "Proposal already executed");

        // Check if proposal approved 
        // check if quorum goal is ok
        require(
            proposal.votesFor > proposal.votesAgainst,
            "Proposal not approved"
        );
        require(
            proposal.votesFor + proposal.votesAgainst >= calculateQuorum(),
            "Quorum not reached"
        );

        // execute proposal
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    function calculateQuorum() internal view returns (uint256) {
        uint256 totalSupply = token.totalSupply();
        return (totalSupply * quorumPercentage) / 100;
    }

    function createBurnPappleProposal(
        address contractAddress, // where to execute proposal
        uint256 amountToBurn,
        string memory description,
        uint256 endTimeStamp
    ) public {
        // check if contract address is not 0
        require(contractAddress != address(0), "Invalid contract address");

        // Encode function burnPapple 
        bytes memory callData = abi.encodeWithSignature(
            "burnPapple(uint256)",
            amountToBurn
        );

        // create new proposal to the dao
        createProposal(contractAddress, callData, description, endTimeStamp);
    }

    function createChangeOwnerProposal(
        address contractAddress,
        address newOwner,
        string memory description,
        uint endTimeStamp
    ) public {
       
        bytes memory callData = abi.encodeWithSignature(
            "transferOwnership(address)",
            newOwner
        );

        
        createProposal(contractAddress, callData, description, endTimeStamp);
    }

    function createVaultTransferERC20Proposal(
        address vaultAddress,
        address erc20Token,
        address to,
        uint256 amount,
        string memory description,
        uint256 endTimeStamp
    ) public {
        bytes memory callData = abi.encodeWithSignature(
            "withdrawERC20(address,address,uint256)",
            to,
            erc20Token,
            amount
        );
        createProposal(vaultAddress, callData, description, endTimeStamp);
    }

    function createVaultTransferERC721Proposal(
        address vaultAddress,
        address to,
        address erc721Token,
        uint256 tokenId,
        string memory description,
        uint256 endTimeStamp
    ) public {
        bytes memory callData = abi.encodeWithSignature(
            "withdrawERC721(address,address,uint256)",
            erc721Token,
            to,
            tokenId
        );
        createProposal(vaultAddress, callData, description, endTimeStamp);
    }

    function createVaultTransferEtherProposal(
        address vaultAddress,
        address payable to,
        uint256 amount,
        string memory description,
        uint256 endTimeStamp
    ) public {
        bytes memory callData = abi.encodeWithSignature(
            "withdrawEther(address,uint256)",
            to,
            amount
        );
        createProposal(vaultAddress, callData, description, endTimeStamp);
    }

    function createVaultTransferPappleProposal(
        address vaultAddress,
        address to,
        uint256 amount,
        string memory description,
        uint256 endTimeStamp
    ) public {
        bytes memory callData = abi.encodeWithSignature(
            "withdrawPapple(address,uint256)",
            to,
            amount
        );
        createProposal(vaultAddress, callData, description, endTimeStamp);
    }

    function createMintTokenProposal(
        address tokenContract,
        address to,
        uint256 amount,
        string memory description,
        uint256 endTimeStamp
    ) public {
        
        bytes memory callData = abi.encodeWithSignature(
            "mint(address,uint256)",
            to,
            amount
        );

        
        createProposal(tokenContract, callData, description, endTimeStamp);
    }

    function listProposals() public view returns (Proposal[] memory) {
        Proposal[] memory proposalsList = new Proposal[](proposals.length);
        for (uint i = 0; i < proposals.length; i++) {
            Proposal storage storedProposal = proposals[i];
            ProposalStatus currentStatus = getProposalStatus(storedProposal);

            
            Proposal memory tempProposal = Proposal({
                id: storedProposal.id,
                description: storedProposal.description,
                targetContract: storedProposal.targetContract,
                callData: storedProposal.callData,
                startTime: storedProposal.startTime,
                endTime: storedProposal.endTime,
                votesFor: storedProposal.votesFor,
                votesAgainst: storedProposal.votesAgainst,
                executed: storedProposal.executed,
                status: currentStatus // Utilisez le statut actuel
            });

            proposalsList[i] = tempProposal;
        }
        return proposalsList;
    }

    function getProposalStatus(
        Proposal storage proposal
    ) internal view returns (ProposalStatus) {
        if (!proposal.executed) {
            if (block.timestamp < proposal.startTime) {
                return ProposalStatus.Pending;
            } else if (block.timestamp <= proposal.endTime) {
                return ProposalStatus.Active;
            } else if (proposal.votesFor <= proposal.votesAgainst) {
                return ProposalStatus.Defeated;
            } else {
                return ProposalStatus.Succeeded;
            }
        }
        return ProposalStatus.Executed;
    }


    function currentProposal() public view  returns(uint){
        return nextProposalId-1;
    }

    function viewActiveProposals() public view returns (Proposal[] memory) {
        uint activeCount = 0;

        
        for (uint i = 0; i < proposals.length; i++) {
            if (getProposalStatus(proposals[i]) == ProposalStatus.Active) {
                activeCount++;
            }
        }

        
        Proposal[] memory activeProposals = new Proposal[](activeCount);
        uint currentIndex = 0;

        
        for (uint i = 0; i < proposals.length; i++) {
            if (getProposalStatus(proposals[i]) == ProposalStatus.Active) {
                activeProposals[currentIndex] = proposals[i];
                currentIndex++;
            }
        }

        return activeProposals;
    }
     function viewLastRejectedProposals(uint maxProposals) public view returns (Proposal[] memory) {
        uint rejectedCount = 0;
        uint proposalsLength = proposals.length;
        maxProposals = maxProposals > 10 ? 10 : maxProposals; // Limiter à 10 propositions

        
        for (uint i = proposalsLength; i > 0 && rejectedCount < maxProposals; i--) {
            if (getProposalStatus(proposals[i - 1]) == ProposalStatus.Defeated) {
                rejectedCount++;
            }
        }

        Proposal[] memory rejectedProposals = new Proposal[](rejectedCount);
        uint currentIndex = 0;

        
        for (uint i = proposalsLength; i > 0 && currentIndex < rejectedCount; i--) {
            if (getProposalStatus(proposals[i - 1]) == ProposalStatus.Defeated) {
                rejectedProposals[currentIndex] = proposals[i - 1];
                currentIndex++;
            }
        }

        return rejectedProposals;
    }

    function viewLastApprovedUnexecutedProposals(uint maxProposals) public view returns (Proposal[] memory) {
        uint count = 0;
        uint proposalsLength = proposals.length;
        maxProposals = maxProposals > 10 ? 10 : maxProposals; // Limiter à 10 propositions

        
        for (uint i = proposalsLength; i > 0 && count < maxProposals; i--) {
            Proposal storage proposal = proposals[i - 1];
            if (proposal.status == ProposalStatus.Succeeded && !proposal.executed) {
                count++;
            }
        }

        
        Proposal[] memory approvedUnexecutedProposals = new Proposal[](count);
        count = 0;

        
        for (uint i = proposalsLength; i > 0 && count < maxProposals; i--) {
            Proposal storage proposal = proposals[i - 1];
            if (proposal.status == ProposalStatus.Succeeded && !proposal.executed) {
                approvedUnexecutedProposals[count] = proposal;
                count++;
            }
        }

        return approvedUnexecutedProposals;
    }
}
