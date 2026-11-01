# MatCUTEst

**OptiProfiler 2.0:** See [compatibility and release boundaries](V2_COMPATIBILITY.md).

This repository provides an interface for OptiProfiler to access the [MatCUTEst](https://github.com/matcutest/matcutest) problem collection.

It maintains a reviewed snapshot of the [compiled version of MatCUTEst](https://github.com/matcutest/matcutest_compiled) in the `src/` directory, while the root directory contains adaptation tools allowing OptiProfiler to invoke and work with these problems.

## Contents

- **`src/`**: Reviewed snapshot of the `matcutest_compiled` repository.
- **Adaptation Tools**: Wrapper scripts and utilities in the root directory that bridge OptiProfiler with the MatCUTEst collection.

## Configuration

The file `config.txt` in this directory controls the adapter-level `test_feasibility_problems` option used by `matcutest_select`.

MatCUTEst is supported only on GNU/Linux. Local tests on macOS intentionally skip the real MatCUTEst smoke test.

## OptiProfiler Setup

The setup and registry workflow below belongs to OptiProfiler 2.0, which the
website describes only once it is released. Ordinary OptiProfiler users should
start from the core repository and let its locked setup install this adapter:

```matlab
setup(struct( ...
    'install_matcutest', true, ...
    'install_solar', false));
```

By default, the adapter checkout is stored below
`prefdir/optiprofiler/problem_libraries/matcutest` and the MatCUTEst runtime is
installed below the same optional-library root. A caller may choose another
writable parent with the core setup option `problem_library_root`.

After setup, use the public provider name rather than a custom path:

```matlab
options.plibs = {'matcutest'};
scores = benchmark(solvers, options);

library = resolveProblemLibrary('matcutest');
```

To update a setup-managed adapter, update the OptiProfiler core and rerun setup.
A clean checkout is aligned to the commit in `matlab_problem_libraries.lock`;
setup does not overwrite a dirty checkout. Do not run `git pull`
unconditionally in the setup-managed directory.

Detach the provider without deleting its checkout or runtime:

```matlab
unregisterProblemLibrary('matcutest');
```

`install_matcutest=false` only skips MatCUTEst during that setup run. It does
not unregister or delete anything. Likewise, `setup uninstall` removes
OptiProfiler-managed MATLAB paths but preserves the registry, adapter checkout,
MatCUTEst runtime, compiled files, caches, and user data. There is deliberately
no destructive setup option.

## Testing

The `CI` workflow runs daily and on pushes on Linux. It installs the compiled MatCUTEst package, then checks the OptiProfiler adapter layer by:

- selecting small problems through `matcutest_select`;
- loading `AKIVA` and a few daily random small problems through `matcutest_load`;
- evaluating `fun`, `cub`, and `ceq` at the initial point;
- checking `test_feasibility_problems` in `config.txt`;
- comparing bound objective/gradient/Hessian and constraint/Jacobian callbacks
  against native results, including alternating runtime roots and a fresh-session MAT reload;
- keeping numerical-library threads capped at two.

For maintainer or local adapter testing on Linux, from this repository:

```matlab
addpath(pwd);
receipt = matcutest_setup('/absolute/path/to/isolated/runtime-parent');
addpath(receipt.runtime_paths{:});
run('tests/smoke_matcutest.m');
addpath('tests');
test_constraint_counts;
test_real_constraints;
test_bound_oracles(fullfile(tempdir, 'matcutest-bound-oracles.mat'));
```

## Managed Runtime Setup

`matcutest_setup(runtime_parent)` is our adapter-owned installer. It extracts
the reviewed local archive into `runtime_parent/matcutest`, or reuses a complete
installation there. It does not download upstream updates, run native `setup`,
change the MATLAB path, or write `startup.m`/`pathdef.m`. Incomplete existing
installations fail explicitly and are not overwritten or removed.

Extraction needs 7-Zip (`7z`) on `PATH`; setup reports a missing `7z` before
staging anything. MATLAB runs external commands with its own `LD_LIBRARY_PATH`,
whose bundled C++ runtime can be older than the one a system `7z` needs. Setup
therefore retries a failed external command once without that variable, keeping
`PATH` and the rest of the environment unchanged.

The returned receipt contains `schema_version=1`, `provider='matcutest'`, the
canonical `runtime_root`, and `runtime_paths`, currently the single exact
`mtools/src` directory below that root. These are runtime requirements, not a
claim of ownership of any paths the user already added. The caller must retain
its own exact added-path records across repeated setup and remove only owned
entries on uninstall. Source, runtime, caches and user files are preserved.
Core versions pinned to an older adapter must adopt this entry point before
they gain its managed-install behavior. The unmodified native installer in
`src/install.m` remains an upstream snapshot, not the managed entry point.

`matcutest_load` uses the native `numnlineq`/`numnleq` metadata without another
constraint probe. If these fields are absent, an explicitly empty native
callback means zero constraints; otherwise a failed size probe raises an error
with its original cause. Unknown counts never become zero silently. Native
paths are temporarily activated only while loading, then restored. The
adapter's internal `MatcutestOracle` binds the exact problem MEX file; callbacks
do not query, activate, or restore the MATLAB path. Objective, gradient and
Hessian commands use that binding. Nonlinear upper sides, lower sides and
equalities retain the ordering and Jacobian convention of native `macup`.

The binding runs native setup once when constructed and again when restored
from a MAT file, because a saved function handle does not preserve a MEX
module's initialized state in a fresh process. The installed runtime must
remain at the same location; metadata is checked when restoring it. This does
not compile, download, or modify upstream code, and no oracle is evaluated to
recover constraint counts. Keep the adapter and core on path when loading
saved `Problem` objects.

If that runtime has moved or is missing, MATLAB can turn an error from
`MatcutestOracle.loadobj` into a warning while loading the MAT file. This
load-time warning contains the original missing-runtime diagnosis; a returned
`Problem` variable is not proof that its callbacks are usable. Later calls may
report a secondary indexing error and return `NaN`. Keep the original runtime
location available, resolve the load warning, and reload before evaluating.

A fresh-session check is:

```matlab
addpath('/path/to/this/adapter', '/path/to/this/adapter/tests');
addpath('/path/to/optiprofiler/matlab/optiprofiler/src');
test_bound_oracles(fullfile(tempdir, 'matcutest-bound-oracles.mat'), true);
```

## Maintenance

`Check MatCUTEst Upstream` compares `src/` with the latest
`matcutest_compiled` revision every day. A difference creates or updates an
`upstream-update` issue and uploads a report. It never changes or pushes `src/`.
Maintainers must review the candidate, run the full Linux adapter CI, and commit
the promoted snapshot explicitly.

Unlike S2MPJ and PyCUTEst, this repository does not maintain a separate collect-info workflow. This is intentional: MatCUTEst already provides `macup` for loading and `secup` for selecting problems, and `matcutest_select` delegates to that upstream logic instead of duplicating a metadata table.

## Provenance and License

The OptiProfiler adapter in this repository (the root MATLAB files, `config.txt`, the documentation, tests and maintenance workflows) is licensed under the [BSD 3-Clause License](LICENSE). That license covers only these files.

The files under `src/` are synchronized from [matcutest/matcutest_compiled](https://github.com/matcutest/matcutest_compiled), which is licensed under LGPL-3.0; see `src/LICENCE.txt`. The MatCUTEst and CUTEst runtime that `matcutest_setup` installs from that snapshot keeps its own terms. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the component boundaries. Please also follow the citation guidance for MatCUTEst and CUTEst.

For the full collection or other languages, please visit the [original repository](https://github.com/matcutest/matcutest_compiled).
