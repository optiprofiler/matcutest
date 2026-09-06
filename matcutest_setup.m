function receipt = matcutest_setup(runtime_parent)
%MATCUTEST_SETUP prepares the reviewed compiled runtime without changing paths.
%
%   RECEIPT = MATCUTEST_SETUP(RUNTIME_PARENT) extracts the bundled compiled
%   archive into RUNTIME_PARENT/matcutest if it is absent. An existing complete
%   installation is reused without rebuilding, overwriting or deleting it.
%   RUNTIME_PARENT must be an explicit writable GNU/Linux directory.
%
%   RECEIPT has schema_version=1, provider='matcutest', canonical runtime_root,
%   and runtime_paths (a cell array of exact required directories). The caller
%   decides which paths to add, persist and own. No addpath, savepath, upstream
%   setup, userpath or startup-file edits are performed here. In particular,
%   the receipt lists requirements, not ownership of pre-existing user paths.
%
%   A missing archive or incomplete existing runtime raises an error; this
%   function neither downloads a moving upstream revision nor repairs user
%   installations implicitly. Native source and compiled artifacts are kept
%   unchanged. There is no destructive uninstall operation.

    if ~isunix || ismac
        error('MatCUTEst:InvalidOS', 'This package supports only GNU/Linux.');
    end
    if nargin ~= 1 || ~(ischar(runtime_parent) && isrow(runtime_parent) || ...
            isstring(runtime_parent) && isscalar(runtime_parent)) || ...
            strlength(string(runtime_parent)) == 0
        error('MatCUTEst:InvalidRuntimeParent', 'Specify one nonempty runtime parent directory.');
    end
    runtime_parent = char(runtime_parent);
    if ~isfolder(runtime_parent)
        [ok, message] = mkdir(runtime_parent);
        if ~ok
            error('MatCUTEst:RuntimeDirectory', 'Cannot create runtime parent: %s', message);
        end
    end
    runtime_parent = canonical_path(runtime_parent);
    runtime_root = fullfile(runtime_parent, 'matcutest');
    if isfolder(runtime_root)
        require_inside(runtime_root, runtime_parent);
        validate_runtime(runtime_root);
    elseif isfile(runtime_root)
        error('MatCUTEst:RuntimeDirectory', 'A file already exists at %s.', runtime_root);
    else
        archive = fullfile(fileparts(mfilename('fullpath')), 'src', 'full.matcutest.7z.001');
        if ~isfile(archive)
            error('MatCUTEst:ArchiveMissing', 'The reviewed compiled archive is missing: %s', archive);
        end
        staging = tempname(runtime_parent);
        mkdir(staging);
        cleanup = onCleanup(@() remove_staging(staging)); %#ok<NASGU>
        [status, output] = system(sprintf('7z x -y -o%s %s', quote(staging), quote(archive)));
        if status ~= 0
            error('MatCUTEst:ExtractionFailed', 'Compiled runtime extraction failed: %s', output);
        end
        staged_root = fullfile(staging, 'matcutest');
        validate_runtime(staged_root);
        if isfolder(runtime_root) || isfile(runtime_root)
            error('MatCUTEst:ConcurrentInstall', 'Runtime appeared during installation; retry without overwriting it.');
        end
        [ok, message] = movefile(staged_root, runtime_root);
        if ~ok
            error('MatCUTEst:RuntimeDirectory', 'Cannot install runtime: %s', message);
        end
    end
    receipt = struct('schema_version', 1, 'provider', 'matcutest', ...
        'runtime_root', canonical_path(runtime_root), ...
        'runtime_paths', {{canonical_path(fullfile(runtime_root, 'mtools', 'src'))}});
end

function validate_runtime(root)
    files = {'mtools/src/macup.m', 'mtools/src/secup.m', ...
        'cutest/src/matlab/cutest_setup.m', 'mtools/GOTCUP'};
    for k = 1:numel(files)
        filename = fullfile(root, files{k});
        if ~isfile(filename)
            error('MatCUTEst:IncompleteRuntime', 'Missing compiled-runtime file: %s', filename);
        end
        require_inside(filename, root);
    end
    if ~strcmp(strtrim(fileread(fullfile(root, 'mtools', 'GOTCUP'))), '1') || ...
            ~isfolder(fullfile(root, 'cutest', 'mex'))
        error('MatCUTEst:IncompleteRuntime', 'The runtime is not a completed compiled installation: %s', root);
    end
    require_inside(fullfile(root, 'mtools', 'src'), root);
    require_inside(fullfile(root, 'cutest', 'mex'), root);
end

function require_inside(filename, root)
    if ~startsWith(canonical_path(filename), [canonical_path(root), filesep])
        error('MatCUTEst:RuntimeOutsideRoot', 'Runtime path escapes the requested root: %s', filename);
    end
end

function filename = canonical_path(filename)
    [status, output] = system(['realpath -e -- ', quote(filename)]);
    if status ~= 0
        error('MatCUTEst:RuntimeDirectory', 'Cannot resolve runtime path: %s', filename);
    end
    filename = strtrim(output);
end

function text = quote(text)
    text = ['''', strrep(char(text), '''', '''"''"'''), ''''];
end

function remove_staging(staging)
    if isfolder(staging)
        rmdir(staging, 's');
    end
end
