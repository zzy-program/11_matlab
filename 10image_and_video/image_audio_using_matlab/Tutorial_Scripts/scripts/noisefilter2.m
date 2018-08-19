function filteredMovie = noisefilter2(movie,noiseType,noisyFrames,numAvgFrames)
%NOISEFILTER Addition of noise to a movie structure, with filtering
%   filteredMovie = noiseFilter(movie, noiseType, noisyFrames, numAvgFrames)
%   Will perform frame averaging over numAvgFrames.  Noise specified by
%   noiseType will be applied to the frames defined in noiseFrames
%
%   noiseType:
%       'salt & pepper'     
%       'gaussian'
%
%   noiseyFrames:
%       []              will add noise to all frames
%       [1 2 3 ...]     will add noise to frames 1, 2, 3, ...
%
%   numAvgFrames:
%       how many frames to average in the temporal domain

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
    if k >= numAvgFrames
       for m = 1:numAvgFrames-1
           curimg_set(:,:,:,m) = movie(k-m).cdata;
       end
       curimg_set(:,:,:,numAvgFrames) = curimg;

       filteredRGB(:,:,:,k) = mean(curimg_set,4);
    else
       filteredRGB(:,:,:,k) = curimg;
    end
end
delete(h);
filteredMovie = immovie(filteredRGB);