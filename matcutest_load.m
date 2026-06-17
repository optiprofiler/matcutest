function problem = matcutest_load(problem_name)
%MATCUTEST_LOAD coverts the MatCUTEst problem name to a Problem class instance.
%
%   PROBLEM = MATCUTEST_LOAD(PROBLEM_NAME) returns a Problem class instance
%   PROBLEM that corresponds to the problem named PROBLEM_NAME in MatCUTEst.
%   More details about MatCUTEst can be found in the official website:
%   <https://github.com/matcutest>.
%
%   You may use the function `matcutest_select` to get the problem names you
%   want.
%
%   Note that MatCUTEst is only available in Linux.
%

    % Convert 'problem_name' to a char.
    problem_name = char(problem_name);

    % Use functions from MatCUTEst to get the problem structure.
    try
        pb = macup(problem_name);
    catch
        error("MATLAB:matcutest_load:errormacup", "Error occurred while using macup function on problem %s. Please check if MatCUTEst is installed correctly.", problem_name);
    end

    % Get the objective function.
    fun = @(x) getfun(pb, x);

    % Get the gradient of the objective function.
    grad = @(x) getgrad(pb, x);

    % Get the Hessian of the objective function.
    hess = @(x) gethess(pb, x);

    % Get the initial guess, lower bound, and upper bound.
    x0 = pb.x0;
    xl = pb.lb;
    xu = pb.ub;

    % Get the linear constraints.
    aeq = pb.Aeq;
    beq = pb.beq;
    aub = pb.Aineq;
    bub = pb.bineq;

    % Get the nonlinear constraints and their Jacobians.
    [m_nonlinear_ub, m_nonlinear_eq] = probe_nonlinear_constraint_sizes(pb, x0);
    ceq = @(x) getceq(pb, x, m_nonlinear_eq);
    cub = @(x) getcub(pb, x, m_nonlinear_ub);
    jceq = @(x) getjceq(pb, x, m_nonlinear_eq);
    jcub = @(x) getjcub(pb, x, m_nonlinear_ub);

    problem = Problem(struct('name', problem_name, 'fun', fun, 'grad', grad, 'hess', hess, 'x0', x0, 'xl', xl, 'xu', xu, 'aeq', aeq, 'beq', beq, 'aub', aub, 'bub', bub, 'ceq', ceq, 'cub', cub, 'jceq', jceq, 'jcub', jcub));
    
end

function fx = getfun(pb, x)
    % Get the objective function value.
    fx = [];
    try
        evalc('fx = pb.objective(x)');
    catch ME
        warn_matcutest_evaluation_failure('the objective function', pb, ME);
        fx = NaN;
    end
end

function gx = getgrad(pb, x)
    % Get the gradient of the objective function.
    gx = [];
    try
        evalc('[~, gx] = pb.objective(x)');
        gx = gx(:);
    catch ME
        warn_matcutest_evaluation_failure('the gradient of the objective function', pb, ME);
        gx = NaN(numel(x), 1);
    end
end

function hx = gethess(pb, x)
    % Get the Hessian of the objective function.
    hx = [];
    try
        evalc('[~, ~, hx] = pb.objective(x)');
        hx = full(hx);
    catch ME
        warn_matcutest_evaluation_failure('the Hessian of the objective function', pb, ME);
        hx = NaN(numel(x), numel(x));
    end
end

function cubx = getcub(pb, x, m_nonlinear_ub_default)
    % Get the nonlinear inequality constraints.
    cubx = [];
    try
        evalc('cubx = pb.nonlcon(x)');
        cubx = full(cubx(:));
    catch ME
        warn_matcutest_evaluation_failure('the nonlinear inequality constraints', pb, ME);
        cubx = NaN(m_nonlinear_ub_default, 1);
    end
end

function ceqx = getceq(pb, x, m_nonlinear_eq_default)
    % Get the nonlinear equality constraints.
    ceqx = [];
    try
        evalc('[~, ceqx] = pb.nonlcon(x)');
        ceqx = full(ceqx(:));
    catch ME
        warn_matcutest_evaluation_failure('the nonlinear equality constraints', pb, ME);
        ceqx = NaN(m_nonlinear_eq_default, 1);
    end
