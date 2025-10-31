% RETIREMENT_PLANNER_CLI
% Simple command-line interface for the retirement contribution calculator.

clc; fprintf('Retirement Planner (CLI)\n');
fprintf('Provide values; press Enter to accept defaults in [brackets].\n\n');

% Helper to read a value with default
read = @(prompt, def) local_read(prompt, def);

S   = read('Desired monthly spending today ($)', 5000);
T   = read('Years until retirement',              25);
L   = read('Years in retirement',                 30);
i   = read('Nominal annual return (%% or decimal)', 6);    % accept 6 or 0.06
pi  = read('Annual inflation (%% or decimal)',       3);    % accept 3 or 0.03
P0  = read('Current savings ($)',                  0);
isAD = read('Contribute at BEGINNING of month? (1=yes, 0=no)', 0) ~= 0;

[C, d] = compute_retirement_contribution(S, T, L, i, pi, P0, isAD);

fprintf('\n--- Results ---\n');
fprintf('Required monthly contribution: $%0.2f\n', C);
fprintf('Required real nest egg at retirement: $%0.2f\n', d.B_real);
fprintf('Required nominal nest egg at retirement: $%0.2f\n', d.B_nominal);
fprintf('Months until retirement: %d\n', round(d.Nw));
fprintf('Months in retirement: %d\n', round(d.Nr));
fprintf('Assumed monthly nominal return j: %0.6f\n', d.j);
fprintf('Assumed monthly inflation g: %0.6f\n', d.g);
fprintf('Assumed monthly real return r: %0.6f\n', d.r);
fprintf('----------------\n');

function val = local_read(prompt, def)
    if isnumeric(def), defStr = num2str(def); else, defStr = def; end
    s = input(sprintf('%s [%s]: ', prompt, defStr), 's');
    if isempty(s)
        val = def;
        return;
    end
    % Try to parse numeric; allow "6%%" or "0.06"
    s = strrep(s, '%', '');
    val = str2double(s);
    if isnan(val)
        warning('Invalid input. Using default %s.', defStr);
        val = def;
    end
end
