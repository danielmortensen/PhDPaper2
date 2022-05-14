function Const = getObjective(sim, var, Const)
objective = zeros([var.nVar,1]);

isOnPeak = sim.bill.onPeak.hours;
onRate = sim.bill.onPeak.energy*sim.deltaT/3600;
offRate = sim.bill.offPeak.energy*sim.deltaT/3600;
for iTime = 1:sim.maxTimeIdx
    p = var.val.p.val.total(iTime);
    if isOnPeak(iTime)
        objective(p) = onRate;
    else
        objective(p) = offRate;
    end
end
objective(var.val.q.val.all) = sim.bill.facilitiesPower;
objective(var.val.q.val.onPeak) = sim.bill.onPeak.power;
Const.obj = objective;
end