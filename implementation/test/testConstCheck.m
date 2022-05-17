function Const = testConstCheck(Const,  nVar, sol, doPlots)
if nargin == 3
    doPlots = false;
elseif strcmp(doPlots,'plotResults')
    doPlots = true;
else
    doPlots = false;
end

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
    if doPlots
        figure;
    end
    Const.(name).eval.sol = sol;
    if ~isempty(equalityIdx) && ~isempty(lessThanIdx)
        if doPlots
            subplot(1,2,1);
            plot(Aeq*sol,'blue','linewidth',2); hold on;
            plot(beq,'--','color','red');
            title("Blue == red " + name);
            legend('solution','b');
        end
        Const.(name).eval.equality.Aeq = Aeq;
        Const.(name).eval.equality.SolEq = Aeq*sol;
        Const.(name).eval.equality.isCorrect = all(isAlmost(Aeq*sol, beq));
        badConstIdx = find(Aeq*sol ~= beq);
        Const.(name).eval.equality.badConstIdx = badConstIdx;
        Const.(name).eval.equality.badConstA = Aeq(badConstIdx,:);
        Const.(name).eval.equality.badConstb = beq(badConstIdx);
        Const.(name).eval.equality.beq = beq;

        if doPlots
            subplot(1,2,2);
            plot(Ain*sol,'blue','linewidth',2); hold on;
            plot(bin,'red');
            title("Blue <= red " + name);
            legend('solution','b');
        end
        Const.(name).eval.inequality.Ain = Ain;
        Const.(name).eval.inequality.SolIn = Ain*sol;
        Const.(name).eval.inequality.isCorrect = all(Ain*sol <= bin);
        badConstIdx = find(Ain*sol > bin);
        Const.(name).eval.inequality.badConstIdx = badConstIdx;
        Const.(name).eval.inequality.badConstA = Ain(badConstIdx,:);
        Const.(name).eval.inequality.badConstb = bin(badConstIdx);
        Const.(name).eval.inequality.bin = bin;

    elseif ~isempty(equalityIdx)
        if doPlots
            plot(Aeq*sol,'blue','linewidth',2); hold on;
            plot(beq,'--','color','red');
            title("Blue == red " + name);
            legend('solution','b');
        end
        Const.(name).eval.equality.Aeq = Aeq;
        Const.(name).eval.equality.SolEq = Aeq*sol;
        Const.(name).eval.equality.isCorrect = all(isAlmost(Aeq*sol, beq));
        badConstIdx = find(Aeq*sol ~= beq);
        Const.(name).eval.equality.badConstIdx = badConstIdx;
        Const.(name).eval.equality.badConstA = Aeq(badConstIdx,:);
        Const.(name).eval.equality.badConstb = beq(badConstIdx);
        Const.(name).eval.equality.beq = beq;
    else
        if doPlots
            plot(Ain*sol,'blue','linewidth',2); hold on;
            plot(bin,'red');
            title("Blue <= red " + name);
            legend('solution','b');
        end
        Const.(name).eval.inequality.Ain = Ain;
        Const.(name).eval.inequality.SolIn = Ain*sol;
        Const.(name).eval.inequality.isCorrect = all(Ain*sol <= bin);
        badConstIdx = find(Ain*sol > bin);
        Const.(name).eval.inequality.badConstIdx = badConstIdx;
        Const.(name).eval.inequality.badConstA = Ain(badConstIdx,:);
        Const.(name).eval.inequality.badConstb = bin(badConstIdx);
        Const.(name).eval.inequality.bin = bin;
    end
end
end

function spA = toSparse(A, nCol)
nRow = max(A(:,1));
spA = sparse(A(:,1), A(:,2), A(:,3), nRow, nCol);
end