classdef MatcutestOracle < handle
%MATCUTESTORACLE Internal, serializable binding to one installed problem MEX.
% Native setup is performed once per construction/reload, not per evaluation.
% All commands use the bound MEX handle; caller path and cwd are untouched by
% objective/constraint callbacks. No upstream source is modified.

    properties (SetAccess = private)
        MexDirectory
        SetupData
    end

    properties (Access = private, Transient)
        Mex
        UpperIndices
        LowerIndices
        EqualityIndices
        LowerBounds
        UpperBounds
    end

    methods
        function oracle = MatcutestOracle(directory)
            if ~isfolder(directory) || ~isfile(fullfile(directory, ['mcutest.', mexext]))
                error('MATLAB:matcutest_load:RuntimeUnavailable', 'Missing problem MEX in %s.', directory);
            end
            original = pwd;
            cleanup = onCleanup(@() cd(original)); %#ok<NASGU>
            cd(directory);
            oracle.Mex = @mcutest;
            detail = functions(oracle.Mex);
            oracle.MexDirectory = fileparts(detail.file);
            if ~strcmp(oracle.MexDirectory, pwd)
                error('MATLAB:matcutest_load:RuntimeIdentityMismatch', 'The selected MEX does not belong to %s.', pwd);
            end
            try
                oracle.Mex('terminate');
            catch
                % The native setup sequence also permits an uninitialized MEX.
            end
            oracle.SetupData = oracle.Mex('setup');
            data = oracle.SetupData;
            oracle.LowerBounds = data.cl(:);
            oracle.UpperBounds = data.cu(:);
            % CUTEst's +/-1e20 bounds denote an absent side, as in macup.
            oracle.LowerBounds(oracle.LowerBounds <= -1e20) = -inf;
            oracle.UpperBounds(oracle.UpperBounds >= 1e20) = inf;
            nonlinear = ~data.linear(:);
            equality = data.equatn(:);
            oracle.UpperIndices = find(nonlinear & ~equality & oracle.UpperBounds < inf);
            oracle.LowerIndices = find(nonlinear & ~equality & oracle.LowerBounds > -inf);
            oracle.EqualityIndices = find(nonlinear & equality);
        end

        function validate(oracle, native, m_ub, m_eq)
            data = oracle.SetupData;
            if ~strcmp(strtrim(data.name), native.name) || ...
                    ~isequaln(data.x(:), native.x0(:)) || ...
                    numel(oracle.UpperIndices) + numel(oracle.LowerIndices) ~= m_ub || ...
                    numel(oracle.EqualityIndices) ~= m_eq
                error('MATLAB:matcutest_load:RuntimeIdentityMismatch', ...
                    'Bound MEX metadata disagrees with macup for %s.', native.name);
            end
        end

        function [f, g, H] = objective(oracle, x)
            if nargout < 2
                f = oracle.Mex('obj', x);
            else
                [f, g] = oracle.Mex('obj', x);
            end
            if nargout > 2
                H = oracle.Mex('ihess', x, 0);
            end
        end

        function [cub, ceq, Jcub, Jceq] = constraints(oracle, x)
            if nargout < 3
                c = oracle.Mex('cons', x);
            else
                [c, J] = oracle.Mex('cons', x);
            end
            upper = oracle.UpperIndices;
            lower = oracle.LowerIndices;
            equality = oracle.EqualityIndices;
            cub = [c(upper) - oracle.UpperBounds(upper); oracle.LowerBounds(lower) - c(lower)];
            ceq = c(equality) - oracle.UpperBounds(equality);
            if nargout > 2
                % Match the native column-gradient convention; the adapter
                % performs its existing final transpose for Problem.
                Jcub = [J(upper, :).', -J(lower, :).'];
                Jceq = J(equality, :).';
            end
        end

        function saved = saveobj(oracle)
            saved = struct('mex_directory', oracle.MexDirectory, 'setup_data', oracle.SetupData);
        end
    end

    methods (Static)
        function oracle = loadobj(saved)
            oracle = MatcutestOracle(saved.mex_directory);
            if ~isequaln(oracle.SetupData, saved.setup_data)
                error('MATLAB:matcutest_load:RuntimeIdentityMismatch', ...
                    'Installed MEX metadata changed since this Problem was saved.');
            end
        end
    end
end
