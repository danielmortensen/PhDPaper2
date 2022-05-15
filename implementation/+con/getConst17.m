function Const = getConst17(sim,var,Const)
nConst = 2*sum(sim.routes.nRoute);
nVal = 3*nConst;
M = ceil(sim.bus.maxBattery/(sim.charger.chargeRate*sim.deltaT));

% preallocate
A = nan([nVal,3]);
b = nan([nConst,1]);

% define constraint
iConst = 1;
iVal = 1;
for iBus = 1:sim.bus.nBus
    for iRoute = 1:sim.routes.nRoute(iBus)
        % unpack loop variables
        k0 = var.val.k.val.start(iBus,iRoute);
        k1 = var.val.k.val.final(iBus,iRoute);
        eq = var.val.k.val.equal(iBus,iRoute);

        % define first constraint
        A(iVal + 0,:) = [iConst + 0, k1,  1];
        A(iVal + 1,:) = [iConst + 0, k0, -1];
        A(iVal + 2,:) = [iConst + 0, eq, -M];
        b(iConst + 0) = 0;

        % define second constraint
        A(iVal + 3,:) = [iConst + 1, k1, -1];
        A(iVal + 4,:) = [iConst + 1, k0,  1];
        A(iVal + 5,:) = [iConst + 1, eq,  M];
        b(iConst + 1) = M;

        % update indexing variables
        iConst = iConst + 2;
        iVal = iVal + 6;
    end
end

% sanity check dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b)) == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);

% package constraints
Const.Constraint17.A = A;
Const.Constraint17.b = b;
Const.Constraint17.eq = repmat('<',[nConst,1]);
Const.Constraint17.info = "Constraints for binary decision that is 0 if " + ...
    "kStart == kFinal and 1 otherwise";
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end