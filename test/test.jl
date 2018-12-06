# Load the module and generate the functions
SRC = "../src"
module CS2Julia
  SRC = "../src"
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

results = (C == true_outputs[2:end,:])
println("\n")
if results
  printstyled(color=:green,bold=true,"Output was $results\n")
else
  printstyled(color=:red,bold=true,"Output was $results\n")
end
