# MatCUTEst

This repository provides an interface for OptiProfiler to access the [MatCUTEst](https://github.com/matcutest/matcutest) problem collection.

It maintains a reviewed snapshot of the [compiled version of MatCUTEst](https://github.com/matcutest/matcutest_compiled) in the `src/` directory, while the root directory contains adaptation tools allowing OptiProfiler to invoke and work with these problems.

## Contents

- **`src/`**: Reviewed snapshot of the `matcutest_compiled` repository.
- **Adaptation Tools**: Wrapper scripts and utilities in the root directory that bridge OptiProfiler with the MatCUTEst collection.

## Configuration

The file `config.txt` in this directory controls the adapter-level `test_feasibility_problems` option used by `matcutest_select`.

MatCUTEst is supported only on GNU/Linux. Local tests on macOS intentionally skip the real MatCUTEst smoke test.

## OptiProfiler Development Setup

The setup and registry workflow below belongs to the unpublished OptiProfiler
`matlab` development branch; it is not a claim about the current stable
website. Ordinary OptiProfiler users should start from the core repository and
let its locked setup install this adapter:

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
- keeping numerical-library threads capped at two.

For maintainer or local adapter testing on Linux, from this repository:

```matlab
addpath('src');
install(pwd);
run('tests/smoke_matcutest.m');
```

## Maintenance

`Check MatCUTEst Upstream` compares `src/` with the latest
`matcutest_compiled` revision every day. A difference creates or updates an
`upstream-update` issue and uploads a report. It never changes or pushes `src/`.
Maintainers must review the candidate, run the full Linux adapter CI, and commit
the promoted snapshot explicitly.

Unlike S2MPJ and PyCUTEst, this repository does not maintain a separate collect-info workflow. This is intentional: MatCUTEst already provides `macup` for loading and `secup` for selecting problems, and `matcutest_select` delegates to that upstream logic instead of duplicating a metadata table.

## Provenance and License

The files under `src/` are synchronized from [matcutest/matcutest_compiled](https://github.com/matcutest/matcutest_compiled), which is licensed under LGPL-3.0; see `src/LICENCE.txt`. This repository adds the OptiProfiler adapter and maintenance workflows. Please also follow the citation guidance for MatCUTEst and CUTEst.

For the full collection or other languages, please visit the [original repository](https://github.com/matcutest/matcutest_compiled).
