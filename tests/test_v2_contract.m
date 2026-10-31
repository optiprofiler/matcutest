function test_v2_contract()
%TEST_V2_CONTRACT checks the public V2 carrier and core-owned recording.
% Run only with core 2.0 and the required native runtime.
    for spec = {'plain', 'noisy+permuted'}
        problem = matcutest_load('AKIVA');
        assert(strcmp(class(problem), 'Problem'));
        assert(isempty(problem.reference));
        trial = FeaturedProblem(problem, Feature(spec{1}), 5, 19);
        assert(isempty(trial.reference));
        before = [trial.n_eval_fun, trial.n_eval_cub, trial.n_eval_ceq];
        assert(isfinite(trial.fun(trial.x0)));
        assert(trial.n_eval_fun == before(1) + 1);
        assert(isequal([trial.n_eval_cub, trial.n_eval_ceq], before(2:3)));
        assert(numel(trial.fun_hist) == trial.n_eval_fun);
    end
end
