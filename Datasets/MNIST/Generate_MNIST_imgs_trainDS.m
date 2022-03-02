function [] = Generate_MNIST_imgs_trainDS()
%%
load('XTrain.mat');
XTrain = extractdata(XTrain);

load('YTrain.mat');

XSize = size(XTrain, 4);
YSize = size(YTrain, 1);

if XSize ~= YSize
    errordlg('XSize ~= YSize');
    return;
else
    Size = XSize;
    clear XSize YSize;
end


for i = 1:Size
    I = mat2gray(XTrain(:,:,:,i));
    
    folder = fullfile('trainDataset', string(YTrain(i)));
    
    if exist(folder, 'dir') == 0
        mkdir(folder);
    end
    
    imwrite(I, fullfile(folder, strcat('image', num2str(i), '.png')), 'png');
end

end
