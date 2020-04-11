include("pieces.jl")
 
blankBoardArray = [
  bs bs bs bs bs bs bs bs;
  bs bs bs bs bs bs bs bs;
  bs bs bs bs bs bs bs bs;
  bs bs bs bs bs bs bs bs;
  bs bs bs bs bs bs bs bs;
  bs bs bs bs bs bs bs bs;
  bs bs bs bs bs bs bs bs;
  bs bs bs bs bs bs bs bs;
];

blankBoard = ChessBoard(blankBoardArray)

# function getMovesFromRay(
# 	 generator::Coord, 
# 	 color::Color, 
# 	 board::ChessBoard, 
# 	 start::Coord,
# 	 oneStepOnly::Bool)


getMovesFromRay(Coord(1,0), white, blankBoard, a1, false)
