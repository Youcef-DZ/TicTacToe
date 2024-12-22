**Tic Tac Toe**

### Tic-tac-toe Definition

> Tic-tac-toe is a simple game in which two players take turns to write Os or Xs in a set of nine squares. The first player to complete a row of three Os or three Xs is the winner. [Oxford Dictionary](https://www.oxfordlearnersdictionaries.com/us/definition/english/tic-tac-toe?q=tic+tac+toe)

TicTacToe Board with playing positions:

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

### Requirments

* To create a game, the player need to send 1 ether and selct a mark (X or O)
  * Each game will be identified by the creators address (mapping)
  * Game creator joins the game as the first player automatically

* For a second player to join an existing game, need to send 1 ether.
  * Can't join a non-existing game.
  * Can't join a game that has already been started or been over
  * Second player will be automatically assigned to X if player 1 selcts O and vice versa.

* Once the second player joins, the game starts
  * First player plays first

* The game is over when a winner can be found, or the game draws
  * If there is a winner, transfer 1.8 ether to winner's address
  * If the game ended in draw, return 0.9 for each players
  * Contract owner keeps 0.1 ether from each player.

### Installations

* Same tools the course has been using in previous homeworks.
  * Ubuntu OS v18.04
  * Download installations.sh from HW 1
  * Install Anaconda
  * create anaconda block environment
    * `conda activate block_env`
  * Run the dowloaded scripts
    * `bash installations.sh block_env`
  * Lunch juypter notebook
    * `jupyter lab`

### Usage

* A contract owner can create a contract by invocing the constructor `contract_interface.constructor()`
* Any player can create a game in the contract by calling `createGame` function and paying 1 ether. Player's address will be used as `gameID`.
* Any other player can join the game by passing `gameID` to `joinGame` function and paying 1 ether.
* Players take turn in invoking `play` function with gameID and desired position to play.
* The game is over when a player gets matching winning combinations or the game ends draw.
"# TicTacToe" 
