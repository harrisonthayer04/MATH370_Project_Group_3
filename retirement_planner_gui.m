function retirement_planner_gui
% RETIREMENT_PLANNER_GUI
% GUI to compute required monthly retirement contributions and visualize balance.
% - X-axis shows AGE (years)
% - Results area resizes with window
% - Assumes END-of-month contributions (annuity-immediate)
% - Inflation must be a DECIMAL (e.g., 0.03)
% - NEW: User sets a RETURN RANGE [min,max] (decimals). We plot 4 scenarios
%        at evenly spaced rates across the range; each scenario computes its own C.

    % --- UI Shell ---
    f = uifigure('Name','Retirement Planner','Position',[100 100 980 600]);
    gl = uigridlayout(f, [12 4]);
    gl.ColumnWidth = {'1x','1x','1x','1x'};
    % Row 12 is the stretch row so the output area resizes with the window
    gl.RowHeight   = {30,30,30,30,30,30,30,30,30,30,'fit','1x'};

    % --- Inputs ---
    uilabel(gl,'Text','Desired monthly spending today ($):','HorizontalAlignment','right');
    SField  = uieditfield(gl,'numeric','Value',5000,'Limits',[0 Inf]); SField.Layout.Column = [2 4];

    uilabel(gl,'Text','Years until retirement:','HorizontalAlignment','right');
    TField  = uieditfield(gl,'numeric','Value',25,'Limits',[0 Inf]);   TField.Layout.Column = [2 4];

    uilabel(gl,'Text','Years in retirement:','HorizontalAlignment','right');
    LField  = uieditfield(gl,'numeric','Value',30,'Limits',[0 Inf]);   LField.Layout.Column = [2 4];

    % --- Return RANGE (decimals) ---
    uilabel(gl,'Text','Nominal annual return MIN (decimal, e.g., 0.06):','HorizontalAlignment','right');
    rMinField  = uieditfield(gl,'numeric','Value',0.06,'Limits',[0 1]); rMinField.Layout.Column = [2 4];

    uilabel(gl,'Text','Nominal annual return MAX (decimal, e.g., 0.12):','HorizontalAlignment','right');
    rMaxField  = uieditfield(gl,'numeric','Value',0.12,'Limits',[0 1]); rMaxField.Layout.Column = [2 4];

    uilabel(gl,'Text','Annual inflation (decimal, e.g., 0.03):','HorizontalAlignment','right');
    piField = uieditfield(gl,'numeric','Value',0.03,'Limits',[0 1]);   piField.Layout.Column = [2 4];

    uilabel(gl,'Text','Current savings ($):','HorizontalAlignment','right');
    P0Field = uieditfield(gl,'numeric','Value',0,'Limits',[0 Inf]);    P0Field.Layout.Column = [2 4];

    uilabel(gl,'Text','Current age (years):','HorizontalAlignment','right');
    AgeField = uieditfield(gl,'numeric','Value',25,'Limits',[0 120]);  AgeField.Layout.Column = [2 4];

    % --- Buttons ---
    calcBtn = uibutton(gl,'Text','Compute & Plot Scenarios','ButtonPushedFcn',@onCompute);
    calcBtn.Layout.Column = [1 2];
    resetBtn = uibutton(gl,'Text','Reset','ButtonPushedFcn',@onReset);
    resetBtn.Layout.Column = [3 4];

    % --- Note (fixed-height rows) ---
    note1 = uilabel(gl,'Text',...
        'Returns & inflation must be decimals (e.g., 0.06 = 6%). We plot 4 evenly spaced return scenarios across your range.',...
        'FontAngle','italic');
    note1.Layout.Row = 11; note1.Layout.Column = [1 4];

    % --- Results Area (resizable row 12) ---
    resultPanel = uipanel(gl,'Title','Results'); 
    resultPanel.Layout.Row = 12; 
    resultPanel.Layout.Column = [1 4];

    % Inner grid that resizes: labels 'fit', values/chart/details stretch
    rg = uigridlayout(resultPanel,[4 2]); 
    rg.RowHeight   = {'fit','fit','3x','1x'};
    rg.ColumnWidth = {'fit','1x'};

    uilabel(rg,'Text','Scenarios (rate → required C):','HorizontalAlignment','right');
    CLabel = uilabel(rg,'Text','—','FontWeight','bold'); % will show summary of Cs per rate

    uilabel(rg,'Text','Required nest egg @ retirement (nominal $) [baseline=min rate]:','HorizontalAlignment','right');
    BNLabel = uilabel(rg,'Text','—');

    % Chart occupies big row 3
    ax = uiaxes(rg);
    ax.Layout.Row = 3; 
    ax.Layout.Column = [1 2];
    title(ax,'Retirement Account Balance — Return Scenarios');
    xlabel(ax,'Age (years)'); ylabel(ax,'Balance ($)');
    grid(ax,'on');

    % Details area (row 4)
    detailsArea = uitextarea(rg,'Editable','off','Value',{'Press Compute to view details...'});
    detailsArea.Layout.Row = 4; 
    detailsArea.Layout.Column = [1 2];

    % ===========================
    % Callbacks (nested functions)
    % ===========================

    function onCompute(~,~)
        % Compute button callback
        try
            S    = SField.Value;
            T    = TField.Value;
            L    = LField.Value;
            rMin = rMinField.Value;   % DECIMAL REQUIRED
            rMax = rMaxField.Value;   % DECIMAL REQUIRED
            pi   = piField.Value;     % DECIMAL REQUIRED
            P0   = P0Field.Value;
            age  = AgeField.Value;    % Current age in years

            validateInputs(S,T,L,rMin,rMax,pi,P0,age);

            % Build 4 evenly spaced scenarios across [rMin, rMax]
            if abs(rMax - rMin) < 1e-12
                rates = rMin; % single scenario if equal
            else
                rates = linspace(rMin, rMax, 4);
            end

            % Compute C and simulate for each scenario
            cla(ax); hold(ax,'on');
            years_max = age + T + L;
            legendEntries = {};
            Cs = zeros(numel(rates),1);
            B_nominal_baseline = NaN;

            % Shaded phases (draw once, behind lines)
            % Use baseline (min) for vertical markers; shading applies to all scenarios equally
            retireAge = age + T; endAge = age + T + L;
            yMin = 0; yMax = 1; % temporary; update after plotting
            hSav = patch(ax, [age retireAge retireAge age], [0 0 1 1], [0 0.5 0], ...
                'FaceAlpha',0.08,'EdgeColor','none','HandleVisibility','off');
            hRet = patch(ax, [retireAge endAge endAge retireAge], [0 0 1 1], [0.8 0 0], ...
                'FaceAlpha',0.08,'EdgeColor','none','HandleVisibility','off');

            colors = lines(max(4,numel(rates))); % distinct colors

            for k = 1:numel(rates)
                i = rates(k);
                % Required monthly contribution for this rate
                [C, d] = compute_retirement_contribution(S, T, L, i, pi, P0, false);
                Cs(k) = C;
                if k == 1
                    BNLabel.Text = dollar(d.B_nominal); % show baseline nest egg (min rate)
                end

                % Simulate balance path for this scenario
                [tMonths, bal] = simulate_balance(S, T, L, i, pi, P0, C);
                yearsFromToday = tMonths/12;
                ages = age + yearsFromToday;

                plot(ax, ages, bal, 'LineWidth', 1.7, 'Color', colors(k,:), ...
                    'DisplayName', sprintf('i = %.1f%%  (C = %s)', 100*i, dollar(C)));

                % Track y-lims
                if k == 1
                    yMin = min(0, min(bal)*1.05);
                    yMax = max( max(1, max(bal)*1.10), 1 );
                else
                    yMin = min(yMin, min(0, min(bal)*1.05));
                    yMax = max(yMax, max( max(1, max(bal)*1.10), 1 ));
                end
                legendEntries{end+1} = sprintf('i = %.1f%%  (C = %s)', 100*i, dollar(C)); %#ok<AGROW>
            end

            % Update shading to full y-range
            set(hSav,'YData',[yMin yMin yMax yMax]);
            set(hRet,'YData',[yMin yMin yMax yMax]);

            % Retirement marker with age label
            xline(ax, retireAge, '--', sprintf('Retire (Age %.0f)', retireAge), ...
                'LabelHorizontalAlignment','left', ...
                'LabelVerticalAlignment','bottom');

            xlim(ax, [age, years_max]);
            ylim(ax, [yMin, yMax]);
            xlabel(ax,'Age (years)');
            legend(ax,'Location','northeast');

            % Summary label of Cs
            if numel(rates) == 1
                CLabel.Text = sprintf('i = %.2f%% → C = %s', 100*rates(1), dollar(Cs(1)));
            else
                parts = strings(numel(rates),1);
                for k = 1:numel(rates)
                    parts(k) = sprintf('%.0f%%→%s', 100*rates(k), dollar(Cs(k)));
                end
                CLabel.Text = strjoin(parts, '   |   ');
            end

            % Details
            detailsArea.Value = { ...
                sprintf('Current age: %.0f', age), ...
                sprintf('Retirement age: %.0f', retireAge), ...
                sprintf('End age: %.0f', endAge), ...
                sprintf('Years to retirement (T): %g', T), ...
                sprintf('Years in retirement (L): %g', L), ...
                sprintf('Inflation (annual, decimal): %.4f', pi), ...
                sprintf('Return scenarios (annual, decimal): [%s]', join(string(rates), ', ')), ...
                'Note: Each line uses its own required monthly contribution C for that return.' ...
            };

        catch ME
            uialert(f, ME.message, 'Input Error');
        end
    end % onCompute

    function onReset(~,~)
        % Reset button callback
        SField.Value  = 5000;
        TField.Value  = 25;
        LField.Value  = 30;
        rMinField.Value = 0.06;
        rMaxField.Value = 0.12;
        piField.Value = 0.03;
        P0Field.Value = 0;
        AgeField.Value = 25;
        CLabel.Text  = '—';
        BNLabel.Text = '—';
        detailsArea.Value = {'Press Compute to view details...'};
        cla(ax);
    end % onReset

    % ==========
    % Helpers
    % ==========

    function [tMonths, bal] = simulate_balance(S, T, L, i, pi, P0, C)
        % Simulates nominal account balance with end-of-month contributions,
        % then end-of-month inflation-adjusted withdrawals in retirement.
        j  = i  / 12;                 % nominal monthly return
        g  = pi / 12;                 % monthly inflation
        Nw = round(12 * T);           % months until retirement
        Nr = round(12 * L);           % months in retirement
        total = Nw + Nr;

        bal = zeros(total + 1, 1);
        bal(1) = P0;

        % Accumulation (end-of-month deposits)
        for t = 1:Nw
            bal(t+1) = bal(t) * (1 + j) + C;
        end

        % Drawdown (end-of-month withdrawals, inflation-adjusted)
        for t = Nw+1:total
            m = t - Nw;  % month in retirement (1..Nr)
            withdrawNom = S * (1 + g)^(Nw + m); % S in today's $ -> nominal at this month-end
            bal(t+1) = bal(t) * (1 + j) - withdrawNom;
        end

        tMonths = (0:total)';         % 0..(Nw+Nr) months
    end % simulate_balance

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
    end % validateInputs

    function out = dollar(v)
        out = sprintf('$%s', formatMoney(v));
    end % dollar

    function s = formatMoney(x)
        % Robust money formatting across MATLAB versions.
        % Try compose with grouping, then Java NumberFormat, else fallback.
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
    end % formatMoney

end % retirement_planner_gui
