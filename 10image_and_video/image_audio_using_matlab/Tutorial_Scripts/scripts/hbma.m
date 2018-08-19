function [predictFrame, mv_d, mv_o] = hbma(targetFrame, anchorFrame, blockSize, rangs, range, accuracy, L)

[frameHeight,frameWidth ] = size(anchorFrame);

m=1;
factor=2.^(L-1);
%Initial motion vector direction: mv_x mv_y
mv_x=0;
mv_y=0;

%Initial error
error=255*blockSize(1)*blockSize(2)*100;

% Upownsample anchorerence Frame with different resolution
upanchorFrame = zeros(frameHeight*2,frameWidth*2);
upanchorFrame(1:2:frameHeight*2,1:2:frameWidth*2) = anchorFrame;
upanchorFrame(1:2:frameHeight*2-1,2:2:frameWidth*2-1) = (anchorFrame(:,1:frameWidth-1)+anchorFrame(:,2:frameWidth))/2;
upanchorFrame(2:2:frameHeight*2-1,1:2:frameWidth*2-1) = (anchorFrame(1:frameHeight-1,:)+anchorFrame(2:frameHeight,:))/2;
upanchorFrame(2:2:frameHeight*2-1,2:2:frameWidth*2-1) = (anchorFrame(1:frameHeight-1,1:frameWidth-1)+anchorFrame(1:frameHeight-1, 2:frameWidth)+anchorFrame(2:frameHeight,1:frameWidth-1)+ anchorFrame(2:frameHeight,2:frameWidth))/4;
% Downsample targetent Frames (for each level) with different resolution
anchorDown = zeros(3,frameHeight,frameWidth);
anchorDown1 = anchorFrame;
targetDown1 = targetFrame;
targetDown2(1:frameHeight/2,1:frameWidth/2) = targetFrame(1:2:frameHeight,1:2:frameWidth);
targetDown3(1:frameHeight/4,1:frameWidth/4) = targetDown2(1:2:frameHeight/2,1:2:frameWidth/2);
anchorDown2(1:frameHeight/2,1:frameWidth/2) = anchorFrame(1:2:frameHeight,1:2:frameWidth);
anchorDown3(1:frameHeight/4,1:frameWidth/4) = anchorDown2(2:2:frameHeight/2,1:2:frameWidth/2);
predictFrame = anchorFrame;

% Search fields range for each level
rangs(1) = rangs(1)/factor;
range(1) = range(1)/factor;
rangs(2) = rangs(2)/factor;
range(2) = range(2)/factor;
frameHeight = frameHeight/factor;
frameWidth = frameWidth/factor;

% Search for all the blocks in targetent Frames of 1st level
for i=1:blockSize(1):frameHeight-blockSize(1)+1
    rangeStart(1)=i+rangs(1);
    rangeEnd(1)=i+blockSize(1)-1+range(1);
    if rangeStart(1)<1
        rangeStart(1)=1;
    end
    if rangeEnd(1)>frameHeight
        rangeEnd(1)=frameHeight;
    end
    for j=1:blockSize(2):frameWidth-blockSize(2)+1
        rangeStart(2)=j+rangs(2);
        rangeEnd(2)=j+blockSize(2)-1+range(2);
        if rangeStart(2)<1
            rangeStart(2)=1;
        end
        if rangeEnd(2)>frameWidth
            rangeEnd(2)=frameWidth;
        end
        tmpt(:,:)=targetDown3(:,:);
        tmpa(:,:)=anchorDown3(:,:);

        % ******************** EBMA SCRIPT ****************************************
        %Get the targetent macro block
        anchorBlock = tmpa(i:i+blockSize(1)-1,j:j+blockSize(2)-1);
        %Search the best estimation from (rangeStart(1),rangeStart(2)) to
        % (rangeEnd(1),rangeEnd(2))
        for y=rangeStart(1):rangeEnd(1)-accuracy*blockSize(2)+1
            for x=rangeStart(2):rangeEnd(2)-accuracy*blockSize(1)+1
                downtargetFrame = tmpt(y:accuracy:y+accuracy*blockSize(1) - 1,x:accuracy:x+accuracy*blockSize(2)-1);
                %caculate the error
                temp_error=sum(sum(abs(anchorBlock-downtargetFrame)));
                if temp_error < error
                    error=temp_error;
                    mv_x=x/accuracy-j;
                    mv_y=y/accuracy-i;
                    % Direction of motion vector as (dx,dy)
                    dx(m) = mv_x;
                    dy(m) = mv_y;
                end;
            end;
        end;
        % *************** END EBMA Script *****************************************
        % Store the location (orientation) of Motion vector as (ox,oy)
        ox(m)=j;
        oy(m)=i;
        m=m+1;
    end
