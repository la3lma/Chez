
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
struct Move
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
        return nothing
     end

     destinationPiece = getPieceAt(board, destination)
     startPiece = getPieceAt(board, start)

     isLegalMove = destinationPiece.color != startPiece.color
     isCapture = isLegalMove && (destinationPiece.color != transparent)

     if (!isLegalMove)
        return nothing
     elseif (requireCaptures)
          if (isCapture)
	    return Move(start, destination, isCapture, startPiece, destinationPiece)
	  else
	    return nothing
          end
     else
          return Move(start, destination, isCapture, startPiece, destinationPiece)
     end
end

# Test movement of a single pawn
@test Move(a2, a3, false, wp, bs) == moveFromJump(startingBoard, a2, Coord(0,1))


## XXX Much too permissive, so just placeholder
move_is_defined(m) = true

function movesFromJumps(board::ChessBoard, start::Coord, jumps::Array{Coord,1}, requireCaptures::Bool)
#    map(j ->
#	  moveFromJump(board, start, j, requireCaptures = requireCaptures),
#        jumps)
    #  XXX I don't understand why the code above fails and the code below works.
    result = []
    for j in jumps
        move = moveFromJump(board, start, j; requireCaptures = requireCaptures)

        print(stdout, "TBD")
        # @printf(STDOUT, "  generated move = %s)", move)
        if (move_is_defined(move))
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
  []  # Arguably, this should throw an exception instead, or return nothing.
end



# Rooks, kings, bishops are all made up by
# rays and filtering.

function getMovesFromRay(
	 generator::Coord,
	 color::Color,
	 board::ChessBoard,
	 start::Coord,
	 oneStepOnly::Bool)
    local destination = start + generator
    local result = []
    local capture=false
    local startPiece = getPieceAt(board, start)
    while (isValidCoord(destination) && !capture)
        local destinationPiece = getPieceAt(board, destination)
	if (destinationPiece.color == startPiece.color)
          break
        end
	capture = (bs != destinationPiece)
        local move = Move(start, destination, capture, startPiece, destinationPiece)
	result = [result ..., move]
	if (!oneStepOnly)
	   destination +=  generator;
        else
           break
        end
    end
    return result
end

function getMovesFromRays(generators::Array{Coord, 1}, color::Color, board::ChessBoard, coord::Coord; oneStepOnly::Bool = false)
    return [ getMovesFromRay(gen, color, board, coord, oneStepOnly) for gen in generators]
end

bishopRayGenerators = [Coord(1,1), Coord(-1,-1), Coord(-1, 1), Coord(1, -1)]

function getMovesForPiece(piece::Bishop, color::Color,  board::ChessBoard, coord::Coord)
	 getMovesFromRays(bishopRayGenerators, color, board, coord)
end

rookRayGenerators = [Coord(0,1), Coord(0,-1), Coord(1, 0), Coord(-1, 0)]

function getMovesForPiece(piece::Rook, color::Color,  board::ChessBoard, coord::Coord)
	 getMovesFromRays(rookRayGenerators, color, board, coord)
end


flatten_moves(x) = x |> Iterators.flatten |> collect

function getRoyalMoves(color::Color,  board::ChessBoard, coord::Coord; oneStepOnly::Bool = false)
    return flatten_moves([getMovesFromRays(bishopRayGenerators, color, board, coord; oneStepOnly = oneStepOnly),
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
  moves = filter(m -> move_is_defined(m), moves) #Kludge

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


# From a chessboard, extract all the possible moves for all
# the pieces for a particular color on the board.
# Return an array (a set) of Move instances
function getMoves(color::Color, board::ChessBoard)
	             flatten_moves(
                         union({ getMovesForPiece(getPieceAt(startingBoard, c).piecetype, color, startingBoard, c)
                for c=getCoordsForPieces(color,startingBoard)
         }))
end

# All the opening moves for pawns and horses
@test 20 == length(getMoves(white, startingBoard))
@test 20 == length(getMoves(black, startingBoard))
