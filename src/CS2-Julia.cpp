#include "jlcxx/jlcxx.hpp"

#include "main.h"

#include <iostream>

void MCMFSolve(jlcxx::ArrayRef<double,2> Data, jlcxx::ArrayRef<double,1> dim_lengths, jlcxx::ArrayRef<double,1> nodes_edges,jlcxx::ArrayRef<double,1> source_sink_id,jlcxx::ArrayRef<double,2> solution, jlcxx::ArrayRef<double,1> flow_steps){
      if ( dim_lengths.size() != 2 ){
            std::cout << "Invalid dimension lengths";
            return;
      }
      if ( dim_lengths[1] != 5){
            std::cout << "Invalid edge data, need (node1,node2,low capcity,high capacity,cost)" << std::endl;
            return;
      }
      if ( dim_lengths[0]*dim_lengths[1] != Data.size() ){
            std::cout << "Invalid dimension lengths needs to be equal to Julia > Size(A,1)*Size(A,2)" << std::endl;
            return;
      }
      // Solve block
      int prev_flow = 0;
      for (int i = 0; i < flow_steps.size(); i++){
            int flowstep = flow_steps[i];
            MCMFProblem MCMF = MCMFProblem(nodes_edges[0],nodes_edges[1]);
            // Loop over all rows and columns (the array is owned by julia and address as flat)
            for (int i = 0; i < dim_lengths[0]; i++){
                  std::vector<int> arc_values = {0,0,0,0,0};
                  for (int j = 0; j < dim_lengths[1]; j++){
                        arc_values[j] = Data[j*dim_lengths[0]+i];
                  }
                  MCMF.mcmf.set_arc(arc_values[0],arc_values[1],arc_values[2],arc_values[3],arc_values[4]);
                  MCMF.Arcs.push_back(arc_values);
            }
            MCMF.source_sink_id = std::vector<int> {source_sink_id[0],source_sink_id[1]};
            MCMF.SetFlow(prev_flow);
            MCMF.Flow(prev_flow);
            prev_flow = MCMF.TrajectoryAlgorithm(flowstep);

            int column = 0;
            for (int i = 0; i < dim_lengths[0]; i++){
                  for (int j = 0; j < 3; j++){
                        solution[j*dim_lengths[0]+i] = MCMF.current_solution[column*3 + j];
                  }
                  column += 1;
            }
      }
}
// this is the exposure block
JLCXX_MODULE define_julia_module(jlcxx::Module & mod){
      mod.method("MCMFSolve", static_cast<void (*)(jlcxx::ArrayRef<double,2>,jlcxx::ArrayRef<double,1>,jlcxx::ArrayRef<double,1>,jlcxx::ArrayRef<double,1>,jlcxx::ArrayRef<double,2>,jlcxx::ArrayRef<double,1>)>(&MCMFSolve));
}
