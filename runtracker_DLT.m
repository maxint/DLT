%% Copyright (C) Naiyan Wang and Dit-Yan Yeung.
%% Learning A Deep Compact Image Representation for Visual Tracking. (NIPS2013')
%% All rights reserved.

% initialize variables
clc; clear;
addpath('affineUtility');
addpath('drawUtility');
addpath('imageUtility');
addpath('NN');
trackparam_DLT;
rand('state',0);  randn('state',0);
frame = double(data(:,:,1))/255;
 
if ~exist('opt','var')  opt = [];  end
if ~isfield(opt,'minopt')
  opt.minopt = optimset; opt.minopt.MaxIter = 25; opt.minopt.Display='off';
end

tmpl.mean = warpimg(frame, param0, opt.tmplsize);
tmpl.basis = [];
% Sample 10 positive templates for initialization
for i = 1 : opt.maxbasis / 10
    tmpl.basis(:, (i - 1) * 10 + 1 : i * 10) = samplePos_DLT(frame, param0, opt.tmplsize);
end
% Sample 100 negative templates for initialization
p0 = paramOld(5);
tmpl.basis(:, opt.maxbasis + 1 : 100 + opt.maxbasis) = sampleNeg(frame, param0, opt.tmplsize, 100, opt, 8);

param.est = param0;
savedRes = [];
 
% draw initial track window
drawopt = drawtrackresult([], 0, frame, tmpl, param, []);
disp('resize the window as necessary, then press any key..'); pause;
drawopt.showcondens = 0;  drawopt.thcondens = 1/opt.numsample;

wimgs = [];


% track the sequence from frame 2 onward
duration = 0; tic;
if (exist('dispstr','var'))  dispstr='';  end
L = [ones(opt.maxbasis, 1); (-1) * ones(100, 1)];
nn = initDLT(tmpl, L);
L = [];
pos = tmpl.basis(:, 1 : opt.maxbasis);
pos(:, opt.maxbasis + 1) = tmpl.basis(:, 1);

opts.numepochs = 5 ;
% opts.plot = 1;

newNN.learningRate = 1e-2;
for f = 1:size(data,3)  
  frame = double(data(:,:,f))/255;
  
  % do tracking
   param = estwarp_condens_DLT(frame, tmpl, param, opt, nn);

  % do update
  
  temp = warpimg(frame, param.est', opt.tmplsize);
  % only sample the last 10 frame result and the first frame
  pos(:, mod(f - 1, opt.maxbasis) + 1) = temp(:);
  if  param.update
      opts.batchsize = 10;
      % Sample two set of negative samples at different range.
      neg = sampleNeg(frame, param.est', opt.tmplsize, 49, opt, 8);
      neg = [neg sampleNeg(frame, param.est', opt.tmplsize, 50, opt, 4)];
      nn = nntrain(nn, [pos neg]', [ones(opt.maxbasis + 1, 1); zeros(99, 1)], opts);
  end
  
  duration = duration + toc;
  
  res = affparam2geom(param.est);
  p(1) = round(res(1));
  p(2) = round(res(2)); 
  p(3) = res(3) * opt.tmplsize(2);
  p(4) = res(5) * (opt.tmplsize(1) / opt.tmplsize(2)) * p(3);
  p(5) = res(4);
  p(3) = round(p(3));
  p(4) = round(p(4));
  savedRes = [savedRes; p];
  tmpl.basis = [pos];
  drawopt = drawtrackresult(drawopt, f, frame, tmpl, param, []);
  tic;
end
duration = duration + toc
save([title '_dlt'], 'savedRes');
fprintf('%d frames took %.3f seconds : %.3fps\n',f,duration,f/duration);

