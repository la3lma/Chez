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

function ==(c1::Color, c2::Color)
   c1.name == c2.name && c1.shortName == c2.shortName
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
  piecetype:: PieceType
  printrep:: String
end

function ==(cp1::ChessPiece, cp2::ChessPiece)
  return (cp1.color == cp2.color) &&
         (cp1.piecetype == cp2.piecetype) &&
	 (cp1.printrep == cp2.printrep)
end

bp  = ChessPiece(black, pawn,  "P");
br  = ChessPiece(black, rook,  "R");
bk  = ChessPiece(black, knight,"g")
bb  = ChessPiece(black, bishop,"B");
bq  = ChessPiece(black, queen, "Q");
bki = ChessPiece(black, king,  "K");

wp  = ChessPiece(white, pawn,  "p");
wr  = ChessPiece(white, rook,  "r");
wk  = ChessPiece(white, knight,"g")
wb  = ChessPiece(white, bishop,"b");
wq  = ChessPiece(white, queen, "q");
wki = ChessPiece(white, king,  "k");

bs = ChessPiece(transparent, blank,  " ");

## Printing pieces
show(io::IO, cd::ChessPiece) = show(io, cd.printrep)


type ChessBoard
   # This must be an 8x8 matrice. That fact shoul
   # be a constraint somewhere
   board::Array{ChessPiece}
end

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


# Constructing an initial chessboard
startingBoardArray = [
  wr wk wb wq wki wb wk wr;
  wp wp wp wp wp  wp wp wp;
  bs bs bs bs bs  bs bs bs;
  bs bs bs bs bs  bs bs bs;
  bs bs bs bs bs  bs bs bs;
  bs bs bs bs bs  bs bs bs;
  bp bp bp bp bp  bp bp bp;
  br bk bb bq bki bb bk br;
];

startingBoard = ChessBoard(startingBoardArray)

type Coord
    x:: Int64 # Should be Uint8!
    y:: Int64
end

function intToChessLetter(i::Integer)
    # This cries out for using a table etc.
    if (i == 1)
        return "a"
    elseif (i == 2)
        return "b"
    elseif (i == 3)
        return "c"
    elseif (i == 4)
        return "d"
    elseif (i == 5)
        return "e"
    elseif (i == 6)
        return "f"
    elseif (i == 7)
        return "g"
    elseif (i == 8)
        return "h"
    else
        return "X"
    end
end

@test intToChessLetter(1) == "a"
@test intToChessLetter(8) == "h"
@test intToChessLetter(81) == "X"

## Printing a coordinate
function show(io::IO, m::Coord)
   # If it's a valid coordinate, use chess notation
   if (isValidCoord(m))
      @printf(io, "%s%d", intToChessLetter(m.x), m.y)
   else
      # If not then use coordinate notation. 
      @printf(io, "Coord(%d, %d)", m.x, m.y)
   end
end

## All coordinates, expanded for convenience
a1=Coord(1,1)
a2=Coord(1,2)
a3=Coord(1,3)
a4=Coord(1,4)
a5=Coord(1,5)
a6=Coord(1,6)
a7=Coord(1,7)
a8=Coord(1,8)

b1=Coord(2,1)
b2=Coord(2,2)
b3=Coord(2,3)
b4=Coord(2,4)
b5=Coord(2,5)
b6=Coord(2,6)
b7=Coord(2,7)
b8=Coord(2,8)


c1=Coord(3,1)
c2=Coord(3,2)
c3=Coord(3,3)
c4=Coord(3,4)
c5=Coord(3,5)
c6=Coord(3,6)
c7=Coord(3,7)
c8=Coord(3,8)

d1=Coord(4,1)
d2=Coord(4,2)
d3=Coord(4,3)
d4=Coord(4,4)
d5=Coord(4,5)
d6=Coord(4,6)
d7=Coord(4,7)
d8=Coord(4,8)

e1=Coord(5,1)
e2=Coord(5,2)
e3=Coord(5,3)
e4=Coord(5,4)
e5=Coord(5,5)
e6=Coord(5,6)
e7=Coord(5,7)
e8=Coord(5,8)

f1=Coord(6,1)
f2=Coord(6,2)
f3=Coord(6,3)
f4=Coord(6,4)
f5=Coord(6,5)
f6=Coord(6,6)
f7=Coord(6,7)
f8=Coord(6,8)

g1=Coord(7,1)
g2=Coord(7,2)
g3=Coord(7,3)
g4=Coord(7,4)
g5=Coord(7,5)
g6=Coord(7,6)
g7=Coord(7,7)
g8=Coord(7,8)

