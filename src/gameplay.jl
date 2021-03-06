###
### Gameplay
###
using Dates

 
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
    winner::Color
    player::Player
end

struct Draw   <: GameOutcome end

show_string(w::Win)  =  @sprintf("Win by %s", w.winner.name)
show_string(w::Draw) =  "Draw"

show(io::IO, w::GameOutcome) = show(io, show_string(w))


# XXX Obsolete code.  Remove once it's been proven to be not used anywhere important.

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
# @test [play_game(random_choice, 5000, devnull) for x in 1:100] != nothing


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

has_wins(t::Tournament_Result)::Bool = t.p1wins != 0 || t.p2wins != 00


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



## TODO Getting started on FEN priting.   At present, this
## code isn't being used, and it also doesn't get the necessary
## information (next player etc.) but it could/should
## be used to log games so that they can be inspected by
## humans for more or less obvious strangeness.
function showFEN(io::IO, cb::ChessBoard, next_player::String, possible_castlings::String, moves_since_last_catch, move_number)

    ## Initial FEN string (board position)
    for y in  8:-1:1
        blanks = 0
        for x in 1:8
            piece = cb.board[y, x].printrep
            if piece ≠ " "
                if blanks ≠ 0
                    print(io, "$blanks")
                    blanks = 0
                end
                print(io, piece)
            else
                blanks += 1
            end
        end
        if blanks ≠ 0
            print(io, "$blanks")
        end
        if y ≠ 1
            print(io, "/")
        end
    end
    println(io, " $next_player $possible_castlings $moves_since_last_catch $move_number")
end


function write_game_logs(tr::Tournament_Result)

    function write_FEN_log()

        function write_game(game::Game_Result)

            for (move::Move,  board::ChessBoard) in zip(game.move_history, game.board_history)
                if move.capture
                    any_captures = true
                    moves_since_capture = 0 # TODO: Check if this is base 0 or base 1.
                else
                    moves_since_capture += 1
                end

                if any_captures
                    captures_count = moves_since_capture
                else
                    captures_count = "-"
                end

                showFEN(stdout,  board, other_color(move.startPiece.color).shortName, "-", captures_count, round)
            end
        end

        moves_since_capture = 0
        any_captures = false
        round = 1

        for game in tr.games
            write_game(game)
            round += 1
        end
    end


    # https://en.wikipedia.org/wiki/Portable_Game_Notation
    function write_PGN_log()

        function write_game(game::Game_Result)
           
            #### XXXX THis isn't working for weird reasons,.
            site = "Chez simulation"
            timenow = Dates.Time(Dates.now(Dates.UTC ))
            # datestring  = Dates.format(timenow, "yyyy.m.dd HH:MM:SS")
            whiteplayer = game.p1.id
            blackplayer = game.p2.id

            println("[Event \"Just another training game\"]")
            println("[Site \"Cyberspace arena of infinite self play\"]")
            # println("[Date \"$datestring\"]")
            # println("[Round \"29\"]")
            println("[White \"$whiteplayer\"]")
            println("[Black  \"$blackplayer\"]")
            
            outcome = show_string(game.outcome)
            println("[Result \"$outcome\"]")


            #  https://en.wikipedia.org/wiki/Algebraic_notation_(chess)
            half_move_no = 2
            move_no = 1
            for move::Move in game.move_history
                if half_move_no % 2 == 0
                    println()
                    print(move_no)
                    print(".")
                    move_no += 1
                end
                print(" ")
                print(move_as_PGN(move))
                half_move_no += 1
            end
            println()
        
        end

        for game in tr.games
            write_game(game)
        end
    end

    write_PGN_log()

end

##
## Plying tournaments
##

## TODO:  Refactor
##  -  Rewrite the FEN writer to operate on game logs rather than logging from
##     within the tournament  mechanics.   Merging the two logics makes the
##     code messy.
##  -  Add a PGN logger that outputs the game as a PGN log instead

function play_tournament(
    player1::Player,
    player2::Player,
    max_rounds=200,
    tournament_length=10,
    logIo::IO=devnull)::Tournament_Result

    function play_game(p1, p2)

        println(logIo, "Playing a game")
        (active_player, inactive_player) = (p1, p2)

        color = white
        game_is_won = false
        round = 0
        board = startingBoard
        move_history = []
        board_history = []
        outcome = Draw()

        moves_since_capture = 0
        
        showFEN(logIo, board, "w", "-", "-", round)
        any_captures = false

        while (!game_is_won && round < max_rounds)
            round += 1
            active_strategy = active_player.strategy
            available_moves = get_moves(color, board)
            if (!isempty(available_moves))

                next_move::Move = active_strategy(board, available_moves, move_history, board_history)
            
                board = apply_move!(next_move, board)

                push!(move_history,  next_move)
                push!(board_history, board)

                game_is_won = captures_king(next_move)
                if game_is_won
                    println(logIo , "Game is won by ",  color)
                    outcome = Win(color, active_player)
                end
            end
            color = other_color(color)
            (active_player, inactive_player) = (inactive_player, active_player)
        end

        println(logIo, "Rounds = $round, Outcome = $outcome")
        return Game_Result(p1, p2, outcome, move_history, board_history)
    end

    println(logIo, "Before playing games")
    println(logIo, "player1 = $player1")
    println(logIo, "player2 = $player2")
    # In the tournament, the players play every other game as white.
    games = [ iseven(i) ?  play_game(player1, player2) : play_game(player2, player1)
              for i in 1:tournament_length ]
    println(logIo, "After playing games")

    ## Inefficient way of calculating these things.
    p1wins = count_wins_for_player(games, player1)
    p2wins = count_wins_for_player(games, player2)
    draws  = count_draws(games)
        
    return Tournament_Result(games, player1, player2, p1wins, p2wins, draws)
end

random_player_1 = Player("random player 1", random_choice, nothing)
random_player_2 = Player("random player 2", random_choice, nothing)

println("Testing: Playing tournament")
@test play_tournament(random_player_1, random_player_2) != Nothing
@test p2_win_ratio(play_tournament(random_player_1, random_player_2)) >= 0
println("Testing: Tournament played")


##
##  Enabling play between humans and agents.
##
function read_legal_move_number(no_of_available_moves)
    while true
        # try 
        j = parse(Int64, readline())
        println("Just read $j")

        if (j < 0 || no_of_available_moves  < j)
            println("Illegal index $j")
        else
            return j
        end
       #  catch e
        println("Not a number, $e")
       #  end
    end
end

function select_move_interactively(available_moves)
    while true
        println("Available moves are (0 to abort): ")

        for i in 1:length(available_moves)
            println("$i = ", available_moves[i])
        end
        
        j = read_legal_move_number(length(available_moves))
        if (j == 0)
            #  This doesn't work. Don't know how to abort :-)
            error("This game is being aborted")
        end
        return available_moves[j]
    end
end

function select_move_interactively(state, available_moves, action_history, state_history)
    println("[2JCurrent state = ")
    println(state)
    return select_move_interactively(available_moves)
            
end

# Play a an interactive game against the computer oposition.")
interactive_game(p::Player) =
    play_tournament(p, Player("Interactive player", select_move_interactively, nothing))

    

