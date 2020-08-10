###
###  Q learning experiments
###

## TODO:
##
##  * Identify the q value calculation/encoding and encapsulate it.
##  * Restructure this module to have a much clearer layering structue.
##


##
##  One-hot coding of game state and moves.
##  Moves are encoded as from/to pairs indicating a move from
##  one of the 64 possible locations to another of the 64 locations.
##  This is ok for many moves, but not for rookings or subsitutions, but at this
##  time we're ont including thos moves.
##

using Flux
using Flux: onehot


one_hot_encode_coordinate_pair(source::Coord, destination::Coord) =
    transpose(vcat(onehot(source,      all_chessboard_locations),
                   onehot(destination, all_chessboard_locations)))

@test length(one_hot_encode_coordinate_pair(Coord(1,1), Coord(2,2))) == 128

one_hot_encode_move(m::Move) = one_hot_encode_coordinate_pair(m.start, m.destination)

one_hot_encode_piece(p::ChessPiece) = onehot(p, all_chess_pieces)

function one_hot_encode_board(board::ChessBoard)
    nested_vector = [one_hot_encode_piece(get_piece_at(board, location)) for location in all_chessboard_locations]
    return reshape(collect(Iterators.flatten(nested_vector)), (1, 832))
end

@test length(one_hot_encode_board(startingBoard)) ==  (13 * 64)


one_hot_encode_chess_state(state, move, action_history = nothing , state_history = nothing) =
     collect(Iterators.flatten([one_hot_encode_board(state), one_hot_encode_move(move)]))


@test length(one_hot_encode_chess_state(startingBoard, Move(Coord(1,1), Coord(2,2), false, bp, bp))) == 960



###
###  Q-learning mechanics
###



mutable struct Q_learning_state
    chain::Flux.Chain
    cache::Dict
    randomness::Float64
end

function wipe_cache!(qs::Q_learning_state)
    for k  in keys(qs.cache)
        delete!(qs.cache, k)
    end
end


###
### Storing and restoring q players' weights
###
using BSON: @save
using BSON: @load


## TODO: Check if GPU is being used, and if it is, then transform
##       chain to/from CPU before/after writing/writing.

function store_q_player(p, name)
    @save "$name.bson" p
end


function restore_q_player(name)
    filename = "$name.bson"
    # TODO: This is just to force the filename to disappear
    rm(filename, force=true)
    if isfile(filename)
        @load filename p
        strategy = new_q_choice(p.state)
        p = Player(p.id, strategy, p.state)
        return p
    else
        return Nothing
    end
end



##
## Store/restore clone generation number
##


function store_int(arg, filename)
    open(filename, "w") do io
        write(io, "$arg\n")
    end    
end

function restore_int(filename)
    if isfile(filename)
        open(filename, "r") do io
            l = readline(io)
            return parse(Int, l)
        end
    else
        return Nothing
    end
end


##
##  Storing players persistently.
##

clone_generation_filename="clone_generation.txt"
store_clone_generation(clone_generation) = store_int(clone_generation, clone_generation_filename)
restore_clone_generation() = restore_int(clone_generation_filename)


learning_round_filename="learning_round.txt"
store_learning_round(round) = store_int(round, learning_round_filename)
restore_learning_round() = restore_int(learning_round_filename)



##
##  Encoding of Q-values
##


# The q-values are discrete values i the range 0-100
#  using one-hot coding
# no_of_output_nodes_to_encode_q=100

# ... but now we're going for direct encoding, full relu.
no_of_output_nodes_to_encode_q=1


# # The input values are in the range 0-1, inclusive
# function encode_q(x)
#     @assert (x >= -1) "$x >= -1 failed"
#     @assert (x <=  1) "$x <=  1 failed"
#     idx = trunc(Int, no_of_output_nodes_to_encode_q * (x+1)/2)
#     @assert(idx > 0)
#     @assert(idx <= no_of_output_nodes_to_encode_q)
#     result = zeros(Bool, no_of_output_nodes_to_encode_q)
#     result[idx] = 1
#     r = permutedims(result)
#     return r
# end


# # output in the range [ -1 - 1] 
# function decode_q(x)
#     decode_index(i::CartesianIndex) = i[2]
#     decode_index(i::Int) = i
#     idx = argmax(x)
#     idx = decode_index(idx)
#     return  2*(idx/no_of_output_nodes_to_encode_q) - 1
# end

encode_q(q) = q
decode_q(q) = q


@test decode_q(encode_q(0.0)) == 0.0


function raw_q_lookup(qs::Q_learning_state, encoded_statemove)
    if haskey(qs.cache, encoded_statemove)
        return qs.cache[encoded_statemove]
    else
        result = decode_q(qs.chain(encoded_statemove))
        result = result[1]
        qs.cache[encoded_statemove] = result
        return result
    end
end

get_q_value(qs, state, move, action_history, state_history) =
    raw_q_lookup(qs, one_hot_encode_chess_state(state, move))


##
## Using Q-values to generate new choices
##



# Find the maximm value in the sequence, then return
# One of the indexes that contains that value
function randomized_argmax(sequence)
    (max_value, first_max_index) = findmax(sequence)
    # Is sufficiently close to max
    is_max(x) = abs(x - max_value) < 0.000000001
    return findall(is_max, sequence) |> get_random_element
end

