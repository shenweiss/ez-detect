
%Note: If a path addition failed and you got the error message displayed, check the calls 
%and arguments to this function, paths are used by matlab to locate functions used through 
%the program and may lead to introduce bugs if you continue the execution.

function error_flag = tryAddPaths(varargin)
    error_flag = false;
    is_directory = 7;
    for i = 1:nargin
        directory_path = varargin{i};
        
        if  exist(directory_path) == is_directory
            addpath(genpath(directory_path));
            error_flag = error_flag || false;
        else
            %Error messages
            disp(['Failed trying to add: ' directory_path ' to Matlab search path.']);
            disp([directory_path 'is not in your file directory.']);
            disp('Quiting Matlab to prevent method lookup failures and crashes in consecuence.');
            error_flag = true;
            quit;
        end
        
    end
end

