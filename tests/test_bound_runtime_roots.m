function test_bound_runtime_roots(roots, filename, reload_only, parallel_check)
%TEST_BOUND_RUNTIME_ROOTS distinct native installations, MAT and process workers.
    if nargin < 3, reload_only = false; end
    if nargin < 4, parallel_check = false; end
    caller_path = path; caller_dir = pwd;
    cleanup = onCleanup(@() restore(caller_path, caller_dir)); %#ok<NASGU>
    if reload_only
        fixture = load(filename);
    else
        assert(numel(roots) == 2);
        names = {'HS13', 'HS6'};
        fixture.problems = cell(1, 2);
        fixture.oracles = cell(1, 2);
        fixture.expected = cell(1, 2);
        fixture.mexdirs = cell(1, 2);
        for k = 1:2
            path(caller_path);
            addpath(fullfile(roots{k}, 'mtools', 'src'), '-begin');
            clear macup cutestdir
            base = path;
            native = macup(names{k});
            assert(startsWith(native.mexdir, [roots{k}, filesep]));
            x = native.x0;
            [f, g, H] = native.objective(x);
            [c, e, Jc, Je] = native.nonlcon(x);
            fixture.expected{k} = {f, g(:), full(H), c(:), e(:), full(Jc.'), full(Je.')};
            path(base);
            fixture.problems{k} = matcutest_load(names{k});
            fixture.oracles{k} = MatcutestOracle(native.mexdir);
            fixture.mexdirs{k} = native.mexdir;
        end
        path(caller_path);
        save(filename, '-struct', 'fixture');
    end
    verify_roots(fixture);
    if parallel_check
        assert(isempty(gcp('nocreate')), 'Test requires its own isolated MATLAB session/pool.');
        pool = parpool('Processes', 2);
        pool_cleanup = onCleanup(@() delete(pool)); %#ok<NASGU>
        first = parfeval(pool, @verify_roots, 0, fixture);
        second = parfeval(pool, @verify_roots, 0, fixture);
        fetchOutputs(first); fetchOutputs(second);
        fprintf('PASS bound root identities and native values in two independent workers\n');
    end
    assert(strcmp(path, caller_path) && strcmp(pwd, caller_dir));
    fprintf('PASS alternating distinct runtime roots, MAT reload=%d, path/cwd unchanged\n', reload_only);
end

function verify_roots(fixture)
    caller_path = path; caller_dir = pwd;
    for repeat = 1:8
        for k = 1:2
            p = fixture.problems{k};
            oracle = fixture.oracles{k};
            assert(strcmp(oracle.MexDirectory, fixture.mexdirs{k}));
            assert(oracle.objective(p.x0) == fixture.expected{k}{1});
            message = evalc('actual = {p.fun(p.x0), p.grad(p.x0), p.hess(p.x0), p.cub(p.x0), p.ceq(p.x0), p.jcub(p.x0), p.jceq(p.x0)};');
            assert(~contains(message, 'Failed to evaluate') && ~contains(message, 'UndefinedFunction'));
            for item = 1:numel(actual)
                expected = fixture.expected{k}{item};
                value = actual{item};
                assert(isequal(size(value), size(expected)) && all(isfinite(value(:))));
                assert(norm(value - expected, 'fro') <= 1e-11 * max(1, norm(expected, 'fro')));
            end
        end
    end
    assert(strcmp(path, caller_path) && strcmp(pwd, caller_dir));
end

function restore(old_path, old_dir)
    path(old_path); cd(old_dir);
    clear macup cutestdir
end
