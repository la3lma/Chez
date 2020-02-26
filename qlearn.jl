###
###  Q learning experiments
###


## XXX Helper
function printdim(label, x)
    println("=> ", label, " type = ", typeof(x))
    a,b = size(x)
    println("=> ", label, " size = (", a,  ",", b, ")")
end



##
##  One-hot coding of game state and moves.
##

using Flux
using Flux: onehot, onecold

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


one_hot_encode_chess_state(state, move_being_queried, action_history = nothing , state_history = nothing) =
     collect(Iterators.flatten([one_hot_encode_board(state), one_hot_encode_move(move_being_queried)]))


@test length(one_hot_encode_chess_state(startingBoard, Move(Coord(1,1), Coord(2,2), false, bp, bp))) == 960


###
###  Q-learning mechanics
###



struct Q_learning_state
    chain
    cache::Dict
end

function wipe_cache!(qs::Q_learning_state)
    for k  in keys(qs.cache)
        delete!(qs.cache, k)
    end
end

##
##  One-hot coding of Q-values
##

no_of_output_nodes_to_encode_q=100

function one_hot_encode_q(x)
    # println("one_hot_encode_q 1")
    @assert (x >= -1) "$x >= -1 failed"
    @assert (x <=  1) "$x <=  1 failed"
    idx = trunc(Int, no_of_output_nodes_to_encode_q * (x+1)/2)
    @assert(idx > 0)
    @assert(idx <= no_of_output_nodes_to_encode_q)
    result = zeros(Bool, no_of_output_nodes_to_encode_q)
    result[idx] = 1
    # println("one_hot_encode_q 2")
    r = permutedims(result)
    # println("one_hot_encode_q 3")    
    return r
end

function one_cold_decode_q(x)
    decode_index(i::CartesianIndex) = i[2]
    decode_index(i::Int) = i
    
    # println("one_hot_decode_q 1")    
    # println("x = ", x)    
    idx = argmax(x)
    # println("idx1 = ", idx)
    idx = decode_index(idx)
    # println("idx2 = ", idx)    
    return  2*(idx/no_of_output_nodes_to_encode_q) - 1
end

@test one_cold_decode_q(one_hot_encode_q(0.0)) == 0.0


function raw_q_lookup(qs::Q_learning_state, encoded_statemove)
    if haskey(qs.cache, encoded_statemove)
        return qs.cache[encoded_statemove]
    else
        result = one_cold_decode_q(qs.chain(encoded_statemove))
        qs.cache[encoded_statemove] = result
        return result
    end
end

get_q_value(qs, state, move, action_history, state_history) =
    raw_q_lookup(qs, one_hot_encode_chess_state(state, move))


function new_q_choice(qs::Q_learning_state)

    # Generate a new choice based on the evaluation in the network ("chain") in the
    # qs learning state.
    function get_q_choice(state,  available_moves, action_history, state_history)
        get_q = move -> get_q_value(qs, state, move, action_history, state_history)
        best_move_index = argmax(map(get_q, available_moves))
        return available_moves[best_move_index]
    end

    return get_q_choice
end



#discount_factor (0 < 𝛾 <= 1)
𝛾 = 0.5

# learning rate (0 < ɑ <= 1)
𝛼 = 0.1


# The state here must be:
#   * The game board
#   * The player that will make the next move
#   * previous 2 moves (to be able to detect draw by repetition)
# The Q value we are estimating to be a number between 1 and 100 (or so)
#   * We will have to represent it using one-hot coding, so it won't be awfully
#     accurate but I think we can live with that.


# https://en.wikipedia.org/wiki/Q-learning
# (seems like the maxq -Q value is missing a layer of parens.
#  https://en.wikipedia.org/wiki/Q-learning
# q_new(state_t, action_t) = q_old(state_t, action_t) + 𝛼 *  (reward + 𝛾 * (argmax_actions(a-> q_old(state_t+1, a)) - q_old(state_t, action_t)))

reward(x::Draw, color::Color) = 0
reward(x::Win, color::Color)  = (x.winner == color) ? 1 : -1


# Calulate what the Q-values should be based on the old q_values
# that are present in qs, and present them as a
# set of learning tuples, that can be interpreted as a
# learning set for the qs.chain network

function learn_from_episode(qs, episode)
    
    q_old(encoded_statemove) = raw_q_lookup(qs, encoded_statemove)
    
    outcome, move_history, board_history = episode
    episode_length = length(move_history)
    
    learning_tuples = []
    future_value_estimate = 0
    for t in episode_length:-1:1
        move   = move_history[t]
        board  = board_history[t]
        color  = get_piece_at(board, move.start).color # color == player
        r      = t != episode_length ? 0 : reward(outcome, color)
        esm    = one_hot_encode_chess_state(board, move)
        new_q = q_old(esm) + 𝛼 * (r + 𝛾 * future_value_estimate)
        future_value_estimate = new_q
        onehot_q = one_hot_encode_q(new_q)
        learning_tuple = [esm, onehot_q]
        push!(learning_tuples, learning_tuple)
    end
    return learning_tuples
end


function q_learn!(qs, episodes)
    wipe_cache!(qs)

    learning_episodes = map(episode -> learn_from_episode(qs, episode), episodes)

    chain = qs.chain
    loss(x, y) = Flux.mse(chain(x), y)
    ps = Flux.params(chain)
    opt =  ADAM() # uses the default η = 0.001 and β = (0.9, 0.999)

    for data in learning_episodes
        # Trying with random data with knownf ormat, just to see where this is going
        # data = [ (rand(960), rand(no_of_output_nodes_to_encode_q)) ]
        Flux.train!(loss, ps, data, opt, cb = () -> println("training"))
    end
end



##
##   Running the Q-learning mechanism
##

function q_learn_round(no_of_rounds = 2, no_of_episodes = 3, max_rounds_cutoff = 500)

    q_state = Q_learning_state(
        # This chain is simply  a placeholder for a more realistic network
        # to be evolved in the future.
        Chain(
         Dense(960, 5, σ),
         Dense(5, no_of_output_nodes_to_encode_q),
            softmax),
        Dict{Array{Bool,1},Float32}()
    )

    for round in 1:no_of_rounds

        q_choice = new_q_choice(q_state)

        # Play some games so we get something to learn from
        episodes = [play_game(q_choice, max_rounds_cutoff, devnull) for x in 1:no_of_episodes]

        q_learn!(q_state, episodes)
    end
    return q_state
end


# Smoketest that will discover many weird errors.
@test q_learn_round() != nothing
