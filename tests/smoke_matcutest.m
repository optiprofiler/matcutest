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

config_path = fullfile(repo_dir, 'config.txt');
original_config = fileread(config_path);
cleanup_config = onCleanup(@() write_text(config_path, original_config));

selected = matcutest_select(struct('ptype', 'ubln', 'maxdim', 5, ...
    'maxb', 20, 'maxlcon', 20, 'maxnlcon', 20, 'maxcon', 20));
assert(iscell(selected));
assert(~isempty(selected));
assert(ismember('AKIVA', selected));

akiva_output = evalc('assert_problem_contract(''AKIVA'');');
assert(~contains(akiva_output, 'Failed to evaluate the nonlinear inequality constraints'));
assert(~contains(akiva_output, 'Failed to evaluate the nonlinear equality constraints'));

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

assert_config_behavior(config_path);

disp('matcutest adapter smoke ok');

function assert_config_behavior(config_path)
    options = struct('ptype', 'ubln', 'maxdim', 5, ...
        'maxb', 20, 'maxlcon', 20, 'maxnlcon', 20, 'maxcon', 20);

    write_matcutest_config(config_path, '0');
    nonfeasibility_names = matcutest_select(options);
    write_matcutest_config(config_path, '1');
    feasibility_names = matcutest_select(options);
    write_matcutest_config(config_path, '2');
    all_names = matcutest_select(options);

    assert(numel(all_names) >= numel(nonfeasibility_names));
    assert(numel(all_names) >= numel(feasibility_names));

    write_matcutest_config(config_path, '3');
    assert_raises(@() matcutest_select(options));
end

function assert_problem_contract(problem_name)
    p = matcutest_load(problem_name);
    assert(p.n >= 1);
    assert(numel(p.x0) == p.n);
    ptype = p.ptype;
    assert(ismember(char(ptype), {'u', 'b', 'l', 'n'}));
    maxcv0 = p.maxcv(p.x0);
    assert(isfinite(maxcv0) || isnan(maxcv0));
    fx0 = p.fun(p.x0);
    assert(isfinite(fx0) || isnan(fx0));
    cub0 = p.cub(p.x0);
    ceq0 = p.ceq(p.x0);
    assert(isvector(cub0));
    assert(isvector(ceq0));
end

function write_matcutest_config(config_path, test_feasibility_problems)
    write_text(config_path, sprintf('test_feasibility_problems=%s\n', test_feasibility_problems));
end

function write_text(path, text)
    fid = fopen(path, 'w');
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', text);
end

function assert_raises(callback)
    did_raise = false;
    try
        callback();
    catch
        did_raise = true;
    end
    assert(did_raise);
end
