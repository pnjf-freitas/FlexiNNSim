function [predictions,loss,accuracy] = modelPredictions(dlnet,dlXTest,dlYTest,classes)
%{
predictions = [];
dlYPred_total = [];
dlYTest_total = [];

while hasdata(mbq)
    
    [dlXTest, dlYTest] = next(mbq);
    dlYPred = predict(dlnet,dlXTest);
    
    %Predictions
    YPred = onehotdecode(dlYPred,classes,1)';
    predictions = [predictions; YPred];
    
    dlYPred_total = [dlYPred_total , dlYPred];
    dlYTest_total = [dlYTest_total , dlYTest];
    
end
%}

dlYPred = predict(dlnet,dlXTest);
predictions = onehotdecode(dlYPred,classes,1)';

loss = crossentropy(dlYPred, dlYTest);
loss = double(gather(extractdata(loss)));

accuracy = (sum(onehotdecode(dlYTest, classes, 1)' == predictions) / numel(predictions)) * 100;

%reset(mbq);
end

