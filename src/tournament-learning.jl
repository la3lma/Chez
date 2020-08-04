
##
##  Tournament learning (self learning).  Starting with one random player and
##  one learning player.  Until the required number of tournaments has
##  been run, play the players against each other. Let the learning player
##  learn until it beats the non-learning player in 55% or more of the
##  games in the tournament.  At that point clone the learning player
##  and let it continue the tournament learning by playing against a non-learning
##  clone of itself.   This way the learning player will always be matched
##  be an equally good, or almost as good player as itself is.
##
function tournament_learning(
    no_of_tournament_rounds::Int64=100,
    cloning_trigger = 0.55,
    max_rounds_in_tournament_games=200,
    tournament_length = 12,
    player_1 = Nothing,
    player_2 = Nothing,
    do_snapshots = true,
    clone_generation = Nothing,
    initial_tournament_round = Nothing)

    log = new_learning_log()


    if initial_tournament_round == Nothing
        initial_tournament_round = 1
    end
    
    if clone_generation == Nothing
        clone_generation = 1
    end

    force_clone_once = false
    
    if player_1 == Nothing
        force_clone_once = true
        player_1    =  new_q_player("Initial q player (1)",  0.05)
    end

    # When playing as a learning player, the q_player will
    # select 5% of its moves randomly among the currently available
    # moves.  This will put it at a disadvantage from a gameplay point of
    # view, but it will also explore more of the game space.  It's an
    # idea.  Don't know how to test it properly yet, but that is one of the
    # many things that should b e part of this experimental program in the end:
    # how to test settings of various hyperparameters and how they
    # influence system performance.

    if player_2 == Nothing
        player_2  = new_q_player("Initial q player (2)",  0.05)
    end        
        
    # Using the random player to bootstrap here. Could equally well
    # have used an initial clone of the initial_q_player.
    (p1, p2) = (player_1, player_2)

    last_tournament_round = initial_tournament_round + no_of_tournament_rounds

    
    for tournament_round in initial_tournament_round:last_tournament_round

        # Play the tournament
        println("Playing tournament round $tournament_round ")
        tournament_result     = play_tournament(
            p1,
            p2,
            max_rounds_in_tournament_games,
            tournament_length)

        # Extract the values we need to log and progress
        p2_advantage = p2_win_ratio(tournament_result)
        p1name = p1.id
        p2name = p2.id
        cloning_triggered =  (p2_advantage >= cloning_trigger)

        # Log  the current learning round into a dataframe ("log")
        # so that we can keep track of progress.
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

        # If cloning was triggered, then do  that
        if cloning_triggered || force_clone_once
            force_clone_once = false
            clone_generation += 1
            clone = clone_q_player("Clone gen $clone_generation q-player", p2)
            (p1, p2) = (p2, clone) ## Or swap?   No semantic diffenence, but different naming.
        end

        # Then  learn from this round
        q_learn_tournament_result!(p2, tournament_result)
        if do_snapshots
            println("Snapshotting players in  round ... $tournament_round ...")
            store_q_player(p1, "p1")
            store_q_player(p2, "p2")
            store_clone_generation(clone_generation)
            store_learning_round(tournament_round)
            println("    ... Done")            
        end
    end

    # Finally return the dataframe with the log, and the
    # final evolved player
    return (log, p2)
end



run_big_tournament() = tournament_learning(
        20,     # no of tournaments
        0.55,   # Trigger
        200,    # Max rounds
        20)     # Tournament length


run_micro_tournament() = tournament_learning(
        5,     # no of tournaments
        0.55,   # Trigger
        200,    # Max rounds
        10)     # Tournament length

# Only useful for unit testing
run_nano_tournament() = tournament_learning(
        2,     # no of tournaments
        0.55,  # Trigger
        20,    # Max rounds
        5)     # Tournament length


@test run_nano_tournament != nothing


function learning_increment(prod=false)
    p1 = restore_q_player("p1")
    p2 = restore_q_player("p2")
    clone_generation = restore_clone_generation()
    learning_round = restore_learning_round()

    if learning_round != Nothing
        learning_round += 1
    end

    # TODO: Appending to the history is not happening in a proper manner!

    if prod
        tournament_learning(
            100,      # no of tournaments
            0.55,    # Trigger
            200,     # Max rounds
            100,     # Tournament length
            p1,      # First player
            p2,      # Second player
            true,    # Do snapshots
            clone_generation, # tssia
            learning_round
        )
    else
        tournament_learning(
            3,      # no of tournaments
            0.55,   # Trigger
            5,      # Max rounds
            2,      # Tournament length
            p1,     # First player
            p2,     # Second player
            true,   # Do snapshots
            clone_generation, # tssia
            learning_round
        )
    end
end

