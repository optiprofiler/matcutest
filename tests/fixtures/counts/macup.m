function pb = macup(name)
% Test-only upstream boundary; add this directory only during the regression.
    if strcmp(name, 'UPSTREAM_FAILURE')
        error('MatCUTEstFixture:LoadFailure', 'Injected upstream load failure.');
    end
    pb = struct('name', name, 'x0', [0; 0], 'lb', [], 'ub', [], ...
        'Aeq', [], 'beq', [], 'Aineq', [], 'bineq', [], ...
        'objective', @(x) sum(x.^2), 'nonlcon', @constraints, ...
        'numnlineq', 2, 'numnleq', 1);
    switch name
        case 'COUNTED_FAILURE'
            pb.nonlcon = @fail_constraints;
        case 'UNKNOWN_FAILURE'
            pb = rmfield(pb, {'numnlineq', 'numnleq'});
            pb.nonlcon = @fail_constraints;
        case 'INVALID_METADATA'
            pb.numnlineq = NaN;
        case 'PARTIAL_METADATA'
            pb = rmfield(pb, 'numnleq');
        case 'MISSING_CALLBACK'
            pb.nonlcon = [];
        case 'EMPTY_CALLBACK'
            pb = rmfield(pb, {'numnlineq', 'numnleq'});
            pb.nonlcon = [];
        case 'LEGACY_VALID'
            pb = rmfield(pb, {'numnlineq', 'numnleq'});
    end
end

function [c, e, gc, ge] = constraints(x)
    global MATCUTEST_FIXTURE_CALLS
    MATCUTEST_FIXTURE_CALLS = MATCUTEST_FIXTURE_CALLS + 1;
    c = x - 1;
    e = sum(x) - 1;
    gc = eye(2);
    ge = ones(2, 1);
end

function varargout = fail_constraints(varargin) %#ok<STOUT,INUSD>
    error('MatCUTEstFixture:OracleFailure', 'Injected nonlinear oracle failure.');
end
