sim = util.getSimParam();
var = util.getVarParam(sim);
Const = con.getConstAll(sim,var);
model = util.toGurobi(Const, var);
solution = gurobi(model);

% addpath('test');
% Const = testConstCheck(Const,solution.x);

% plot state of charge for each bus
h = var.val.h.val;
soc = nan(size(h));
time = nan(size(h));
for iBus = 1:sim.bus.nBus
    soc(iBus,1) = solution.x(h(iBus,1));
    for iRoute = 1:sim.routes.nRoute(iBus)
        soc(iBus,iRoute + 1) = solution.x(h(iBus,iRoute + 1));    
        time(iBus,iRoute) = sim.routes.tArrival(iBus,iRoute);
    end
    time(iBus,iRoute + 1) = sim.routes.tDepart(iBus,iRoute);
end

figure; hold on; 
for iBus = 1:sim.bus.nBus
nRoute = sim.routes.nRoute(iBus);
xAxis = seconds(time(iBus,1:nRoute + 1));
plot(xAxis,soc(iBus,1:nRoute + 1));
end

% plot the power use
allPowerIdx = var.val.p.val.total;
allPower = solution.x(allPowerIdx);
busPower = allPower - sim.externLoad';
xAxis = 0:15*60:(24*60 - 15)*60;
figure; plot(xAxis,allPower); 
hold on; plot(xAxis, busPower); shg
