function [fig2_struct, j] = WeightHistogram_fig_update(fig2, idx, nLayers, dlnet_learnables, gradients, ...
    j, epoch, start, save_bool, varargin)
%UNTITLED6 Summary of this function goes here
%   j is an external counter for the validation steps
%   varargin{1} is fig2_struct

if isempty(varargin) == false
    fig2_struct = varargin{1};
end

temp_idx = find(idx);

for i = 1 : length(fig2.Children) - 1
    %Weights
    if i > nLayers
        histogram(fig2.Children(i), extractdata(gradients.Value{temp_idx(i-nLayers), :}));

        if save_bool == true
            fig2_struct.Data.Gradients{j,i-nLayers} = fig2.Children(i).Children.Data;
        end
    %Gradients
    else
        histogram(fig2.Children(i), extractdata(dlnet_learnables.Value{temp_idx(i), :}));

        if save_bool == true
            fig2_struct.Data.Weights{j,i} = fig2.Children(i).Children.Data;
        end
    end
end

D = duration(0,0,toc(start),'Format','hh:mm:ss');
set(fig2.Children(length(fig2.Children)), 'String', "Epoch: " + epoch + ", Elapsed: " + string(D));
%sgtitle(fig2, "Epoch: " + epoch + ", Elapsed: " + string(D));

%Capture plot as an image
fig2_struct.frame(j) = getframe(fig2);

j=j+1;
end

