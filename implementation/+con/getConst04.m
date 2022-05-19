function Const = getConst04(sim,var,Const)
nConst = sum(sim.routes.nRoute) + sim.bus.nBus;
nVal = 4*(nConst - sim.bus.nBus) + sim.bus.nBus;
A = nan([nVal,3]);
b = nan([nConst,1]);
eq = nan([nConst,1]);
iVal = 1;
iConst = 1;
p = sim.charger.chargeRate;
M = sim.bus.maxBattery;
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

        % define b
        delta = sim.routes.discharge(iBus,iRoute);
        b(iConst + 0) = - delta;       
        eq(iConst) = '=';
        iConst = iConst + 1;
        iVal = iVal + 4;
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