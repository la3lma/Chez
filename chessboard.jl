###
###  Representing and printing the chessboard
###


using Printf

struct ChessBoard
   board::Array{ChessPiece}
end


## Printing chessboards
function show(io::IO, cb::ChessBoard)
 for y1  in  1:8
  y = 9 - y1
  print(io, y)
  for x in  1:8
     @printf(io, "%s",  cb.board[y, x].unicode)
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

@test show(stdout, startingBoard) == nothing

struct Coord
    x:: Int8
    y:: Int8
end

function intToChessLetter(i::Integer)
    # This cries out for using a table etc.
    if isequal(i, 1)
        return "a"
    elseif isequal(i, 2)
        return "b"
    elseif isequal(i, 3)
        return "c"
    elseif isequal(i, 4)
        return "d"
    elseif isequal(i, 5)
        return "e"
    elseif isequal(i, 6)
        return "f"
    elseif isequal(i, 7)
        return "g"
    elseif isequal(i, 8)
        return "h"
    else
        return "X"
    end
end

@test isequal(intToChessLetter(1), "a")
@test isequal(intToChessLetter(8), "h")
@test isequal(intToChessLetter(81), "X")

# For the chessboard only ordinates in the range [1..8] are
# valid, so we add some predicates to test for that
isValidOrdinate(c)  =  1 <= c && c <= 8

@test !isValidOrdinate(0)
@test  isValidOrdinate(1)
@test  isValidOrdinate(8)
@test !isValidOrdinate(9)

# A coordinate is valid only when its ordinates are
function isValidCoord(coord::Coord)
   isValidOrdinate(coord.x) && isValidOrdinate(coord.y)
end


## Printing a coordinate

# If it's a valid coordinate, use chess notation, otherwise print as coordinate
function coord_to_string(m::Coord)
    if (isValidCoord(m))
        return @sprintf("%s%d", intToChessLetter(m.x), m.y)
    else
        return @sprintf("Coord(%d, %d)", m.x, m.y)
    end
end

@test coord_to_string(Coord(8,8)) == "h8"
@test coord_to_string(Coord(8,9)) == "Coord(8, 9)"


function show(io::IO, m::Coord)

    print(io, coord_to_string(m))
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

#
# Treat the set of coordinates as a linear space.
#
+(c1::Coord, c2::Coord) = Coord(c1.x + c2.x, c1.y + c2.y)
*(n::Number, c::Coord)  = Coord(n * c.x, n * c.y)
*(c::Coord,  n::Number) = n * c

#
# Define coordinate equality

==(c1::Coord, c2::Coord) = (c1.x == c2.x && c1.y == c2.y)

@test Coord(3,3) == (Coord(1,1) + Coord(2,2))
@test Coord(4,4) ==  2 * Coord(2,2)


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