end
% Search for all the blocks in targetent Frames of all levels
for ii=L-1:-1:1
    % Update all parameters for the targetent level.
    dx=dx*2;
    dy=dy*2;
    frameHeight=frameHeight*2;
    lineWidth=floor(frameWidth/blockSize(2));
    frameWidth=frameWidth*2;
    ttt=size(dy);
    m=1;
    % Search for all the blocks in targetent Frames in the iith level
    for i=1:blockSize(1):frameHeight-blockSize(1)+1
        baseline=double(uint32(i/2/blockSize(1)))*double(lineWidth);
        for j=1:blockSize(2):frameWidth-blockSize(2)+1
            % Caculate the search range in targeterence Frames.
            mindx=floor(baseline+double(uint32(j/2/blockSize(2)))+1);
            if mindx>ttt(2)
                mindx=ttt(2);
            end
            rangeStart(1)=i+dy(mindx)+rangs(1);
            rangeEnd(1)=i+dy(mindx)+blockSize(1)-1+range(1);
            if rangeStart(1)<1
                rangeStart(1)=1;
            end
            if rangeEnd(1)>frameHeight
                rangeEnd(1)=frameHeight;
            end
            rangeStart(2)=j+dx(mindx)+rangs(2);
            rangeEnd(2)=j+dx(mindx)+blockSize(2)-1+range(2);
            if rangeStart(2)<1
                rangeStart(2)=1;
            end
            if rangeEnd(2)>frameWidth
                rangeEnd(2)=frameWidth;
            end
            % Level 2
            if ii==2
                tmpt=targetDown2(:,:);
                tmpa=anchorDown2(:,:);
            end
            % Level 1
            if ii==1
                tmpt=targetDown1(:,:);
                tmpa=anchorDown1(:,:);
            end
            % ******************** EBMA SCRIPT ****************************************
            %Get the targetent macro block
            anchorBlock = tmpa(i:i+blockSize(1)-1,j:j+blockSize(2)-1);
            %Initial motion vector direction: mv_x mv_y
            mv_x=0;
            mv_y=0;
            %Initial error
            error=255*blockSize(1)*blockSize(2)*100;
            %Search the best estimation from (rangeStart(1),rangeStart(2)) to
            % (rangeEnd(1),rangeEnd(2))
            for y=rangeStart(1):rangeEnd(1)-accuracy*blockSize(2)+1
                for x=rangeStart(2):rangeEnd(2)-accuracy*blockSize(1)+1
                    downtargetFrame = tmpt(y:accuracy:y+accuracy*blockSize(1) - 1,x:accuracy:x+accuracy*blockSize(2)-1);
                    %caculate the error
                    temp_error=sum(sum(abs(anchorBlock-downtargetFrame)));
                    if temp_error < error
                        error=temp_error;
                        mv_x=x/accuracy-j;
                        mv_y=y/accuracy-i;
                        % Direction of motion vector as (dx,dy)
                        dxx(m) = mv_x;
                        dyy(m) = mv_y;
                        predictFrame(i:i+blockSize(1)-1,j:j+blockSize(1)-1) = downtargetFrame;
                    end;
                end;
            end;
            % *************** END EBMA Script *****************************************
            % Store the location (orientation) of Motion vector as (ox,oy)
            ox(m)=j;
            oy(m)=i;
            m=m+1;
        end
    end
    dx=dxx;
    dy=dyy;
end
mv_d = [dx; dy];
mv_o = [ox; oy];