function [] = Generate_MNIST_imgs_testDS()

%%
load('XTest.mat');
XTest = extractdata(XTest);

load('YTest.mat');

XSize = size(XTest, 4);
YSize = size(YTest, 1);

if XSize ~= YSize
    errordlg('XSize ~= YSize');
    return;
else
    Size = XSize;
    clear XSize YSize;
end


for i = 1:Size
    I = mat2gray(XTest(:,:,:,i));
    
    folder = fullfile('testDataset', string(YTest(i)));
    
    if exist(folder, 'dir') == 0
        mkdir(folder);
    end
    
    imwrite(I, fullfile(folder, strcat('image_test_', num2str(i), '.png')), 'png');
end
end
