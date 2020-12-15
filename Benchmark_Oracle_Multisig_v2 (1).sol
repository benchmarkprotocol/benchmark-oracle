pragma solidity ^0.5.17;

/******************************************/
/*       Benchmark starts here            */
/******************************************/

contract Benchmark
{
    function rebase(uint256 supplyDelta, bool increaseSupply) external returns (uint256);
}

/******************************************/
/*       multiSigOracle starts here       */
/******************************************/

contract MultiSigOracle {

    address owner1;
    address owner2;
    address owner3;
    address owner4;
    Benchmark bm;

    Transaction public pendingRebasement;
    uint internal lastRebasementTime;

    struct Transaction {
        address initiator;
        uint supplyDelta;
        bool increaseSupply;
        bool executed;
    }

    modifier isOwner() 
    {
        require (msg.sender == owner1 || msg.sender == owner2 || msg.sender == owner3 || msg.sender == owner4);
        _;
    }

    constructor(address _Benchmark) public
    {
        owner1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        owner2 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        owner3 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        owner4 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        bm = Benchmark(_Benchmark);
        
        pendingRebasement.executed = true;
    }

    /**
     * @dev Initiates a rebasement proposal that has to be confirmed by another owner of the contract to be executed. Can't be called while another proposal is pending.
     * @param _supplyDelta Change in totalSupply of the Benchmark token.
     * @param _increaseSupply Whether to increase or decrease the totalSupply of the Benchmark token.
     */
    function initiateRebasement(uint256 _supplyDelta, bool _increaseSupply) public isOwner
    {
        require (pendingRebasement.executed == true, "Pending rebasement.");
        require (lastRebasementTime < (now - 64800), "Rebasement has already occured within the past 18 hours.");

        Transaction storage txn = pendingRebasement; 
        txn.initiator = msg.sender;
        txn.supplyDelta = _supplyDelta;
        txn.increaseSupply = _increaseSupply;
        txn.executed = false;
    }

    /**
     * @dev Confirms and executes a pending rebasement proposal. Prohibits further proposals for 18 hours.
     */
    function confirmRebasement() public isOwner
    {
        require (pendingRebasement.initiator != msg.sender, "Initiator can't confirm rebasement.");
        require (pendingRebasement.executed == false, "Rebasement already executed.");
        
        pendingRebasement.executed = true;
        lastRebasementTime = now;

        bm.rebase(pendingRebasement.supplyDelta, pendingRebasement.increaseSupply);
    }

    /**
     * @dev Denies a pending rebasement proposal and allows the creation of a new proposal.
     */
    function denyRebasement() public isOwner
    {
        require (pendingRebasement.executed == false, "Rebasement already executed.");
        
        pendingRebasement.executed = true;
    }

}
    