end

function jcubx = getjcub(pb, x, m_nonlinear_ub_default)
    % Get the Jacobian of the nonlinear inequality constraints.
    jcubx = [];
    try
        evalc('[~, ~, jcubx] = pb.nonlcon(x)');
        jcubx = convert_matcutest_jacobian(jcubx, m_nonlinear_ub_default, numel(x));
    catch ME
        warn_matcutest_evaluation_failure('the Jacobian of the nonlinear inequality constraints', pb, ME);
        jcubx = NaN(m_nonlinear_ub_default, numel(x));
    end
end

function jceqx = getjceq(pb, x, m_nonlinear_eq_default)
    % Get the Jacobian of the nonlinear equality constraints.
    jceqx = [];
    try
        evalc('[~, ~, ~, jceqx] = pb.nonlcon(x)');
        jceqx = convert_matcutest_jacobian(jceqx, m_nonlinear_eq_default, numel(x));
    catch ME
        warn_matcutest_evaluation_failure('the Jacobian of the nonlinear equality constraints', pb, ME);
        jceqx = NaN(m_nonlinear_eq_default, numel(x));
    end
end

function J = convert_matcutest_jacobian(J, m_expected, n_expected)
    J = full(J);
    if isempty(J)
        J = NaN(m_expected, n_expected);
        return;
    end
    if ~isequal(size(J), [n_expected, m_expected])
        error("MATLAB:matcutest_load:UnexpectedJacobianShape", "The Jacobian returned by MatCUTEst has shape (%d, %d), but the expected shape before transposition is (%d, %d).", size(J, 1), size(J, 2), n_expected, m_expected);
    end
    J = J.';
end

function [m_nonlinear_ub, m_nonlinear_eq] = probe_nonlinear_constraint_sizes(pb, x0)
    % Probe the nonlinear constraint sizes at the initial point.
    m_nonlinear_ub = 0;
    m_nonlinear_eq = 0;
    try
        evalc('[cub0, ceq0] = pb.nonlcon(x0)');
        if ~isempty(cub0)
            m_nonlinear_ub = numel(cub0);
        end
        if ~isempty(ceq0)
            m_nonlinear_eq = numel(ceq0);
        end
    catch
        % Keep zero sizes if probing fails.
    end
end

function warn_matcutest_evaluation_failure(what, pb, ME)
    problem_name = '<unknown>';
    if isfield(pb, 'name') && ~isempty(pb.name)
        problem_name = char(pb.name);
    end
    print_matcutest_warning(sprintf('Failed to evaluate %s of problem %s: %s', what, problem_name, shorten_exception_message(ME)));
end

function msg = shorten_exception_message(ME)
    msg = strtrim(ME.message);
    if isempty(msg)
        msg = strtrim(ME.identifier);
    elseif ~isempty(ME.identifier)
        msg = sprintf('%s: %s', ME.identifier, msg);
    end
    msg = regexprep(msg, '[\f\n\r\t\v]+', ' ');
    max_len = 180;
    if numel(msg) > max_len
        msg = [msg(1:max_len - 3), '...'];
    end
end

function print_matcutest_warning(message)
    width = 104;
    prefix = sprintf('[%-7s] ', 'WARNING');
    message = strtrim(regexprep(char(message), '[\f\n\r\t\v]+', ' '));
    if isempty(message)
        return;
    end
    body_width = max(20, width - numel(prefix));
    lines = wrap_matcutest_text(message, body_width);
    fprintf('%s%s\n', prefix, lines{1});
    continuation_prefix = repmat(' ', 1, numel(prefix));
    for i_line = 2:numel(lines)
        fprintf('%s%s\n', continuation_prefix, lines{i_line});
    end
end

function lines = wrap_matcutest_text(message, width)
    lines = {};
    remaining = message;
    while numel(remaining) > width
        chunk = remaining(1:width);
        break_idx = find(isspace(chunk), 1, 'last');
        if isempty(break_idx) || break_idx < 1
            break_idx = width;
        end
        lines{end + 1} = strtrim(remaining(1:break_idx)); %#ok<AGROW>
        remaining = strtrim(remaining(break_idx + 1:end));
    end
    lines{end + 1} = remaining;
end
