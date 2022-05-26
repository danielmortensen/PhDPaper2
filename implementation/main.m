simulations.nBus = [1:6 2:6 3:6 4:6 5:6 6 35 7:15 5 35];
simulations.nCharger = [ones([1,6])*1 ones([1,5])*2 ones([1,4])*3 ...
                        ones([1,3])*4 ones([1,2])*5 ones([1,1])*6 ...
                        4 ones([1,9]) 2 4];
simulations.objType = [repmat("fiscal",[1,31]) repmat("baseline",[1,2])];
simulations.nSim = 33;
simulations.resultPath = {"..","results"};                                 %#ok

for iSim = 6:simulations.nSim

    % define simulation parameters
    nBus = simulations.nBus(iSim);
    nCharger = simulations.nCharger(iSim);
    objType = simulations.objType(iSim);

    % run simulation
    sim = util.getSimParam(nCharger, nBus, objType);
    var = util.getVarParam(sim);
    Const = con.getConstAll(sim,var);
    model = util.toGurobi(Const,var);
    solution = gurobi(model);

    % save results
    filename = "nBus_" + string(nBus) + ...
        "_nCharger_" + string(nCharger) + ...
        "_obj_" + objType + ".mat";
    filepath = fullfile(simulations.resultPath{:}, filename);
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
