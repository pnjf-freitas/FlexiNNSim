function [fig2, nLayers] = WeightHistogram_fig_initialize(dlnet)
    fig2 = figure;
    idx = find(dlnet.Learnables.Parameter == "Weights");
    nLayers = length(idx);
    for i = 1 : 2*nLayers
        if i <= nLayers
            subplot(2, nLayers, i);
            xlabel('Weight');
            title(strcat("Layer ", num2str(i), " Weights"));
        else
            subplot(2, nLayers, i);
            xlabel('Gradient');
            title(strcat("Layer ", num2str(i-nLayers), " Gradients"));
        end
        set(gca, 'NextPlot', 'replacechildren');
    end
    
    sgtitle("Epoch: " + "0" + ", Elapsed: " + string(duration(0,0,0)));
    
    set(fig2, 'Children', flipud(fig2.Children));
    
    clear i;
end