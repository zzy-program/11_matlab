function [predictFrame, mv_d, mv_o] = ebma(targetFrame, anchorFrame, blockSize, p, accuracy)

[frameWidth, frameHeight] = size(anchorFrame);
predictFrame=zeros(frameWidth,frameHeight);

k=1;
h = waitbar(0,'Please wait...','CreateCancelBtn','button_callback');

% Loop for width x height of frame by blocksize
% Caculate the search range in Reference Images.
for m=1:blockSize(1):frameWidth-blockSize(1)+1
    waitbar(m/(frameWidth-blockSize(1)+1));
    rangeStart(1)= m*accuracy - p*accuracy;
    rangeEnd(1)= m*accuracy + blockSize(1)*accuracy + p*accuracy;
    if rangeStart(1)<1
        rangeStart(1)=1;
    end
    if rangeEnd(1)>frameWidth*accuracy
        rangeEnd(1)=frameWidth*accuracy;
    end
    for n=1:blockSize(2):frameHeight-blockSize(2)+1
        rangeStart(2)= n*accuracy - p*accuracy;
        rangeEnd(2)= n*accuracy + blockSize(2)*accuracy + p*accuracy;
        if rangeStart(2) < 1
            rangeStart(2) = 1;
        end
        if rangeEnd(2) > frameHeight*accuracy
            rangeEnd(2) = frameHeight*accuracy;
        end

        % -----------------   EBMA SCRIPT  --------------------------------------------
        %Get the Current macro block
        anchorBlock=anchorFrame(m:m+blockSize(1)-1,n:n+blockSize(2)-1);
        %Initial motion vector direction: mv_x mv_y
        mv_x=0;
        mv_y=0;
        %Initial error
        error=255*blockSize(1)*blockSize(2)*100;
        %Search the best estimation from (rangeStart(1),rangeStart(2)) to
        % (rangeEnd(1),rangeEnd(2))
        for x=rangeStart(1):rangeEnd(1)-accuracy*blockSize(2)
            for y=rangeStart(2):rangeEnd(2)-accuracy*blockSize(1)
                targetBlock=targetFrame(x:accuracy:x+accuracy*blockSize(1)- 1, y:accuracy:y+accuracy*blockSize(2)-1);
                %caculate the error
                temp_error=sum(sum(abs(anchorBlock-targetBlock)));
                if temp_error < error
                    error=temp_error;
                    % Direction of motion vector is (mv_x,mv_y)
                    mv_x=y/accuracy-n;
                    mv_y=x/accuracy-m;
                    predictFrame(m:m+blockSize(1)-1,n:n+blockSize(1)-1) =  targetBlock;
                    dx(k) = mv_x;
                    dy(k) = mv_y;
                end; % end if
            end; % end for y
        end; % end for x
        % -----------------   END EBMA SCRIPT  ----------------------------------------
        % Store the location (orientation) of Motion vector as (ox,oy)
        ox(k)=n;
        oy(k)=m;
        k=k+1;
    end
end
mv_d = [dx; dy];
mv_o = [ox; oy];
delete(h);