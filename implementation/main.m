param = getSimulationParam();
varInfo = getVarInfo(param);

function param = getSimulationParam()
% define input parameters
dirData = '/home/daniel/PhD/paper2/data_management/data/';
dirGridload = fullfile(dirData,'processed_tpss/TPSS_Cov15.mat');
dirRoutes = fullfile(dirData,'processed/routesTable.csv'); 
MBattery = 450; % battery capacity in kWh
MTime = 24*60*60; % maximum time index
soc0 = 85*MBattery/100; % initial soc in kWh
dTime = 15*60; % delta time in seconds
rCharge = 300/3600; % kWh/second
mBattery = 10*MBattery/100; % minimum allowed soc in kWh
nBus = 6;
nCharger = 2;

% load data
gridload = load(dirGridload);
gridload = gridload.mu;
routes = readtable(dirRoutes);
routes = sortrows(routes,'nRoute','descend');

% get nBus worth of route data
simRoutes = routes(1:nBus,:);
nRoute = simRoutes(:,end-1);
simRoutes = simRoutes(:,1:end-3);
simRoutes = table2array(simRoutes);
tArrival = simRoutes(:,1:3:end);
tDepart = simRoutes(:,2:3:end);
dSoc = simRoutes(:,3:3:end);

param.deltaT = dTime;
param.externLoad = gridload;
param.maxTime = MTime;
param.maxTimeIdx = MTime/dTime;
param.charger.chargeRate = rCharge;
param.charger.nCharger = nCharger;
param.bus.maxBattery = MBattery;
param.bus.initSoc = soc0;
param.bus.minBattery = mBattery;
param.bus.nBus = nBus;
param.routes.tArrival = tArrival;
param.routes.tDepart = tDepart;
param.routes.discharge = dSoc;
param.routes.nRoute = table2array(nRoute);
param.bill.facilitiesPower = 4.81;
param.bill.onPeak.energy = 5.8282e-2;
param.bill.onPeak.power = 15.73;
param.bill.onPeak.hours = zeros([param.maxTimeIdx,1]);
onPeakStart = 15*3600/param.deltaT + 1;
onPeakFinal = 22*3600/param.deltaT;
param.bill.onPeak.hours(onPeakStart:onPeakFinal) = 1;
param.bill.offPeak.energy = 2.9624e-2;
param.bill.offPeak.hours = ones([param.maxTimeIdx,1]) - param.bill.onPeak.hours;
end

function varInfo = getVarInfo(param)
startIdx = 1;
nBus = param.bus.nBus;
nRoute = param.routes.nRoute;

% sigma
nCharger = param.charger.nCharger;
maxStops = max(param.routes.nRoute);
sigma.val = nan([nBus,maxStops,nCharger]);
for iBus = 1:nBus
    finalIdx = startIdx + nRoute(iBus)*nCharger - 1;
    s = size(sigma(iBus,1:nRoute(iBus),:));
    idx = reshape(startIdx:finalIdx,s);
    sigma.val(iBus,1:nRoute(iBus),:) = idx;
    startIdx = finalIdx + 1;
end % 182 values in this constraint
sigma.type = 'B';

% p
nMaxTime = param.maxTimeIdx;
p.val.onRamp = nan([nBus,maxStops,param.maxTimeIdx]);
p.val.offRamp = nan([nBus,maxStops,param.maxTimeIdx]);
p.val.total = nan([param.maxTimeIdx,1]);
for iBus = 1:nBus
    finalIdx1 = startIdx + nRoute(iBus)*nMaxTime - 1;
    finalIdx2 = finalIdx1 + nRoute(iBus)*nMaxTime;
    sz = size(p.onRamp(iBus,1:nRoute(iBus),:));
    idx1 = reshape(startIdx:finalIdx1,sz);
    idx2 = reshape(finalIdx1 + 1:finalIdx2,sz);
    p.val.onRamp(iBus,1:nRoute(iBus),:) = idx1;
    p.val.offRamp(iBus,1:nRoute(iBus),:) = idx2;
    startIdx = finalIdx2 + 1;
