
# using Pkg
# Pkg.add("DataFrames")
# Pkg.add("CSV")
# Pkg.add("IndexedTables")
# Pkg.add("StatsPlots")
# Pkg.add("Pandas")

using DataFrames
using CSV
using IndexedTables
using StatsPlots


using Pandas

tournament = CSV.read("learning_round_log.csv")

using Plots

gr()


#  Things we want to plot:  :round

plot(tournament[:round],  tournament[:p2advantage])

# plot(tournament[:round], [tournament[:p2advantage], tournament[:clone_generation]])
# @df tournament plot(:round, [:p2advantage, :clone_generation]))
