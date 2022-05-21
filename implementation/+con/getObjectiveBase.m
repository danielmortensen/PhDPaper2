function Const = getObjectiveBase(sim, var, Const)
objective = zeros([var.nVar,1]);
sigmaIdx = var.val.sigma.val(:);
sigmaIdx(isnan(sigmaIdx)) = [];
objective(sigmaIdx) = 1;
Const.obj = objective;
end