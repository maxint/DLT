 % script: trackparam.m
%     loads data and initializes variables
%

% Copyright (C) Jongwoo Lim and David Ross.
% All rights reserved.

% DESCRIPTION OF OPTIONS:
%
% Following is a description of the options you can adjust for
% tracking, each proceeded by its default value.  For a new sequence
% you will certainly have to change p.  To set the other options,
% first try using the values given for one of the demonstration
% sequences, and change parameters as necessary.
%
% p = [px, py, sx, sy, theta]; The location of the target in the first
% frame.
% px and py are th coordinates of the centre of the box
% sx and sy are the size of the box in the x (width) and y (height)
%   dimensions, before rotation
% theta is the rotation angle of the box
%
% 'numsample',1000,   The number of samples used in the condensation
% algorithm/particle filter.  Increasing this will likely improve the
% results, but make the tracker slower.
%
% 'condenssig',0.01,  The standard deviation of the observation likelihood.
%
% 'affsig',[4,4,.02,.02,.005,.001]  These are the standard deviations of
% the dynamics distribution, that is how much we expect the target
% object might move from one frame to the next.  The meaning of each
% number is as follows:
%    affsig(1) = x translation (pixels, mean is 0)
%    affsig(2) = y translation (pixels, mean is 0)
%    affsig(3) = x & y scaling
%    affsig(4) = rotation angle
%    affsig(5) = aspect ratio
%    affsig(6) = skew angle
clear all
% dataPath = 'D:\Dropbox\dropbox\Tracking\data\';
% dataPath = 'F:\dropbox\Tracking\data\';
dataPath = 'e:\projects\object_tracking\data\datasets\';
% title = '20131105_104041';
% title = '20131102_140141';
title = '20131105_105426';

switch (title)
case 'davidin';  p = [158 106 62 78 0];
    opt = struct('numsample',1000, 'affsig',[4, 4,.005,.00,.001,.00]);
case 'trellis';  p = [200 100 45 49 0];
    opt = struct('numsample',1000, 'affsig',[4,4,.00, 0.00, 0.00, 0.0]);
case 'car4';  p = [123 94 107 87 0];
    opt = struct('numsample',1000, 'affsig',[4,4,.02,.0,.001,.00]);
case 'car11';  p = [88 139 30 25 0];
    opt = struct('numsample',1000,'affsig',[4,4,.005,.0,.001,.00]);
case 'animal'; p = [350 40 100 70 0];
    opt = struct('numsample',1000,'affsig',[12, 12,.005, .0, .001, 0.00]);
case 'shaking';  p = [250 170 60 70 0];% A bit unstable
    opt = struct('numsample',1000, 'affsig',[4,4,.005,.00,.001,.00]);
case 'singer1';  p = [100 200 100 300 0];
    opt = struct('numsample',1000, 'affsig',[4,4,.01,.00,.001,.0000]);
case 'bolt';  p = [292 107 25 60 0];
    opt = struct('numsample',1000, 'affsig',[4,4,.005,.000,.001,.000]);
case 'woman';  p = [222 165 35 95 0.0];
    opt = struct('numsample',1000, 'affsig',[4,4,.005,.000,.001,.000]);               
case 'bird2';  p = [116 254 68 72 0.0]; % A bit unstable
    opt = struct('numsample',1000, 'affsig',[4,4,.005,.000,.001,.000]); 
case 'surfer';  p = [286 152 32 35 0.0];
    opt = struct('numsample',1000,'affsig',[8,8,.01,.000,.001,.000]);     
otherwise;
    % read input from init.txt
    inputFile = sprintf('%s/%s/init.txt', dataPath, title);
    if exist(inputFile, 'file')
        p = dlmread(inputFile);
        p(1) = p(1) + p(3)/2;
        p(2) = p(2) + p(4)/2;
        p(5) = 0; % first frame
        opt = struct('numsample',100, 'affsig',[4, 4,.005,.00,.001,.00]);
    else
        error(['unknown title ' title]);        
    end
end

% The number of previous frames used as positive samples.
opt.maxbasis = 10;
% Indicate whether to use GPU in computation.
global useGpu;
useGpu = true;
opt.condenssig = 0.01;
opt.tmplsize = [32, 32];
% Load data
disp('Loading data...');
fullPath = [dataPath, title, '\'];
d = dir([fullPath, '*.jpg']);
if size(d, 1) == 0
    d = dir([fullPath, '*.png']);
end
if size(d, 1) == 0
    d = dir([fullPath, '*.bmp']);
end
im = imread([fullPath, d(1).name]);
data = zeros(size(im, 1), size(im, 2), size(d, 1));
for i = 1 : size(d, 1)
    im = imread([fullPath, d(i).name]);
    if ndims(im) == 2
        data(:, :, i) = im;
    else
        data(:, :, i) = rgb2gray(im);
    end
end

paramOld = [p(1), p(2), p(3)/opt.tmplsize(2), p(5), p(4) /p(3) / (opt.tmplsize(1) / opt.tmplsize(2)), 0];
param0 = affparam2mat(paramOld);