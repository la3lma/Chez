##
##  Representing movement
##

type Coord
    x:: Int64 # Should be Uint8!
    y:: Int64
end

type Move
    start:: Coord
    destination:: Coord
    capture:: Bool
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
