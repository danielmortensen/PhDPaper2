function Const = getConst09(sim, var, Const)
nAllRoute = sum(sim.routes.nRoute);
nAllTime = sim.maxTimeIdx;
M = nAllTime*2;
nConst = (1 + nAllTime*2)*nAllRoute;
nVal = (5*nAllTime + 3)*nAllRoute;

iVal = 1;
iConstr = 1;

A = nan([nVal,3]);
b = nan([nConst,1]);
eq = nan([nConst, 1]);

for iBus = 1:sim.bus.nBus
    for iRoute = 1:sim.routes.nRoute(iBus)
        % first constraint
        k1 = var.val.k.val.final(iBus,iRoute);
        k0 = var.val.k.val.start(iBus,iRoute);
        kq = var.val.k.val.equal(iBus,iRoute);
        s2 = var.val.s2.val.center(iBus,iRoute,:);

        A(iVal + 0,:) = [iConstr, k0,  1];
        A(iVal + 1,:) = [iConstr, k1, -1];
        A(iVal + 2,:) = [iConstr, kq,  1];
        b(iConstr) = 0;
        eq(iConstr) = '=';        
        iVal = iVal + 3;

        for iTime = 1:nAllTime
            s = s2(iTime);
            iConstr1 = iConstr + (iTime - 1)*2 + 1;
            iConstr2 = iConstr + iTime*2;
            A(iVal + 0,:) = [iConstr + 0, s, 1];

            A(iVal + 1,:) = [iConstr1, s, M + iTime];
            A(iVal + 2,:) = [iConstr1, k1, -1      ];
            b(iConstr1) = M;     
            eq(iConstr1) = '<';

            A(iVal + 3,:) = [iConstr2, s, M - iTime];
            A(iVal + 4,:) = [iConstr2, k0, 1       ];
            b(iConstr2) = M;
            eq(iConstr2) = '<';
            iVal = iVal + 5;
        end
        iConstr = iConstr + 2*nAllTime + 1;        
    end
end

% validate dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b),'all') == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);
assert(all(A(:,1) > 0));
assert(all(A(:,2) > 0));

% package constraint
Const.Constraint9.A = A;
Const.Constraint9.b = b;
Const.Constraint9.eq = eq;
Const.Constraint9.info = "constrain values of 'on' periods for s2.center";
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end