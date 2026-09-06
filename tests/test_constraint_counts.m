function test_constraint_counts()
%TEST_CONSTRAINT_COUNTS exercise the adapter with the real core Problem class.
    old_path = path;
    cleanup = onCleanup(@() path(old_path)); %#ok<NASGU>
    addpath(fullfile(fileparts(mfilename('fullpath')), 'fixtures', 'counts'));
    clear macup
    cases = {@metadata_without_probe, @counted_failure, @unknown_failure, ...
        @invalid_metadata, @partial_metadata, @missing_callback, ...
        @empty_callback, @legacy_valid, @upstream_failure};
    failures = 0;
    for k = 1:numel(cases)
        try
            cases{k}();
            fprintf('PASS %s\n', func2str(cases{k}));
        catch exception
            failures = failures + 1;
            fprintf('FAIL %s: %s [%s]\n', func2str(cases{k}), ...
                exception.message, exception.identifier);
        end
    end
    clear macup
    assert(failures == 0, 'MatCUTEstTest:ConstraintCounts', ...
        '%d/%d constraint-count regressions failed.', failures, numel(cases));
end

function metadata_without_probe()
    global MATCUTEST_FIXTURE_CALLS
    MATCUTEST_FIXTURE_CALLS = 0;
    pb = matcutest_load('METADATA_ONLY');
    assert(MATCUTEST_FIXTURE_CALLS == 0, 'Metadata must not require an oracle probe.');
    assert(pb.m_nonlinear_ub == 2 && pb.m_nonlinear_eq == 1);
    assert(isequal(pb.cub(pb.x0), [-1; -1]));
    assert(isequal(pb.ceq(pb.x0), -1));
    assert(isequal(pb.jcub(pb.x0), eye(2)));
    assert(isequal(pb.jceq(pb.x0), [1, 1]));
end

function counted_failure()
    pb = matcutest_load('COUNTED_FAILURE');
    output = evalc('c = pb.cub(pb.x0); e = pb.ceq(pb.x0);');
    assert(isequal(size(c), [2, 1]) && all(isnan(c)));
    assert(isequal(size(e), [1, 1]) && isnan(e));
    assert(contains(output, 'MatCUTEstFixture:OracleFailure'));
    assert(strcmp(pb.ptype, 'n'));
    assert(isnan(pb.maxcv(pb.x0)));
end

function unknown_failure()
    exception = expect_error(@() matcutest_load('UNKNOWN_FAILURE'), ...
        'MATLAB:matcutest_load:ConstraintCountUnavailable');
    assert(contains(exception.message, 'UNKNOWN_FAILURE'));
    assert(any(cellfun(@(cause) strcmp(cause.identifier, ...
        'MatCUTEstFixture:OracleFailure'), exception.cause)));
end

function invalid_metadata()
    expect_error(@() matcutest_load('INVALID_METADATA'), ...
        'MATLAB:matcutest_load:InvalidConstraintMetadata');
end

function partial_metadata()
    expect_error(@() matcutest_load('PARTIAL_METADATA'), ...
        'MATLAB:matcutest_load:InvalidConstraintMetadata');
end

function missing_callback()
    expect_error(@() matcutest_load('MISSING_CALLBACK'), ...
        'MATLAB:matcutest_load:InvalidConstraintMetadata');
end

function empty_callback()
    pb = matcutest_load('EMPTY_CALLBACK');
    assert(pb.m_nonlinear_ub == 0 && pb.m_nonlinear_eq == 0);
    assert(isempty(pb.cub(pb.x0)) && isempty(pb.ceq(pb.x0)));
    assert(strcmp(pb.ptype, 'u'));
end

function legacy_valid()
    global MATCUTEST_FIXTURE_CALLS
    MATCUTEST_FIXTURE_CALLS = 0;
    pb = matcutest_load('LEGACY_VALID');
    assert(MATCUTEST_FIXTURE_CALLS == 1);
    assert(pb.m_nonlinear_ub == 2 && pb.m_nonlinear_eq == 1);
end

function upstream_failure()
    exception = expect_error(@() matcutest_load('UPSTREAM_FAILURE'), ...
        'MATLAB:matcutest_load:errormacup');
    assert(any(cellfun(@(cause) strcmp(cause.identifier, ...
        'MatCUTEstFixture:LoadFailure'), exception.cause)));
end

function exception = expect_error(callback, identifier)
    try
        callback();
    catch exception
        assert(strcmp(exception.identifier, identifier), ...
            'Unexpected error: %s', exception.getReport());
        return;
    end
    error('MatCUTEstTest:ExpectedError', 'Expected %s, but loading succeeded.', identifier);
end
