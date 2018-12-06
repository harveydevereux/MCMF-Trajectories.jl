#include "main.h"
#include <vector>

int main(int argc, char ** argv) {
  std::string filename;
  if (argc >= 2){
    filename = argv[1];
  }
  else{
    filename = "mcmf.in";
  }
  std::string out;
  if ( argc >= 3){
    out = argv[2];
  }
  else{
    out = "mcmf.out";
  }
  int flow = 0;
  if (argc >= 4){
    flow = std::stoi(argv[3]);
  }
  MCMFProblem P(0,0);
  std::vector<int> flows = {10000,1000,100,10,1};
  int prev_flow = flow;
  for (int i = 0; i < flows.size(); i++){
    P.Flow(prev_flow);
    prev_flow = P.TrajectoryAlgorithm(filename, out, flows[i]);
    std::cout << "PREV FLOW " << prev_flow << std::endl;
  }
}
