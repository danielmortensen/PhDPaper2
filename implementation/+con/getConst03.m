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
M = param.maxTime;
for iBus = 1:param.bus.nBus
    for iRoute = 1:param.routes.nRoute(iBus)        
        for jBus = 1:param.bus.nBus
            for jRoute = 1:param.routes.nRoute(jBus)
                l = var.val.l.val(iBus,iRoute,jBus,jRoute);
                if ~isnan(l)
                    ci = var.val.c.val(iBus,iRoute);
                    si = var.val.s.val(iBus,iRoute);
                    cj = var.val.c.val(jBus,jRoute);
                    sj = var.val.s.val(jBus,jRoute);
                    for kCharger = 1:param.charger.nCharger
                        sgmI = var.val.sigma.val(iBus,iRoute,kCharger);
                        sgmJ = var.val.sigma.val(jBus,jRoute,kCharger);

                        % first constraint
                        A(iA + 0,:) = [iConstr + 0, ci,  -1];
                        A(iA + 1,:) = [iConstr + 0, sj,   1];
                        A(iA + 2,:) = [iConstr + 0, sgmI, M];
                        A(iA + 3,:) = [iConstr + 0, sgmJ, M];
                        A(iA + 4,:) = [iConstr + 0, l,   -M];
                        b(iConstr) = 2*M;

                        % second constraint
                        A(iA + 5,:) = [iConstr + 1, si,   1];
                        A(iA + 6,:) = [iConstr + 1, cj,  -1];
                        A(iA + 7,:) = [iConstr + 1, sgmI, M];
                        A(iA + 8,:) = [iConstr + 1, sgmJ, M];
                        A(iA + 9,:) = [iConstr + 1, l,    M];
                        b(iConstr + 1) = 3*M;

                        % update indexing variables
                        iConstr = iConstr + 2;
                        iA = iA + 10;                        
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
