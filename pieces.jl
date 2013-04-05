##
## The Chess kata in Julia
##
## The objective is to write a simple minimax/alpha-beta 
## correctly playing chess game.  The purpose behind this
## objective is to do some nontrivial programming in Julia
## just to get a feel for it. Playing strength of the chess
## program is not something I'm very interested in :-)
##



type Color 
   name:: String
   shortName:: String
end

black = Color("Black", "b");
white = Color("White", "w"); 
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


## XXX  Don't know how to make a chessboard
startingBoard = [
 [br, bk, bb, bq, bk, bb, bk, br], 
 [bp, bp, bp, bp, bp, bp, bp, bp], 
 [bs, bs, bs, bs, bs, bs, bs, bs,], 
 [bs, bs, bs, bs, bs, bs, bs, bs,], 
 [bs, bs, bs, bs, bs, bs, bs, bs,], 
 [bs, bs, bs, bs, bs, bs, bs, bs,], 
 [wp, wp, wp, wp, wp, wp, wp, wp], 
 [wr, wk, wb, wq, wk, wb, wk, wr], 
];

# Wring it into the right shape ;)
startingboard=reshape(startingBoard, 8, 8)'

## Once I know how to make a chessboard, I should
## figure out to print one nicely and compactly
