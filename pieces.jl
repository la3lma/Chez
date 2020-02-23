##
## The Chess kata in Julia
##
## The objective is to write a simple minimax/alpha-beta
## correctly playing chess game.  The purpose behind this
## objective is to do some nontrivial programming in Julia
## just to get a feel for it. Playing strength of the chess
## program is not something I'm very interested in :-)
##
## To print chess symbols in unicode.
## https://en.wikipedia.org/wiki/Chess_symbols_in_Unicode

import Base.show
import Base.==
import Base.+
import Base.*

using  Test



struct Color
   name:: String
   shortName:: String
end

function ==(c1::Color, c2::Color)
   isequal(c1.name, c2.name) && isequal(c1.shortName, c2.shortName)
end

@test Color("a","b") == Color("a", "b")
@test Color("a","b") != Color("b", "a")

black       = Color("Black", "b");
white       = Color("White", "w");
transparent = Color("Blank", " ");

@test white == white
@test white != black
@test white != transparent

@test black == black
@test black != white
@test black != transparent

abstract type PieceType end
struct Pawn   <: PieceType end
struct Rook   <: PieceType end
struct Knight <: PieceType end
struct Bishop <: PieceType end
struct Queen  <: PieceType end
struct King   <: PieceType end
struct Blank  <: PieceType end

pawn   = Pawn();
rook   = Rook();
knight = Knight();
bishop = Bishop();
queen  = Queen();
king   = King();
blank  = Blank();

struct ChessPiece
  color:: Color
  piecetype:: PieceType
  printrep:: String
  unicode:: String
end

function ==(cp1::ChessPiece, cp2::ChessPiece)
  return (cp1.color == cp2.color) &&
         (cp1.piecetype == cp2.piecetype) &&
	 (cp1.printrep == cp2.printrep)
end

bp  = ChessPiece(black, pawn,   "P", "♟");
br  = ChessPiece(black, rook,   "R", "♜");
bk  = ChessPiece(black, knight, "G", "♞")
bb  = ChessPiece(black, bishop, "B", "♝");
bq  = ChessPiece(black, queen,  "Q", "♛");
bki = ChessPiece(black, king,   "K", "♚");

wp  = ChessPiece(white, pawn,   "p", "♙");
wr  = ChessPiece(white, rook,   "r", "♖");
wk  = ChessPiece(white, knight, "g", "♘");
wb  = ChessPiece(white, bishop, "b", "♗");
wq  = Chesspiece(white, queen,  "q", "♕");
wki = ChessPiece(white, king,   "k", "♔");

bs = ChessPiece(transparent, blank,  " ",  " ");

## Printing pieces
show(io::IO, cd::ChessPiece) = show(io, cd.printrep)
