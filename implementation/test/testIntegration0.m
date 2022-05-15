addpath('../');
sim = testGetParam0();
var = util.getVarParam(sim);
Const = con.getConstAll(sim,var);
sol = testGetSolution0(sim, var);
model = util.toGurobi(Const,var);
result = gurobi(model);
if 1 ...strcmp(result.status,'INFEASIBLE')
    Const = visualizeConstraints(Const, var.nVar, sol);
end



function Const = visualizeConstraints(Const,  nVar, sol)
for iConst = 1:Const.nConst
    name = "Constraint" + string(iConst);
    curConst = Const.(name);
    equalityIdx = find(curConst.eq == '=');
    lessThanIdx = find(curConst.eq == '<');
    A = toSparse(curConst.A, nVar);
    b = curConst.b;
    Aeq = A(equalityIdx,:);
    Ain = A(lessThanIdx,:);
    beq = b(equalityIdx);
    bin = b(lessThanIdx);    

    % plot constraint and solution values
    figure;
    Const.(name).eval.sol = sol;
    if ~isempty(equalityIdx) && ~isempty(lessThanIdx)
        subplot(1,2,1);
        plot(Aeq*sol,'blue','linewidth',2); hold on;
        plot(beq,'--','color','red');
        title("Blue == red " + name);
        legend('solution','b');
        Const.(name).eval.equality.Aeq = Aeq;
        Const.(name).eval.equality.SolEq = Aeq*sol;
        Const.(name).eval.equality.isIncorrect = any(Aeq*sol ~= beq);
        badConstIdx = find(Aeq*sol ~= beq);
        Const.(name).eval.equality.badConstIdx = badConstIdx;
        Const.(name).eval.equality.badConstA = Aeq(badConstIdx,:);
        Const.(name).eval.equality.badConstb = beq(badConstIdx);

        subplot(1,2,2);        
        plot(Ain*sol,'blue','linewidth',2); hold on; 
        plot(bin,'red');
        title("Blue <= red " + name);
        legend('solution','b');
        Const.(name).eval.inequality.Ain = Ain;
        Const.(name).eval.inequality.SolIn = Ain*sol;
        Const.(name).eval.inequality.isIncorrect = any(Ain*sol > bin);
        badConstIdx = find(Ain*sol > bin);
        Const.(name).eval.inequality.badConstIdx = badConstIdx;
        Const.(name).eval.inequality.badConstA = Ain(badConstIdx,:);
        Const.(name).eval.inequality.badConstb = bin(badConstIdx);

    elseif ~isempty(equalityIdx)
        plot(Aeq*sol,'blue','linewidth',2); hold on; 
        plot(beq,'--','color','red');
        title("Blue == red " + name);
        legend('solution','b');
        Const.(name).eval.equality.Aeq = Aeq;
        Const.(name).eval.equality.SolEq = Aeq*sol;
        Const.(name).eval.equality.isIncorrect = any(Aeq ~= beq);
        badConstIdx = find(Aeq*sol ~= beq);
        Const.(name).eval.equality.badConstIdx = badConstIdx;
        Const.(name).eval.equality.badConstA = Aeq(badConstIdx,:);
        Const.(name).eval.equality.badConstb = beq(badConstIdx);
    else
        plot(Ain*sol,'blue','linewidth',2); hold on; 
        plot(bin,'red'); 
        title("Blue <= red " + name);
        legend('solution','b');
        Const.(name).eval.inequality.Ain = Ain;
        Const.(name).eval.inequality.SolIn = Ain*sol;
        Const.(name).eval.inequality.isIncorrect = any(Ain*sol > bin);
        badConstIdx = find(Ain*sol > bin);
        Const.(name).eval.inequality.badConstIdx = badConstIdx;
        Const.(name).eval.inequality.badConstA = Ain(badConstIdx,:);
        Const.(name).eval.inequality.badConstb = bin(badConstIdx);
    end
end
end

function spA = toSparse(A, nCol)
nRow = max(A(:,1));
spA = sparse(A(:,1), A(:,2), A(:,3), nRow, nCol);
end