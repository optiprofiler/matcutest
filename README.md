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
addpath(pwd);
receipt = matcutest_setup('/absolute/path/to/isolated/runtime-parent');
addpath(receipt.runtime_paths{:});
run('tests/smoke_matcutest.m');
addpath('tests');
test_constraint_counts;
test_real_constraints;
```

## Managed Runtime Setup

`matcutest_setup(runtime_parent)` is our adapter-owned installer. It extracts
the reviewed local archive into `runtime_parent/matcutest`, or reuses a complete
installation there. It does not download upstream updates, run native `setup`,
change the MATLAB path, or write `startup.m`/`pathdef.m`. Incomplete existing
installations fail explicitly and are not overwritten or removed.

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
MEX paths are temporarily activated for loading and each returned callback,
then restored; they are not installed or persisted as a blanket MEX tree.

## Maintenance

This paper-maintenance branch retains its reviewed upstream snapshot. Its
historical sync job is restricted to `main` and has read-only repository
permissions; neither scheduled nor manual runs on this frozen branch may
change `src/` or push commits. The current development `main` has its separate
notification-only upstream review workflow. Upstream promotion is a reviewed
maintenance operation, not part of installation.

Unlike S2MPJ and PyCUTEst, this repository does not maintain a separate collect-info workflow. This is intentional: MatCUTEst already provides `macup` for loading and `secup` for selecting problems, and `matcutest_select` delegates to that upstream logic instead of duplicating a metadata table.

## Provenance and License

The files under `src/` are synchronized from [matcutest/matcutest_compiled](https://github.com/matcutest/matcutest_compiled), which is licensed under LGPL-3.0; see `src/LICENCE.txt`. This repository adds the OptiProfiler adapter and maintenance workflows. Please also follow the citation guidance for MatCUTEst and CUTEst.

For the full collection or other languages, please visit the [original repository](https://github.com/matcutest/matcutest_compiled).
