function [output, message] = functionSquareThree(input1)

if isnumeric(input1) == 1 && length(input1) == 1
    try
        numberOutput = input1.^2;
        message = [];
    catch
        numberOutput = 0;
        message = 'function failed';
    end
else
    numberOutput = 0;
    message = 'input not a number';
end
'pausing for docker testing stuff'
pause(1)

output{1} = pwd;
output{2} = numberOutput;


