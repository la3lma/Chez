import Pkg;
Pkg.add("CuArrays")
Pkg.add("Flux")
Pkg.add("IndexedTables")
Pkg.add("Pandas")
Pkg.add("Plots")




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
println("Done loading chez.jl")
