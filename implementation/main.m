sim = util.getSimParam();
var = util.getVarParam(sim);
const = con.getConst01(sim,var,struct('nConst',0, 'nAllVal',0,'nAllCon',0));
const = con.getConst02(sim,var,const);
const = con.getConst03(sim,var,const);
const = con.getConst04(sim,var,const);
const = con.getConst05(sim,var,const);
const = con.getConst06(sim,var,const);
const = con.getConst07(sim,var,const);
const = con.getConst08(sim,var,const);
const = con.getConst09(sim,var,const);
const = con.getConst10(sim,var,const);
const = con.getConst11(sim,var,const);
const = con.getConst12(sim,var,const);
const = con.getConst13(sim,var,const);
const = con.getConst14(sim,var,const);
const = con.getConst15(sim,var,const);
const = con.getObjective(sim,var,const);

% concatenate all sparse matrices
nAllCon = const.nAllCon;
nAllVal = const.nAllVal;
iAllCon = 1;
iAllVal = 1;
A = nan([nAllVal,3]);
b = nan([nAllCon,1]);
eq = nan([nAllCon,1]);

% concatenate values for each constraint
for iConst = 1:const.nConst
    % define loop variables
    name = "Constraint" + string(iConst);
    curConst = const.(name);
    nCurVal = size(curConst.A,1);
    nCurCon = size(curConst.b,1);

    % concatenate relevent values
    curConst.A(:,1) = curConst.A(:,1) + iAllCon - 1;
    A(iAllVal:iAllVal + nCurVal - 1,:) = curConst.A;
    
    b(iAllCon:iAllCon + nCurCon - 1,:) = curConst.b;
    eq(iAllCon:iAllCon + nCurCon - 1,:) = curConst.eq;

    % increment indices
    iAllCon = iAllCon + nCurCon;
    iAllVal = iAllVal + nCurVal;
end

% sanity check dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b),'all') == 0);
assert(size(A,1) == nAllVal);
assert(size(b,1) == nAllCon);

% convert to sparse matrix
A = sparse(A(:,1), A(:,2), A(:,3));
assert(size(A,1) == nAllCon);
assert(size(A,2) == var.nVar);
assert(size(b,1) == nAllCon);

% create gurobi model
model.vtype = var.type;
model.A = A;
model.rhs = b;
model.sense = char(eq);
model.obj = const.obj;

solution = gurobi(model);


