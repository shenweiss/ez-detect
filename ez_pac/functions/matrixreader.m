function [channelinfo] = matrixreader(matrixfilename)

% Ictal Map v0.1 matrixreader function. Written by Garrett Banks.
% Columbia University, 2011-2014.
% Please contact Dr. Weiss (saweiss@mednet.ucla.edu) before publicly or
% privately distributing this code. 

%This function will load a file or take a cell matrix of names
channelinfo.names{1} = ''; %Parameter names is cell type for the names of the channels
channelinfo.proximity{1,1} = '0'; %Parameter proximity is a numerical matrix read UL,U,UR,L,R,DL,D,DR for which channels have which channels in proximity to them.
channelinfo.fail = 0;

%Determining the input type
if ischar(matrixfilename)
    load(matrixfilename);
    if (exist('matrix') == 0)
        disp('Error in loading file - File must exist and contain a variable called matrix');
        channelinfo.fail = 1;
        return
    end
    disp(strcat('Loading File: ', matrixfilename));
elseif iscell(matrixfilename)
    disp('Received input matrix of cell type.');
    matrix = matrixfilename;
else
    disp('ERROR: Program does not understand input.');
    channelinfo.fail = 1;
    return
end

%Program now has a variable of cell type called matrix that will be
%analyzed, regardless of input modality.
MatrixSize = size(matrix); %MatrixSize(1) = Number of Rows MatrixSize(2) = Number of Columns
Counter = 0;
for i = 1:MatrixSize(1)
    for j = 1:MatrixSize(2)
        if(strcmp(matrix{i,j},'0')~=1)
            Counter = Counter + 1;
            channelinfo.names{Counter} = matrix{i,j};
            %Check UL (Upper left)
            if(i~=1 && j~=1 && MatrixSize(1) ~= 1 && MatrixSize(2) ~= 1)
                if(0 == strcmp(matrix{(i-1),(j-1)}, '0'))
                    channelinfo.proximity{Counter,1} = matrix{(i-1),(j-1)};
                else
                    channelinfo.proximity{Counter,1} = '0';
                end
            else
                channelinfo.proximity{Counter,1} = '0';
            end
            %Check U (Up)
            if(i~=1 && MatrixSize(1) ~= 1)
                if(0 == strcmp(matrix{(i-1),(j)}, '0'))
                    channelinfo.proximity{Counter,2} = matrix{(i-1),(j)};
                else
                    channelinfo.proximity{Counter,2} = '0';
                end
            else
                channelinfo.proximity{Counter,2} = '0';
            end
            %Check UR (Upper right)
            if(i~=1 && j~=MatrixSize(2) && MatrixSize(1) ~= 1 && MatrixSize(2) ~= 1)
                if(0 == strcmp(matrix{(i-1),(j+1)}, '0'))
                    channelinfo.proximity{Counter,3} = matrix{(i-1),(j+1)};
                else
                    channelinfo.proximity{Counter,3} = '0';
                end
            else
                channelinfo.proximity{Counter,3} = '0';
            end
            %Check L (Left)
            if(j~=1 && MatrixSize(1) ~= 1)
                if(0 == strcmp(matrix{(i),(j-1)}, '0'))
                    channelinfo.proximity{Counter,4} = matrix{(i),(j-1)};
                else
                    channelinfo.proximity{Counter,4} = '0';
                end
            else
                channelinfo.proximity{Counter,4} = '0';
            end
            %Check R (Right)
            if(j~=MatrixSize(2) && MatrixSize(1) ~= 1)
                if(0 == strcmp(matrix{(i),(j+1)}, '0'))
                    channelinfo.proximity{Counter,5} = matrix{(i),(j+1)};
                else
                    channelinfo.proximity{Counter,5} = '0';
                end
            else
                channelinfo.proximity{Counter,5} = '0';
            end
            %Check DL (Down Left)
            if(i~=MatrixSize(1) && j~=1 && MatrixSize(1) ~= 1 && MatrixSize(2) ~= 1)
                if(0 == strcmp(matrix{(i+1),(j-1)}, '0'))
                    channelinfo.proximity{Counter,6} = matrix{(i+1),(j-1)};
                else
                    channelinfo.proximity{Counter,6} = '0';
                end
            else
                channelinfo.proximity{Counter,6} = '0';
            end
            %Check D (Down)
            if(i~=MatrixSize(1) && MatrixSize(1) ~= 1)
                if(0 == strcmp(matrix{(i+1),(j)}, '0'))
                    channelinfo.proximity{Counter,7} = matrix{(i+1),(j)};
                else
                    channelinfo.proximity{Counter,7} = '0';
                end
            else
                channelinfo.proximity{Counter,7} = '0';
            end
            %Check DR (Down Right)
            if(i~=MatrixSize(1) && j~=MatrixSize(2) && MatrixSize(1) ~= 1 && MatrixSize(2) ~= 1)
                if(0 == strcmp(matrix{(i+1),(j+1)}, '0'))
                    channelinfo.proximity{Counter,8} = matrix{(i+1),(j+1)};
                else
                    channelinfo.proximity{Counter,8} = '0';
                end
            else
                channelinfo.proximity{Counter,8} = '0';
            end
           
        end
    end
end
channelinfo.matrix = matrix;


end

