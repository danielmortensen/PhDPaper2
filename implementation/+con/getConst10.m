function Const = getConst10(sim,var,Const)

% define function variables
nConst = 2*sum(sim.routes.nRoute);
nVal = nConst*2;
deltaT = sim.deltaT;
p = sim.charger.chargeRate;

% preallocate
A = nan([nVal,3]);
b = nan([nConst,1]);

% define constraint
iConst = 1;
iVal = 1;

for iBus = 1:sim.bus.nBus
    for iRoute = 1:sim.routes.nRoute(iBus)
        r0 = var.val.r.val.start(iBus,iRoute);
        r1 = var.val.r.val.final(iBus,iRoute);
        p0 = var.val.p.val.onRampAvg(iBus,iRoute);
        p1 = var.val.p.val.offRampAvg(iBus,iRoute);

        A(iVal + 0,:) = [iConst + 0, p0, 1       ];
        A(iVal + 1,:) = [iConst + 0, r0, p/deltaT];
        b(iConst) = p;

        A(iVal + 2,:) = [iConst + 1,  p1, 1       ];
        A(iVal + 3,:) = [iConst + 1, -r1, p/deltaT];
        b(iConst + 1) = 0;

        iVal = iVal + 4;
        iConst = iConst + 2;
    end
end

% sanity check dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b),'all') == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);

% package constraint
Const.Constraint10.A = A;
Const.Constraint10.b = b;
Const.Constraint10.eq = repmat('=',[nConst,1]);
Const.Constraint10.info = "constriants for partial average power when " + ...
    "discretizing values";
end