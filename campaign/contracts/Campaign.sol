pragma solidity ^0.4.24;

contract CampignFactory {
    address[] public deployedCampaigns;
    
    constructor (uint minimum) public {
        address newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }
    
    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }
    
    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;

    modifier restricted() {
        require(msg.sender == manager, "Sender is not manager");
        _;
    }

    constructor (uint minimum, address creator) public {
        manager = creator;
        minimumContribution == minimum;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution, "Requires minimum contribution");
        
        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(string description, uint value, address recipient) public restricted {
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            approvalCount: 0
        });

        requests.push(newRequest);
    }
    
    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender], "Sender is not approved");
        require(!request.approvals[msg.sender], "Sender is not allowed to approve the request");
        
        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }
    
    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];

        require(!request.complete, "Request is already finalized");
        require(request.approvalCount > (approversCount / 2), "Not enough votes");
        
        request.recipient.transfer(request.value);
        request.complete = true;
    }
}