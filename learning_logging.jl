
using Pkg
Pkg.add("DataFrames")
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


function log_learning_round!(
    log::DataFrame,
    round::Int64,
    p1_name::String,
    p2_name::String,
    p1_wins::Int,
    p2_wins::Int,
    draws::Int,
    p2_advantage::Float64,
    cloning_triggered::Bool,
    clone_generation::Int)

    tuple = (round,
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


# using Pkg
# Pkg.add("DataFrames")
# Pkg.add("CSV")
# Pkg.add("IndexedTables")
# Pkg.add("StatsPlots")
# Pkg.add("Pandas")

using DataFrames
using CSV
using IndexedTables
# using StatsPlots
using Pandas

using Plots


function plot_tournament_result(file="learning_round_log.csv")

    tournament = CSV.read(file)
    gr()
    #  Things we want to plot:  :round
    plot(tournament[:round],  tournament[:p2advantage])
end

# plot(tournament[:round], [tournament[:p2advantage], tournament[:clone_generation]])
# @df tournament plot(:round, [:p2advantage, :clone_generation]))
