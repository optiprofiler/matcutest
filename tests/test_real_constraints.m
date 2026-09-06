function test_real_constraints()
%TEST_REAL_CONSTRAINTS actual native counts, callback paths and saved closures.
    names = {'AKIVA', 'ROSENBR', 'HS6', 'HS13', 'HS21'};
    initial_path = path;
    cleanup = onCleanup(@() path(initial_path)); %#ok<NASGU>
    for k = 1:numel(names)
        raw = macup(names{k});
        counts = [raw.numnlineq, raw.numnleq];
        [c_expected, e_expected] = deal(zeros(0, 1));
        if isa(raw.nonlcon, 'function_handle')
            [c_expected, e_expected] = raw.nonlcon(raw.x0);
        end
        f_expected = raw.objective(raw.x0);
        path(initial_path);
        p = matcutest_load(names{k});
        assert(strcmp(path, initial_path));
        assert(isequal([p.m_nonlinear_ub, p.m_nonlinear_eq], counts));
        for repeat = 1:2
            assert(abs(p.fun(p.x0) - f_expected) < 1e-10 * max(1, abs(f_expected)));
            assert(isequal(p.cub(p.x0), c_expected(:)));
            assert(isequal(p.ceq(p.x0), e_expected(:)));
            assert(strcmp(path, initial_path));
        end
        assert(all(isfinite(p.grad(p.x0))));
        assert(isequal(size(p.jcub(p.x0)), [counts(1), p.n]));
        assert(isequal(size(p.jceq(p.x0)), [counts(2), p.n]));
        filename = [tempname, '.mat'];
        file_cleanup = onCleanup(@() delete(filename));
        save(filename, 'p');
        saved = load(filename, 'p');
        assert(abs(saved.p.fun(saved.p.x0) - f_expected) < 1e-10 * max(1, abs(f_expected)));
        assert(isequal(saved.p.cub(saved.p.x0), c_expected(:)));
        assert(strcmp(path, initial_path));
        clear file_cleanup
        fprintf('PASS real %s: nonlinear=(%d,%d), callbacks and MAT reload\n', names{k}, counts);
    end
    first = matcutest_load('HS13');
    first_value = first.fun(first.x0);
    second = matcutest_load('HS6');
    second_value = second.fun(second.x0);
    assert(first.fun(first.x0) == first_value);
    assert(second.fun(second.x0) == second_value);
    assert(strcmp(path, initial_path));
    fprintf('PASS alternating two returned Problem closures with scoped MEX paths\n');
end
