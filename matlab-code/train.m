function output = train()
% This acts as a template function for using AWS SageMaker with a Docker
% image that uses this function as the Entrypoint. Still need to test
% failure conditions


% Training data available at: /opt/ml/input/data/training
fileList = dir('/opt/ml/input/data/training/');

% fileList(1).name = .
% fileList(2).name = ..
% fileList(3).name is the .csv data file
% Create the file location path
try
    %% 1. File Import Preparation
    % This unoptimized loop simply looks for .csv files in the fileList.
    % Change as needed to read in multiple files, different filetypes, etc.
    fileListNames = {fileList(:).name};
    for k = 1:length(fileListNames)
        csvLocs = strfind(fileListNames{k},'.csv');
        if  isempty(csvLocs) == 1
            csvLog(k) = 0;
        else
            csvLog(k) = 1;
        end
    end
    fileListID = find(csvLog,1);
    tableFileLocation = ['/opt/ml/input/data/training/' fileList(fileListID).name];
    %read in the data
    dataTable = readtable(tableFileLocation);
    
    % pull the number to be sent to the function.
    fcnInput = dataTable{1,2};
    
    %% 2.  Call your specialized function here:
    [functionOutput, message] = functionSquareThree(fcnInput);
    
    
    %% 3. Save the function output.
    functionOutputTabled = table(functionOutput); % this would go to a helper function for "tableizing" your output if it's not done already.
    writetable(functionOutputTabled, '/opt/ml/model/modelOutput.txt')
    
    
    
    % Write error message to /opt/ml/output
    if isempty(message) ~= 1
        messageCell{1} = message;
        tableMessage = table(messageCell);
%         writetable(tableMessage,'/opt/ml/output/failure/Error_Message.txt')
        writetable(tableMessage,'/opt/ml/output/failure')
        'failure 1'
        output = 1;
        
    else
        output = 0;
        'matlab runs as expected'
    end
    
catch
    messageCell{1} = 'bad input file';
    tableMessage = table(messageCell);
%     writetable(tableMessage,'/opt/ml/output/failure/Error_Message.txt')
    writetable(tableMessage,'/opt/ml/output/failure')
    'failure 2'
    output = 2;
end


