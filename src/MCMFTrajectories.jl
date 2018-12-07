using ProgressMeter
using Random
using LightGraphs
using CSV
using Plots
using DelimitedFiles

include("/home/harvey/Documents/PhD/Code/src/Julia/Pipeline.jl")
using Main.DataPipline

# Load the module and generate the functions
SRC = "/home/harvey/Documents/PhD/CS2-Julia/src"
module CS2Julia
  SRC = "/home/harvey/Documents/PhD/CS2-Julia/src"
  using CxxWrap
  @wrapmodule(joinpath("$SRC/build","libCS2-Julia.so"))

  function __init__()
    @initcxx
  end
end

function VectorIoU(x,y)
    if (size(x,1) == size(y,1))
        J_num = 0
        J_denom = 0
        for i in 1:size(x,1)
            J_num += min(x[i],y[i])
            J_denom += max(x[i],y[i])
        end
        return J_num./J_denom
    else
        println("Need to vectors of the same shape, got x: ", size(x), " and y: ", size(y))
    end
end

function IoUCost(x,y,dt,a=1,b=1) return a*(1-VectorIoU(x,y))+b*(dt-1) end

function BuildFlowModel(X;t_max,N=1,b=0.01,a=1,c=1,t=0.8)
  G = zeros(1,5)
  source = 2.0
  sink = 1.0
  capacity = 100
  NodeCost = function(b) return floor(100*log(b/(1-b))) end
  SourceCost = function(b) return floor(100*-log(b)) end
  SinkCost = function(b) return floor(100*-log(b)) end
  LinkCost = function(X,i,j,k,dt,a,c) return floor(100*IoUCost(X[i,j,1:2],X[i+dt,k,1:2],dt,a,c)) end
  AddNode = function(name,node_number,node_dict)
    if (name in keys(node_dict) ? false : node_dict[name] = node_number) > 0
      node_number += 1
    end
    return node_number
  end

  node_number = 3
  # keeps track of all nodes, needed for link edges (go forward in time)
  node_dict = Dict("source" => source, "sink" => sink)
  @showprogress for i in 1:t_max
    for j in 1:size(X,2)
      if sum(X[i,j,:]) == 0
        continue
      end
      # detection arc
      node_number = AddNode("u_$i"*"_$j",node_number,node_dict)
      node_number = AddNode("v_$i"*"_$j",node_number,node_dict)
      IJ = [node_dict["u_$i"*"_$j"],node_dict["v_$i"*"_$j"],0,100,NodeCost(b)]'
      G = cat(G,IJ,dims=1)
      # source-detection arc
      SI = [source,IJ[1],0,100,SourceCost(b)]'
      G = cat(G,SI,dims=1)
      # detection-sink arc
      IT = [IJ[2],sink,0,100,SinkCost(b)]'
      G = cat(G,IT,dims=1)
      for k in 1:size(X,2)
        for n in 1:(N)
          if i+n <= t_max
            if VectorIoU(X[i,j,1:2],X[i+n,k,1:2]) > t
              # linking detections edge
              # will only actually add the node if it is not already there
              node_number = AddNode("u_$(i+n)"*"_$k",node_number,node_dict)
              node_number = AddNode("v_$(i+n)"*"_$k",node_number,node_dict)
              LIJ = [node_dict["v_$i"*"_$j"],node_dict["u_$(i+n)"*"_$k"],0,100,LinkCost(X,i,j,k,n,a,c)]'
              G = cat(G,LIJ,dims=1)
            end
          end
        end
      end
    end
  end
  return G[2:end,:],node_dict,node_number
end

function MCMFPostProcessing(nodes,C)
  G = Graph(nnodes)
  for i in 1:size(C,1)
    if C[i,3] == 100.0
      add_edge!(G,C[i,1],C[i,2])
    end
  end
  shortest_paths = yen_k_shortest_paths(G,2,1,weights(G),199).paths

  seen = []
  MAP = Dict(value => key for (key,value) in nodes)
  t = zeros(size(T,2),Int.((size(shortest_paths[1],1)-2)/2))
  @showprogress for P in shortest_paths
    agent = parse(Int,split(MAP[P[2]],"_")[3])
    push!(seen,agent)
    for n in P
      n = MAP[n]
      if n == "source" || n == "sink" || split(n,"_")[1] == "u"
        continue
      else
        time = parse(Int,split(n,"_")[2])
        next = parse(Int,split(n,"_")[3])
        t[agent,time,1] = next
      end
    end
  end
  return t
