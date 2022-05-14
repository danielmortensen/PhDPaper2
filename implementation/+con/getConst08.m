function Const = getConst08(sim,var,Const)
% define function variables
nAllRoute = sum(sim.routes.nRoute);
nConst = 4*nAllRoute;
nVal = nAllRoute*(4*sim.maxTimeIdx + 2);
A = nan([nVal,3]);
b = nan([nConst,1]);

% define constraint
iVal = 1;
iConst = 1;
for iBus = 1:sim.bus.nBus
    for iRoute = 1:sim.routes.nRoute(iBus)
        k0 = var.val.k.val.start(iBus,iRoute);
        k1 = var.val.k.val.final(iBus,iRoute);
        s2OnRamp = var.val.s2.val.onRamp(iBus,iRoute,:);
        s2OffRamp = var.val.s2.val.offRamp(iBus,iRoute,:);
        A(iVal + 0,:) = [iConst + 0, k0, -1];
        A(iVal + 1,:) = [iConst + 1, k1, -1];
        iVal = iVal + 2;
        for iTime = 1:sim.maxTimeIdx
            s20 =s2OnRamp(iTime);
            s21 = s2OffRamp(iTime);
            A(iVal + 0,:) = [iConst + 0, s20, iTime];
            A(iVal + 1,:) = [iConst + 1, s21, iTime];
            A(iVal + 2,:) = [iConst + 2, s20, 1    ];
            A(iVal + 3,:) = [iConst + 3, s21, 1    ];
            iVal = iVal + 4;
        end
        b(iConst + 0) = 0;
        b(iConst + 1) = 0;
        b(iConst + 2) = 1;
        b(iConst + 3) = 1;
        iConst = iConst + 4;
    end
end

% sanity check dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b),'all') == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);
assert(all(A(:,1) > 0));
assert(all(A(:,2) > 0));

% package constraints
Const.Constraint8.A = A;
Const.Constraint8.b = b;
Const.Constraint8.eq = repmat('=',[nConst,1]);
Const.Constraint8.info = "Convert to binary indices from s and r for on " + ...
    " and off ramping";
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end