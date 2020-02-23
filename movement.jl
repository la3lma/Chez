
###
###  Representing movement
###

function get_all_coords()
    result = Coord[]
     for y = 1:8, x = 1:8
        c = Coord(x, y)
        push!(result, c)
     end
     return result
end

coords = get_all_coords()

@test 64 == length(coords)

# Get coordinates for all the pieces of a particular
# color
function get_coords_for_pieces(color::Color, board::ChessBoard)
   return filter(c -> (getPieceAt(board, c).color == color), coords)
end

# Representing moves
struct Move
    start:: Coord
    destination:: Coord
    capture:: Bool
    startPiece:: ChessPiece
    destinationPiece:: ChessPiece
    # XXX Must include a field stating if it's a chess or not
end

# Take a look at http://en.wikipedia.org/wiki/Chess_notation, Print moves
# in an orderly proficient algebraic or long algebraic manner.

# The two implementations below are not really conformant

# Standard Algebraic Notation (SAN)
function move_as_san(m::Move)
    capture = m.capture ? "x" : ""
    return @sprintf("%s%s%s%s", m.startPiece.printrep, m.start, capture, m.destination)
end

# Figurine Algebraic Notation (FAN)
function move_as_san(m::Move)
    capture = m.capture ? "x" : ""
    return @sprintf("%s%s%s%s", m.startPiece.unicode, m.start, capture, m.destination)
end



show(io::IO, m::Move) = show(io, move_as_san(m))


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

function get_moves_from_ray(
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

function get_moves_from_rays(generators::Array{Coord, 1}, color::Color, board::ChessBoard, coord::Coord, oneStepOnly::Bool = false)
    return [ get_moves_from_ray(gen, color, board, coord, oneStepOnly) for gen in generators]
end

bishop_ray_generators = [Coord(1,1), Coord(-1,-1), Coord(-1, 1), Coord(1, -1)]

function get_moves_for_piece(piece::Bishop, color::Color,  board::ChessBoard, coord::Coord)
	 get_moves_from_rays(bishop_ray_generators, color, board, coord)
end

rook_ray_generators = [Coord(0,1), Coord(0,-1), Coord(1, 0), Coord(-1, 0)]

function get_moves_for_piece(piece::Rook, color::Color,  board::ChessBoard, coord::Coord)
	 get_moves_from_rays(rook_ray_generators, color, board, coord)
end


flatten_moves(x) = x |> Iterators.flatten |> collect

function get_royal_moves(color::Color, board::ChessBoard, coord::Coord,
    oneStepOnly::Bool = false) return flatten_moves(
    [get_moves_from_rays(bishop_ray_generators, color, board, coord,
    oneStepOnly), get_moves_from_rays(rook_ray_generators, color, board,
    coord, oneStepOnly)]) end

is_legal_king_move(move::Move, board::ChessBoard) = false

get_moves_for_piece(piece::Queen, color::Color,  board::ChessBoard, coord::Coord) =  get_royal_moves(color, board, coord, false)
get_moves_for_piece(piece::King, color::Color,  board::ChessBoard, coord::Coord) =
      flatten_moves(get_royal_moves(color, board, coord, true)) |>   moves -> filter(m->is_legal_king_move(m, board), moves)


knightJumps = [Coord(-2, 1), Coord(2, 1),   Coord(1, 2),    Coord(-1, 2),
 	       Coord(2, -1), Coord(-2, -1), Coord(-1, -2),  Coord(1, -2)]

function get_moves_for_piece(piece::Knight, color::Color, board::ChessBoard, coord::Coord)
    moves_from_jumps(board, coord, knightJumps, false)
end


# this test shouldn't depend on the order of items in the list, it should treat
# this as a test for collection equality
@test [ Move(b1, c3, false, wk, bs), Move(b1, a3, false, wk, bs)] == get_moves_for_piece(wk.piecetype, white,  startingBoard, b1)


pawn_start_line(color::Color) =  (color == black) ? 7 : 2
finish_line(color::Color)    =  (color == black) ? 1 : 8


function get_moves_for_piece(piece::Pawn, color::Color,  board::ChessBoard, coord::Coord)
  # First we establish a jump direction that is color dependent
  # (for pawns only)
  speed = (color == white) ? 1 : -1

  # Then we establish a single non-capturing movement ray
  if  (coord.y == pawn_start_line(color))
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

  moves = filter(move_is_valid, moves) #Kludge

  # Finally we do the pawn-specific tranformation
  # if we find ourself ending up on the finishing line
  for move in moves
      if (move.destination.y == finish_line(color))
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
get_moves(color::Color, board::ChessBoard) =
    filter(m -> m isa Move, flatten_moves([get_moves_for_piece(getPieceAt(startingBoard, c).piecetype, color, startingBoard, c)
                               for c in get_coords_for_pieces(color,startingBoard)]))



# All the opening moves for pawns and horses
@test 20 == length(get_moves(white, startingBoard))
@test 20 == length(get_moves(black, startingBoard))