end % p.onRamp and p.offRamp together contain 17472 values

p.val.total(1:end) = startIdx:startIdx + nMaxTime - 1;
startIdx = startIdx + nMaxTime;
p.type = 'C';
% p.total contains 96 values

% c
c.val = nan([nBus,maxStops]);
for iBus = 1:nBus
    finalIdx = startIdx + nRoute(iBus) - 1;
    c.val(iBus,1:nRoute(iBus)) = startIdx:finalIdx;
    startIdx = finalIdx + 1;
end % c containts 91 values
c.type = 'C';

% s
s.val = nan([nBus,maxStops]);
for iBus = 1:nBus
    finalIdx = startIdx + nRoute(iBus) - 1;
    s.val(iBus,1:nRoute(iBus)) = startIdx:finalIdx;
    startIdx = finalIdx + 1;
end % s containts 91 values
s.type = 'C';

% h
h.val = nan([nBus,maxStops + 1]);
for iBus = 1:nBus
    finalIdx = startIdx + nRoute(iBus);
    h.val(iBus,1:nRoute(iBus) + 1) = startIdx:finalIdx;
    startIdx = finalIdx + 1;
end % s containts 97 values
h.type = 'C';

% k
k.val.start = nan([nBus,maxStops]);
k.val.final = nan([nBus,maxStops]);
for iBus = 1:nBus
    finalIdx1 = startIdx + nRoute(iBus) - 1;
    finalIdx2 = finalIdx1 + nRoute(iBus);
    k.val.start(iBus,1:nRoute(iBus)) = startIdx:finalIdx1;
    k.val.final(iBus,1:nRoute(iBus)) = finalIdx1 + 1:finalIdx2;
    startIdx = finalIdx2 + 1;
end % both k.start and k.final both have 91 values each
k.type = 'I';

% r
r.val.start = nan([nBus,maxStops]);
r.val.final = nan([nBus,maxStops]);
for iBus = 1:nBus
    finalIdx1 = startIdx + nRoute(iBus) - 1;
    finalIdx2 = finalIdx1 + nRoute(iBus);
    r.val.start(iBus,1:nRoute(iBus)) = startIdx:finalIdx1;
    r.val.final(iBus,1:nRoute(iBus)) = finalIdx1 + 1:finalIdx2;
end % both r.start and r.final both have 91 values each
r.type = 'C';

% s2
s2.val.onRamp = nan([nBus,maxStops,nMaxTime]);
s2.val.offRamp = nan([nBus,maxStops,nMaxTime]);
s2.val.center = nan([nBus,maxStops,nMaxTime]);
for iBus = 1:nBus
    nCurRoute = nRoute(iBus);
finalIdx1 = startIdx + nCurRoute*nMaxTime - 1;
startIdx2 = finalIdx1 + 1;
finalIdx2 = startIdx2 + nCurRoute*nMaxTime - 1;
startIdx3 = finalIdx2 + 1;
finalIdx3 = startIdx3 + nCurRoute*nMaxTime - 1;
sz = size(s2.onRamp(iBus,1:nCurRoute,:));
s2.val.onRamp(iBus,1:nCurRoute,:) = reshape(startIdx:finalIdx1,sz);
s2.val.offRamp(iBus,1:nCurRoute,:) = reshape(startIdx2:finalIdx2,sz);
s2.val.center(iBus,1:nCurRoute,:) = reshape(startIdx3:finalIdx3,sz);
startIdx = finalIdx3 + 1;
end %s2.onRamp,s2.offRamp, and s2.center each contain 8736 values
s2.type = 'B';

q.onPeak.val = startIdx;
q.all.val = startIdx + 1;
q.type = 'C';

% package variable descriptions
varInfo.sigma = sigma;
varInfo.p = p;
varInfo.c = c;
varInfo.s = s;
varInfo.h = h;
varInfo.k = k;
varInfo.r = r;
varInfo.s2 = s2;
varInfo.q = q;
varInfo.nVar = startIdx + 1;
end
