addpath('../');
sim = testGetParam0();
var = util.getVarParam(sim);
Const = con.getConstAll(sim,var);
sol = testGetSolution0(sim, var);
model = util.toGurobi(Const,var);
result = gurobi(model);
Const = testConstCheck(Const, var.nVar, sol);
for iConst = 1:Const.nConst
    name = "Constraint" + string(iConst);
    curConst = Const.(name);
    if isfield(curConst.eval,'equality')
        assert(curConst.eval.equality.isCorrect)
    end
    if isfield(curConst.eval, 'inequality')
        assert(curConst.eval.inequality.isCorrect);
    end
end



