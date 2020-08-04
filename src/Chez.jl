module Chez

using Flux, Test, BSON, CSV, DataFrames, IndexedTables, Pkg, Plots, Printf,  NNlib, JLD, HDF5
export Player, ChessBoard, Coord, Player, Win , Draw , Game_Result,Tournament_Result, Move, Color, Pawn , Rook , Knight , Bishop , Queen, King , Blank , ChessPiece, Q_learning_state, learning_increment


println("including -> pieces.jl")
include("pieces.jl")
println("including -> chessboard.jl")
include("chessboard.jl")
println("including -> movement.jl")
include("movement.jl")
println("including -> gameplay.jl")
include("gameplay.jl")
println("including -> learning_logging.jl")
include("learning_logging.jl")
println("including -> qlearn.jl")
include("qlearn.jl")
println("including tournament-learning.jl")
include("tournament-learning.jl")

println("Done loading Chez.jl")


end # module
