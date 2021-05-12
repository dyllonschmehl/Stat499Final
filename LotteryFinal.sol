pragma solidity ^0.4.26;

contract Lottery{
    mapping(address => bool) public managers;
    mapping(address => playerEntry) public players;
    address[] private playerList;
    address public lastWinner;
    struct playerEntry {
        uint index;
        uint amount;
    }
   
    
    modifier onlyManagers() {
        // Ensure the participant awarding the ether is the manager
        require(managers[msg.sender]);
        _;
    }
    
    modifier notEntered() {
        // only allow players to enter once
        require(players[msg.sender].index == 0);
        require(players[msg.sender].amount == 0);
        _;
    }
    
    modifier hasEntered() {
        // only allow players to enter once
        require(players[msg.sender].amount != 0);
        _;
    }

    constructor() public{
        managers[msg.sender] = true;
    }
    
    function addManager(address newManager) public onlyManagers {
        // add a new manager
        managers[newManager] = true;
    }
    
    function removeManager(address manager) public onlyManagers {
        // remove a manager
        managers[manager] = false; 
    }
    
    function enter() public notEntered payable{
        // enforce a minimum bet
        require(msg.value > 0.001 ether);
        
        // add sender address to the list
        uint newIdx = playerList.length;
        playerList.push(msg.sender);
        
        // create new playerEntry
        players[msg.sender] = playerEntry(newIdx , msg.value);
    }
    
    function withdraw() public hasEntered {
        // save amount to withdraw into a variable
        uint withdrawAmt = players[msg.sender].amount;
        
        // first remove from the array
        removeFromLottery(players[msg.sender].index);
        
        // remove from mapping
        delete players[msg.sender];
        
        // finally, send withdrawn funds to account (good practice to do last)
        msg.sender.transfer(withdrawAmt); // <- how to send funds to the msg sender?
    }

    function pickWinner() public onlyManagers {
        // specify the winner
        lastWinner = playerList[ random() % playerList.length ];

        // setup for another lottery
        resetLottery();

        // transfer all money from lottery contract to the player
        uint contractAmnt = address(this).balance;
        players[lastWinner].amount = contractAmnt;
    }

    function getPlayers() public view returns (address[]) {
        // Return list of players
        return playerList;
    }
    
    function resetLottery() private {
        // clear player mapping
        for (uint i = 0; i < playerList.length; i++) {
            delete players[playerList[i]];
        }
        
        // reinitialize the playerList
        playerList = new address[](0);
    }
    
    // iterate through the playerList and remove the withdrawn player
    function removeFromLottery(uint remIdx) private {
        // check that index is not too big
        if (remIdx >= playerList.length) return;

        // move entries above index down by one
        for (uint i = remIdx; i < playerList.length - 1; i++){
            playerList[i] = playerList[i+1];
            players[playerList[i+1]].index = i;
        }
        
        // actually remove the entry
        delete playerList[playerList.length-1];
        playerList.length--;
    }
    
    // helper function to find the winner
    function random() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, now, playerList)));
    }
}