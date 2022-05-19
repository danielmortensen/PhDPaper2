function Const = getConst10(sim,var,Const)

% define function variables
nConst = 8*sum(sim.routes.nRoute);
nVal =  24*sum(sim.routes.nRoute);
deltaT = sim.deltaT;
p = sim.charger.chargeRate*3600; % Convert from kwh/second to kwh/h (or kw)
M = max(sim.routes.tDepart(:) - sim.routes.tArrival(:));

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
        k = var.val.k.val.equal(iBus,iRoute);
        
        % first constraint
        A(iVal + 0,:) = [iConst + 0, p0, 1       ];
        A(iVal + 1,:) = [iConst + 0, r0, p/deltaT];
        A(iVal + 2,:) = [iConst + 0, k,  M       ];
        b(iConst + 0) = M + p;

        % second constraint
        A(iVal + 3,:) = [iConst + 1, p0, -1       ];
        A(iVal + 4,:) = [iConst + 1, r0, -p/deltaT];
        A(iVal + 5,:) = [iConst + 1, k,   M       ];
        b(iConst + 1) = M - p;

        % third constraint
        A(iVal + 6,:) = [iConst + 2, p0,  1       ];
        A(iVal + 7,:) = [iConst + 2, r1, -p/deltaT];
        A(iVal + 8,:) = [iConst + 2, r0,  p/deltaT];
        A(iVal + 9,:) = [iConst + 2, k,   -M];
        b(iConst + 2) = 0;

        % fourth constraint
        A(iVal + 10,:) = [iConst + 3, p0, -1       ];
        A(iVal + 11,:) = [iConst + 3, r1,  p/deltaT];
        A(iVal + 12,:) = [iConst + 3, r0, -p/deltaT];
        A(iVal + 13,:) = [iConst + 3, k,  -M       ];
        b(iConst + 3) = 0;

        % fifth constraint
        A(iVal + 14,:) = [iConst + 4, p1,  1       ];
        A(iVal + 15,:) = [iConst + 4, r1, -p/deltaT];
        A(iVal + 16,:) = [iConst + 4, k,   M       ];
        b(iConst + 4) = M;

        % sixth constraint
        A(iVal + 17,:) = [iConst + 5, p1, -1      ];
        A(iVal + 18,:) = [iConst + 5, r1, p/deltaT];
        A(iVal + 19,:) = [iConst + 5, k,  M       ];
        b(iConst + 5) = M;

        % seventh constraint
        A(iVal + 20,:) = [iConst + 6, p1, 1       ];
        A(iVal + 21,:) = [iConst + 6, k,  -M      ];
        b(iConst + 6) = 0;
        
        % eighth constraint
        A(iVal + 22,:) = [iConst + 7, p1, -1];
        A(iVal + 23,:) = [iConst + 7, k,  -M];
        b(iConst + 7) = 0;

        % update index values
        iVal = iVal + 24;
        iConst = iConst + 8;
    end
end

% sanity check dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b),'all') == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);
assert(all(A(:,1) > 0));
assert(all(A(:,2) > 0));

% package constraint
Const.Constraint10.A = A;
Const.Constraint10.b = b;
Const.Constraint10.eq = repmat('<',[nConst,1]);
Const.Constraint10.info = "constriants for partial average power when " + ...
    "discretizing values";
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end