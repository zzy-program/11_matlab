% Copyright 2011 O. Marques
% Practical Image and Video Processing Using MATLAB, Wiley-IEEE, 2011.
% Revision: 1.0 Date: 19-Jan-2012 15:44:20

%% Preprocess training images

for k = 1:Ntrain
    class = trn_data.y(k);
    I = imread([out_dir, sprintf('train_image_%02d_%02d.png',...
        class,rem(k,100))]);
    bw1 = ~im2bw(I,graythresh(I));
    [L, N] = bwlabel(bw1);
    if N > 1 % more than one blob... not good ...
        disp(sprintf('Warning: train_image_%02d_%02d.png has problems and \n has been replaced with a copy of image %s\n', ...
            class, rem(k,100),last_success));
        copyfile([out_dir, last_success], [out_dir, ...
            sprintf('train_image_%02d_%02d_bw.png',class,rem(k,100))]);
    else
        imwrite(bw1,[out_dir, sprintf('train_image_%02d_%02d_bw.png',...
            class,rem(k,100))]);
    end
    last_success = sprintf('train_image_%02d_%02d_bw.png',...
        class,rem(k,100));
end

%% Preprocess test images

% Fix problems by copying good images over bad ones (and keeping dataset 
% size the same as before)

for k = 1:Ntest
    class = tst_data.y(k);
    I = imread([out_dir, sprintf('test_image_%02d_%02d.png',...
        class,rem(k,100))]);
    bw1 = ~im2bw(I,graythresh(I));
    [L, N] = bwlabel(bw1);
    if N > 1 % more than one blob... not good ...
        disp(sprintf('Warning: test_image_%02d_%02d.png has problems and \n has been replaced with a copy of image %s\n', ...
            class, rem(k,100),last_success));
        copyfile([out_dir, last_success], [out_dir, ...
            sprintf('test_image_%02d_%02d_bw.png',class,rem(k,100))]);
    else
        imwrite(bw1,[out_dir, sprintf('test_image_%02d_%02d_bw.png',...
            class,rem(k,100))]);
    end
    last_success = sprintf('test_image_%02d_%02d_bw.png',class,rem(k,100));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%