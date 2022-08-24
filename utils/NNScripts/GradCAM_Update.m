function [fig4, fig4_struct, k] = GradCAM_Update(dlnet, dlXTest, dlYTest, Digit_idx, classes, fig4, epoch, start, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% varargin(1) = fig4_struct
% varargin(2) = k
% k is a counter for storing the frames in fig4_struct

if isempty(varargin)
    k=1;
else
    fig4_struct = varargin{1};
    k = varargin{2};
end


for l = 1 : length(fig4.Children)-1
    Display_prediction = dlfeval(@modelPredictions, dlnet, dlXTest(:,:,:,Digit_idx(l)), dlYTest(:,Digit_idx(l)), classes);
    scoreMap = gradCAM(dlnet, dlXTest(:,:,:,Digit_idx(l)), Display_prediction);
    fig4.Children(l+1).Children.CData = scoreMap;
    fig4.Children(l+1).Title.String = strcat("Prediction = ", string(Display_prediction));

    fig4_struct.scoreMap{k,l} = scoreMap;                   
end

D = duration(0,0,toc(start),'Format','hh:mm:ss');
set(fig4.Children(1), 'String', "Epoch: " + epoch + ", Elapsed: " + string(D));

fig4_struct.frame(k) = getframe(fig4);

k=k+1;
end

