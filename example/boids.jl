#----------------------------------------------------------------------
# Boids algorithm visualization
# Based on pseudocode at http://www.kfish.org/boids/pseudocode.html
# Simulate flocking birds using simple rules.
# Initial version developed and contributed by Iain Dunning (@IainNZ)
# as part of the JuliaCon 2015 workshop
# TODO:
# - Add interactivity for parameters that govern behavior.
# - Add a force that attracts to mouse pointer.
#----------------------------------------------------------------------
using Reactive, GeometryTypes, GLAbstraction, GLPlot, GLVisualize, Colors, ColorTypes

typealias Position Point{2, Float32}
typealias Velocity Vec{2, Float32}

immutable Boids
    position::Vector{Position}
    velocity::Vector{Velocity}
end

# Create new boid at random location and velocity
Boids(n = 200) = Boids([rand(Position) for i=1:n], [rand(Velocity)/1000 for i=1:n])

#----------------------------------------------------------------------

function simulate!(t, boids)
    len = Float32(length(boids.position))
    boid_center = sum(boids.position)/len
    @inbounds for (i, vel) in enumerate(boids.velocity)
        boids.velocity[i] = vel + Vec(boid_center - boids.position[i])/600
    end

    # Force 2: Avoid others
    @inbounds for (i, boidpos) in enumerate(boids.position)
        avoidance = zero(Velocity)
        for (j, other_boidpos) in enumerate(boids.position)
            i == j && continue
            if norm(boidpos - other_boidpos) <= 0.2
                avoidance -= Vec(other_boidpos - boidpos)
            end
        end
        bvel = boids.velocity[i]
        boids.velocity[i] = bvel + (avoidance/1000f0)
    end
    @inbounds for (i, bvel) in enumerate(boids.velocity)
        perceived_vel = zero(Velocity)
        for (j, other_boidvel) in enumerate(boids.velocity)
            i == j && continue
            perceived_vel += other_boidvel
        end
        perceived_vel /= len-1f0
        boids.velocity[i] = bvel + (perceived_vel - bvel)/900f0
    end
    # Limit max velocity
    MAXVEL = 0.5f0
    @inbounds for (i, vel) in boids.velocity
        absvel = norm(vel)
        if absvel >= MAXVEL
            boids.velocity[i] = vel / absvel*MAXVEL
        end
    end
    # Update positions
    @inbounds for (i, vel) in enumerate(boids.velocity)
        boids.position[i] = boids.position[i] + Point(vel)
    end
    boids.position, boids.velocity
end
Base.clamp{T}(x::T) = clamp(x, zero(T), one(T))

to_color(velocities, mul) = RGBA{N0f8}[RGBA{N0f8}(clamp(velocity[1]*mul), clamp(velocity[2]*mul), 1.0, 0.8) for velocity in velocities]
function main()
    # Create population of boids
    boids = Boids()
    pv = map(simulate!, bounce(0:1000), Signal(boids))
    positions = map(first, pv)
    velocity = map(pv) do pv
        map(norm, pv[2])
    end
    glplot(
       (Circle, positions), scale = Vec2f0(0.05),
       intensity = velocity,
       color_map = GLVisualize.default(Vector{RGBA}),
       color_norm = Vec2f0(0, 0.02)
    )

end


x = main()
