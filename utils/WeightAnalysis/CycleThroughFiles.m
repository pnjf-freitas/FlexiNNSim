clear all;
close all;
clc;

%% Get file list

rootdir = uigetdir;
filename = "Weight_Gradient_Data.mat";

filelist = dir(fullfile(rootdir, strcat("**\", filename)));

filelist = filelist(~[filelist.isdir]);

%% Run function

parfor (i = 1 : length(filelist))
    Weight_heatmap_GIF_Maker_function(filelist(i).folder, filelist(i).name);
end