h1=Coord(8,1)
h2=Coord(8,2)
h3=Coord(8,3)
h4=Coord(8,4)
h5=Coord(8,5)
h6=Coord(8,6)
h7=Coord(8,7)
h8=Coord(8,8)


# Coordinates are linear, so we must define addition of coordinates
# and and multiplication of coordinates with numbers.

+(c1::Coord, c2::Coord) = Coord(c1.x + c2.x, c1.y + c2.y)
*(n::Number, c::Coord)  = Coord(n * c.x, n * c.y)
*(c::Coord,  n::Number) = n * c
==(c1::Coord, c2::Coord) = (c1.x == c2.x && c1.y == c2.y)

@test Coord(3,3) == Coord(1,1) + Coord(2,2)
@test Coord(4,4) ==  2 * Coord(2,2)

# For the chessboard only ordinates in the range [1..8] are
# valid, so we add some predicates to test for that 
isValidOrdinate(c::Int)  =  1 <= c && c <= 8

@test !isValidOrdinate(0)
@test  isValidOrdinate(1)
@test  isValidOrdinate(8)
@test !isValidOrdinate(9)

function isValidCoord(coord::Coord) 
   isValidOrdinate(coord.x) && isValidOrdinate(coord.y)
end

@test isValidCoord(Coord(1,1))
@test isValidCoord(Coord(1,2))
@test isValidCoord(Coord(1,3))
@test !isValidCoord(Coord(0,2))
@test !isValidCoord(Coord(1,0))

function getPieceAt(board::ChessBoard, coord::Coord)
    return board.board[coord.y, coord.x]
end

# Check that the coordinates are not messed up
@test getPieceAt(startingBoard, Coord(1,1)) == wr
@test getPieceAt(startingBoard, Coord(2,1)) == wk
@test getPieceAt(startingBoard, Coord(5,1)) == wki
@test getPieceAt(startingBoard, Coord(4,1)) == wq
@test getPieceAt(startingBoard, Coord(4,2)) == wp

##
##  Representing movement
##

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

# Get coordinates for all the pieces of a particular
# color
function getCoordsForPieces(color::Color, board::ChessBoard)
   return filter(c -> (getPieceAt(board, c).color == color), coords)
end

# Representing moves

type Move
    start:: Coord
    destination:: Coord
    capture:: Bool # XXX Redundant!
    startPiece:: ChessPiece
    destinationPiece:: ChessPiece
end

# Take a look at http://en.wikipedia.org/wiki/Chess_notation, print moves
# in an orderly proficient algebraic or long algebraic manner.

function ==(m1::Move, m2::Move)
     return (m1.start == m2.start) &&
            (m1.destination == m2.destination) &&
	    (m1.capture == m2.capture) &&
	    (m1.startPiece == m2.startPiece) &&
	    (m1.destinationPiece == m2.destinationPiece)
end


function validMoves(moves::Array{Move, 1})
     filter(m -> isValidCoord(m.destination), moves)
end


function moveFromJump(board::ChessBoard, start::Coord, jump::Coord; requireCaptures::Bool = false)
    destination = start + jump

    if (!isValidCoord(destination))
        return null
     end

     destinationPiece = getPieceAt(board, destination)
     startPiece = getPieceAt(board, start)

     isLegalMove = destinationPiece.color != startPiece.color
     isCapture = isLegalMove && (destinationPiece.color != transparent)

     if (!isLegalMove)
        return null
     elseif (requireCaptures)
          if (isCapture)
	    return Move(start, destination, isCapture, startPiece, destinationPiece)
	  else
	    return null
          end
     else
          return Move(start, destination, isCapture, startPiece, destinationPiece)
     end
end

# Test movement of a single pawn
@test Move(a2, a3, false, wp, bs) == moveFromJump(startingBoard, a2, Coord(0,1))


function movesFromJumps(board::ChessBoard, start::Coord, jumps::Array{Coord,1}, requireCaptures::Bool)
#    map(j ->
#	  moveFromJump(board, start, j, requireCaptures = requireCaptures),
#        jumps)
    #  XXX I don't understand why the code above fails and the code below works.
    result = []
    for j in jumps
       move = moveFromJump(board, start, j; requireCaptures = requireCaptures)
       if (move != null)
           result = [result..., move]
       end
    end
    return result
end

@test [ Move(a2, a3, false, wp, bs)]   == movesFromJumps(startingBoard, a2,[Coord(0,1)], false)

function getMovesForPiece(piece::PieceType, color::Color,  board::ChessBoard, coord::Coord)
  []
end

function getMovesForPiece(piece::Blank, board::ChessBoard, coord::Coord)
  []  # Arguably, this should throw an exception instead, or return null.
end





