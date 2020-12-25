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
/*       TestSync starts here            */
/******************************************/


contract testSync {

    DEX[] public Pools;

    /**
     * @dev Add a new Liquidity Pool. 
     * @param _lpPool Address of Liquidity Pool.
     */
    function addPool (address _lpPool) public /** onlyOwner */ {
        Pools.push(DEX(_lpPool));
    }

    /**
     * @dev Call the sync() function on all added Liquidity Pools. 
     */
    function syncPools() public {
        
        uint arrayLength = Pools.length;

        for (uint256 i = 0; i < arrayLength; i++) 
        {
            Pools[i].sync();
        }
    }

}