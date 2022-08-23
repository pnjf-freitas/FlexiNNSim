function [fig1, lineAccTrain, lineAccValidation, lineLossTrain, lineLossValidation] = TrainProgress_fig_initialize()  
    fig1 = figure;
    %Acc
    subplot(2,1,1);
    lineAccTrain = animatedline('Color',[0.3010 0.7450 0.9330], 'LineStyle', '-');
    lineAccValidation = animatedline('Color', 'k', 'LineStyle', '--', 'Marker', '.');
    ylim([0 inf]);
    xlabel("Iteration");
    ylabel("Accuracy");
    grid on;

    %Loss
    subplot(2,1,2);
    lineLossTrain = animatedline('Color',[0.85 0.325 0.098], 'LineStyle', '-');
    lineLossValidation = animatedline('Color', 'k', 'LineStyle', '--', 'Marker', '.');
    ylim([0 inf]);
    xlabel("Iteration");
    ylabel("Loss");
    grid on;
end