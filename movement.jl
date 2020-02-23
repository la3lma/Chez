
###
###  Representing movement
###

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
    capture:: Bool
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


move_is_valid(::Nothing) = false
move_is_valid(m::Move)   = isValidCoord(m.destination)

function validMoves(moves::Array{Move, 1})
     filter(move_is_valid, moves)
end


function move_from_jump(board::ChessBoard, start::Coord, jump::Coord, requireCapture::Bool = false)
    destination = start + jump

    if (!isValidCoord(destination))
        return nothing
    end

    destinationPiece = getPieceAt(board, destination)
    startPiece = getPieceAt(board, start)

    isLegalMove = destinationPiece.color != startPiece.color
    isCapture = isLegalMove && (destinationPiece.color != transparent)

    if (!isLegalMove || (requireCapture && !isCapture))
       return nothing
    else
       return Move(start, destination, isCapture, startPiece, destinationPiece)
    end
end

# Test movement of a single pawn
@test Move(a2, a3, false, wp, bs) == move_from_jump(startingBoard, a2, Coord(0,1))


function moves_from_jumps(board::ChessBoard, start::Coord, jumps::Array{Coord,1}, requireCaptures::Bool)
    candidates =  [ move_from_jump(board, start, j, requireCaptures) for j in jumps ]
    return filter(move_is_valid, candidates)
end

@test [ Move(a2, a3, false, wp, bs)]   == moves_from_jumps(startingBoard, a2,[Coord(0,1)], false)

function get_moves_for_piece(piece::PieceType, color::Color,  board::ChessBoard, coord::Coord)
  []
end

function get_moves_for_piece(piece::Blank, board::ChessBoard, coord::Coord)
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

    destination = start + generator
    result = []
    capture=false
    startPiece = getPieceAt(board, start)

    while (isValidCoord(destination) && !capture)
        destinationPiece = getPieceAt(board, destination)
	if (destinationPiece.color == startPiece.color)
          break
        end

	capture = (bs != destinationPiece)
        move = Move(start, destination, capture, startPiece, destinationPiece)
        push!(result, move)

	if (!oneStepOnly)
	   destination +=  generator
        else
           break
        end
    end
    return result
end

function getMovesFromRays(generators::Array{Coord, 1}, color::Color, board::ChessBoard, coord::Coord, oneStepOnly::Bool = false)
    return [ getMovesFromRay(gen, color, board, coord, oneStepOnly) for gen in generators]
end

bishopRayGenerators = [Coord(1,1), Coord(-1,-1), Coord(-1, 1), Coord(1, -1)]

function get_moves_for_piece(piece::Bishop, color::Color,  board::ChessBoard, coord::Coord)
	 getMovesFromRays(bishopRayGenerators, color, board, coord)
end

rookRayGenerators = [Coord(0,1), Coord(0,-1), Coord(1, 0), Coord(-1, 0)]

function get_moves_for_piece(piece::Rook, color::Color,  board::ChessBoard, coord::Coord)
	 getMovesFromRays(rookRayGenerators, color, board, coord)
end


flatten_moves(x) = x |> Iterators.flatten |> collect

function getRoyalMoves(color::Color, board::ChessBoard, coord::Coord,
    oneStepOnly::Bool = false) return flatten_moves(
    [getMovesFromRays(bishopRayGenerators, color, board, coord,
    oneStepOnly), getMovesFromRays(rookRayGenerators, color, board,
    coord, oneStepOnly)]) end

is_legal_king_move(move::Move, board::ChessBoard) = false

get_moves_for_piece(piece::Queen, color::Color,  board::ChessBoard, coord::Coord) =  getRoyalMoves(color, board, coord, false)
get_moves_for_piece(piece::King, color::Color,  board::ChessBoard, coord::Coord) =
      flatten_moves(getRoyalMoves(color, board, coord, true)) |>   moves -> filter(m->is_legal_king_move(m, board), moves)


knightJumps = [Coord(-2, 1), Coord(2, 1),   Coord(1, 2),    Coord(-1, 2),
 	       Coord(2, -1), Coord(-2, -1), Coord(-1, -2),  Coord(1, -2)]

function get_moves_for_piece(piece::Knight, color::Color, board::ChessBoard, coord::Coord)
    moves_from_jumps(board, coord, knightJumps, false)
end


# this test shouldn't depend on the order of items in the list, it should treat
# this as a test for collection equality
@test [ Move(b1, c3, false, wk, bs), Move(b1, a3, false, wk, bs)] == get_moves_for_piece(wk.piecetype, white,  startingBoard, b1)


pawnStartLine(color::Color) =  (color == black) ? 7 : 2
finishLine(color::Color)    =  (color == black) ? 1 : 8


function get_moves_for_piece(piece::Pawn, color::Color,  board::ChessBoard, coord::Coord)
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
  moves = flatten_moves(vcat([moves_from_jumps(board, coord, ncray, false),
    		moves_from_jumps(board, coord, captureJumps, true)]))

  println("moves = ", moves)
  moves = filter(move_is_valid, moves) #Kludge

  # Finally we do the pawn-specific tranformation
  # if we find ourself ending up on the finishing line
  for move in moves
      if (move.destination.y == finishLine(color))
	 move.piece = queenOfColor(color)
      end
  end
  return moves
end

@test 2 == length(get_moves_for_piece(pawn,   white, startingBoard, a2))
@test 2 == length(get_moves_for_piece(knight, white, startingBoard, b1))


# From a chessboard, extract all the possible moves for all
# the pieces for a particular color on the board.
# Return an array (a set) of Move instances
function getMoves(color::Color, board::ChessBoard)
   return  [get_moves_for_piece(getPieceAt(startingBoard, c).piecetype, color, startingBoard, c)
                               for c in getCoordsForPieces(color,startingBoard)]

end

# All the opening moves for pawns and horses
@test 20 == length(getMoves(white, startingBoard))
@test 20 == length(getMoves(black, startingBoard))
