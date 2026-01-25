# MatCUTEst

This repository provides an interface for OptiProfiler to access the [MatCUTEst](https://github.com/matcutest/matcutest) problem collection.

It maintains a fork of the [compiled version of MatCUTEst](https://github.com/matcutest/matcutest_compiled) in the `src/` directory, while the root directory contains adaptation tools allowing OptiProfiler to invoke and work with these problems.

## Contents

- **`src/`**: Directory synchronized with the `matcutest_compiled` repository.
- **Adaptation Tools**: Wrapper scripts and utilities in the root directory that bridge OptiProfiler with the MatCUTEst collection.

## Maintenance

This repository is **automatically synchronized** with the upstream `matcutest_compiled` repository via GitHub Actions. It checks for updates daily to ensure the problem set remains current.

For the full collection or other languages, please visit the [original repository](https://github.com/matcutest/matcutest_compiled).
