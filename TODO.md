

Game mechanics
===

* Detect move repetition to signal draws.
* Let the game board contain the state of the rookings, and movements of the king/rooks.
* Implement en-passant


Strategy development
==

* Minimax player.
* Minimax player with alpha-beta pruing.
* Deep neural network, reinforcement learning player based on Flux.jl
   - Map game-states into neural network representations
   - Design a network architecture to either find next move or evaluate positions.
   - Design a "goodness" criterion for strategies.
   - Find a way to make this architecture learn by playing against itself.
   - => Alpha zero light
