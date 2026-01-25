function success = install(path)
%INSTALL installs MatCUTEst at fullfile(path, 'matcutest'), using the compiled CUTEst in the
% directory containing this M file or at zipurl.

if ispc || ismac
    error('MatCUTEst:InvalidOS', 'This package supports only GNU/Linux.');
end

% 7z is needed. For Ubuntu, try  `type 7z || sudo apt install 7zip`.
sevenz = '7z';
[status, output] = system([sevenz ' 2>&1']);
if status ~= 0
    error('MatCUTEst:SevenzFailed', '\nCommand ''%s'' failed with message:\n%s\nMake sure that 7zip is installed and %s can be called within MATLAB.', sevenz, output, sevenz);
end

% pkg is the package containing the compiled version of MatCUTEst.
pkg = 'full.matcutest.7z.001';
gitaccount = 'matcutest';
gitrepo = 'matcutest_compiled';
zipurl = ['https://github.com/', gitaccount, '/', gitrepo, '/archive/refs/heads/main.zip'];

% mdir is the directory containing this script.
mdir = fileparts(mfilename('fullpath'));
% cpwd is the current directory.
cpwd = pwd();

if nargin > 0
    if ~exist(path, 'dir')
        mkdir(path);
    end
else
    % Decide `path` if it is not provided.
    homedir = getenv('HOME');
    if exist(fullfile(homedir, 'local'), 'dir')
        path = fullfile(homedir, 'local');
    elseif exist(fullfile(homedir, '.local'), 'dir')
        path = fullfile(homedir, '.local');
    else
        path = mdir;
    end
end

% matcutest is the root directory of MatCUTEst.
matcutest = fullfile(path, 'matcutest');
if exist(matcutest, 'dir') || exist(matcutest, 'file')
    fprintf('\nThe package path\n\n    %s\n\nalready exists. Remove it to (re-)install the package.\n\n',  matcutest);
    success = false;
    return
end
fprintf('\nMatCUTEst will be installed at\n\n    %s\n', matcutest);

if exist(fullfile(mdir, pkg), 'file')
    pkg = fullfile(mdir, pkg);
else
    [~, name, ext] = fileparts(zipurl);
    zipname = [gitrepo, '-', name, ext];
    zipname = fullfile(tempdir, zipname);

    fprintf('\nDownloading the compiled package from\n\n    %s\n\nThis may take some time.\n', zipurl);
    websave(zipname, zipurl);
    unzip(zipname, tempdir);
    zipdir = fullfile(tempdir, [gitrepo, '-', name]);
    pkg = fullfile(zipdir, pkg);
    fprintf('\nDone.\n');
end

fprintf('\nInstalling the compiled package\n\n    %s\n\nThis may take some time.\n', pkg);

exception = [];
try
    cd(path);
    % Run `7z x pkg`. Use `evalc` to make is quiet.
    [status, output] = system([sevenz ' x ' pkg]);
    if status ~= 0
        error('MatCUTEst:SevenzExtractFailed', '\nExtraction failed with message:\n%s', output);
    end
    cd(fullfile(matcutest, 'mtools'));
    setup();
catch exception
    if exist(matcutest, 'dir')
        rmdir(matcutest, 's');
    end
end
cd(cpwd);

if isempty(exception)
    fprintf('MatCUTEst is successfully installed at\n\n    %s\n', matcutest);
    fprintf('\nTry "help matcutest" for more information.\n\n');
    success = true;
else
    rethrow(exception);
end

return
