# Third-Party Notices

This repository combines the OptiProfiler MATLAB adapter with a reviewed snapshot
of compiled MatCUTEst. The components keep separate terms. Nothing here
relicenses upstream material, and no license is inferred for one component from
another.

## Component inventory

| Component | Paths | Terms | License text |
| --- | --- | --- | --- |
| Snapshot of `matcutest_compiled`, including its compiled archives | `src/` | LGPL-3.0, as stated by the upstream repository | `src/LICENCE.txt` |
| Runtime unpacked from that snapshot | `matcutest/` under the directory given to `matcutest_setup`; not stored here unpacked | Keeps its upstream terms; see below | `cutest/LICENSE` in the unpacked runtime, for CUTEst |
| OptiProfiler adapter, documentation, tests and workflows | Root `*.m`, root `*.md`, `config.txt`, `tests/`, `.github/`, `.gitignore` | BSD-3-Clause | `LICENSE` |

## MatCUTEst snapshot

`src/` is a reviewed snapshot of
[matcutest/matcutest_compiled](https://github.com/matcutest/matcutest_compiled).
Its `src/LICENCE.txt` is kept unchanged.

## Installed runtime

`matcutest_setup` unpacks `src/full.matcutest.7z.001` into the runtime directory.
The result holds the MatCUTEst tools in `mtools/` and
[CUTEst](https://github.com/ralna/CUTEst) in `cutest/`. It keeps its upstream
terms, and this repository changes neither its files nor those terms. CUTEst
carries its own license in `cutest/LICENSE`. Please also follow the citation
guidance for MatCUTEst and CUTEst.

## OptiProfiler adapter

The root MATLAB files, `config.txt`, documentation, tests and workflows are
independent OptiProfiler work, licensed under the BSD 3-Clause License in
`LICENSE`. That license covers only these files. It does not cover `src/` or the
runtime, and the upstream terms above do not apply to the adapter by virtue of
being stored here.
