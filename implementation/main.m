sim = util.getSimParam();
var = util.getVarParam(sim);
Const = con.getConstAll(sim,var);
model = util.toGurobi(Const, var);
solution = gurobi(model);


