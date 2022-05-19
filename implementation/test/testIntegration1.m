addpath('../');
sim = testGetParam1();
var = util.getVarParam(sim);
Const = con.getConstAll(sim,var);
sol = testGetSolution1(sim, var);
model = util.toGurobi(Const,var);
result = gurobi(model);
Const = testConstCheck(Const, var.nVar, sol, 'plotResults');

for iConst = 1:Const.nConst
    if iConst == 5
        continue
    end
    name = "Constraint" + string(iConst);
    curConst = Const.(name);
    if isfield(curConst.myEval,'equality')
        assert(curConst.myEval.equality.isCorrect)
    end
    if isfield(curConst.myEval, 'inequality')
        assert(curConst.myEval.inequality.isCorrect);
    end
end

