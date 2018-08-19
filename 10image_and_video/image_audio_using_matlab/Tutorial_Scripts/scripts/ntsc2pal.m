function [mov, yuv] = ntsc2pal(yuv_sequence)
%NTSC2PAL Convert a video sequence from NTSC (720-by-480) to PAL (720-576)
%   [MOV, YUV] = NTSC2PAL(YUV_SEQUENCE) Converts the NTSC YUV video 
%       sequence into PAL.  
%       The structure MOV returned is a MATLAB video sequence, and
%       YUV is a M-by-N-by-3-by-X array, where M and N are the frame size,
%       and X is the number of frames.  YUV_SEQUENCE must have a multiple
%       of 30 frames.


%get dimensions
[rows, cols, temp, numFrames] = size(yuv_sequence);

%make sure we have proper number of frames
if mod(numFrames, 30) ~= 0
    msgbox('Number of frames must be a multiple of 30');
    mov = [];
    yuv = [];
    return;
end

%preallocate variable for next step
yuv_deint = zeros(rows, cols, 3, numFrames * 2, 'uint8');


%STEP 1: DEINTERLACE (30fps -> 60fps)
h = waitbar(0, {['Operation 1 of 5'], ['Deinterlacing...']});
for m = 1:numFrames
    waitbar(m/numFrames,h);

    [yframe1, yframe2] = deinterlace('lineAverage',yuv_sequence(:,:,1,m)); 
        
    %use chroma from original frame
    yuv_deint(:,:,1,(2*m - 1)) = uint8(yframe1);
    yuv_deint(:,:,2,(2*m - 1)) = uint8(yuv_sequence(:,:,2,m));
    yuv_deint(:,:,3,(2*m - 1)) = uint8(yuv_sequence(:,:,3,m));
    
    yuv_deint(:,:,1,(2*m)) = uint8(yframe2);
    yuv_deint(:,:,2,(2*m)) = uint8(yuv_sequence(:,:,2,m));
    yuv_deint(:,:,3,(2*m)) = uint8(yuv_sequence(:,:,3,m));
end
delete(h);
numFrames = numFrames * 2;  %we now have 2x number of frames


%STEP 2: LINE RATE UP-CONVERSION (480 -> 576) (6/5 ratio)
%preallocate variable for next step
yuv_lineup = zeros(rows * (6/5), cols, 3, numFrames, 'uint8');
coeff = [1.0/6.0, 2.0/6.0, 3.0/6.0, 4.0/6.0, 5.0/6.0];
lines_out = rows * (6/5);
h = waitbar(0, {['Operation 2 of 5'], ...
    ['Performing line rate up-conversion ...']});
for m = 1:numFrames
    waitbar(m/numFrames,h);
    cur_row = 1;
    for n = 1:rows
        if mod(n,5) == 1 || n == rows
            %first line of set of 5, just copy
            %or last row in frame
            yuv_lineup(cur_row,:,:,m) = yuv_deint(n,:,:,m);
            cur_row = cur_row + 1;
        end
        if n ~= rows
            %perform interpolation based on coeff
            mycoeff = mod(n,5);
            mycoeff(find(mycoeff == 0)) = 5;
            yuv_lineup(cur_row,:,:,m) = ...
                yuv_deint(n,:,:,m) .* coeff(mycoeff) + ...
                yuv_deint(n+1,:,:,m) .* (1 - coeff(mycoeff));
            cur_row = cur_row + 1;
        end
    end
end
delete(h)
clear yuv_deint;


%STEP 3: FRAME RATE DOWN-CONVERSTION
yuv_dwn = zeros(rows * (6/5), cols, 3, numFrames * (5/6), 'uint8');
coeff = [1.0/5.0, 2.0/5.0, 3.0/5.0, 4.0/5.0];
cur_frame = 1;
h = waitbar(0, {['Operation 3 of 5'], ['Performing frame rate down-conversion ...']});
for m = 1:numFrames
    waitbar(m/numFrames,h);
    if mod(m,6) == 1
        %First frame of set of 6, just copy
        yuv_dwn(:,:,:,cur_frame) = yuv_lineup(:,:,:,m);
        cur_frame = cur_frame + 1;
    else if mod(m,6) ~= 0
        %interpolate 
        mycoeff = mod(m-1,5);
        mycoeff(find(mycoeff == 0)) = 4;
        yuv_dwn(:,:,:,cur_frame) = yuv_lineup(:,:,:,m) .* coeff(mycoeff) + ...
            yuv_lineup(:,:,:,m+1) .* (1 - coeff(mycoeff));
        cur_frame = cur_frame + 1;
        end
    end
end
clear yuv_lineup
%update number of frames and sizes
[rows, cols, temp, numFrames] = size(yuv_dwn);
delete(h)

%STEP 4: INTERLACE FRAMES
yuv_int = zeros(rows, cols, 3, numFrames/2, 'uint8');
h = waitbar(0, {['Operation 4 of 5'], ['Interlacing frames ...']});
for m = 1:numFrames/2
    waitbar(m/(numFrames/2),h);
    %Extract fields from current and next frame
    field1a = double(yuv_dwn(1:2:rows,:,:,(m*2-1)));
    field1b = double(yuv_dwn(1:2:rows,:,:,(m*2)));
    field2a = double(yuv_dwn(2:2:rows,:,:,(m*2-1)));
    field2b = double(yuv_dwn(2:2:rows,:,:,(m*2)));
    %Average the fields together
    yuv_int(1:2:rows,:,:,m) = uint8((field1a + field1b)/2);
    yuv_int(2:2:rows,:,:,m) = uint8((field2a + field2b)/2);   
end
delete(h)
numFrames = numFrames / 2;
clear yuv_dwn;    
yuv = yuv_int;


%STEP 5: CREATE RGB VIDEO SEQUENCE
h = waitbar(0, {['Operation 5 of 5'], ['Creating RGB video sequence ...']});
for m = 1:numFrames
    waitbar(m/(numFrames), h);
    rgbframe = ycbcr2rgb(yuv(:,:,:,m));
    mov(m) = im2frame(rgbframe);
end
delete(h)