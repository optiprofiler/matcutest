repo_dir = fileparts(fileparts(mfilename('fullpath')));
if ~isunix || ismac
    fprintf('MatCUTEst smoke test skipped: MatCUTEst compiled package supports GNU/Linux only.\n');
    return;
end

addpath(repo_dir);
addpath(fullfile(repo_dir, 'src'));

local_op_src = fullfile(fileparts(fileparts(repo_dir)), ...
    'optiprofiler', 'matlab', 'optiprofiler', 'src');
ci_op_src = fullfile(repo_dir, 'optiprofiler', ...
    'matlab', 'optiprofiler', 'src');
if exist(ci_op_src, 'dir') == 7
    addpath(ci_op_src);
elseif exist(local_op_src, 'dir') == 7
    addpath(local_op_src);
else
    error('MatCUTEst:SmokeTest', 'Could not find OptiProfiler MATLAB source path.');
end

if exist('macup', 'file') ~= 2 || exist('secup', 'file') ~= 2
    mtools_dir = fullfile(repo_dir, 'matcutest', 'mtools');
    if exist(fullfile(mtools_dir, 'setup.m'), 'file') == 2
        current_dir = pwd;
        cleanup = onCleanup(@() cd(current_dir));
        cd(mtools_dir);
        setup();
    end
end

if exist('macup', 'file') ~= 2 || exist('secup', 'file') ~= 2
    error('MatCUTEst:SmokeTest', ...
        'MatCUTEst is not installed. Run addpath(''src''); install(pwd) before this test.');
end

selected = matcutest_select(struct('ptype', 'ubln', 'maxdim', 5, ...
    'maxb', 20, 'maxlcon', 20, 'maxnlcon', 20, 'maxcon', 20));
assert(iscell(selected));
assert(~isempty(selected));
assert(ismember('AKIVA', selected));

assert_problem_contract('AKIVA');

seed_text = getenv('OP_RANDOM_SEED');
if isempty(seed_text)
    seed_text = datestr(datetime('today'), 'yyyymmdd');
end
seed = str2double(seed_text);
if isnan(seed)
    seed = 1;
end
rng(seed);
sample_size = min(3, numel(selected));
sample_indices = randperm(numel(selected), sample_size);
sample = selected(sample_indices);
fprintf('MatCUTEst random sample seed=%d:', seed);
for i = 1:numel(sample)
    fprintf(' %s', sample{i});
end
fprintf('\n');
for i = 1:numel(sample)
    assert_problem_contract(sample{i});
end

disp('matcutest adapter smoke ok');

function assert_problem_contract(problem_name)
    p = matcutest_load(problem_name);
    assert(p.n >= 1);
    assert(numel(p.x0) == p.n);
    fx0 = p.fun(p.x0);
    assert(isfinite(fx0) || isnan(fx0));
    cub0 = p.cub(p.x0);
    ceq0 = p.ceq(p.x0);
    assert(isvector(cub0));
    assert(isvector(ceq0));
end
