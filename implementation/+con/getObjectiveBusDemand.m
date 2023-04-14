function Const = getObjectiveBusDemand(sim, var, Const)
objective = zeros([var.nVar,1]);
objective(var.val.q.val.bus) = 1;
Const.obj = objective;
end