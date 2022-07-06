clear all; close all; 
datetime.setDefaultFormats('default','yyyy-MM-dd HH:mm:ss');   

resultdir = '\\wsl.localhost\ubuntu\home\dmortensen\paper2\PhDPaper2\results\new\';
mediadir = '\\wsl.localhost\ubuntu\home\dmortensen\paper2\PhDPaper2\documentation\writeup\media\7_objective\';
totalPowerTableFile = 'Optimized5Bus5ChargerAugmentedTotalPowerPlot.csv';
powerTableFile = 'Optimized5Bus5ChargerAugmentedPowerPlot.csv';
resultfile = 'nBus_5_nCharger_5_obj_fiscal_augmentedLoad.mat';...'nBus_5_nCharger_5_obj_baseline.mat';...'nBus_5_nCharger_5_obj_fiscal.mat';
resultpath = fullfile(resultdir,resultfile);

data = load(resultpath);

% get bus load
nBus = data.sim.bus.nBus;
nRoute = data.sim.routes.nRoute;
fig1 = figure; hold on; 
fig2 = figure; hold on; 
for iBus = 1:nBus
    for iRoute = 1:nRoute(iBus)
        offrampIdx = squeeze(data.var.val.p.val.offRamp(iBus,iRoute,:));
        onrampIdx = squeeze(data.var.val.p.val.onRamp(iBus,iRoute,:));
        centerIdx = data.var.val.s2.val.center(iBus,iRoute,:);       
        centerPower = data.solution.x(centerIdx)*data.sim.charger.chargeRate*3600;
        onrampPower = data.solution.x(onrampIdx);
        offrampPower = data.solution.x(offrampIdx);
        routePower = centerPower + onrampPower + offrampPower;
        if exist('busPowerKw','var')
            busPowerKw = busPowerKw + routePower;
        else
            busPowerKw = routePower;
        end
        % plot blue box around available charge time
        cIdx = data.var.val.c.val(iBus,iRoute);
        sIdx = data.var.val.s.val(iBus,iRoute);
        top = iBus + 0.5; bottom = iBus - 0.5;
        left = data.solution.x(cIdx);
        right = data.solution.x(sIdx);
        if abs(right - left) > 1e-4
            y = [bottom bottom top top];
            x = [right left left right];
            plot(polyshape(x,y));
        end
    end
    figure(fig1);
    socIdx = data.var.val.h.val(iBus,:);
    socIdx(isnan(socIdx)) = [];
    time = data.sim.routes.tArrival(iBus,:);
    time(isnan(time)) = [];
    time(end + 1) = 24*3600;                                               %#ok
    busSoc = data.solution.x(socIdx);
    plot(time/3600,busSoc); 
    figure(fig2);
end
temp = 0:900:24*3600; xline(temp); figure(fig1);
legend('bus 1','bus 2','bus 3','bus 4','bus 5');

% get total load
loadKw = data.sim.externLoad';

% compute total power and energy
totalPower = busPowerKw + loadKw;
totalEnergy = totalPower*data.sim.deltaT/3600;


% get on-peak energy rate
onPeakEnergyRate = data.sim.bill.onPeak.energy;

% get off-peak energy rate
offPeakEnergyRate = data.sim.bill.offPeak.energy;

% get on-peak demand rate
onPeakDemandRate = data.sim.bill.onPeak.power;

% get facilities demand rate
facilitiesDemandRate = data.sim.bill.facilitiesPower;


% compute on-peak energy charge
onPeakIdx = data.sim.bill.onPeak.hours;
costOnPeakEnergy = onPeakEnergyRate*sum(onPeakIdx.*totalEnergy,'all');

% compute off-peak energy charge
offPeakIdx = data.sim.bill.offPeak.hours;
costOffPeakEnergy = offPeakEnergyRate*sum(offPeakIdx.*totalEnergy,'all');

% compute total energy cost
costEnergy = costOnPeakEnergy + costOffPeakEnergy;

% get max on-peak 
idx = data.var.val.q.val.onPeak;
maxOnPeakKw = data.solution.x(idx);
[measMaxOnPeakKw, maxOnPeakKwIdx] = max(totalPower.*onPeakIdx);
assert(abs(maxOnPeakKw - measMaxOnPeakKw) < 10);

% get max facilities
idx = data.var.val.q.val.all;
maxAllKw = data.solution.x(idx);
[maxAllKwMeas, maxAllKwIdx] = max(totalPower);
assert(abs(maxAllKw - maxAllKwMeas) < 10);

% compute on-peak demand charge
costOnPeakDemand = onPeakDemandRate*maxOnPeakKw;

% compute facilities charge
costFacilitiesDemand = facilitiesDemandRate*maxAllKw;

% create table to output plotting results
nTime = numel(totalPower);
totalPowerMatrix = zeros([nTime,4]);
totalPowerMatrix(:,1) = totalPower.*onPeakIdx;
totalPowerMatrix(:,2) = totalPower;
totalPowerMatrix(maxAllKwIdx,3) = maxAllKw;
totalPowerMatrix(maxOnPeakKwIdx,4) = maxOnPeakKw;
headers = {'onPeakOut','facilitiesOut','maxFacilitiesOut','maxOnPeakOut'};
totalPowerTable = array2table(totalPowerMatrix);
totalPowerTable.Properties.VariableNames = headers;
offset = seconds((0:1:nTime - 1)/nTime*3600*24);
time = datetime(2021,8,23);
...time.Format = "yyyy-MM-dd HH:mm:ss";
time = time + offset';
totalPowerTable.time = string(time);
totalPowerTableDir = fullfile(mediadir,totalPowerTableFile);

writetable(totalPowerTable,totalPowerTableDir);

powerMatrix = zeros([nTime,2]);
powerMatrix(:,1) = busPowerKw;
powerMatrix(:,2) = loadKw;
headers = {'meanBusPower','loadPower'};
powerTable = array2table(powerMatrix);
powerTable.Properties.VariableNames = headers;
powerTable.time = string(time);
powerTableDir = fullfile(mediadir,powerTableFile);
writetable(powerTable,powerTableDir);

fprintf("energy cost: %f\n",costEnergy);
fprintf("On-Peak Demand Cost: %f\n",costOnPeakDemand);
fprintf("Facilities Demand Cost: %f\n",costFacilitiesDemand);

