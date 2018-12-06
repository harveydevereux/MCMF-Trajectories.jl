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

using DelimitedFiles

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
