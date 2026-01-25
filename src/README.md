# MatCUTEst (compiled)

[![CI](https://github.com/matcutest/matcutest_compiled/actions/workflows/ci.yml/badge.svg)](https://github.com/matcutest/matcutest_compiled/actions/workflows/ci.yml)
[![View MatCUTEst on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/127948-matcutest)

## What is this?

This is a compiled version of [MatCUTEst](https://github.com/matcutest/matcutest), which aims to facilitate the use of [CUTEst](https://github.com/ralna/CUTEst) in MATLAB on Linux.

## How to install?

**Before starting, make sure that [`7z`](https://en.wikipedia.org/wiki/7-Zip) is available**
(e.g., try `type 7z || sudo apt install 7zip` on Ubuntu).

### Brief version (this is for YOU!)

```bash
rm -rf matcutest_compiled && git clone https://github.com/matcutest/matcutest_compiled.git && matlab -batch "cd matcutest_compiled; install;" && rm -rf matcutest_compiled
```

### Detailed version (this is for those who are really curious about what is going on)

1. Clone this repository. You should then get a folder containing this README file and the
[`install.m`](install.m) file.

2. In the command window of MATLAB, change your directory to the folder mentioned above, and execute

```matlab
install
```

You may specify the path where you want MatCUTEst to be installed by passing it as an input to `install`.

If the above succeeds, then the [CUTEst](https://github.com/ralna/CUTEst) problems should be
available to you via `macup`, `secup`, etc. Try `help matcutest` for more information.

Success is expected if you are using [MATLAB R2020b or
above on Ubuntu 22.04 or above](https://github.com/matcutest/matcutest_compiled/actions/workflows/ci.yml).
Let me know by opening an issue if this is not the case.

If this compiled version does not work, then you may try installing
[MatCUTEst](https://github.com/matcutest/matcutest) from source
following the [README](https://github.com/matcutest/matcutest/blob/main/README.md) therein.


## Use MatCUTEst in GitHub Actions

If you want to use MatCUTEst in [GitHub Actions](https://docs.github.com/en/actions), see
the [demo](https://github.com/matcutest/matcutest_compiled/blob/main/.github/workflows/demo.yml).
MatCUTEst has been used intensively in the testing and development of [PRIMA](http://www.libprima.net),
where you can find more [realistic examples](https://github.com/libprima/prima/blob/main/.github/workflows/verify_large.yml)
of using MatCUTEst in GitHub Actions.


## Use MatCUTEst in `parfor` loops

MatCUTEst can be used within [`parfor` loops](https://www.mathworks.com/help/parallel-computing/parfor.html). Here is an example.

```matlab
problist = {'AKIVA', 'BOX2', 'ZECEVIC2', 'ZY2'};
parfor ip = 1 : length(problist)
    pname = problist{ip};
    fprintf('\n%d. Try %s:\n', ip, pname);
    p = macup(pname);  % make a CUTEst problem
    p.objective(p.x0)
    decup(p);  % destroy the CUTEst problem
end
```


## Remarks

- MatCUTEst has been playing a vital role in the testing and development of [PRIMA](http://www.libprima.net).
- If you would like to use CUTEst in Python, check [PyCUTEst](https://github.com/jfowkes/pycutest).
