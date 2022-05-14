function Const = getConst04(sim,var,Const)
nConst = 4*(sum(sim.routes.nRoute)) + sim.bus.nBus;
nVal = (nConst - sim.bus.nBus)*(3 + sim.charger.nCharger) + sim.bus.nBus;
A = nan([nVal,3]);
b = nan([nConst,1]);
eq = nan([nConst,1]);
iVal = 1;
iConst = 1;
p = sim.charger.chargeRate;
M = sim.bus.maxBattery*5;
for iBus = 1:sim.bus.nBus
    % extract sub-variables
    nRoute = sim.routes.nRoute(iBus);

    % constrain the initial state of charge
    h = var.val.h.val(iBus,1);
    A(iVal,:) = [iConst, h, 1];
    b(iConst) = sim.bus.initSoc;
    eq(iConst) = '=';
    iVal = iVal + 1;
    iConst = iConst + 1;

    % constrain all other state of charge values
    for iRoute = 1:nRoute
        h1 = var.val.h.val(iBus,iRoute + 0);
        h2 = var.val.h.val(iBus,iRoute + 1);
        s  = var.val.s.val(iBus,iRoute);
        c  = var.val.c.val(iBus,iRoute);

        % first constraint
        A(iVal + 0,:) = [iConst + 0, h2,  1];
        A(iVal + 1,:) = [iConst + 0, h1, -1];
        A(iVal + 2,:) = [iConst + 0, s,  -p];
        A(iVal + 3,:) = [iConst + 0, c,   p];

        % second constraint
        A(iVal + 4,:) = [iConst + 1, h2, -1];
        A(iVal + 5,:) = [iConst + 1, h1,  1];
        A(iVal + 6,:) = [iConst + 1, s,   p];
        A(iVal + 7,:) = [iConst + 1, c,  -p];

        % third constraint
        A(iVal + 8, :) = [iConst + 2, h2,  1];
        A(iVal + 9, :) = [iConst + 2, h1, -1];

        % fourth constraint
        A(iVal + 10,:) = [iConst + 3, h2,  -1];
        A(iVal + 11,:) = [iConst + 3, h1,   1];

        % define sigma values for each constraint
        iVal = iVal + 12;
        for iCharger = 1:sim.charger.nCharger  
            sigma = var.val.sigma.val(iBus,iRoute,iCharger);
            A(iVal + 0,:) = [iConst + 0, sigma,  M];
            A(iVal + 1,:) = [iConst + 1, sigma,  M];
            A(iVal + 2,:) = [iConst + 2, sigma, -M];
            A(iVal + 3,:) = [iConst + 3, sigma, -M];
            iVal = iVal + 4;
        end   

        % define b
        delta = sim.routes.discharge(iBus,iRoute);
        b(iConst + 0) =  M - delta;
        b(iConst + 1) =  delta + M;
        b(iConst + 2) = -delta;
        b(iConst + 3) =  delta;
        eq(iConst:iConst + 3) = '<';
        iConst = iConst + 4;
    end
end

% sanity checks
assert(~any(isnan(A(:))));
assert(~any(isnan(b)));
assert(iConst - 1 == nConst);
assert(iVal -1 == nVal);
assert(all(A(:,1) > 0));
assert(all(A(:,2) > 0));

% package constraints
Const.Constraint4.A = A;
Const.Constraint4.b = b;
Const.Constraint4.info = "Constraints for state of charge";
Const.Constraint4.eq = eq;
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end