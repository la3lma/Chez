##
## The Chess kata in Julia
##
## The objective is to write a simple minimax/alpha-beta
## correctly playing chess game.  The purpose behind this
## objective is to do some nontrivial programming in Julia
## just to get a feel for it. Playing strength of the chess
## program is not something I'm very interested in :-)
##

import Base.show
using  Base.Test

type Color
   name:: String
   shortName:: String
end

black       = Color("Black", "b");
white       = Color("White", "w");
transparent = Color("Blank", " ");

abstract PieceType
type Pawn   <: PieceType end
type Rook   <: PieceType end
type Knight <: PieceType end
type Bishop <: PieceType end
type Queen  <: PieceType end
type King   <: PieceType end
type Blank  <: PieceType end

pawn   = Pawn();
rook   = Rook();
knight = Knight();
bishop = Bishop();
queen  = Queen();
king   = King();
blank  = Blank();

type ChessPiece
  color:: Color
  piece:: PieceType
  printrep:: String
end

bp  = ChessPiece(black, pawn,  "P");
br  = ChessPiece(black, rook,  "R");
bk  = ChessPiece(black, knight,"T")
bb  = ChessPiece(black, bishop,"B");
bq  = ChessPiece(black, queen, "Q");
bki = ChessPiece(black, king,  "K");

wp  = ChessPiece(white, pawn,  "p");
wr  = ChessPiece(white, rook,  "r");
wk  = ChessPiece(white, knight,"t")
wb  = ChessPiece(white, bishop,"b");
wq  = ChessPiece(white, queen, "q");
wki = ChessPiece(white, king,  "k");

bs = ChessPiece(transparent, blank,  " ");

type ChessBoard
   # This must be an 8x8 matrice. That fact shoul
   # be a constraint somewhere
   board::Array{ChessPiece}
end


startingBoardArray = [
  wr wk wb wq wk wb wk wr
  wp wp wp wp wp wp wp wp;
  bs bs bs bs bs bs bs bs;
  bs bs bs bs bs bs bs bs;
  bs bs bs bs bs bs bs bs;
  bs bs bs bs bs bs bs bs;
  bp bp bp bp bp bp bp bp;
  br bk bb bq bk bb bk br;
];

startingBoard = ChessBoard(startingBoardArray)

## XXX This is a very inefficient representation.  Can
 ##     we do better?

## Printing pieces
show(io::IO, cd::ChessPiece) = show(io, cd.printrep)

## Printing chessboards
function show(io::IO, cb::ChessBoard)
 for y1 = 1:8
  y = 9 - y1;
  print(io, y)
   for x = 1:8
       @printf(io, "%s",  cb.board[y, x].printrep)
   end
   println(io, y)
 end
end


##
##  Representing movement
##

type Coord
    x:: Int64 # Should be Uint8!
    y:: Int64
end


function allCoords()
    result = Coord[]
     for y = 1:8, x = 1:8
        c = Coord(x, y)
        push!(result, c)
     end
     return result
end

coords = allCoords()

@test 64 == length(coords)


function getPieceAt(board::ChessBoard, coord::Coord) 
    return board.board(coord.x, coord.y)
end


# Get coordinates for all the pieces of a particular
# color
function getCoordsForPieces(color::Color, board::ChessBoard)
   return filter(c -> (getPieceAt(board, c).color == color), coords)
end


type Move
    start:: Coord
    destination:: Coord
    capture:: Bool
end

 
function getMovesForPiece(piece::PieceType, board::ChessBoard, coord::Coord)
  # To be improved on
  []
end

# From a chessboard, extract all the possible moves for all
# the pieces for a particular color on the board.
# Return an array (a set) of Move instances
function getMoves(color::Color, board::ChessBoard)
   ## This is inelegant, it should be purely functional
   ## set and list processing!
   result = Move[]
   for coord in  getCoordsForPieces(color, board)
     piece = getPieceAt(boarrd, coord)
     movesFromPiece = getMovesForPiece(piece.piecetype, board, coord)
     push!(result, movesFromPiece)
   end
   return result
end

@test 20 == length(getMoves(white, startingBoard))
@test 20 == length(getMoves(black, startingBoard))