@test randomized_argmax([0; 0; 2; 3; 3; 2; 1]) >= 3
@test randomized_argmax([0; 0; 2; 3; 3; 2; 1]) <= 5

function new_q_choice(qs::Q_learning_state)

    # Generate a new choice based on the evaluation in the network ("chain") in the
    # qs learning state.
    function get_q_choice(state,  available_moves, action_history, state_history)
        get_q = move -> get_q_value(qs, state, move, action_history, state_history)
        if qs.randomness > rand()
            return get_random_element(available_moves)
        else            
            best_move_index = randomized_argmax(map(get_q, available_moves))
            return available_moves[best_move_index]
        end
    end

    return get_q_choice
end


##
## Calculate the rewards from winnings and draws
##

reward(x::Draw, color::Color)  = 0
reward(x::Win,  color::Color)  = (x.winner == color) ? 1 : -1


deconstruct_episode(r::Game_Result) = (r.outcome, r.move_history, r.board_history)


# Calulate what the Q-values should be based on the old q_values
# that are present in qs, and present them as a
# set of learning tuples, that can be interpreted as a
# learning set for the qs.chain network


function learn_from_episode(qs, episode)

    q_old(encoded_statemove) = raw_q_lookup(qs, encoded_statemove)


    # Destructuring!
    outcome, move_history, board_history = deconstruct_episode(episode)

    episode_length = length(move_history)

    learning_tuples = []
    future_value_estimate = 0

    # Impact on first position
    impact1 = 1/episode_length

    #discount_factor (0 < 𝛾 <= 1)
    #  ... the discount factor is tuned soo that the
    # the impact isn't  too small
    𝛾 = (1/episode_length)^(1/episode_length)

    # println("𝛾 = $𝛾")

    # learning rate (0 < ɑ <= 1)
    # Consider tweaking this over time, adding
    # regulators to hyperparameters is dark magic.
    𝛼 = 0.3

    for t in episode_length:-1:1

        move   = move_history[t]
        board  = board_history[t]
        color  = get_piece_at(board, move.start).color # color == player, in chess.  Need to generalize that.
        rew    = reward(outcome, color)
        r      = t != episode_length ? 0 : rew
        esm    = one_hot_encode_chess_state(board, move)

        # Basic Q-learning formula (with added bias)
        innovation = 𝛼 * (r + 𝛾 * future_value_estimate)
        bias =  0.05  * rew
        
        new_q = q_old(esm) + innovation + bias

        # Since this is an adversarial game, every other
        # round we need to flip the value estimate's sign
        future_value_estimate = - new_q

        encoded_q = encode_q(new_q)
        learning_tuple = (esm, encoded_q)
        push!(learning_tuples, learning_tuple)
    end
    return learning_tuples
end


function encoded_q_values_difference(q1,q2)
    v1 = decode_q(q1)
    v2 = decode_q(q2)
    return v1 - v2
end

function q_learn!(qs, episodes)
    wipe_cache!(qs)

    println("Q-learning")

    learning_episodes = map(e -> learn_from_episode(qs, e), episodes)
    learning_episodes = todevice(learning_episodes)
    chain             = todevice(qs.chain)

    loss(x, y) = (chain(x)[1] - y)^2

    
    ps = Flux.params(chain)
    opt =  ADAM() # uses the default η = 0.001 and β = (0.9, 0.999)

    print("   Training: ")
    for episode in learning_episodes
        print(".")
        Flux.train!(loss, ps, episode, opt)
    end

    # The chain we store in the data structure is always the
    # CPU version,  so that we can be consistent when reading
    # and writing it.
    qs.chain = chain |> cpu
    println()
end


##
## A quick hack to be able to send something from cpu to the compute
## device either throug transformation to GPU structure,  if rnning a GPU
## or through identity if we're just using the host CPU.
##
use_gpu = false
todevice(x) = use_gpu ? gpu(x) : x


##
##   Running the Q-learning mechanism
##


## XXX The chain being  used here is just made  up at the spur of the moment.
##     it needs to be properly engineered and tuned. Right now it's just
##     a placeholder to get the rest of the machinery in place.

new_q_chain() =
    Chain(
        Dense(960, 100, relu),
        Dense(100, no_of_output_nodes_to_encode_q, relu)
    )

new_q_state(chain  = new_q_chain(), randomness::Float64 = 0) =
    Q_learning_state(
        chain,
        Dict{Array{Bool,1},Float32}(),
        randomness)

###
###  Next generation tournament-based players
###  TODO: (when this works, refactor much of the code above into oblivion)
###

function new_q_player(name, randomness)
    qs = new_q_state(new_q_chain(), randomness)
    strategy = new_q_choice(qs)
    return Player(name, strategy, qs)
end

clone_q_state(qs, clone_randomness::Bool = false) =
    Q_learning_state(deepcopy(qs.chain), Dict{Array{Bool,1},Float32}(), clone_randomness ? qs.randomness : 0.0)

function clone_q_player(name, qp)
    qs = clone_q_state(qp.state)
    strategy = new_q_choice(qs)
    return Player(name, strategy, qs)
end

function q_learn_tournament_result!(learning_player, tournament_result)
    q_learn!(learning_player.state,  tournament_result.games)
end


#####
## TODO: Move elsewhere

function test_saving_players()
    s = new_q_player("foobar", 0.05)
    store_q_player(a, "foobar")
end

####

