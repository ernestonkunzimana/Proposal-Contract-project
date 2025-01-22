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
        uint createdAt; // Timestamp when the proposal was created
        mapping(address => uint) voters; // Tracks who has voted and their vote type
    }

    mapping(uint256 => Proposal) proposal_history; // Recordings of previous proposals
    mapping(uint => Proposal) public proposals;
    mapping(address => bool) public admins; // Tracks admin addresses

    event ProposalCreated(uint256 proposalId, string title, string description, uint total_vote_to_end); // Event for proposal creation
    event VoteChanged(uint256 proposalId, address voter, uint oldVoteType, uint newVoteType); // Event for changing votes

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not an admin");
        _;
    }

    modifier validVoteType(uint _voteType) {
        require(_voteType == 1 || _voteType == 2 || _voteType == 3, "Invalid vote type");
        _;
    }

    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    function addAdmin(address _admin) public onlyOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) public onlyOwner {
        admins[_admin] = false;
    }

    function create(string calldata _title, string calldata _description, uint256 _total_vote_to_end) external onlyAdmin {
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

    function vote(uint _proposalId, uint _voteType) public validVoteType(_voteType) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.is_active, "Proposal is not active");
        require(proposal.voters[msg.sender] == 0, "You have already voted");

        if (_voteType == 1) {
            proposal.approve++;
        } else if (_voteType == 2) {
            proposal.reject++;
        } else if (_voteType == 3) {
            proposal.pass++;
        }

        proposal.voters[msg.sender] = _voteType;

        if (proposal.approve + proposal.reject + proposal.pass >= proposal.total_vote_to_end) {
            proposal.is_active = false;
            proposal.current_state = (proposal.approve > proposal.reject);
        }
    }

    function changeVote(uint _proposalId, uint _newVoteType) public validVoteType(_newVoteType) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.is_active, "Proposal is not active");
        require(proposal.voters[msg.sender] != 0, "You have not voted yet");

        uint oldVoteType = proposal.voters[msg.sender];

        if (oldVoteType == 1) {
            proposal.approve--;
        } else if (oldVoteType == 2) {
            proposal.reject--;
        } else if (oldVoteType == 3) {
            proposal.pass--;
        }

        if (_newVoteType == 1) {
            proposal.approve++;
        } else if (_newVoteType == 2) {
            proposal.reject++;
        } else if (_newVoteType == 3) {
            proposal.pass++;
        }

        proposal.voters[msg.sender] = _newVoteType;

        emit VoteChanged(_proposalId, msg.sender, oldVoteType, _newVoteType);

        if (proposal.approve + proposal.reject + proposal.pass >= proposal.total_vote_to_end) {
            proposal.is_active = false;
            proposal.current_state = (proposal.approve > proposal.reject);
        }
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
