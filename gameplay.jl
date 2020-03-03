###
### Gameplay
###

##
## Players, holding strategies and evolving some state
##
struct Player
    id::String
    strategy
    state
end


##
##  Representing game outcomes
##
abstract type GameOutcome end
struct Win   <: GameOutcome
    winner:: Color
    player:: Player
end

struct Draw   <: GameOutcome end

show_string(w::Win)  =  @sprintf("Win by %s", w.winner)
show_string(w::Draw) =  "Draw"

show(io::IO, w::GameOutcome) = show(io, show_string(w))


#XXX Obsolete code.  Remove once it's been proven to be not used anywhere important.

# ##
# ##   The mechanics of playing a game using some
# ##   strategy that will select the next move.
# ##

# function play_game(strategy, max_rounds, io::IO = stdout)
#     color = white
#     game_is_won = false
#     round = 0
#     board = startingBoard
#     move_history = []
#     board_history = []
#     outcome = Draw()

#     while (!game_is_won && round < max_rounds + 1)
#         println(io, "Round " , round, " color ", color)
#         available_moves = get_moves(color, board)
#         if (!isempty(available_moves))
#             println(io, "Number of moves available = ", length(available_moves))

#             println(io, "Moves available = ", available_moves)
#             next_move = strategy(board, available_moves, move_history, board_history)
#             println(io, "Applying next_move ",  next_move)
#             board = apply_move!(next_move, board)

#             push!(move_history, next_move)
#             push!(board_history, board)

#             println(io, board)
#             game_is_won = captures_king(next_move)
#             if game_is_won
#                 println(io, "Game is won by ",  color)
#                 outcome = Win(color, Player("Not a real player", nothing, nothing))
#             end
#         end
#         round += 1
#         color = other_color(color)
#     end

#     return (outcome, move_history, board_history)
# end

##
##   A very simple gameplay strategy: Select a move at
##   random among the available moves.
##

get_random_element(x) = x[rand(1:length(x))]

random_choice(state, available_moves, action_history, state_history) =
    get_random_element(available_moves)


# Play a hundred random games with no output, just to check that the
# game mechanics isn't totally screwed up
@test [play_game(random_choice, 5000, devnull) for x in 1:100] != nothing


##
## Some tests just to get a feel for the thing.
##


play_random_game(rounds=50) = play_game(random_choice, rounds)



###
###  Tournament play (for pitting two competitors against each other)
###

struct Game_Result
    p1::Player
    p2::Player
    outcome::GameOutcome
    move_history
    board_history
end


##
## Evaluating tournament results
##

struct Tournament_Result
    games
    p1
    p2
    p1wins
    p2wins
    draws
end

player_is_winner(w::Win,  p::Player)  = (p == w.player)
player_is_winner(w::Draw, p::Player)  = false

is_draw(w::Win)  = false
is_draw(w::Draw) = true
        
        
did_player_win(game::Game_Result, player::Player)  =   player_is_winner(game.outcome, player)

count_wins_for_player(games, player::Player) = 
    sum([did_player_win(game, player) for game in games])    

count_draws(games) =
    sum([is_draw(game_result.outcome) for game_result  in games])


p2_win_ratio(t::Tournament_Result) =
    t.p2wins / (t.p1wins + t.p2wins + t.draws)


function show(io::IO, r::Tournament_Result)
    no_of_games = length(r.games)
    p1 = r.p1.id
    p2 = r.p2.id
    p1wins = r.p1wins
    p2wins = r.p2wins
    draws =  r.draws
    result = "Tournament_Result{games= {$no_of_games}, p1='$p1', p2='$p2',  p1wins = $p1wins, p2wins = $p2wins, draws = $draws}"
    show(io, result)
end


##
## Plying tournaments
##

function play_tournament(
    player1::Player,
    player2::Player,
    max_rounds=200,
    tournament_length = 10,
    io::IO = devnull)::Tournament_Result


    function play_game(p1, p2)
        (active_player, inactive_player) = (p1, p2)

        color = white
        game_is_won = false
        round = 0
        board = startingBoard
        move_history = []
        board_history = []
        outcome = Draw()
        
        while (!game_is_won && round < max_rounds + 1)
            active_strategy = active_player.strategy
            println(io, "Round " , round, " color ", color)
            available_moves = get_moves(color, board)
            if (!isempty(available_moves))
                println(io, "Number of moves available = ", length(available_moves))
                println(io, "Moves available = ", available_moves)

                next_move = active_strategy(board, available_moves, move_history, board_history)
                println(io, "Applying next_move ",  next_move)
                board = apply_move!(next_move, board)

                push!(move_history,  next_move)
                push!(board_history, board)

                println(io, board)
                game_is_won = captures_king(next_move)
                if game_is_won
                    println(io, "Game is won by ",  color)
                    outcome = Win(color, active_player)
                end
            end
            round += 1
            color = other_color(color)
            (active_player, inactive_player) = (inactive_player, active_player)
        end
        return Game_Result(p1, p2, outcome, move_history, board_history)
    end

    # In the tournament, the players play every other game as white.
    games = [ iseven(i) ?  play_game(player1, player2) : play_game(player2, player1)
              for i in 1:tournament_length ]

    ## Inefficient way of calculating these things.
    p1wins = count_wins_for_player(games, player1)
    p2wins = count_wins_for_player(games, player2)
    draws  = count_draws(games)
        
    return Tournament_Result(games, player1, player2, p1wins, p2wins, draws)
end

random_player_1 = Player("random player 1", random_choice, nothing)
random_player_2 = Player("random player 2", random_choice, nothing)

println("Playing tournament")
@test play_tournament(random_player_1, Random_player_2) != Nothing
@test p2_win_ratio(play_tournament(random_player_1, random_player_2)) >= 0

println("Tournament played")




