
# using BSON: @save
# using BSON: @load

# Deprecated!
function q_learn_round(no_of_rounds = 20, no_of_episodes = 30, max_rounds_cutoff = 200, q_state  = new_q_state(), do_save = false, do_restore = false)

    # if do_restore
    #     @load "qlearn_chain.bson" chain
    #     q_state = Q_learning_state(chain)
    # end

    for round in 1:no_of_rounds
        println("Learning round ", round)
        q_choice = new_q_choice(q_state)

        # Play some games so we get something to learn from
        episodes = [play_game(q_choice, max_rounds_cutoff, devnull) for x in 1:no_of_episodes]

        # Plot the distribution of lengths of games (won/draw ratio would also be of interest over time)
        plot_game_length_histogram(episodes)

        q_learn!(q_state, episodes)

#        @save "qlearn_chain.bson" q_state.chain
    end

    return q_state
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
