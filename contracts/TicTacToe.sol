// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract TicTacToe {

    /*
     TicTacToe Board with playing positions
    	     |     |
    	  0  |  1  |  2
    	_____|_____|_____
    	     |     |
    	  3  |  4  |  5
    	_____|_____|_____
    	     |     |
    	  6  |  7  |  8
    	     |     |
    	     
    Winning combinations: 
            [0, 1, 2], [3, 4, 5], [6, 7, 8],  // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8],  // Cols
            [0, 4, 8], [6, 4, 2]              // Diags
    	     
    To create a game, the player need to send 1 ether and selct a mark (X or O)
        Each game will be identified by the creators address (mapping)
        Game creator joins the game as the first player automatically
    
    For a second player to join an existing game, need to send 1 ether.
        Can't join a non-existing game.
        Can't join a game that has already been started or been over
        Second player will be automatically assigned to X if player 1 selcts O and vice versa.
        
    Once the second player joins, the game starts
        First player plays first
        
    The game is over when a winner can be found, or the game draws
        If there is a winner, transfer 1.8 ether to winner's address
        If the game ended in draw, return 0.9 for each players
        Contract owner keeps 0.1 ether from each player
    
    */
    
    // MAX_POSITIONS is the board array size
    // also the maximum number of moves any two players can make in a single Game
    uint constant MAX_POSITIONS = 9;
    uint256 constant PLAY_TIMEOUT = 2 * 60;

    // possible game states
    enum States { NOT_STARTED, PLAYING, WINNER, DRAW }

    struct Game {
        address payable player1Addr;
        address payable player2Addr;
    	address payable winnerAddr;
    	address playerTurn;
    	
     	string[MAX_POSITIONS] positions; 
        string player1Mark;
        string player2Mark;
           
        uint256 lastMove;
    	uint8 elapsedTurns;   
    	bool gameOver;
        States state;
    }
    
    event CustomFailure(string customFailure);

    mapping(address => Game) public games;
    address payable internal owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier notOwner() {
        require(msg.sender != owner, "owner cannot play");
        _;
    }
    
    function createGame(string memory _player1Mark) external notOwner payable {
        
        // creator has to select X or O mark to create a game
        // creator has to pay 1 ether to contract
        require(compareStrings(_player1Mark, "X") || compareStrings (_player1Mark, "O"), "Select X or O");
        require(msg.value == 1 ether, "You have to pay 1 ether to create a game!");
        
        Game memory newGame;
        newGame.state = States.NOT_STARTED;
        newGame.player1Addr = msg.sender;
        newGame.playerTurn = msg.sender; // player 1 plays first
        newGame.gameOver = false;        
        newGame.player1Mark = _player1Mark;
        newGame.player2Mark = string(compareStrings(_player1Mark, "X") ? "O" : "X");
        
        for(uint i = 0; i < MAX_POSITIONS; i++)
            newGame.positions[i] = "-";
            
        games[msg.sender] = newGame;
    }
    
    function joinGame(address creatorAddr) public payable
    {
        Game storage _game = games[creatorAddr];

        // check if the game exist in mapping
        // creator cannot join, automatically joined by creating the Game
        // 1 ether is required to join the Game
        // cannot join a game that been started already
        require(_game != address(0), "Game doesn't exist!");
        require(creatorAddr != msg.sender, "You are the creator of the game, automatically joind!");
        require(msg.value == 1 ether, "You have to pay 1 ether to play!");
        require(_game.state == States.NOT_STARTED, "Game already started or its over!");
        
        _game.player2Addr = msg.sender;
        _game.state = States.PLAYING;
        _game.lastMove = block.timestamp;
    }
    
    function play(address creatorAddr, uint8 pos) public
    {
        Game storage _game = games[creatorAddr];

        // check if the game exist in mapping
        // cannot play in a game that is over or not started playerTurn
        // check players turns
        // check for valid position
        require(_game.player1Addr != address(0), "Game doesn't exist!");
        require(_game.state == States.PLAYING, "Game is not playing");
        require(_game.playerTurn == msg.sender, "Its not your turn");
        require(pos >= 0 && pos < MAX_POSITIONS && compareStrings(_game.positions[pos], '-'), "Not a valid move!");
        
        // if the player waits more than two minutes end game giving the other player a win
        if((block.timestamp - _game.lastMove) > PLAY_TIMEOUT) {
            _game.gameOver = true;
            _game.state = States.WINNER;
            _game.winnerAddr = _game.player1Addr == msg.sender ? _game.player2Addr : _game.player1Addr;
            _game.winnerAddr.transfer(1.8 ether);
            return;
        }

        // mark the position and change turns
        _game.positions[pos] = (msg.sender == _game.player1Addr) ? _game.player1Mark : _game.player2Mark;
        _game.playerTurn = (msg.sender == _game.player1Addr) ? _game.player2Addr : _game.player1Addr;
        _game.elapsedTurns++;
        
        if (checkForWinner(creatorAddr)) { // winner case
            _game.state = States.WINNER;
            _game.winnerAddr = msg.sender;
            _game.winnerAddr.transfer(1.8 ether);
            _game.gameOver = true;
        } 
        else if (_game.elapsedTurns >= MAX_POSITIONS) { // draw case
            _game.gameOver = true;
            _game.state = States.DRAW;
            _game.player1Addr.transfer(0.9 ether);
            _game.player2Addr.transfer(0.9 ether);
        }
    }
    
    function checkForWinner(address creatorAddr) internal view returns(bool){
        Game memory _game = games[creatorAddr];

        uint8[3][8] memory winningCombinations = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8],  // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8],  // Cols
            [0, 4, 8], [6, 4, 2]              // Diags
        ];
        
        
        // loop through possible wiining combinations  
        for (uint8 i = 0; i < winningCombinations.length; i++) {
            uint8[3] memory filter = winningCombinations[i];
            
            if (compareStrings(_game.positions[filter[0]], _game.positions[filter[1]]) && 
                compareStrings(_game.positions[filter[1]], _game.positions[filter[2]]) && 
                !compareStrings(_game.positions[filter[2]], "-")) {
                return true;
            }
        }
        
        return false;
    } 

    function getCurrentGrid(address creatorAddr) public view returns(string memory)
    {
        Game memory _game = games[creatorAddr];
        
        // return a comman delimited string of current positions
    	string memory grid_map = '';
    	for (uint8 i = 0; i < _game.positions.length; i++) {
    	    if (i == 0) {
    	    	grid_map = _game.positions[i];
    	    } else {
    	    	grid_map = string(abi.encodePacked(grid_map, ',', _game.positions[i]));
    	    }
    	}
    	grid_map = string(abi.encodePacked(grid_map, ','));
    	
    	return grid_map;
    }
    
    function balanceOfContract() public view returns(uint)
    {
        return address(this).balance;
    }
    
    
    function getWinner(address creatorAddr) public view returns(string memory)
    {
        Game memory _game = games[creatorAddr];
        require(_game.gameOver, "Game is not Over");
        
        if (_game.player1Addr == _game.winnerAddr) return "Player 1";
        else if (_game.player2Addr == _game.winnerAddr) return "Player 2";
        
        return "Draw";
    }
    
    function getStatus(address creatorAddr) public view returns(string memory)
    {
        Game memory _game = games[creatorAddr];

        if (_game.state == States.NOT_STARTED) return "NOT STARTED";
        else if (_game.state == States.PLAYING) return "PLAYING";
        else if (_game.state == States.WINNER) return "WINNER";

        return "Draw";
    }
    
    /*
    * private function to compare strings; as strings are not really a primitive type in Solidity.
    */
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
