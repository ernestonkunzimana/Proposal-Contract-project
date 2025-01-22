// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProposalContract {
    address public owner;
    uint public proposalCount;
    uint256 private counter; // This line is added

    struct Proposal {
        string title; // Title of the proposal
        string description; // Description of the proposal
        uint approve; // Number of approve votes
        uint reject; // Number of reject votes
        uint pass; // Number of pass votes
        uint total_vote_to_end; // When the total votes in the proposal reaches this limit, proposal ends
        bool current_state; // This shows the current state of the proposal, meaning whether it passes or fails
        bool is_active; // This shows if others can vote to our contract
        mapping(address => bool) voters; // Tracks who has voted
    }

    mapping(uint256 => Proposal) proposal_history; // Recordings of previous proposals
    mapping(uint => Proposal) public proposals;

    event ProposalCreated(uint256 proposalId, string title, string description, uint total_vote_to_end); // Event for proposal creation

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
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

        emit ProposalCreated(counter, _title, _description, _total_vote_to_end);
    }

    function vote(uint _proposalId, uint _voteType) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.is_active, "Proposal is not active");
        require(!proposal.voters[msg.sender], "You have already voted");

        if (_voteType == 1) {
            proposal.approve++;
        } else if (_voteType == 2) {
            proposal.reject++;
        } else if (_voteType == 3) {
            proposal.pass++;
        }

        proposal.voters[msg.sender] = true;

        if (proposal.approve + proposal.reject + proposal.pass >= proposal.total_vote_to_end) {
            proposal.is_active = false;
            proposal.current_state = (proposal.approve > proposal.reject);
        }
    }

    function getProposal(uint _proposalId) public view returns (string memory, string memory, uint, uint, uint, uint, bool, bool) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.title, proposal.description, proposal.approve, proposal.reject, proposal.pass, proposal.total_vote_to_end, proposal.current_state, proposal.is_active);
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
}
