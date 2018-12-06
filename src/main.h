#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <iterator>
#include <algorithm>
#include <stdexcept>

#include "mcmf.cpp"

class MCMFProblem{
public:
  MCMFProblem(long nodes, long arcs)
    : mcmf(nodes,arcs), min_cost(1000000), flow(10), nodes(nodes), edges(arcs)
    {}
  MCMFProblem()
    : mcmf(0,0), min_cost(1000000), flow(10)
    {}
  int TrajectoryAlgorithm(int flow_step = 10);
  void Flow(int & flow){
    this->flow = flow;
  }
  void SetFlow(int & flow){
    if (source_sink_id[0] > 0 && source_sink_id[1] > 0){
      this->mcmf.set_supply_demand_of_node(source_sink_id[0], flow);
      this->mcmf.set_supply_demand_of_node(source_sink_id[1], -flow);
    }
    else{
      std::cout << "Uninitialised source and sink\n";
      std::cout << "Or node label 0 is invalid start with 1";
    }
  }
  void ResetArcs();
  //std::vector<int> ReadData(std::string & line);
  std::vector< std::vector<int> > Arcs;
  std::vector<int> current_solution;
  std::vector<int> source_sink_id = {0,0};
  int flow = 0;
  int prev_flow = 0;
  int min_cost;
  int cost;
  int edges;
  int nodes;
  MCMF_CS2 mcmf;
};

void MCMFProblem::ResetArcs(){
  MCMF_CS2 m(this->nodes,this->edges);
  this->mcmf = m;
  for (int i = 0; i < this->Arcs.size(); i++){
      std::vector<int> arc_values = this->Arcs[i];
      this->mcmf.set_arc(arc_values[0],arc_values[1],arc_values[2],arc_values[3],arc_values[4]);
    }
}

int MCMFProblem::TrajectoryAlgorithm(int flow_step){
  // termination is when the problem is
  // unfeasible which cause the whole program to exit
  int change = 0;
  int prev_cost = 0;
  int prev_flow = 0;
  while(true){
    std::vector<int> k;
    this->current_solution = k;
    SetFlow(this->flow);
    this->mcmf.run_cs2(false,this->min_cost,this->cost,this->current_solution);
    change = this->cost - prev_cost;
    if (change > 0){
      std::cout << "Reached convex minimum";
      return prev_flow-flow_step;
    }
    std::cout << "FLOW " << this->flow << std::endl;
    prev_flow = this->flow;
    this->flow += flow_step;
    prev_cost = this->cost;
    this->ResetArcs();
  }
}
