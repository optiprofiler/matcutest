# MatCUTEst

This repository provides an interface for OptiProfiler to access the [MatCUTEst](https://github.com/matcutest/matcutest) problem collection.

It maintains a fork of the [compiled version of MatCUTEst](https://github.com/matcutest/matcutest_compiled) in the `src/` directory, while the root directory contains adaptation tools allowing OptiProfiler to invoke and work with these problems.

## Contents

- **`src/`**: Directory synchronized with the `matcutest_compiled` repository.
- **Adaptation Tools**: Wrapper scripts and utilities in the root directory that bridge OptiProfiler with the MatCUTEst collection.

## Configuration

The file `config.txt` in this directory controls the adapter-level `test_feasibility_problems` option used by `matcutest_select`.

MatCUTEst is supported only on GNU/Linux. Local tests on macOS intentionally skip the real MatCUTEst smoke test.

## Testing

The `CI` workflow runs daily and on pushes on Linux. It installs the compiled MatCUTEst package, then checks the OptiProfiler adapter layer by:

- selecting small problems through `matcutest_select`;
- loading `AKIVA` and a few daily random small problems through `matcutest_load`;
- evaluating `fun`, `cub`, and `ceq` at the initial point;
- checking `test_feasibility_problems` in `config.txt`;
- keeping numerical-library threads capped at two.

Locally on Linux, from this repository:

```matlab
addpath('src');
install(pwd);
run('tests/smoke_matcutest.m');
```

## Maintenance

This repository is **automatically synchronized** with the upstream `matcutest_compiled` repository via GitHub Actions. It checks for updates daily to ensure the problem set remains current.

Unlike S2MPJ and PyCUTEst, this repository does not maintain a separate collect-info workflow. This is intentional: MatCUTEst already provides `macup` for loading and `secup` for selecting problems, and `matcutest_select` delegates to that upstream logic instead of duplicating a metadata table.

## Provenance and License

The files under `src/` are synchronized from [matcutest/matcutest_compiled](https://github.com/matcutest/matcutest_compiled), which is licensed under LGPL-3.0; see `src/LICENCE.txt`. This repository adds the OptiProfiler adapter and maintenance workflows. Please also follow the citation guidance for MatCUTEst and CUTEst.

For the full collection or other languages, please visit the [original repository](https://github.com/matcutest/matcutest_compiled).
