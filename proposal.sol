// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProposalContract {
    address public owner;
    uint public proposalCount;
    uint256 private counter;

    address[] private voted_addresses;

    struct Proposal {
        string title; // Title of the proposal
        string description; // Description of the proposal
        uint approve; // Number of approve votes
        uint reject; // Number of reject votes
        uint pass; // Number of pass votes
        uint total_vote_to_end; // When the total votes in the proposal reaches this limit, proposal ends
        bool current_state; // This shows the current state of the proposal, meaning whether it passes or fails
        bool is_active; // This shows if others can vote to our contract
        uint createdAt; // Timestamp when the proposal was created
        mapping(address => uint) voters; // Tracks who has voted and their vote type
    }

    mapping(uint256 => Proposal) proposal_history; // Recordings of previous proposals
    mapping(uint => Proposal) public proposals;

    event ProposalCreated(uint256 proposalId, string title, string description, uint total_vote_to_end); // Event for proposal creation
    event VoteChanged(uint256 proposalId, address voter, uint oldVoteType, uint newVoteType); // Event for changing votes
    event OwnerSet(address indexed oldOwner, address indexed newOwner); // Event for setting a new owner

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier active(uint proposalId) {
        require(proposal_history[proposalId].is_active == true, "The proposal is not active");
        _;
    }

    modifier notVoted(uint proposalId) {
        require(proposal_history[proposalId].voters[msg.sender] == 0, "You have already voted");
        _;
    }

    constructor() {
        owner = msg.sender;
        voted_addresses.push(msg.sender);
    }

    function setOwner(address new_owner) external onlyOwner {
        require(new_owner != address(0), "Invalid address");
        emit OwnerSet(owner, new_owner);
        owner = new_owner;
    }

    function create(string calldata _title, string calldata _description, uint256 _total_vote_to_end) external onlyOwner {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");

        counter += 1;
        Proposal storage newProposal = proposal_history[counter];
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.total_vote_to_end = _total_vote_to_end;
        newProposal.is_active = true;
        newProposal.current_state = false;
        newProposal.createdAt = block.timestamp;

        emit ProposalCreated(counter, _title, _description, _total_vote_to_end);
    }

    function vote(uint proposalId, uint8 choice) external active(proposalId) notVoted(proposalId) {
        Proposal storage proposal = proposal_history[proposalId];
        uint256 total_vote = proposal.approve + proposal.reject + proposal.pass;

        // Validate the choice
        require(choice == 0 || choice == 1 || choice == 2, "Invalid vote choice");

        // Apply the vote
        if (choice == 1) {
            proposal.approve += 1;
        } else if (choice == 2) {
            proposal.reject += 1;
        } else if (choice == 0) {
            proposal.pass += 1;
        }

        proposal.voters[msg.sender] = choice;
        voted_addresses.push(msg.sender);

        // Update the current state
        proposal.current_state = calculateCurrentState(proposalId);

        // Check if the proposal should be closed
        if (total_vote + 1 >= proposal.total_vote_to_end) {
            proposal.is_active = false;
        }
    }

    function calculateCurrentState(uint proposalId) internal view returns (bool) {
        Proposal storage proposal = proposal_history[proposalId];
        return proposal.approve > proposal.reject;
    }

    function getProposal(uint _proposalId) public view returns (string memory, string memory, uint, uint, uint, uint, bool, bool, uint) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.title, proposal.description, proposal.approve, proposal.reject, proposal.pass, proposal.total_vote_to_end, proposal.current_state, proposal.is_active, proposal.createdAt);
    }

    function getProposalHistory() public view returns (uint[] memory _ids) {
        uint256 count;
        for (uint i = 1; i <= proposalCount; i++) {
            Proposal storage prop = proposals[i];
            if (prop.is_active) {
                _ids[count++] = i;
            }
        }
        return (_ids);
    }

    function checkProposalExpiry(uint _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.createdAt + 30 days, "Proposal has not expired yet");

        proposal.is_active = false;
    }
}
