function [] = TrainProgress_fig_update(fig1, start, ValidationFrequency, overwriteValidation, ...
    lineAccTrain, accuracyTrain, lineAccValidation, accuracyValidation, ...
    lineLossTrain, lossTrain, lineLossValidation, lossValidation, iteration, epoch)

%Acc
%subplot(2,1,1);
D = duration(0,0,toc(start),'Format','hh:mm:ss');
title(fig1.Children(2), "Epoch: " + epoch + ", Elapsed: " + string(D));
addpoints(lineAccTrain,iteration,accuracyTrain);
if mod(iteration, ValidationFrequency) == 0 || iteration == 1 || overwriteValidation == true
    addpoints(lineAccValidation,iteration,accuracyValidation);
end
drawnow;

%Loss
%subplot(2,1,2);
addpoints(lineLossTrain,iteration,lossTrain);
if mod(iteration, ValidationFrequency) == 0 || iteration == 1 || overwriteValidation == true
    addpoints(lineLossValidation, iteration, lossValidation);
end
drawnow;

end

