// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/******************************************/
/*       DEX starts here            */
/******************************************/

abstract contract DEX 

{
    function sync() external virtual;
}

/******************************************/
/*       Benchmark starts here            */
/******************************************/

abstract contract Benchmark 

{
    function rebase(uint256 supplyDelta, bool increaseSupply) external virtual returns (uint256);
}

/******************************************/
/*       multiSigOracle starts here       */
/******************************************/

contract MultiSigOracle {

    address owner1;
    address owner2;
    address owner3;
    address owner4;
    address owner5;
    
    Benchmark public bm;
    DEX[] public Pools;

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
        require (msg.sender == owner1 || msg.sender == owner2 || msg.sender == owner3 || msg.sender == owner4 || msg.sender == owner5);
        _;
    }

    constructor(address _Benchmark)
    {
        owner1 = 0xbdE1ADC18a02c3d0D9C2701968AA6f08d828Da1a;
        owner2 = 0x0AA11910e697F9AAB3f593babd26fa9C4BDecb9E;
        owner3 = 0x2c155e07a1Ee62f229c9968B7A903dC69436e3Ec;
        owner4 = 0x89c3bD19aFA54bC933528D90b027d1dD103e24a8;
        owner5 = 0x89c3bD19aFA54bC933528D90b027d1dD103e24a8;
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
        require (lastRebasementTime < (block.timestamp - 64800), "Rebasement has already occured within the past 18 hours.");

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
        lastRebasementTime = block.timestamp;

        bm.rebase(pendingRebasement.supplyDelta, pendingRebasement.increaseSupply);

        uint arrayLength = Pools.length;
        for (uint256 i = 0; i < arrayLength; i++) 
        {
            Pools[i].sync();
        }
    }

    /**
     * @dev Denies a pending rebasement proposal and allows the creation of a new proposal.
     */
    function denyRebasement() public isOwner
    {
        require (pendingRebasement.executed == false, "Rebasement already executed.");
        
        pendingRebasement.executed = true;
    }

    /**
     * @dev Add a new Liquidity Pool. 
     * @param _lpPool Address of Liquidity Pool.
     */
    function addPool (address _lpPool) public isOwner {
        Pools.push(DEX(_lpPool));
    }
}
    