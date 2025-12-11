function retirement_planner_gui
% RETIREMENT_PLANNER_GUI
% Step 1: compute S from cost categories
% Step 2: specify retirement horizon, inflation, return range, current savings, age
% Step 3: view required contributions and balance graphs (for a range of returns)
% S = H + Trans + Food + Med + W  (all monthly in today's dollars)

    % Main window + layout
    f = uifigure('Name','Retirement Planner','Position',[100 100 1100 720]);

    mainGL = uigridlayout(f,[2 1]);
    mainGL.RowHeight   = {'1x',60};     % more space for bottom buttons
    mainGL.ColumnWidth = {'1x'};

    % Content container
    contentPanel = uipanel(mainGL);
    contentPanel.Layout.Row    = 1;
    contentPanel.Layout.Column = 1;

    contentGL = uigridlayout(contentPanel,[1 1]);
    contentGL.RowHeight   = {'1x'};
    contentGL.ColumnWidth = {'1x'};

    % Navigation container
    navPanel = uipanel(mainGL);
    navPanel.Layout.Row    = 2;
    navPanel.Layout.Column = 1;

    navGL = uigridlayout(navPanel,[1 3]);
    navGL.ColumnWidth = {150, '1x', 150};
    navGL.RowHeight   = {'1x'};
    navGL.Padding     = [10 5 10 5];

    prevBtn = uibutton(navGL,'Text','< Previous','ButtonPushedFcn',@onPrev);
    prevBtn.Layout.Row = 1; prevBtn.Layout.Column = 1;

    stepLabel = uilabel(navGL,'Text','Step 1 of 3: Monthly Spending',...
                        'HorizontalAlignment','center');
    stepLabel.Layout.Row = 1; stepLabel.Layout.Column = 2;

    nextBtn = uibutton(navGL,'Text','Next >','ButtonPushedFcn',@onNext);
    nextBtn.Layout.Row = 1; nextBtn.Layout.Column = 3;

    % ===========================
    % Page 1: Cost breakdown -> S
    % ===========================
    page1 = uipanel(contentGL,'Title','Step 1: Monthly Spending (S = H + Trans + Food + Med + W)');
    page1.Layout.Row = 1; page1.Layout.Column = 1;

    gl1 = uigridlayout(page1,[8 4]);
    gl1.ColumnWidth = {'1x','1x','1x','1x'};
    gl1.RowHeight   = {30,30,30,30,30,30,30,'1x'};

    uilabel(gl1,'Text','Monthly Housing (H):','HorizontalAlignment','right');
    HField  = uieditfield(gl1,'numeric','Value',2000,'Limits',[0 Inf]); 
    HField.Layout.Column = [2 4];

    uilabel(gl1,'Text','Monthly Transportation (Trans):','HorizontalAlignment','right');
    TransField  = uieditfield(gl1,'numeric','Value',600,'Limits',[0 Inf]); 
    TransField.Layout.Column = [2 4];

    uilabel(gl1,'Text','Monthly Food (Food):','HorizontalAlignment','right');
    FoodField  = uieditfield(gl1,'numeric','Value',600,'Limits',[0 Inf]); 
    FoodField.Layout.Column = [2 4];

    uilabel(gl1,'Text','Monthly Medical (Med):','HorizontalAlignment','right');
    MedField  = uieditfield(gl1,'numeric','Value',400,'Limits',[0 Inf]); 
    MedField.Layout.Column = [2 4];

    uilabel(gl1,'Text','Monthly Wants (W total):','HorizontalAlignment','right');
    WField  = uieditfield(gl1,'numeric','Value',800,'Limits',[0 Inf]); 
    WField.Layout.Column = [2 4];

    uilabel(gl1,'Text','Total monthly spending S (computed):','HorizontalAlignment','right');
    SLabel = uilabel(gl1,'Text','$0.00','FontWeight','bold');
    SLabel.Layout.Column = [2 4];

    computeSBtn = uibutton(gl1,'Text','Compute S','ButtonPushedFcn',@onComputeS);
    computeSBtn.Layout.Row = 6; computeSBtn.Layout.Column = 1;

    note1 = uilabel(gl1,'Text',...
        'All amounts are monthly in today''s dollars. S is your post-retirement spending target.',...
        'FontAngle','italic');
    note1.Layout.Row = 7; note1.Layout.Column = [1 4];

    % ===========================
    % Page 2: Retirement inputs & return range
    % ===========================
    page2 = uipanel(contentGL,'Title','Step 2: Retirement Horizon and Return Assumptions');
    page2.Layout.Row = 1; page2.Layout.Column = 1;
    page2.Visible = 'off';

    gl2 = uigridlayout(page2,[9 4]);
    gl2.ColumnWidth = {'1x','1x','1x','1x'};
    gl2.RowHeight   = {30,30,30,30,30,30,30,30,'1x'};

    uilabel(gl2,'Text','Total monthly spending S (from Step 1):','HorizontalAlignment','right');
    SDisplayLabel = uilabel(gl2,'Text','$0.00','FontWeight','bold');
    SDisplayLabel.Layout.Column = [2 4];

    uilabel(gl2,'Text','Years until retirement (T):','HorizontalAlignment','right');
    TField  = uieditfield(gl2,'numeric','Value',25,'Limits',[0 Inf]);   
    TField.Layout.Column = [2 4];

    uilabel(gl2,'Text','Years in retirement (L):','HorizontalAlignment','right');
    LField  = uieditfield(gl2,'numeric','Value',30,'Limits',[0 Inf]);   
    LField.Layout.Column = [2 4];

    uilabel(gl2,'Text','Nominal annual return MIN (decimal, e.g., 0.06):','HorizontalAlignment','right');
    rMinField  = uieditfield(gl2,'numeric','Value',0.06,'Limits',[0 1]); 
    rMinField.Layout.Column = [2 4];

    uilabel(gl2,'Text','Nominal annual return MAX (decimal, e.g., 0.12):','HorizontalAlignment','right');
    rMaxField  = uieditfield(gl2,'numeric','Value',0.12,'Limits',[0 1]); 
    rMaxField.Layout.Column = [2 4];

    uilabel(gl2,'Text','Annual inflation (decimal, e.g., 0.03):','HorizontalAlignment','right');
    piField = uieditfield(gl2,'numeric','Value',0.03,'Limits',[0 1]);   
    piField.Layout.Column = [2 4];

    uilabel(gl2,'Text','Current savings (P0) ($):','HorizontalAlignment','right');
    P0Field = uieditfield(gl2,'numeric','Value',0,'Limits',[0 Inf]);    
    P0Field.Layout.Column = [2 4];

    uilabel(gl2,'Text','Current age (years):','HorizontalAlignment','right');
    AgeField = uieditfield(gl2,'numeric','Value',25,'Limits',[0 120]);  
    AgeField.Layout.Column = [2 4];

    % ===========================
    % Page 3: Results (graphs + summary)
    % ===========================
    page3 = uipanel(contentGL,'Title','Step 3: Results');
    page3.Layout.Row = 1; page3.Layout.Column = 1;
    page3.Visible = 'off';

    gl3 = uigridlayout(page3,[4 2]);
    gl3.RowHeight   = {'fit','fit','3x','1x'};
    gl3.ColumnWidth = {'fit','1x'};

    uilabel(gl3,'Text','Scenarios (rate → required C):','HorizontalAlignment','right');
    CLabel = uilabel(gl3,'Text','—','FontWeight','bold');

    uilabel(gl3,'Text','Required nest egg @ retirement (nominal $) [baseline=min rate]:','HorizontalAlignment','right');
    BNLabel = uilabel(gl3,'Text','—');

    ax = uiaxes(gl3);
    ax.Layout.Row = 3; 
    ax.Layout.Column = [1 2];
    title(ax,'Retirement Account Balance — Return Scenarios');
    xlabel(ax,'Age (years)'); ylabel(ax,'Balance ($)');
    grid(ax,'on');

    detailsArea = uitextarea(gl3,'Editable','off','Value',{'Complete Steps 1 and 2, then click Next to view results.'});
    detailsArea.Layout.Row = 4; 
    detailsArea.Layout.Column = [1 2];

    % State
    currentPage = 1;

    % ===========================
    % Navigation helpers
    % ===========================
    function showPage(p)
        currentPage = p;
        switch p
            case 1
                page1.Visible = 'on';
                page2.Visible = 'off';
                page3.Visible = 'off';
                prevBtn.Enable = 'off';
                nextBtn.Enable = 'on';
                nextBtn.Text   = 'Next >';
                stepLabel.Text = 'Step 1 of 3: Monthly Spending';
            case 2
                page1.Visible = 'off';
                page2.Visible = 'on';
                page3.Visible = 'off';
                prevBtn.Enable = 'on';
                nextBtn.Enable = 'on';
                nextBtn.Text   = 'Next >';
                stepLabel.Text = 'Step 2 of 3: Retirement Inputs';
            case 3
                page1.Visible = 'off';
                page2.Visible = 'off';
                page3.Visible = 'on';
                prevBtn.Enable = 'on';
                nextBtn.Enable = 'off';
                stepLabel.Text = 'Step 3 of 3: Results';
        end
    end

    function onPrev(~,~)
        if currentPage > 1
            showPage(currentPage - 1);
        end
    end

    function onNext(~,~)
        switch currentPage
            case 1
                updateSLabel();
                showPage(2);
            case 2
                ok = computeAndPlot();
                if ok
                    showPage(3);
                end
        end
    end

    % ===========================
    % Cost computation (S)
    % ===========================
    function onComputeS(~,~)
        updateSLabel();
    end

    function updateSLabel()
        H    = HField.Value;
        Trans= TransField.Value;
        Food = FoodField.Value;
        Med  = MedField.Value;
        W    = WField.Value;
        S    = H + Trans + Food + Med + W;
        SLabel.Text        = dollar(S);
        SDisplayLabel.Text = dollar(S);
    end

    % ===========================
    % Core computation and plotting
    % ===========================
    function ok = computeAndPlot()
        ok = false;
        try
            H    = HField.Value;
            Trans= TransField.Value;
            Food = FoodField.Value;
            Med  = MedField.Value;
            W    = WField.Value;
            S    = H + Trans + Food + Med + W;

            T    = TField.Value;
            L    = LField.Value;
            rMin = rMinField.Value;
            rMax = rMaxField.Value;
            pi   = piField.Value;
            P0   = P0Field.Value;
            age  = AgeField.Value;

            validateInputs(S,T,L,rMin,rMax,pi,P0,age);

            if abs(rMax - rMin) < 1e-12
                rates = rMin;
            else
                rates = linspace(rMin, rMax, 4);
            end

            cla(ax); hold(ax,'on');
            years_max = age + T + L;
            Cs = zeros(numel(rates),1);

            retireAge = age + T; 
            endAge    = age + T + L;
            yMin = 0; yMax = 1;

            hSav = patch(ax, [age retireAge retireAge age], [0 0 1 1], [0 0.5 0], ...
                'FaceAlpha',0.08,'EdgeColor','none','HandleVisibility','off');
            hRet = patch(ax, [retireAge endAge endAge retireAge], [0 0 1 1], [0.8 0 0], ...
                'FaceAlpha',0.08,'EdgeColor','none','HandleVisibility','off');

            colors = lines(max(4,numel(rates)));

            for k = 1:numel(rates)
                i = rates(k);
                [C, d] = compute_retirement_contribution(S, T, L, i, pi, P0, false);
                Cs(k) = C;
                if k == 1
                    BNLabel.Text = dollar(d.B_nominal);
                end

                [tMonths, bal] = simulate_balance(S, T, L, i, pi, P0, C);
                yearsFromToday = tMonths/12;
                ages = age + yearsFromToday;

                plot(ax, ages, bal, 'LineWidth', 1.7, 'Color', colors(k,:), ...
                    'DisplayName', sprintf('i = %.1f%%  (C = %s)', 100*i, dollar(C)));

                if k == 1
                    yMin = min(0, min(bal)*1.05);
                    yMax = max(max(1, max(bal)*1.10), 1);
                else
                    yMin = min(yMin, min(0, min(bal)*1.05));
                    yMax = max(yMax, max(max(1, max(bal)*1.10), 1));
                end
            end

            set(hSav,'YData',[yMin yMin yMax yMax]);
            set(hRet,'YData',[yMin yMin yMax yMax]);

            xline(ax, retireAge, '--', sprintf('Retire (Age %.0f)', retireAge), ...
                'LabelHorizontalAlignment','left', ...
                'LabelVerticalAlignment','bottom');

            xlim(ax, [age, years_max]);
            ylim(ax, [yMin, yMax]);
            xlabel(ax,'Age (years)');
            legend(ax,'Location','northeast');

            if numel(rates) == 1
                CLabel.Text = sprintf('i = %.2f%% → C = %s', 100*rates(1), dollar(Cs(1)));
            else
                parts = strings(numel(rates),1);
                for k = 1:numel(rates)
                    parts(k) = sprintf('%.0f%%→%s', 100*rates(k), dollar(Cs(k)));
                end
                CLabel.Text = strjoin(parts, '   |   ');
            end

            detailsArea.Value = { ...
                sprintf('Housing (H):             $%.2f', H), ...
                sprintf('Transportation (Trans):  $%.2f', Trans), ...
                sprintf('Food:                     $%.2f', Food), ...
                sprintf('Medical (Med):            $%.2f', Med), ...
                sprintf('Wants (W total):          $%.2f', W), ...
                sprintf('Total S = H+Trans+Food+Med+W: $%.2f', S), ...
                ' ', ...
                sprintf('Current age: %.0f', age), ...
                sprintf('Retirement age: %.0f', retireAge), ...
                sprintf('End age: %.0f', endAge), ...
                sprintf('Years to retirement (T): %g', T), ...
                sprintf('Years in retirement (L): %g', L), ...
                sprintf('Inflation (annual, decimal): %.4f', pi), ...
                sprintf('Return scenarios (annual, decimal): [%s]', join(string(rates), ', ')), ...
                'Each line uses its own required monthly contribution C for that return.' ...
            };

            ok = true;

        catch ME
            uialert(f, ME.message, 'Input Error');
        end
    end

    % Helpers
    function [tMonths, bal] = simulate_balance(S, T, L, i, pi, P0, C)
        j  = i  / 12;
        g  = pi / 12;
        Nw = round(12 * T);
        Nr = round(12 * L);
        total = Nw + Nr;

        bal = zeros(total + 1, 1);
        bal(1) = P0;

        for t = 1:Nw
            bal(t+1) = bal(t) * (1 + j) + C;
        end

        for t = Nw+1:total
            m = t - Nw;
            withdrawNom = S * (1 + g)^(Nw + m);
            bal(t+1) = bal(t) * (1 + j) - withdrawNom;
        end

        tMonths = (0:total)';
    end

    function validateInputs(S,T,L,rMin,rMax,pi,P0,age)
        if S < 0 || T < 0 || L < 0 || P0 < 0 || age < 0
            error('S, T, L, age, and P0 must be non-negative.');
        end
        if ~isfinite(rMin) || ~isfinite(rMax) || ~isfinite(pi)
            error('Rates must be finite numbers.');
        end
        if ~(pi >= 0 && pi < 1)
            error('Inflation must be a DECIMAL in [0,1): e.g., 0.03 for 3%%.');
        end
        if ~(rMin >= 0 && rMin < 1) || ~(rMax >= 0 && rMax < 1)
            error('Return min/max must be DECIMALS in [0,1).');
        end
        if rMax < rMin
            error('Return MAX must be >= MIN.');
        end
        if age > 120
            error('Please enter a plausible age (0–120).');
        end
    end

    function out = dollar(v)
        out = sprintf('$%s', formatMoney(v));
    end

    function s = formatMoney(x)
        try
            s = compose('%,.2f', x);
            s = s{1};
        catch
            try
                if usejava('jvm')
                    nf = java.text.NumberFormat.getNumberInstance(java.util.Locale.US);
                    nf.setGroupingUsed(true);
                    nf.setMinimumFractionDigits(2);
                    nf.setMaximumFractionDigits(2);
                    s = char(nf.format(x));
                else
                    s = sprintf('%.2f', x);
                end
            catch
                s = sprintf('%.2f', x);
            end
        end
    end

    % Start on page 1
    showPage(1);

end