end

function IndicesToTrajectories(T;solution_indices)
  X = copy(T)
  for i in 1:size(X,1)
    for j in 1:size(X,2)
      X[i,j,:] = T[i,Int.(solution_indices[j,i]),:]
    end
  end
  return X
end

PATH = "/home/harvey/Documents/PhD/Data/200-beetles-1000-frames/Processed"
Vid = Video(PATH,["x","y","angle"])
X = MatrixForm(Vid)

Tracks = CSV.read("/home/harvey/Documents/PhD/Data/200-by-hand/tracks_0_200.csv")
Tracks = convert(Array{Float64,2},Tracks)[:,2:end]
T = zeros(size(Tracks,1),Int.(size(Tracks,2)/2),3)
for i in 1:size(Tracks,1)
    for j in 1:size(T,2)
        T[i,j,1:2] = [Tracks[i,(j*2)-1],Tracks[i,j*2]]
    end
end

NULL = Int.(ones(size(T,1),size(T,2)))
for i in 1:size(NULL,1)
  NULL[i,:] = NULL[i,:].*i
end
NULL

Test = copy(T)
PERMS = zeros(size(T,1),size(T,2))
for i in 2:size(T,1)
  perm = randperm(size(T,2))
  Test[i,:,:] = T[i,perm,:]
  PERMS[i,:] = perm
end
PERMS[1,:] = collect(1:size(T,2))
PERMS = PERMS'

ANSWER = zeros(size(PERMS,1),size(PERMS,2))
for i in 1:size(T,1)
  for j in 1:size(T,2)
    ind = findall(x -> x .== j, PERMS[:,i])[1]
    ANSWER[j,i] = ind
    # println(sum(Test[i,ind,1:2] .== T[i,j,1:2]) == 2)
  end
end

X = IndicesToTrajectories(Test,solution_indices=ANSWER)

plot(X[1:100,:,1],X[1:100,:,2],title="De-permuted",label="")

plot(T[1:100,:,1],T[1:100,:,2],title="Original",label="")
plot(Test[1:100,:,1],Test[1:100,:,2],title="Permuted",label="")

t_max = 50
G,nodes,nnodes = BuildFlowModel(Test,t_max=t_max,N=1,b=0.01,a=1,c=1,t=0.9)

C = zeros(size(G,1),3)
CS2Julia.MCMFSolve(G,Float64.([size(G)...]),Float64.([nnodes,size(G,1)]),[2.0,1.0],C,[10000.0,1000.0,100.0,10.0])
C

t = MCMFPostProcessing(nodes,C)
sum(t .== ANSWER[1:size(t,1),1:size(t,2)]) ./ (size(t,1)*size(t,2))

T_model = IndicesToTrajectories(Test[1:size(t,2),:,:],solution_indices=t)

plot(T_model[:,:,1],T_model[:,:,2],label="",title="50 Frames Solved")

savefig("50-solved.png")

plot(T[1:50,:,1],T[1:50,:,2],title="Original",label="")

savefig("Original-50.png")

plot(Test[1:50,:,1],Test[1:50,:,2],title="Permuted",label="")
savefig("Permuted-50.png")

## OLD

G,nodes,nnodes = BuildFlowModel(T,t_max=5,N=1,b=0.01,a=1,c=1,t=0.9)
G
nnodes
nodes

C = zeros(size(G,1),3)
CS2Julia.MCMFSolve(G,Float64.([size(G)...]),Float64.([nnodes,size(G,1)]),[2.0,1.0],C,[10000.0,1000.0,100.0,10.0])
C

t = MCMFPostProcessing(nodes,C)
sum(t .== NULL[1:size(t,1),1:size(t,2)]) ./ (size(t,1)*size(t,2))

## TEST

IN = "$SRC/test.in"
OUT = "$SRC/test.out"
inputs = readdlm(IN)
true_outputs = readdlm(OUT)

nodes = inputs[1,1]
ST = inputs[end-1:end,1:2]
A = convert(Array{Float64,2},inputs[2:end-2,:])
C = zeros(size(A,1),3)

CS2Julia.MCMFSolve(A,Float64.([size(A)...]),Float64.([nodes,size(A,1)]),[2.0,1.0],C,[10000.0,1000.0,100.0,10.0])

println(C == true_outputs[2:end,:])
