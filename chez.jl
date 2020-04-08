import Pkg;
Pkg.add("CuArrays")
Pkg.add("Flux")
Pkg.add("IndexedTables")
Pkg.add("Pandas")
Pkg.add("Plots")




include("pieces.jl")
include("chessboard.jl")
include("movement.jl")
include("gameplay.jl")
include("learning_logging.jl")
include("qlearn.jl")

