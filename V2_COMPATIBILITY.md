# OptiProfiler 2.0 compatibility

This line is the reviewed MatCUTEst adapter for OptiProfiler 2.0.0. Provider API
version remains **1**. Upstream problem definitions, selection metadata and the
manual review of upstream updates are unchanged.

The adapter supplies selection and public Problem callbacks. Ordered feature
composition, counters and histories, scores, save/load, and eval_report/2 are
owned by core, not duplicated in adapters. No core-private class is accessed.
The loader returns the public MATLAB Problem class, not a subclass.

No trusted reference has been promoted for these wrapped instances, so
Problem.reference remains empty ([]) and profiles keep the empirical default
target. Initial values, history minima, upstream solution vectors and metadata
fbest are not converted into references. A future fact needs raw `fun` and
`maxcv`, one of the two kinds `feasible` or `merit`, and a verifiable source
under the core reference contract.

MATLAB uses the public registry and supported setup contract, not Python
entry points. Optional roots are external to core; S2MPJ stays bundled.
Unregister removes registration/path ownership, not source/runtime/cache.
Core uninstall does not delete provider data. Validate with isolated registry,
startup and pathdef targets, including new sessions and parallel workers.
Core setup installs this adapter at the exact commit in
matlab_problem_libraries.lock, which `main` and the branch
`release/optiprofiler-2.0.0` keep reachable.
