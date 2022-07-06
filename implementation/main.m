simulations.nBus = [5 5 5];
simulations.nCharger = [5 5 5];
simulations.objType = ["fiscal","energy","baseline"];
simulations.nSim = 3;
simulations.resultPath = {"..","results","new"};                     %#ok

for iSim = 1:simulations.nSim

    % define simulation parameters
    nBus = simulations.nBus(iSim);
    nCharger = simulations.nCharger(iSim);
    objType = simulations.objType(iSim);
% %     nBus = 5;
% %     nCharger = 5;
% %     objType = "energy";
% %     resultPath = {"..","results","new"};                                   %#ok
    % run simulation
    sim = util.getSimParam(nCharger, nBus, objType);
    var = util.getVarParam(sim);
    Const = con.getConstAll(sim,var);
    model = util.toGurobi(Const,var);
    param = struct('MIPGap',0.02);
    solution = gurobi(model,param);

    % save results
    filename = "nBus_" + string(nBus) + ...
        "_nCharger_" + string(nCharger) + ...
        "_obj_" + objType + "_augmentedLoad.mat";
    filepath = fullfile(simulations.resultPath{:}, filename);
  ...  filepath = fullfile(resultPath{:},filename);
    fprintf("saving file: " + filename + " percent complete: %f \n",iSim/simulations.nSim);
    save(filepath,'sim','var','Const','solution');
 end




% % plot state of charge for each bus
% h = var.val.h.val;
% soc = nan(size(h));
% time = nan(size(h));
% for iBus = 1:sim.bus.nBus
%     soc(iBus,1) = solution.x(h(iBus,1));
%     for iRoute = 1:sim.routes.nRoute(iBus)
%         soc(iBus,iRoute + 1) = solution.x(h(iBus,iRoute + 1));    
%         time(iBus,iRoute) = sim.routes.tArrival(iBus,iRoute);
%     end
%     time(iBus,iRoute + 1) = sim.routes.tDepart(iBus,iRoute);
% end
% 
% figure; hold on; 
% for iBus = 1:sim.bus.nBus
% nRoute = sim.routes.nRoute(iBus);
% xAxis = seconds(time(iBus,1:nRoute + 1));
% plot(xAxis,soc(iBus,1:nRoute + 1));
% end
% 
% % plot the power use
% allPowerIdx = var.val.p.val.total;
% allPower = solution.x(allPowerIdx);
% busPower = allPower - sim.externLoad';
% xAxis = 0:15*60:(24*60 - 15)*60;
% figure; plot(xAxis,allPower); 
% hold on; plot(xAxis, busPower); shg
