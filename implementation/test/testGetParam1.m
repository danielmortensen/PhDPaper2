function param = testGetParam1()
% define input parameters
if ispc
    dirData = '\\wsl.localhost\ubuntu\home\dmortensen\paper2\PhDPaper2\data_management\data';
else
    dirData = '/home/daniel/PhD/paper2/data_management/data/';
end

dirGridload = fullfile(dirData,'processed_tpss','TPSS_Cov15.mat');
...dirRoutes = fullfile(dirData,'processed','routesTable.csv');
MBattery = 450; % battery capacity in kWh
MTime = 24*60*60; % maximum time index
soc0 = 85*MBattery/100; % initial soc in kWh
dTime = 15*60; % delta time in seconds
rCharge = 300/3600; % kWh/second
mBattery = 10*MBattery/100; % minimum allowed soc in kWh
nBus = 3;
nCharger = 2;

% load data
gridload = load(dirGridload);
gridload = gridload.mu;
% routes = readtable(dirRoutes);
% routes = sortrows(routes,'nRoute','descend');

% get nBus worth of route data
% simRoutes = routes(1:nBus,:);
% nRoute = simRoutes(:,end-1);
% simRoutes = simRoutes(:,1:end-3);
% simRoutes = table2array(simRoutes);
nRoute = [4; 4; 4];
arrive1 = [0         8*3600    10.5*3600 23*3600];
arrive2 = [0         8.5*3600  11.5*3600 23*3600];
arrive3 = [0         8.25*3600 12.5*3600 23*3600];
tArrival = [arrive1; arrive2; arrive3];

depart1 = [4.75*3600 9*3600    11.5*3600 24*3600];
depart2 = [5.75*3600 9.5*3600  12.5*3600 24*3600];
depart3 = [6.75*3600 9.25*3600 13.5*3600 24*3600];
tDepart = [depart1; depart2; depart3];

delta1 = [1 2 3 0];
delta2 = [4 5 6 0];
delta3 = [7 8 9 0];
dSoc = [delta1; delta2; delta3];

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
param.routes.nRoute = nRoute;
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
