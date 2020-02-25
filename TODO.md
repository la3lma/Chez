

Game mechanics
===

* Detect move repetition to signal draws.
* Let the game board contain the state of the rookings, and movements of the king/rooks.
* Implement en-passant


Strategy development
==

* Minimax player.
* Minimax player with alpha-beta pruing.
* Deep neural network, reinforcement learning player based on Flux.jl
   - Map game-states into neural network representations
   - Design a network architecture to either find next move or evaluate positions.
   - Design a "goodness" criterion for strategies.
   - Find a way to make this architecture learn by playing against itself.
   - => Alpha zero light

Practical next moves
==

qlearn.jl currently fails to load due to the error below, and that
must be fixed.  I don't really know what the cause is, but it seems
like it's some type of array dimenison or type mismatch.  It could be
that the input feature vector is a vector of float64 values, but
Flux.jl requires float32 values (or maybe it doesn't I don't really
know).

Anyhow, this is where the game is today, and this is the next hurdle that
needs to be overcome.



     julia> include("qlearn.jl")
     Error During Test at /Users/rmz/git/AI/chezjulia/qlearn.jl:124
       Test threw exception
       Expression: q_learn_round() != nothing
       DimensionMismatch("A has dimensions (1,960) but B has dimensions (1,960)")
       Stacktrace:
	[1] gemm_wrapper!(::Array{Float32,2}, ::Char, ::Char, ::Array{Float32,2}, ::Array{Float32,2}, ::LinearAlgebra.MulAddMul{true,true,Float32,Float32}) at /Users/julia/buildbot/worker/package_macos64/build/usr/share/julia/stdlib/v1.3/LinearAlgebra/src/matmul.jl:545
	[2] mul! at /Users/julia/buildbot/worker/package_macos64/build/usr/share/julia/stdlib/v1.3/LinearAlgebra/src/matmul.jl:160 [inlined]
	[3] mul! at /Users/julia/buildbot/worker/package_macos64/build/usr/share/julia/stdlib/v1.3/LinearAlgebra/src/matmul.jl:203 [inlined]
	[4] * at /Users/julia/buildbot/worker/package_macos64/build/usr/share/julia/stdlib/v1.3/LinearAlgebra/src/matmul.jl:153 [inlined]
	[5] (::Dense{typeof(σ),Array{Float32,2},Array{Float32,1}})(::Array{Float32,2}) at /Users/rmz/.julia/packages/Flux/2i5P1/src/layers/basic.jl:102
	[6] Dense at /Users/rmz/.julia/packages/Flux/2i5P1/src/layers/basic.jl:113 [inlined]
	[7] (::Dense{typeof(σ),Array{Float32,2},Array{Float32,1}})(::LinearAlgebra.Transpose{Float64,Array{Float64,1}}) at /Users/rmz/.julia/packages/Flux/2i5P1/src/layers/basic.jl:116
	[8] (::Chain{Tuple{Dense{typeof(σ),Array{Float32,2},Array{Float32,1}},Dense{typeof(identity),Array{Float32,2},Array{Float32,1}},typeof(softmax)}})(::LinearAlgebra.Transpose{Float64,Array{Float64,1}}) at /Users/rmz/.julia/packages/Flux/2i5P1/src/layers/basic.jl:30
	[9] (::var"#get_q_value#107"{ChessBoard,Array{Any,1},Array{Any,1},Q_learning_state})(::Move) at /Users/rmz/git/AI/chezjulia/qlearn.jl:83
	[10] iterate at ./generator.jl:47 [inlined]
	[11] _collect(::Array{Any,1}, ::Base.Generator{Array{Any,1},var"#get_q_value#107"{ChessBoard,Array{Any,1},Array{Any,1},Q_learning_state}}, ::Base.EltypeUnknown, ::Base.HasShape{1}) at ./array.jl:635
	[12] collect_similar at ./array.jl:564 [inlined]
	[13] map at ./abstractarray.jl:2073 [inlined]
	[14] (::var"#get_q_choice#106"{Q_learning_state})(::ChessBoard, ::Array{Any,1}, ::Array{Any,1}, ::Array{Any,1}) at /Users/rmz/git/AI/chezjulia/qlearn.jl:86
	[15] play_game(::var"#get_q_choice#106"{Q_learning_state}, ::Int64, ::Base.DevNull) at /Users/rmz/git/AI/chezjulia/gameplay.jl:43
	[16] #108 at ./none:0 [inlined]
	[17] iterate at ./generator.jl:47 [inlined]
	[18] collect(::Base.Generator{UnitRange{Int64},var"#108#109"{Int64,var"#get_q_choice#106"{Q_learning_state}}}) at ./array.jl:622
	[19] q_learn_round(::Int64, ::Int64, ::Int64) at /Users/rmz/git/AI/chezjulia/qlearn.jl:114
	[20] q_learn_round() at /Users/rmz/git/AI/chezjulia/qlearn.jl:105
	[21] top-level scope at /Users/rmz/git/AI/chezjulia/qlearn.jl:124
	[22] include at ./boot.jl:328 [inlined]
	[23] include_relative(::Module, ::String) at ./loading.jl:1105
	[24] include(::Module, ::String) at ./Base.jl:31
	[25] include(::String) at ./client.jl:424
	[26] top-level scope at REPL[9]:1
	[27] eval(::Module, ::Any) at ./boot.jl:330
	[28] eval_user_input(::Any, ::REPL.REPLBackend) at /Users/julia/buildbot/worker/package_macos64/build/usr/share/julia/stdlib/v1.3/REPL/src/REPL.jl:86
	[29] macro expansion at /Users/julia/buildbot/worker/package_macos64/build/usr/share/julia/stdlib/v1.3/REPL/src/REPL.jl:118 [inlined]
	[30] (::REPL.var"#26#27"{REPL.REPLBackend})() at ./task.jl:333

     ERROR: LoadError: There was an error during testing
     in expression starting at /Users/rmz/git/AI/chezjulia/qlearn.jl:124

     julia> 
