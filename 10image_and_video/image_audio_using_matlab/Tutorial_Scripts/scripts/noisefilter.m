function filteredMovie = noisefilter(movie,noiseType,filterType,noisyFrames)
%NOISEFILTER Addition of noise to a movie structure, with filtering
%   filteredMovie = noiseFilter(movie, noiseType, filterType, noisyFrames)
%   will apply noise to all frames designated in noiseFrames, and will then
%   filter the entire sequence using the designated filter in filterType.
%   Options are as follows:
%
%   noiseType:
%       'salt & pepper'     
%       'gaussian'
%
%   filterType:
%       'average'
%       'median'
%
%   noiseyFrames:
%       []              will add noise to all frames
%       [1 2 3 ...]     will add noise to frames 1, 2, 3, ...

frames = length(movie);
[r,c,temp] = size(movie(1).cdata);
filteredRGB = uint8(zeros(r,c,3,frames));

h = waitbar(0);
for k = 1:frames
    waitbar(k/frames,h,['Frame ',num2str(k)]);
    
    curimg = movie(k).cdata;
    
    %if this is one of the selected frames, add noise
    if max(ismember(k,noisyFrames)) || isempty(noisyFrames)
        switch noiseType
            case 'salt & pepper'
                curimg = imnoise(curimg,'salt & pepper');
            case 'gaussian'
                curimg = imnoise(curimg,'gaussian');
        end
    end
    
    %perform filtering
    switch filterType
        case 'average'
            filt = fspecial('average');
            curimg = imfilter(curimg,filt);
        case 'median'
            %filter each component
            curimg(:,:,1) = medfilt2(curimg(:,:,1));
            curimg(:,:,2) = medfilt2(curimg(:,:,2));
            curimg(:,:,3) = medfilt2(curimg(:,:,3));
        case 'wiener'
            curimg(:,:,1) = wiener2(curimg(:,:,1));
            curimg(:,:,2) = wiener2(curimg(:,:,2));
            curimg(:,:,3) = wiener2(curimg(:,:,3));
    end
    % save new frame into rgb sequence
    filteredRGB(:,:,:,k) = curimg;
end
delete(h);
filteredMovie = immovie(filteredRGB);