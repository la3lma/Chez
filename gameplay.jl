###
### Gameplay
###




##
##  Representing game outcomes
##
abstract type GameOutcome end
struct Win   <: GameOutcome
    winner:: Color 
end

struct Draw   <: GameOutcome end

show_string(w::Win)  =  @sprintf("Win by %s", w.winner)
show_string(w::Draw) =  "Draw"


show(io::IO, w::GameOutcome) = show(io, show_string(w))


##
##   The mechanics of playing a game using some
##   strategy that will select the next move.
##

function play_game(strategy, max_rounds, io::IO = stdout)
    color = white
    game_is_won = false
    round = 0
    board = startingBoard
    move_history = []
    board_history = []
    outcome = Draw()

    while (!game_is_won && round < max_rounds + 1)
        println(io, "Round " , round, " color ", color)
        available_moves = get_moves(color, board)
        if (!isempty(available_moves))
            println(io, "Number of moves available = ", length(available_moves))

            println(io, "Moves available = ", available_moves)
            next_move = strategy(board, available_moves, move_history, board_history)
            println(io, "Applying next_move ",  next_move)
            board = apply_move!(next_move, board)
            
            push!(move_history, next_move)            
            push!(board_history, board)
            
            println(io, board)
            game_is_won = captures_king(next_move)
            if game_is_won
                println(io, "Game is won by ",  color)
                outcome = Win(color)
            end
        end
        round += 1
        color = other_color(color)        
    end

    return (outcome, move_history, board_history)
end


##
##   A very simple gameplay strategy: Select a move at
##   random among the available moves.
##

get_random_element(x) = x[rand(1:length(x))]

random_choice(state, available_moves, action_history, state_history) = get_random_element(available_moves)


# Play a hundred random games with no output, just to check that the
# game mechanics isn't totally screwed up
@test [play_game(random_choice, 5000, devnull) for x in 1:100] != nothing


##
## Some tests just to get a feel for the thing.
##


play_random_game(rounds=50) = play_game(random_choice, rounds)

# XXX This fails, for some reason
# using Plots
#
#function plot_game_length_histogram() 
#    histogram([length((play_game(random_choice, 5000, devnull))[2]) for x in 1:300], bins=:scott)
#end
