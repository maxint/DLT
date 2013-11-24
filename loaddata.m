function data=loaddata(fullPath)
% Load image frames from data path

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
return 