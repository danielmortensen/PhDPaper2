function Const = getConst03(param,var,Const)
nConst = sum(param.routes.nRoute)^2*param.charger.nCharger;
nVal = nConst*4;

% preallocate
A = nan([nVal,3]);
b = nan([nConst,1]);
debug = nan([nConst,4]);
% define constraints when needed
iConstr = 1;
iA = 1;
M = param.maxTime*2;
for iBus = 1:param.bus.nBus
    for iRoute = 1:param.routes.nRoute(iBus)
        curIArrival = param.routes.tArrival(iBus,iRoute);
        curIDepart = param.routes.tDepart(iBus,iRoute);
        for jBus = 1:param.bus.nBus
            for jRoute = 1:param.routes.nRoute(jBus)
                curJDepart = param.routes.tDepart(jBus,jRoute);
                if (curJDepart > curIArrival) && (curJDepart < curIDepart)
                    ci = var.val.c.val(iBus,iRoute);
                    sj = var.val.s.val(jBus,jRoute);
                    for kCharger = 1:param.charger.nCharger
                        sgmI = var.val.sigma.val(iBus,iRoute,kCharger);
                        sgmJ = var.val.sigma.val(jBus,jRoute,kCharger);
                        A(iA + 0,:) = [iConstr, ci,  -1];
                        A(iA + 1,:) = [iConstr, sj,   1];
                        A(iA + 2,:) = [iConstr, sgmI, M];
                        A(iA + 3,:) = [iConstr, sgmJ, M];
                        b(iConstr) = M;
                        iConstr = iConstr + 1;
                        iA = iA + 4;                        
                    end
                    debug(iConstr,:) = [iBus, iRoute, jBus, jRoute];
                end
            end
        end
    end
end

% trim unneeded values
A(any(isnan(A),2),:) = [];
b(isnan(b)) = [];
debug(any(isnan(debug),2),:) = [];
nConst = size(b,1);
nVal = size(A,1);
assert(all(A(:,1) > 0));
assert(all(A(:,2) > 0));

% package constraint
Const.Constraint3.A = A;
Const.Constraint3.b = b;
Const.Constraint3.info = "constrains all buses that charge at the same " + ...
    "time to charge on different chargers.";
Const.Constraint3.eq = repmat('<',[nConst,1]);
Const.Constraint3.debug = debug;
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end
