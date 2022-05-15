function sol = testGetSolution0(sim, var)
sol = zeros([var.nVar,1]);
nBus = sim.bus.nBus;
nRoute = sim.routes.nRoute;

% initialize values for c (the charge start time) and s (the charge stop
% time). These values won't matter, we we can set them to the arrival and 
% departure times.
cAll = var.val.c.val;
sAll = var.val.s.val;
aAll = sim.routes.tArrival;
dAll = sim.routes.tDepart;
k0All = var.val.k.val.start;
k1All = var.val.k.val.final;
r0All = var.val.r.val.start;
r1All = var.val.r.val.final;
kqAll = var.val.k.val.equal;
dt = sim.deltaT;
p = sim.charger.chargeRate;
p1All = var.val.p.val.offRampAvg;
p0All = var.val.p.val.onRampAvg;
for iBus = 1:nBus
    for iRoute = 1:nRoute(iBus)

        % extract parameter solution indices
        cIdx = cAll(iBus,iRoute);
        sIdx = sAll(iBus,iRoute);
        k0Idx = k0All(iBus,iRoute);
        k1Idx = k1All(iBus,iRoute);
        r0Idx = r0All(iBus,iRoute);
        r1Idx = r1All(iBus,iRoute);
        kqIdx = kqAll(iBus,iRoute);
        p0Idx = p0All(iBus,iRoute);
        p1Idx = p1All(iBus,iRoute);

        % get arrival and departure times
        a = aAll(iBus,iRoute);
        d = dAll(iBus,iRoute);

        % compute synthetic charge start and stop times
        diff = d - a;
        c = a + diff/2 - 10;
        s = d - diff/2 + 10;

        % compute the integer and remainder versions       
        k0 = floor(c/dt);
        r0 = c - k0*dt;
        k1 = floor(s/dt);
        r1 = s - k1*dt;
        kq = k0 ~= k1;

        % compute partial average power
        p0 = p*(dt - r0)/dt;
        p1 = p*r1/dt;

        % assign values to appropriate binary locations
        s2On = var.val.s2.val.onRamp(iBus,iRoute,k0);
        s2Off = var.val.s2.val.offRamp(iBus,iRoute,k1);
        s2Cen = var.val.s2.val.center(iBus,iRoute,k0 + 1:k1 - 1);       

        % assign values to appropriate solution vector locations.
        sol(cIdx) = c;
        sol(sIdx) = s;
        sol(k0Idx) = k0;
        sol(k1Idx) = k1;
        sol(kqIdx) = kq;
        sol(r0Idx) = r0;
        sol(r1Idx) = r1;
        sol(s2On) = 1;
        sol(s2Off) = 1;
        sol(s2Cen) = 1;
        sol(p0Idx) = p0;
        sol(p1Idx) = p1;
    end
end

% initialize values for state of charge (h) values. These are all equal to
% the initial state of charge as this assumes a no-charge scenario.
hAll = var.val.h.val;
for iBus = 1:nBus
    for iRoute = 1:nRoute(iBus) + 1
        hIdx = hAll(iBus,iRoute);
        sol(hIdx) = sim.bus.initSoc;
    end
end

% the total average power will be equal to the uncontrolled loads
pTotalIdx = var.val.p.val.total;
sol(pTotalIdx) = sim.externLoad;

% set the maximum power for on-peak and overall power use
qAllIdx = var.val.q.val.all;
qAll = max(sim.externLoad);
qOnIdx = var.val.q.val.onPeak;
qOn = max(sim.externLoad(logical(sim.bill.onPeak.hours)));
sol(qAllIdx) = qAll;
sol(qOnIdx) = qOn;
end