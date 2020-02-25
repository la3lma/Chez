###
###  Q learning experiments
###



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


one_hot_encode_chess_state(state, move_being_queried, action_history, state_history) =
     collect(Iterators.flatten([one_hot_encode_board(state), one_hot_encode_move(move_being_queried)]))

             
@test length(one_hot_encode_chess_state(startingBoard, Move(Coord(1,1), Coord(2,2), false, bp, bp), nothing, nothing)) == 960


##
##  Q-learning mechanics
##



struct Q_learning_state
    chain
    cache::Dict
end


# Get an action-selection function connected to a q-learning instance.



function new_q_choice(qs::Q_learning_state)

    # Generate a new choice based on the evaluation in the network ("chain") in the
    # qs learning state.
    function get_q_choice(state,  available_moves, action_history, state_history)
        function get_q_value(move)
            encoded_state = one_hot_encode_chess_state(state, move, action_history, state_history)

            result = nothing
            if haskey(qs.cache, encoded_state)
                result = qs.cache[encoded_state]
            else
                result = argmax(qs.chain(encoded_state))
                println("Result = ", result)
                qs.cache[encoded_state] = result
            end
            return result
        end            

        best_move_index = argmax(map(get_q_value, available_moves))
        return available_moves[best_move_index]
    end
    
    return get_q_choice
end
    
    

#discount_factor (0 < 𝛾 <= 1)
𝛾 = 0.5

# learning rate (0 < ɑ <= 1)
ɑ = 0.5


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
# q_new(state_t, action_t) = q_old(state_t, action_t) + ɑ *  (reward + 𝛾 * (argmax_actions(a-> q_old(state_t, a)) - q_old(state_t, action_t)))


    
function q_learn!(q_state, episodes)

    ## Cacheing can be useful here
    function learn_from_episode(episode)
        q_old(t) = q_state.chain(episode[1][t])
        
    end
    
        
    return nothing
end



##
##   Running the Q-learning mechanism
##

function q_learn_round(no_of_rounds = 2, no_of_episodes = 3, max_rounds_cutoff = 500)

    q_state = Q_learning_state(
        Chain(
         Dense(960, 5, σ),
         Dense(5, 100),
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
