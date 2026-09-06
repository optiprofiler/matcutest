function test_runtime_setup(runtime_parent)
%TEST_RUNTIME_SETUP installation is explicit, repeatable and non-persistent.
    before_path = path;
    before_dir = pwd;
    receipt = matcutest_setup(runtime_parent);
    assert(isequal(receipt, matcutest_setup(runtime_parent)));
    assert(strcmp(path, before_path) && strcmp(pwd, before_dir));
    assert(receipt.schema_version == 1 && strcmp(receipt.provider, 'matcutest'));
    assert(isequal(receipt.runtime_paths, {fullfile(receipt.runtime_root, 'mtools', 'src')}));
    marker = fullfile(receipt.runtime_root, 'user-data-marker.txt');
    if ~isfile(marker)
        fid = fopen(marker, 'w');
        fprintf(fid, 'user data\n');
        fclose(fid);
    end
    before_marker = fileread(marker);
    matcutest_setup(runtime_parent);
    assert(strcmp(fileread(marker), before_marker));

    addpath(receipt.runtime_paths{:});
    cleanup = onCleanup(@() path(before_path)); %#ok<NASGU>
    assert(isequal(receipt, matcutest_setup(runtime_parent)));
    assert(contains(path, receipt.runtime_paths{1}));
    fprintf('PASS setup receipt, unchanged path/cwd, reuse and user marker preservation\n');
end
