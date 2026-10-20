function test_setup_system_commands(work_root)
%TEST_SETUP_SYSTEM_COMMANDS setup survives MATLAB's library path and reports a missing 7z.
%   MATLAB passes its own LD_LIBRARY_PATH (with an older bundled libstdc++)
%   to system(). On hosts whose 7z needs a newer libstdc++ (for example
%   Ubuntu 26.04: CXXABI_1.3.15), extraction then failed. A 7z wrapper that
%   refuses to start while LD_LIBRARY_PATH is set reproduces that failure on
%   any Linux host; otherwise it runs the real 7z.
    work_root = char(work_root);
    if ~isfolder(work_root), mkdir(work_root); end
    old_path = getenv('PATH');
    old_library_path = getenv('LD_LIBRARY_PATH');
    restore = onCleanup(@() restore_environment(old_path, old_library_path)); %#ok<NASGU>
    [status, real_7z] = system('command -v 7z');
    assert(status == 0, '7z is required for this test.');
    real_7z = strtrim(real_7z);

    fake_bin = fullfile(work_root, 'fake-bin');
    mkdir(fake_bin);
    write_script(fullfile(fake_bin, '7z'), sprintf(['#!/bin/sh\n' ...
        'if [ -n "$LD_LIBRARY_PATH" ]; then\n' ...
        '  echo "7z: version CXXABI_1.3.15 not found (simulated)" >&2\n' ...
        '  exit 1\n' ...
        'fi\n' ...
        'exec %s "$@"\n'], real_7z));
    setenv('PATH', [fake_bin, pathsep, old_path]);
    if isempty(old_library_path)
        % MATLAB normally sets it; make the simulated failure unconditional.
        setenv('LD_LIBRARY_PATH', fake_bin);
    end
    receipt = matcutest_setup(fullfile(work_root, 'runtime-retry'));
    assert(isfile(fullfile(receipt.runtime_root, 'mtools', 'GOTCUP')));
    assert(isequal(receipt, matcutest_setup(fullfile(work_root, 'runtime-retry'))));
    fprintf('PASS setup retries external commands without MATLAB''s library path\n');

    % Without 7z the error names the missing tool and leaves no staging behind.
    tool_bin = fullfile(work_root, 'tool-bin');
    mkdir(tool_bin);
    [status, realpath_command] = system('command -v realpath');
    assert(status == 0, 'realpath is required for this test.');
    write_script(fullfile(tool_bin, 'realpath'), sprintf('#!/bin/sh\nexec %s "$@"\n', strtrim(realpath_command)));
    setenv('PATH', tool_bin);
    parent = fullfile(work_root, 'runtime-missing-7z');
    try
        matcutest_setup(parent);
        error('MatCUTEst:TestFailure', 'A missing 7z must be reported.');
    catch failure
        assert(strcmp(failure.identifier, 'MatCUTEst:SevenZipMissing'), ...
            'Unexpected error %s: %s', failure.identifier, failure.message);
        assert(contains(failure.message, '7z'));
    end
    entries = dir(parent);
    assert(all(ismember({entries.name}, {'.', '..'})), 'Setup left files behind after a missing 7z.');
    fprintf('PASS setup reports a missing 7z before staging anything\n');
end

function write_script(filename, text)
    fid = fopen(filename, 'w');
    assert(fid >= 0, 'Cannot write %s', filename);
    fprintf(fid, '%s', text);
    fclose(fid);
    [status, output] = system(['chmod +x ', filename]);
    assert(status == 0, 'chmod failed: %s', output);
end

function restore_environment(old_path, old_library_path)
    setenv('PATH', old_path);
    setenv('LD_LIBRARY_PATH', old_library_path);
end
