function [mov, yuv] = pulldown_32(yuv_sequence)

[rows, cols, temp, numFrames] = size(yuv_sequence);

new_yuv = zeros(rows, cols, 3, numFrames * (5/4), 'uint8');

h = waitbar(0, 'Performing 3:2 pulldown conversion');
%Convert each group of 4 frames to 5 using 3:2 pulldown method
new_ind = 1;
for m = 1:4:numFrames
    waitbar(m/(numFrames/4),h);
    %Extract fields from Y component for 4 frames
    field_A1 = yuv_sequence(1:2:rows,:,1,m);
    field_A2 = yuv_sequence(2:2:rows,:,1,m);
    field_B1 = yuv_sequence(1:2:rows,:,1,m+1);
    field_B2 = yuv_sequence(2:2:rows,:,1,m+1);
    field_C1 = yuv_sequence(1:2:rows,:,1,m+2);
    field_C2 = yuv_sequence(2:2:rows,:,1,m+2);
    field_D1 = yuv_sequence(1:2:rows,:,1,m+3);
    field_D2 = yuv_sequence(2:2:rows,:,1,m+3);
    
    %Define new frames based on the 3:2 pulldown method, and use chroma
    %from original frame (chroma for 5 = chroma for 4)
    %frame 1
    new_yuv(1:2:rows,:,1,new_ind) = field_A1;
    new_yuv(2:2:rows,:,1,new_ind) = field_A2;
    new_yuv(:,:,[2 3],new_ind) = yuv_sequence(:,:,[2 3],m);
    %frame 2
    new_yuv(1:2:rows,:,1,new_ind + 1) = field_A1;
    new_yuv(2:2:rows,:,1,new_ind + 1) = field_B2;
    new_yuv(:,:,[2 3],new_ind + 1) = yuv_sequence(:,:,[2 3], m + 1);
    %frame 3
    new_yuv(1:2:rows,:,1,new_ind + 2) = field_B1;
    new_yuv(2:2:rows,:,1,new_ind + 2) = field_C2;
    new_yuv(:,:,[2 3],new_ind + 2) = yuv_sequence(:,:,[2 3], m + 2);
    %frame 4
    new_yuv(1:2:rows,:,1,new_ind + 3) = field_C1;
    new_yuv(2:2:rows,:,1,new_ind + 3) = field_C2;
    new_yuv(:,:,[2 3],new_ind + 3) = yuv_sequence(:,:,[2 3], m + 3);
    %frame 5
    new_yuv(1:2:rows,:,1,new_ind + 4) = field_D1;
    new_yuv(2:2:rows,:,1,new_ind + 4) = field_D2;
    new_yuv(:,:,[2 3], new_ind + 4) = yuv_sequence(:,:,[2 3], m + 3);
    
    new_ind = new_ind + 5;
end
delete(h)
yuv = new_yuv;
numFrames = numFrames * (5/4); %update number of frames

%CREATE RGB VIDEO SEQUENCE
h = waitbar(0, {['Operation 2 of 2'], ['Creating RGB video sequence ...']});
for m = 1:numFrames
    waitbar(m/(numFrames), h);
    rgbframe = ycbcr2rgb(new_yuv(:,:,:,m));
    mov(m) = im2frame(rgbframe);
end
delete(h)

