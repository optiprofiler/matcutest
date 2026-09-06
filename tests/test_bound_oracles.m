function test_bound_oracles(filename, reload_only)
%TEST_BOUND_ORACLES compare native values/derivatives and reload bound Problems.
% Run once to save the fixture, then with RELOAD_ONLY=true in a fresh MATLAB
% session with only the adapter and core on path (no native mtools/MEX paths).
    if nargin < 2, reload_only = false; end
    caller_path = path; caller_dir = pwd;
    cleanup = onCleanup(@() restore(caller_path, caller_dir)); %#ok<NASGU>
    if reload_only
        fixture = load(filename, 'problems', 'expected', 'points');
        verify_fixture(fixture);
        assert(strcmp(path, caller_path) && strcmp(pwd, caller_dir));
        fprintf('PASS fresh MAT reload: bound identities, derivatives, caller path/cwd\n');
        return;
    end
    names = {'ROSENBR', 'AKIVA', 'HS6', 'HS12', 'HS13', 'HS21'};
    fixture.problems = cell(size(names));
    fixture.expected = cell(size(names));
    fixture.points = cell(size(names));
    for k = 1:numel(names)
        native = macup(names{k});
        x = native.x0;
        point_set = [x, x + 1e-4 * ones(size(x))];
        expected = cell(1, size(point_set, 2));
        for point = 1:size(point_set, 2)
            z = point_set(:, point);
            [f, g, H] = native.objective(z);
            c = zeros(0, 1); e = c; Jc = zeros(0, numel(z)); Je = Jc;
            if isa(native.nonlcon, 'function_handle')
                [c, e, native_Jc, native_Je] = native.nonlcon(z);
                Jc = native_Jc.'; Je = native_Je.';
            end
            expected{point} = {f, g(:), full(H), c(:), e(:), full(Jc), full(Je)};
        end
        path(caller_path);
        fixture.problems{k} = matcutest_load(names{k});
        fixture.expected{k} = expected;
        fixture.points{k} = point_set;
        assert(strcmp(path, caller_path) && strcmp(pwd, caller_dir));
    end
    verify_fixture(fixture);
    save(filename, '-struct', 'fixture');
    reloaded = load(filename);
    verify_fixture(reloaded);
    assert(strcmp(path, caller_path) && strcmp(pwd, caller_dir));
    fprintf('PASS bound oracle/native parity and interleaved MAT reload (%d problems, two points each)\n', numel(names));
end

function verify_fixture(fixture)
    for repeat = 1:3
        for k = numel(fixture.problems):-1:1
            p = fixture.problems{k};
            for point = 1:size(fixture.points{k}, 2)
                x = fixture.points{k}(:, point);
                message = evalc('actual = {p.fun(x), p.grad(x), p.hess(x), p.cub(x), p.ceq(x), p.jcub(x), p.jceq(x)};');
                assert(~contains(message, 'Failed to evaluate') && ~contains(message, 'UndefinedFunction'));
                for item = 1:numel(actual)
                    reference = fixture.expected{k}{point}{item};
                    value = actual{item};
                    assert(isequal(size(value), size(reference)) && all(isfinite(value(:))) && all(isfinite(reference(:))));
                    assert(norm(value - reference, 'fro') <= 1e-11 * max(1, norm(reference, 'fro')));
                end
            end
        end
    end
end

function restore(old_path, old_dir)
    path(old_path); cd(old_dir);
end
