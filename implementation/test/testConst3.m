addpath('../');
sim = testGetParam();
var = getVarParam(sim);
Const = struct;
Const = getConst3(sim,var,Const);

assert(all(Const.Constraint3.debug == [2 1 1 1;...
                                       2 2 1 2;...
                                       2 2 3 2;...
                                       3 1 1 1;...
                                       3 1 2 1;...
                                       3 2 1 2],'all'));
assert(numel(Const.Constraint3.b) == 12);