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
    @assert (x >= -1) "$x >= -1 failed"
    @assert (x <=  1) "$x <=  1 failed"
    idx = trunc(Int, no_of_output_nodes_to_encode_q * (x+1)/2)
    @assert(idx > 0)
    @assert(idx <= no_of_output_nodes_to_encode_q)
    result = zeros(Bool, no_of_output_nodes_to_encode_q)
    result[idx] = 1
    r = permutedims(result)
    return r
end

function one_cold_decode_q(x)
    decode_index(i::CartesianIndex) = i[2]
    decode_index(i::Int) = i
    idx = argmax(x)
    idx = decode_index(idx)
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

        # XXX For now this is randomized with respect  to maximal moves,
        #     but to explore it will be necessary to also explore some
        #     non-optimal moves.
        best_move_index = randomized_argmax(map(get_q, available_moves))
        return available_moves[best_move_index]
    end

    return get_q_choice
end



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

#
#  Also think about https://en.wikipedia.org/wiki/State%E2%80%93action%E2%80%93reward%E2%80%93state%E2%80%93action
#

reward(x::Draw, color::Color) = 0
reward(x::Win, color::Color)  = (x.winner == color) ? 1 : -1


## XXX Once this works, remove the first
##     definition and only use the last one.
deconstruct_episode(episode::Any) = episode
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
    𝛼 = 0.3

    for t in episode_length:-1:1

        move   = move_history[t]
        board  = board_history[t]
        color  = get_piece_at(board, move.start).color # color == player, in chess.  Need to generalize that.
        r      = t != episode_length ? 0 : reward(outcome, color)
        esm    = one_hot_encode_chess_state(board, move)

        # Basic Q-learning formula
        new_q = q_old(esm) + 𝛼 * (r + 𝛾 * future_value_estimate)

        # Since this is an adversarial game, every other
        # round we need to flip the value estimate's sign
        future_value_estimate = - new_q
        # Kludge to avoid the q value going above 1 (which may or may not
        # be very important to do.

        q_to_encode = 2*sigmoid(new_q) - 1
        #    println("Episode $t has q to encode = $q_to_encode")

        onehot_q = one_hot_encode_q(q_to_encode)
        learning_tuple = [esm, onehot_q]
        push!(learning_tuples, learning_tuple)
    end
    return learning_tuples
end


function one_hot_coded_q_values_difference(q1,q2)
    v1 = one_hot_encode_q(q1)
    v2 = one_hot_encode_q(q2)
    return v1 - v2
end

function q_learn!(qs, episodes)
    wipe_cache!(qs)

    println("Q-learning")

    learning_episodes = map(episode -> learn_from_episode(qs, episode), episodes)

    chain = qs.chain
    loss(x, y) = Flux.mse(chain(x), y)
    # loss(x, y) = one_hot_coded_q_values_difference(chain(x), y)
    ps = Flux.params(chain)
    opt =  ADAM() # uses the default η = 0.001 and β = (0.9, 0.999)

    print("   Training: ")
    for data in learning_episodes
        print(".")
        Flux.train!(loss, ps, data, opt)
    end
    println()
end



##
##   Running the Q-learning mechanism
##


using Plots
using DataStructures

function plot_game_length_histogram(episodes)
    # each episode has structure (outcome, move_history, board_history)
    lengths = [length(e[2]) for e in episodes]
    winners = [e[1] for e in episodes]
    println("histogram's lenghts = ", lengths)
    winner_strings = map(x -> show_string(x), winners)
    counts = counter(winner_strings)
    println("winner strings = ", counts)
    # black_wins = counts("Win by Color(\"Black\", \"b\")")
    # white_wins = counts("Win by Color(\"White\", \"w\")")
    # draws = counts("Draw")
    # white_fraction = white_wins / (black_wins + white_wins + draws )
    # println("White fraction = ", white_fraction)
    histogram(lengths)
    # histogram(lengths, bins=:scott)
end



new_q_state(chain  =  Chain(
    Dense(960, 960, σ),
    Dense(960, 400, σ),
    Dense(400, 200, σ),
    Dense(200, 200, σ),
    Dense(200, 200, σ),
    Dense(200, 200, σ),
    Dense(200, 200, σ),
    Dense(200, 200, σ),
    Dense(200, 200, σ),
    Dense(200, no_of_output_nodes_to_encode_q),
    softmax)) = Q_learning_state(
        # This chain is simply  a placeholder for a more realistic network
        # to be evolved in the future.
        chain,
        Dict{Array{Bool,1},Float32}()
    )



