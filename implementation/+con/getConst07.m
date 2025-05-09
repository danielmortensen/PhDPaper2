function Const = getConst07(sim,var,Const)

% define function variables
nConst = sum(sim.routes.nRoute)*6;
nVal = (3 + 3 + 1 + 1 + 1 + 1)*nConst/6;
deltaT = sim.deltaT;

% preallocate
A = nan([nVal,3]);
b = nan([nConst,1]);
eq = nan([nConst,1]);

% define constraint
iConst = 1;
iVal = 1;
for iBus = 1:sim.bus.nBus
    for iRoute = 1:sim.routes.nRoute(iBus)
        k0 = var.val.k.val.start(iBus,iRoute);
        k1 = var.val.k.val.final(iBus,iRoute);
        r0 = var.val.r.val.start(iBus,iRoute);
        r1 = var.val.r.val.final(iBus,iRoute);
        c  = var.val.c.val(iBus,iRoute);
        s  = var.val.s.val(iBus,iRoute);

        A(iVal + 0,:) = [iConst + 0, k0, deltaT];
        A(iVal + 1,:) = [iConst + 0, r0,  1    ];
        A(iVal + 2,:) = [iConst + 0, c,  -1    ];
        A(iVal + 3,:) = [iConst + 1, k1, deltaT];
        A(iVal + 4,:) = [iConst + 1, r1,  1    ];
        A(iVal + 5,:) = [iConst + 1, s,  -1    ];

        A(iVal + 6,:) = [iConst + 2, r0, -1    ];
        A(iVal + 8,:) = [iConst + 3, r0,  1    ];
        A(iVal + 7,:) = [iConst + 4, r1, -1    ];
        A(iVal + 9,:) = [iConst + 5, r1,  1    ];

        eq(iConst + 0) = '=';
        eq(iConst + 1) = '='; 
        b(iConst + 0) = deltaT;
        b(iConst + 1) = deltaT;
        
        eq(iConst + 2) = '<';
        eq(iConst + 3) = '<'; 
        eq(iConst + 4) = '<';
        eq(iConst + 5) = '<';
        b(iConst + 2) = 0;
        b(iConst + 3) = deltaT; 
        b(iConst + 4) = 0;
        b(iConst + 5) = deltaT;

        iVal = iVal + 10;
        iConst = iConst + 6;
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
Const.Constraint7.A = A;
Const.Constraint7.b = b;
Const.Constraint7.eq = eq;
Const.Constraint7.info = "Constraint for the descritization of s and c " + ...
    "using r and k";
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end