# Rooks, kings, bishops are all made up by
# rays and filtering.


function getMovesFromRays(generators::Array{Coord, 1}, color::Color, board::ChessBoard, coord::Coord; oneStepOnly::Bool = false)
    []
end

bishopRayGenerators = [Coord(1,1), Coord(-1,-1), Coord(-1, 1), Coord(1, -1)]

function getMovesForPiece(piece::Bishop, color::Color,  board::ChessBoard, coord::Coord)
	 getMovesFromRays(bishopRayGenerators, color, board, coord)
end

rookRayGenerators = [Coord(0,1), Coord(0,-1), Coord(1, 0), Coord(-1, 0)]

function getMovesForPiece(piece::Rook, color::Color,  board::ChessBoard, coord::Coord)
	 getMovesFromRays(rookRayGenerators, color, board, coord)
end


function getRoyalMoves(color::Color,  board::ChessBoard, coord::Coord; oneStepOnly::Bool = false)
   flatten([getMovesFromRays(bishopRayGenerators, color, board, coord; oneStepOnly = oneStepOnly), 
            getMovesFromRays(rookRayGenerators, color, board, coord; oneStepOnly = oneStepOnly)])
end

function getMovesForPiece(piece::Queen, color::Color,  board::ChessBoard, coord::Coord)
   getRoyalMoves(color, board, coord; oneStepOnly=false)
end

# XXX Return true iff the move represents a legal move for a king
#     (don't get too close to a king on the board essentially, check 
#      detection is not implemented at this level).
function islegalKingMove(move::Move, board::ChessBoard) 
  false
end

function getMovesForPiece(piece::King, color::Color,  board::ChessBoard, coord::Coord)
   moves = getRoyalMoves(color, board, coord; oneStepOnly=true)
   filter(m->isLegalKingMove(m, board), moves)
end

knightJumps = [Coord(-2, 1), Coord(2, 1),   Coord(1, 2),    Coord(-1, 2),
 	       Coord(2, -1), Coord(-2, -1), Coord(-1, -2),  Coord(1, -2)]

function getMovesForPiece(piece::Knight, color::Color, board::ChessBoard, coord::Coord)
    movesFromJumps(board, coord, knightJumps, false)
end


# this test shouldn't depend on the order of items in the list, it should treat
# this as a test for collection equality
@test [ Move(b1, c3, false, wk, bs), Move(b1, a3, false, wk, bs)] == getMovesForPiece(wk.piecetype, white,  startingBoard, b1)


pawnStartLine(color::Color) =  (color == black) ? 7 : 2
finishLine(color::Color)    =  (color == black) ? 1 : 8


function getMovesForPiece(piece::Pawn, color::Color,  board::ChessBoard, coord::Coord)
  # First we establish a jump speed that is color dependent
  # (for pawns only)
  speed = (color == white) ? 1 : -1

  # Then we establish a single non-capturing movement ray
  if  (coord.y == pawnStartLine(color))
     ncray = [Coord(0,speed), 2 * Coord(0, speed)]
  else
     ncray = [Coord(0,speed)]
  end

  # And a set of possibly capturing jumps
  captureJumps = [Coord(1,speed), Coord(-1, speed)]

  # Then we have to process these alternatives
  # to check that they are inside the board etc.
  # XXX Just use flatten instead?
  moves = union([movesFromJumps(board, coord, ncray, false),
    		 movesFromJumps(board, coord, captureJumps, true)])
  moves = filter(m -> m != null, moves) #Kludge

  # Finally we do the pawn-specific tranformation
  # if we find ourself ending up on the finishing line
  for move in moves
      if (move.destination.y == finishLine(color))
	 move.piece = queenOfColor(color)
      end
  end
  return moves
end

@test 2 == length(getMovesForPiece(pawn,   white, startingBoard, a2))
@test 2 == length(getMovesForPiece(knight, white, startingBoard, b1))

# From the intertubes
flatten{T}(a::Array{T,1}) = any(map(x->isa(x,Array),a))? flatten(vcat(map(flatten,a)...)): a
flatten{T}(a::Array{T}) = reshape(a,prod(size(a)))
flatten(a)=a

# From a chessboard, extract all the possible moves for all
# the pieces for a particular color on the board.
# Return an array (a set) of Move instances
function getMoves(color::Color, board::ChessBoard)
	    flatten( union({ getMovesForPiece(getPieceAt(startingBoard, c).piecetype, color, startingBoard, c)
                for c=getCoordsForPieces(color,startingBoard)
         }))
end

# All the opening moves for pawns
@test 20 == length(getMoves(white, startingBoard))
@test 20 == length(getMoves(black, startingBoard))

