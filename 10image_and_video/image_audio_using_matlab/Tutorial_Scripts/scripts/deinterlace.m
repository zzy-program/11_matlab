function [deIntFrame1,deIntFrame2] = deinterlace(method, currY, prevY, nextY);
%
% deinterlace: De-interlace one Y component frame.
%   DEINTERLACE(METHOD, CURRY,PREVY, NEXTY) retrieves the top
%   and bottom fields from an interlaced frame.  The fields are used
%   to de-interlace the Y frame based on the METHOD type passed to the 
%   function.  
%
%   Some methods only require the current frame, currY to be passed to 
%   the function, while others require the next and previous frames.

%   NETHODS that require the current frame, currY to be passed without
%   the prevY and nextY arguments are:  
%       lineAverage: averages two lines from the same frame 
%       fieldMerge: merges the two fields together (makes a copy)
%
%   METHODS that require current frame, currY, previous frame, prevY
%   and next frame, nextY to be passed to the function are:
%       fieldAverage: average of field from prevY frame and nextY frame
%       lineFieldAverage: average of field from prevY frame and nextY frame
%                         and the two lines from the currY frame

[rows cols] = size(currY);
% Get top and bottom fields of Y frame.  Save to jpg image
topFieldCurr(1:rows/2,:,:) = currY(1:2:rows,:,:);
bottomFieldCurr(1:rows/2,:,:) = currY(2:2:rows,:,:);

% Restore field size to original frame size and fill with zeros
topFieldCurr = zeros(rows,cols);
bottomFieldCurr = zeros(rows,cols);
topFieldCurr(1:2:rows,:) = currY(1:2:rows,:);
bottomFieldCurr(2:2:rows,:) = currY(2:2:rows,:);

deIntFrame1 = topFieldCurr;
deIntFrame2 = bottomFieldCurr;

% Only Current frame is used for de-interlacing
if (nargin == 2)
    if (isequal(method,'lineAverage'))
        % LINE AVERAGE METHOD
        
        % De-interlace Field 1
        for i=1:2:rows-2
            for j=1:cols
                deIntFrame1(i+1,j) = (topFieldCurr(i,j) + topFieldCurr(i+2,j))/2;
            end
        end
        deIntFrame1(rows,:) = topFieldCurr(rows,:);
        
        % De-interlace Field 2
        for i=2:2:rows-2
            for j=1:cols
                deIntFrame2(i+1,j) = (bottomFieldCurr(i,j) + bottomFieldCurr(i+2,j))/2;
            end
        end
        deIntFrame2(1,:) = bottomFieldCurr(2,:);

        
    elseif (isequal(method,'fieldMerge'))
        % FIELD MERGE METHOD
        
        % De-interlace Field 1 & Field 2 by merging
        deIntFrame1(2:2:rows,:) = bottomFieldCurr(2:2:rows,:);
        deIntFrame2(1:2:rows,:) = topFieldCurr(1:2:rows,:);

        
    else 'Invalid Method Type'
    end    
    
% Current, Previous, and Next frames are used for de-interlacing    
elseif (nargin == 4)
    
    % Get top and bottom fields of previous and next Y frames.
    topFieldPrev = zeros(rows,cols);
    topFieldNext = zeros(rows,cols);
    bottomFieldPrev = zeros(rows,cols);
    bottomFieldNext = zeros(rows,cols);
    
    topFieldPrev(1:2:rows,:) = prevY(1:2:rows,:);
    topFieldNext(1:2:rows,:) = nextY(1:2:rows,:);
    bottomFieldPrev(2:2:rows,:) = prevY(2:2:rows,:);
    bottomFieldNext(2:2:rows,:) = nextY(2:2:rows,:);
    
    if (isequal(method,'fieldAverage'))
        % FIELD AVERAGE METHOD
        
        % De-interlace Field 1
        for i=2:2:rows
            for j=1:cols
                deIntFrame1(i,j) = (bottomFieldPrev(i,j) + bottomFieldNext(i,j)) /2;
            end
        end
         
        % De-interlace Field 2
        for i=1:2:rows
            for j=1:cols
                deIntFrame2(i,j) = (topFieldPrev(i,j) + topFieldNext(i,j)) /2;
            end
        end

        
    elseif (isequal(method,'lineFieldAverage'))
        % LINE AND FIELD AVERAGE METHOD
        
        % De-Interlace Field 1
        for i=2:2:rows-2
            for j=1:cols
                deIntFrame1(i,j) = ( topFieldCurr(i-1,j) + topFieldCurr(i+1,j) + bottomFieldPrev(i,j) + bottomFieldNext(i,j) ) /4;
            end
        end
        deIntFrame1(rows,:) = topFieldCurr(rows-1,:); 
        
        % De-Interlace Field 2
         for i=3:2:rows-2
            for j=1:cols
                deIntFrame2(i,j) = ( bottomFieldCurr(i-1,j) + bottomFieldCurr(i+1,j) + topFieldPrev(i,j) + topFieldNext(i,j) ) /4;
            end
        end
        deIntFrame2(1,:) = topFieldCurr(1,:);
        

    else 'Invalid Method Type'
    end
    
else 'Invalid Number of Arguments'
end
   

        
    