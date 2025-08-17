# inspired from @dreamingsuntide1 on YouTube, and their python code
# YouTube Channel: https://www.youtube.com/@dreamingsuntide1
# YouTube Video: https://www.youtube.com/watch?v=XrDDFqGWkIA

using Random
using Plots, Measures

# Simulated times
# ==============================================================================
# sd refers to the simulated difference between times dodging
function interstep!(mat, i, j, sd)
    return max(mat[i,j] * sd + j, 1.0)
end

function simulated_times!(sim_mat::Matrix{Float64}, sd::Int64)
    len, wid = size(sim_mat)
    @inbounds for j in 1:wid
        for i in 1:len
            sim_mat[i,j] = interstep!(sim_mat,i,j,sd)
        end
    end
    return sim_mat
end

# Adrenaline Rush uptime
# ==============================================================================
function adr_rush(times::AbstractVector{Float64})
    total, up, cd = 0.0, 0.0, 30.0
    for i in times
        total += i
        if i < cd
            up += i
            cd -= i
        else
            up += cd
            cd = 30.0
        end
    end
    return up / total
end

# Adrenaline Rush + Razor's Edge I/II uptime
# ==============================================================================
function adr_rush_rzr(times::AbstractVector{Float64})
    total, up, ext, cd = 0.0, 0.0, 0.0, 45.0
    used_ext = false
    for i in times
        total += i
        if i < cd
            if !used_ext
                cd += 15.0
                used_ext = true
            end
            up  += i
            ext += i
            cd  -= i
        else
            up  += cd
            cd = 45.0
            used_ext = false
        end
    end
    return (up / total, ext / total)
end

# Generate Simulated Times
# ==============================================================================
function ar_uptime(times_mat::Matrix{Float64})
    time_frame = size(times_mat, 2)
    razor0 = Vector{Float64}(undef, time_frame)
    razor1 = Vector{Float64}(undef, time_frame)
    razor2 = Vector{Float64}(undef, time_frame)
    for t in 1:time_frame
        vmat = view(times_mat,:,t)
        razor0[t] = adr_rush(vmat)
        razor1[t], razor2[t] = adr_rush_rzr(vmat)
    end
    return razor0, razor1, razor2
end

# RUN ==========================================================================
# sd = 10, but could more likely be sd = 15
simulation = randn(Random.seed!(1234), 100_000, 120);
simulated_times!(simulation, 10);
(re_0, re_1, re_2) = ar_uptime(simulation);

# PLOTS ========================================================================

# Damage Calculations
ar_level = collect(2:6) .* 5;

RE0 = ar_level[5] .* re_0;
RE1 = ar_level[5] .* re_1;
RE2 = ar_level[5] .* re_1 .+ re_2 .* (210 * 0.05); # RE-II gives 1.05x
# TODO: don't remember where 210 came from specifically -- find out.

p1 = plot([re_0, re_1],
     title="MH Wilds: Dual Blades",
     xlab="Avg. Dodge Time (sec)",
     ylab="Adrenaline Rush Uptime",
     label=["No Razor's Edge"  "Razor's Edge I"],
     xlim=(0,120),
     ylim=(0,1));

p2 = plot([RE0, RE1, RE2],
     title="MH Wilds: Dual Blades",
     xlab="Avg. Dodge Time (sec)",
     ylab="Raw Damage",
     label=["No Razor's Edge"  "Razor's Edge I"  "Razor's Edge II"],
     xlim=(0,120),
     ylim=(0,40));

p3 = plot([RE1 .- RE0, RE2 .- RE1],
     title="MH Wilds: Dual Blades",
     xlab="Avg. Dodge Time (sec)",
     ylab="Raw Damage Difference Between Skills",
     label=[
         "No Razor's Edge -> Razor's Edge I" "Razor's Edge I -> Razor's Edge II"
     ],
     xlim=(0,120),
     ylim=(0,10));

plot(p1, p2, p3, size=(1_200,700), title="", margin=7mm)
