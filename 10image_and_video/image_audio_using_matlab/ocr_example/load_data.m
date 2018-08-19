% Copyright 2011 O. Marques
% Practical Image and Video Processing Using MATLAB, Wiley-IEEE, 2011.
% 19-Jan-2012 15:36:58

clear all;

out_dir = './ocr_demo_ch19/';
if exist(out_dir)~=7
  mkdir(out_dir)
end 

% load the data
%   data - structure with data
%    .X  - [N x num_vectors]
%    .y  - [1 x num_vectors] class labels
trn_data = load('ocr_trn_data');   % training set
tst_data = load('ocr_tst_data');   % test set 

% Generate images from data file 

temp = size(trn_data.X);
Ntrain = temp(2);

for k = 1:Ntrain
    class = trn_data.y(k);
    char1 = trn_data.X(:,k);
    char2 = reshape(char1,13,13);
    char3 = mat2gray(char2);
    char4 = imresize(char3,[64 64], 'bicubic');
    char5 = imadjust(char4);
    imwrite(char5,[out_dir, sprintf('train_image_%02d_%02d.png',...
        class,rem(k,100))]);
end

temp = size(tst_data.X);
Ntest = temp(2);

for k = 1:Ntest
    class = tst_data.y(k);
    char1 = tst_data.X(:,k);
    char2 = reshape(char1,13,13);
    char3 = mat2gray(char2);
    char4 = imresize(char3,[64 64], 'bicubic');
    char5 = imadjust(char4);
    imwrite(char5,[out_dir, sprintf('test_image_%02d_%02d.png',...
        class,rem(k,100))]);
end