# MCMF-Trajectories.jl
Compute trajectories using a minimum-cost maximum-flow approach 

## Example 
### Using a pre-tracked set of Beetle trajectories the algorithm visually performs as follows

#### The Pre-tracked set

![Pre-tracked](https://github.com/harveydevereux/MCMF-Trajectories.jl/blob/master/resources/Original-50.png)

#### Randomly permuted trajectories fed into the algorithm

![Permuted](https://github.com/harveydevereux/MCMF-Trajectories.jl/blob/master/resources/Permuted-50.png)

#### Output of the tracking algorithm

- ~ 5 minutes for the whole process
- ~ 70% of matrix elements correct

![Algorithm Output](https://github.com/harveydevereux/MCMF-Trajectories.jl/blob/master/resources/50-solved.png)

## Original Paper for the Trajectory Framework Implemented

[Zhang, L., Li, Y. and Nevatia, R., 2008, June. Global data association for multi-object tracking using network flows. In Computer Vision and Pattern Recognition, 2008. CVPR 2008. IEEE Conference on (pp. 1-8). IEEE](http://mplab.ucsd.edu/wp-content/uploads/CVPR2008/Conference/data/papers/244.pdf)

## TODO

- Organise a full into module
- Proper error/accuracy measurement
- Add parameter tuning?, neural network?

## Base Minimum-Cost Maximum Flow Algorithm 

A.V. Goldberg, "An Efficient Implementation of a Scaling Minimum-Cost Flow Algorithm," J. Algorithms, vol. 22, pp. 1-29, 1997

#### This code uses a ported C++ Implementation of the Original C MCMF Algorithm by Cristinel Ababei January 2009, Fargo NDcristinel.ababei@ndsu.edu

[CS2-CPP](https://github.com/eigenpi/CS2-CPP)

Files edited from CS2-CPP to fit with Julia
[mcmf.cpp](https://github.com/harveydevereux/MCMF-Trajectories.jl/blob/master/src/mcmf.cpp)
[mcmf.h](https://github.com/harveydevereux/MCMF-Trajectories.jl/blob/master/src/mcmf.h)

#### C++ code ported using [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl)


