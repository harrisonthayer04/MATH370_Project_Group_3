function [C, details] = compute_retirement_contribution(S, T, L, i, pi, P0, isAnnuityDue)
% COMPUTE_RETIREMENT_CONTRIBUTION
%   Computes required monthly contribution C to meet a target monthly
%   retirement spending S (in today's dollars) given:
%     S  - desired monthly spending (today's $)
%     T  - years until retirement
%     L  - years in retirement
%     i  - nominal annual return (decimal, e.g., 0.06 or 6 for 6%%)
%     pi - annual inflation rate (decimal, e.g., 0.03 or 3 for 3%%)
%     P0 - current savings (default 0 if omitted)
%     isAnnuityDue - true if contributing at BEGINNING of each month; false otherwise
%
%   Returns:
%     C        - required monthly contribution (nominal $ today)
%     details  - struct with intermediate values for auditing

    if nargin < 6 || isempty(P0), P0 = 0; end
    if nargin < 7 || isempty(isAnnuityDue), isAnnuityDue = false; end

    % Accept percent-style inputs (e.g., 6 meaning 6%%)
    if abs(i) > 1,  i  = i  / 100; end
    if abs(pi) > 1, pi = pi / 100; end

    % Basic validation
    assert(T >= 0 && L >= 0, 'T and L must be non-negative.');
    assert(isfinite(S) && isfinite(T) && isfinite(L) && isfinite(i) && isfinite(pi) && isfinite(P0), ...
        'Inputs must be finite numbers.');

    % Monthly rates and periods
    j   = i  / 12;       % nominal monthly return
    g   = pi / 12;       % monthly inflation rate
    r   = (1 + j) / (1 + g) - 1;  % monthly REAL return
    Nw  = 12 * T;        % months until retirement
    Nr  = 12 * L;        % months in retirement

    EPS = 1e-12;

    % Step A: Real nest egg required at retirement to fund S (today's $) for Nr months
    if abs(r) < EPS
        B_real = S * Nr;
    else
        B_real = S * (1 - (1 + r)^(-Nr)) / r;
    end

    % Step B: Convert to nominal dollars at retirement (inflate over accumulation period)
    B = B_real * (1 + g)^Nw;

    % Step C: Annuity accumulation during working years (end-of-month deposits)
    if abs(j) < EPS
        AF = Nw;                % limit as j -> 0
        growth = 1;             % (1 + j)^Nw ~ 1
    else
        AF = ((1 + j)^Nw - 1) / j;
        growth = (1 + j)^Nw;
    end

    C = (B - P0 * growth) / AF;

    % Adjust if contributions occur at the BEGINNING of each month (annuity-due)
    if isAnnuityDue
        C = C / (1 + j);
    end

    % Expose useful internals
    details = struct('j', j, 'g', g, 'r', r, 'Nw', Nw, 'Nr', Nr, ...
                     'B_real', B_real, 'B_nominal', B, 'AF', AF, ...
                     'growth_factor', growth, 'isAnnuityDue', isAnnuityDue);
end
