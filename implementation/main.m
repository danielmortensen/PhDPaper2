param = getSimulationParam();

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


param.maxBattery = MBattery;
param.maxTime = MTime;
param.initSoc = soc0;
param.deltaT = dTime;
param.chargeRate = rCharge;
param.minBattery = mBattery;
param.nBus = nBus;
param.externLoad = gridload;
param.routes.tArrival = tArrival;
param.routes.tDepart = tDepart;
param.routes.discharge = dSoc;
param.routes.nRoute = nRoute;
end
