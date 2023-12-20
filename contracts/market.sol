// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    address public owner;
    
    enum JobStatus { Open, InProgress, Completed, Disputed, Closed }

    struct Job {
        uint256 jobId;
        address client;
        address freelancer;
        string description;
        uint256 amount;
        JobStatus status;
    }

    mapping(uint256 => Job) public jobs;
    uint256 public jobCounter;

    event JobCreated(uint256 jobId, address indexed client, string description, uint256 amount);
    event JobAccepted(uint256 jobId, address indexed freelancer);
    event JobCompleted(uint256 jobId, address indexed freelancer);
    event JobDisputed(uint256 jobId);
    event JobClosed(uint256 jobId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyClient(uint256 _jobId) {
        require(msg.sender == jobs[_jobId].client, "Only the client can call this function");
        _;
    }

    modifier onlyFreelancer(uint256 _jobId) {
        require(msg.sender == jobs[_jobId].freelancer, "Only the freelancer can call this function");
        _;
    }

    modifier jobExists(uint256 _jobId) {
        require(_jobId <= jobCounter, "Job does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createJob(string memory _description, uint256 _amount) external {
        jobCounter++;
        jobs[jobCounter] = Job({
            jobId: jobCounter,
            client: msg.sender,
            freelancer: address(0),
            description: _description,
            amount: _amount,
            status: JobStatus.Open
        });

        emit JobCreated(jobCounter, msg.sender, _description, _amount);
    }

    function acceptJob(uint256 _jobId) external jobExists(_jobId) {
        Job storage job = jobs[_jobId];
        require(job.status == JobStatus.Open, "Job is not open for acceptance");
        job.freelancer = msg.sender;
        job.status = JobStatus.InProgress;

        emit JobAccepted(_jobId, msg.sender);
    }

    function completeJob(uint256 _jobId) external jobExists(_jobId) onlyFreelancer(_jobId) {
        Job storage job = jobs[_jobId];
        require(job.status == JobStatus.InProgress, "Job is not in progress");
        job.status = JobStatus.Completed;

        // Transfer funds to the freelancer
        payable(msg.sender).transfer(job.amount);

        emit JobCompleted(_jobId, msg.sender);
    }

    function disputeJob(uint256 _jobId) external jobExists(_jobId) onlyClient(_jobId) {
        Job storage job = jobs[_jobId];
        require(job.status == JobStatus.InProgress, "Job is not in progress");
        job.status = JobStatus.Disputed;

        emit JobDisputed(_jobId);
    }


    function closeJob(uint256 _jobId) external jobExists(_jobId) onlyOwner {
        Job storage job = jobs[_jobId];
        require(job.status == JobStatus.Completed || job.status == JobStatus.Disputed, "Job is not completed or disputed");
        job.status = JobStatus.Closed;

        emit JobClosed(_jobId);
    }
}
