using ImmutableArrays
immutable Plane{T}
	point::Vector3{T}
	normal::Vector3{T}
end
immutable Line{T}
	p0::Vector3{T}
	p1::Vector3{T}
end

function intersect(a::Plane, b::Plane)
	local const equals_zero = 0.0
	#Find the direction for the line equation
	dir = cross(a.normal, b.normal)
	if all(x-> x <= equals_zero, dir)
		return Line(Vector3(0.0), Vector3(0.0))
	else
		#finding the point for the line equation
		#We can leave out the maximum non zero dimension to solve the equation
		maxdim 	= indmax(dir)
		dims 	= [1,2,3] 
		splice!(dims, maxdim)
		d1 = -dot(a.normal, a.point)
    	d2 = -dot(b.normal, b.point)
    	x = y = z = 0.0
    	if maxdim == 1
    		y = (d2*a.normal[3] - d1*b.normal[3]) / dir[maxdim]
    		z = (d1*b.normal[2] - d2*a.normal[2]) / dir[maxdim]
    	elseif maxdim == 2
    		x = (d1*b.normal[3] - d2*a.normal[3]) / dir[maxdim]
    		z = (d2*a.normal[1] - d1*b.normal[1]) / dir[maxdim]
    	elseif maxdim == 3
    		x = (d2*a.normal[2] - d1*b.normal[2]) / dir[maxdim]
    		y = (d1*b.normal[1] - d2*a.normal[1]) / dir[maxdim]
    	end
    	return Line(dir / norm(dir), Vector3(x,y,z))
	end
end


function LineLineIntersect(p1::Vector3, p2::Vector3, p3::Vector3, p4::Vector3)

	p13 	= p1 - p3
	b_direction 	= p4 - p3

	if abs(b_direction[1]) < eps(0.0) && abs(b_direction[2]) < eps(0.0) && abs(b_direction[3]) < eps(0.0)
		return -1.0
	end
	a_direction = p2 - p1
	if abs(a_direction[1]) < eps(0.0) && abs(a_direction[2]) < eps(0.0) && abs(a_direction[3]) < eps(0.0)
		return -1.0
	end

	d1343 = dot(p13, b_direction)
	d4321 = dot(b_direction, a_direction)
	d1321 = dot(p13, a_direction)
	d4343 = dot(b_direction, b_direction)
	d2121 = dot(a_direction, a_direction)

	denom = d2121 * d4343 - d4321 * d4321
	if abs(denom) < eps(0.0)
		return -1.0
	end
	numer = d1343 * d4321 - d1321 * d4343

	mua = (numer / denom) 
	return (mua, p1 + mua * a_direction)
	#=
	mub = (d1343 + d4321 * (mua)) / d4343


	pa = p1 + mua * a_direction
	pb = p3 + mub * b_direction

	return pa, pb
	=#
end
function intersect(p0::Vector3, p1::Vector3, pn::Plane)
    u = p1 - p0
    w = p0 - pn.point

    D = dot(pn.normal, u)
   	N = -dot(pn.normal, w)

    if abs(D) < eps(0.0)        		# segment is parallel to plane
        if N == 0               		# segment lies in plane
            return (-1 , Vector3(0.0))    
        else 							# no intersection
            return (-2 , Vector3(0.0))    			
        end      
    end
    # they are not parallel
    # compute intersect param
    sI = N / D
    if sI < 0.0 || sI > 1.0
        return (-3 , Vector3(0.0)) 	# no intersection
    end
    I = p0 + sI * u           		# compute segment intersect point
    return (sI , I)
end

function cut_triangle()

function cut_triangles!{T <: Real}(p1::Vector3{T}, p2::Vector3{T}, p3::Vector3{T}, plane::Plane)

	intersected, intersection = intersect(p0, p1, plane)
	if intersected == 0.0
		push!(result, p0)
	elseif intersected == 1.0
		push!(result, p0, p1)
	elseif intersected > 0.0
		push!(result, intersection)
		push!(intersects, intersection)

		side = dot( plane.normal, p1 - p0)
		if side < 0
			push!(result, p0)
		elseif side > 0
			push!(result, p1)
		else
			error("Somethings fishy... I need to rethink my Math")
		end
	end
	@assert length(result) >= 3 && length(result) <= 5
	result, intersects
end
function planemeshcut(points::Vector{Float32}, indexes::Vector{GLuint}, plane::Plane)
	for i=1:length(indexes) / 3
		a,b,c = 
	end
end

points = [Vector3(0,0,0), Vector3(0,0,1), Vector3(1,0,1, Vector3(1,0,0)]
plane =  Plane(Vector3(0.8, 0.0, 0.8), Vector3(-1.0,0.0,-1.0))
@show planequadcut(points, plane)