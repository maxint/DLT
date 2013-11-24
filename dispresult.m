function dispresult(title)

addpath('drawUtility');

% display result
dataFile = [title, '_dlt.mat'];
res = load(dataFile, 'savedRes');
res = res.savedRes;
dataPath = 'e:\projects\object_tracking\data\datasets\';
data = loaddata([dataPath, title, '\']);

% draw initial track window
for f = 1:size(data,3)  
  frame = double(data(:,:,f))/255;
  imshow(frame);
  hold on
  bb = res(f,:);
  x0 = bb(1) - bb(3)/2;
  x1 = bb(1) + bb(3)/2;
  y0 = bb(2) - bb(4)/2;
  y1 = bb(2) + bb(4)/2;
  plot([x0 x1 x1 x0 x0],[y0 y0 y1 y1 y0],'Color','r','LineWidth',2)
  hold off
  pause(0.1)
end