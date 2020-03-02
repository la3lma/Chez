

Game mechanics
===

* Detect move repetition to signal draws.
* Let the game board contain the state of the rookings, and movements of the king/rooks.
* Implement en-passant


Reflection on the current state
==

I do have a halfway decent implementation of the game mechanics of
chess. It doesn't have rookings, en passant or draw by repetition
implemented, but that can be added by spending time, and it will not
change any external interfaces.  I'm not giving that much priority
now.  Efficiency can obviously be improved, but I'm also not giving
that any priority now.

What I don't have at all is a functioning reinforcement learning
setup, so I need to work on that.  Chess is a complicated game with
high move fan-out that takes some time to play so it may be worth it
to experiment with the reinforcement learning strategies on a simpler
game, but to make sure that the chess game can be plugged in an run on
it at any time (keep that as an unit test)

There are a few chess-specific pieces of code in the reinforecement
learning thing, and weeding those out will in themselves be useful.

Now, using a simpler game, like "four in a row" will also make it
possible to learn from other people's work (see some references
below).  That will obviously be useful too.

One change that will need to be implemented very soon, and could be
done using the existing chess machinery as a mock for future games, is
to set up tournaments with players.  The players will have state
represented as a set of neural networks, and a few identifying bits.
Alphago apparently trains itself (find reference) by starting with two
identical models, then playing a mutating version of itself against a
static version.  When the mutating version has a 55% win rate over the
static version, the mutating version is cloned and becomes its own
static version, and the cycle repeats. Something like that.

The actual Q-learning, SARSA, position/move evaluation whatever
algorithms that are plugged in, with whatever generic heuristics
can be added, needs to be _crystal_clear_.   The current
implementation of "q-learning" (which has already mutated)
is quickly getting messy.  That cannot be permitted to happen.
The core algorithm must be crystal clear for the reader, and the
rest of the supporting software must enable this clarity.

Finally, but not least importantly: I need to add instrumentation to
track progress.  It is nice to get little printouts as we move along,
but it is also important to log performance over time in an orderly
consistent manner, and to be able to plot evolution of performance
over time.   Some ideas are:

 * Use sqlite or the julia-native database thing to log values.
 * Read the Q-learning papers (and other) and shamelessly copy
   their metrics and graphs.  Reproduce them.
 * Use these metrics to track progress of the learning algorithms
   over time, across classes of games, and instances of games.
 * Don't be cute, use denormalized tables, one per metric,


Finally.  It's getting lonely.  I need to find some forum to discuss
this stuff in.  I need someone to play ball with, bounce ideas off,
get feedback, also rubber duck.


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

Tactical (development, software engineering) improvements
==

* Stop using untyped touples holding game/tournament results. Use structs with
  named types and named components

References
===
* https://github.com/tensorflow/minigo
* https://arxiv.org/pdf/2001.09318.pdf
* https://nikcheerla.github.io/deeplearningschool/2018/01/01/AlphaZero-Explained/
* https://web.stanford.edu/~surag/posts/alphazero.html


Four in a row
==

* https://medium.com/@sleepsonthefloor/azfour-a-connect-four-webapp-powered-by-the-alphazero-algorithm-d0c82d6f3ae9
* https://towardsdatascience.com/from-scratch-implementation-of-alphazero-for-connect4-f73d4554002a
* https://makerspace.aisingapore.org/2019/04/from-scratch-implementation-of-alphazero-for-connect4/
* https://timmccloud.net/blog-alphafour-understanding-googles-alphazero-with-connect-4/


Chessboards
==

Consider using http://chessboardjs.com/docs to add som real chessboard action.