###
###  Next generation tournament-based players
###  (when this works, refactor much of the code above into oblivion)
###

function new_q_player(name)
    qs = new_q_state()
    strategy = new_q_choice(qs)
    return Player(name, strategy, qs)
end

clone_q_state(qs) = Q_learning_state(deepcopy(qs.chain), Dict{Array{Bool,1},Float32}())

function clone_q_player(name, qp)
    qs = clone_q_state(qp.state)
    strategy = new_q_choice(qs)
    return Player(name, strategy, qs)
end

function q_learn_tournament_result!(learning_player, tournament_result)
    q_learn!(learning_player.state,  tournament_result.games)
end



using Pkg
Pkg.add("DataFrames")

using Pkg
Pkg.add("CSV")

using DataFrames
using CSV


function new_learning_log()
    return DataFrame(round = Int[],
                     p1name = String[],
                     p2name = String[],
                     p1wins = Int[],
                     p2wins = Int[],
                     draws = Int[],
                     p2advantage = Float64[],
                     cloning_triggered = Bool[],
                     clone_generation = Int[])
end


## (::DataFrame, ::Int64, ::String, ::String, ::Int64, ::Int64, ::Int64, ::Float64, ::Bool, ::Int64)

function log_learning_round!(
    log::DataFrame,
    round::Int64,
#    noOfGames::Int,
    p1_name::String,
    p2_name::String,
    p1_wins::Int,
    p2_wins::Int,
    draws::Int,
    p2_advantage::Float64,
    cloning_triggered::Bool,
    clone_generation::Int)

    tuple = (round,
 #            noOfGames,
             p1_name,
             p2_name,
             p1_wins,
             p2_wins,
             draws,
             p2_advantage,
             cloning_triggered,
             clone_generation)
    push!(log, tuple)

    println(stdout, "round $round p2_advantage = $p2_advantage")
    if (cloning_triggered)
        println(stdout, "   p2( $p2_name, learning) has a $p2_advantage advantage, so cloning it into p1, replacing ($p1_name, static)")
    end

    ## Just trying out the csv thingy. This is not the final interface.
    CSV.write("learning_round_log.csv", log)
end


##
##  Tournament learning.  Starting with one random player and
##  one learning player.  Until the required number of tournaments has
##  been run, play the players against each other. Let the learning player
##  learn until it beats the non-learning player in 55% or more of the
##  games in the tournament.  At that point clone the learning player
##  and let it continue the tournament learning by playing against a non-learning
##  clone of itself.   This way the learning player will always be matched
##  be an equally good, or almost as good player as itself is.
##
function tournament_learning(
    no_of_tournaments=100,
    cloning_trigger = 0.55,
    max_rounds_in_tournament_games=200,
    tournament_length = 12)

    log = new_learning_log()

    random_player   = Player("random player 1", random_choice, nothing)

    initial_q_player  = new_q_player("Initial q player")

    # Using the random player to bootstrap here. Could equally well
    # have used an initial clone of the initial_q_player.
    (p1, p2) = (random_player, initial_q_player)
    clone_generation = 1
    for tournament_round in 1:no_of_tournaments

        println("Playing tournament round $tournament_round ")
        tournament_result     = play_tournament(
            p1,
            p2,
            max_rounds_in_tournament_games,
            tournament_length)

        println("Tournament result = $tournament_result")

        p2_advantage = p2_win_ratio(tournament_result)
        p1name = p1.id
        p2name = p2.id
        cloning_triggered =  (p2_advantage >= cloning_trigger)

        # XXX This is the result that should be logged into the dataframe, and
        ##    should be displayed, graphs should be made from, etc.
        log_learning_round!(
            log,
            tournament_round,
            p1.id,
            p2.id,
            tournament_result.p1wins,
            tournament_result.p2wins,
            tournament_result.draws,
            p2_advantage,
            cloning_triggered,
            clone_generation)

        if cloning_triggered
            clone_generation += 1
            clone = clone_q_player("Clone gen $clone_generation q-player", p2)
            (p1, p2) = (p2, clone)
        else
            q_learn_tournament_result!(p2, tournament_result)
        end
    end
    return (log, p2)
end

# @test tournament_learning() != nothing

(log, winning_player) = tournament_learning(
    400,
    0.55,
    200,
    100)

