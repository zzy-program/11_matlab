function ihmdemo(action,value)
%IHMDEMO Interactive Histogram Matching Demo
%   This demo allows you to interactively create a function that will be
%   used for histogram matching.  The function that you create represents
%   the desired histogram shape and is used with the histeq function to 
%   perform histogram matching.
%
%IHMDEMO(img)
%   You can also specify your own image using the syntax ihmdemo('<your
%   image file name>').  Color images will be converted to monochrome.
%
% To create a new point on the curve, click on the curve where you want
% the new point.
%
% To move a point, click and drag the point you want.  
%
% To delete a point, simply click on it.
%
% The points you create are interpolated to create the function points in
% between your points.  There are several interpolation methods that
% MATLAB can use.  These methods can be selected from the 'Interpolation
% Method' pull-down menu.  If you wish to see the matched histogram and
% matched image update continuously while you create your function, you
% can select the 'Continuous Update' check box.  This only really applies
% to dragging points, because the histogram and image are automatically
% updated after a change has been made to the function.

% Sub-function descriptions
%
%   InitializeIHMDemo       Initializes the figure and all defaults
%
%   MyButtonDownFcn         Is called when either a point or the function
%                           is clicked.  
%
%   ButtonUp                Is called when the mouse is released
%
%   Motion                  This function is active after the
%                           MyButtonDownFcn is called - after the user
%                           clicks either a point or line.  It is called
%                           every time the user moves the mouse with the
%                           mouse button down on the axes.
%
%   plot_data               This function updates the plot of the
%                           function.  When you create/delete
%                           or move points, the cooridinates for those
%                           points are updated, but the interpolated
%                           function line must be updated as well.  That is
%                           what this function does.
%
%   update_img              This updates the histogram and image according
%                           to the new specification function.


if nargin<1,
    %Demo was started with no specified image
    InitializeIHMDemo()
elseif nargin == 1
    %User specified an image when started
    InitializeIHMDemo(action)
else
    %An action from the figure was called
    switch action
        case 'MyButtonDownFcn'
            MyButtonDownFcn(value);
        case 'Motion'
            Motion(value);
        case 'ButtonUp'
            ButtonUp(value);
        case 'Update'
            yi = plot_data;
            update_img(yi);
    end
end;

return;



%%%
%%%  Sub-Function InitializeIHMDemo()
%%%

function InitializeIHMDemo(imgname)
% imgname: User specified image name

%If demo is already running, close it
h = findobj(allchild(0), 'tag', 'IHMDemoFig');
if ~isempty(h)
   close(h(1))
end

if nargin<1
    %Load with default image
    img = imread('imdemos/pout.tif');
else
    %Try to load user specified image
    try
        img = imread(imgname);
    catch
        disp 'Bad image filename'
        return
    end
    %Make sure image is monochrome or indexed
    if ndims(img) ~= 2
        img = rgb2gray(img);
        disp 'Image was converted to monochrome'
    end
end

%Create figure, but keep visibility off until it is complete
IHMDemoFig = figure( ...
    'Name', 'Interactive Histogram Matching Demo', ...
    'NumberTitle', 'Off', ...
    'Resize', 'Off', ...
    'Tag', 'IHMDemoFig', ...
    'Toolbar', 'None', ...
    'Units', 'Pixels', ...
    'Visible', 'Off');

%Calculate new position for figure
curpos = get(IHMDemoFig,'Position');
screen = get(0,'ScreenSize');
new_height = 535;
new_width = 815;
new_left = (screen(3) / 2) - 400;
new_bottom = (screen(4) / 2) - (new_height / 2);
set(IHMDemoFig, ...
    'Position', [new_left new_bottom new_width new_height]);
 
%Create both histogram plotting axes
ud.hist1 = axes( ...
    'Parent', IHMDemoFig, ...
    'Units', 'Pixels', ...
    'Position', [40 300 200 200]);

ud.hist2 = axes( ...
    'Parent', IHMDemoFig, ...
    'Units', 'Pixels', ...
    'Position', [575 300 200 200]);

%Create colorbar axes
cbar = 0:255;
cbar = repmat(cbar,3,1);

colorbar1 = axes( ...
    'Units', 'Pixels', ...
    'Position', [40 290 200 10]);
image(cbar);
set(colorbar1, ...
    'XTick', [], ...
    'YTick', []);

colorbar2 = axes( ...
    'Units', 'Pixels', ...
    'Position', [575 290 200 10]);
image(cbar);
set(colorbar2, ...
    'XTick', [], ...
    'YTick', []);

%Create both image axes
ud.img1 = axes( ...
    'Units', 'Pixels', ...
    'Position', [40 25 200 200]);
 
ud.img2 = axes( ...
    'Units', 'Pixels', ...
    'Position', [575 25 200 200]);
 
%Create Hist Matching axes
ud.histmatch = axes( ...
    'Units', 'Pixels', ...
    'Position', [300 175 225 200], ...
    'Xlim', [0 1], ...
    'Ylim', [0 1], ...
    'Drawmode', 'fast', ...
    'GridLineStyle',':');
title('Desired Histogram Shape');
grid on

%Default points and function line object (not the actual interpolated
%function line, but just the object.  This will be update later).
ud.xpts = [0 1];
ud.ypts = [0.5 0.5];
ud.hmline = line( ...
    'Parent', ud.histmatch, ...
    'LineWidth', 2, ...
	'ButtonDownFcn', 'ihmdemo(''MyButtonDownFcn'',0)');

%Initial hist matching points
ud.hmpoint_default.LineStyle = 'none';
ud.hmpoint_default.Marker = 'o';
ud.hmpoint_default.MarkerFaceColor = 'g';
ud.hmpoint_default.Color = 'k';
ud.hmpoint_default.ButtonDownFcn = ...
    'ihmdemo(''MyButtonDownFcn'',1)';
ud.hmpoint_default.Parent = ud.histmatch;

ud.hmpoint{1} = line(ud.hmpoint_default, ...
    'XData', [ud.xpts(1) ud.xpts(1)], ...
    'YData', [ud.ypts(1) ud.ypts(1)]);
ud.hmpoint{2} = line(ud.hmpoint_default, ...
    'XData', [ud.xpts(2) ud.xpts(2)], ...
    'YData', [ud.ypts(2) ud.ypts(2)]);
    
%Show histogram data for original image
CNTS = imhist(img,256);
bar(ud.hist1,CNTS);
axis tight
set(ud.hist1,...
    'XLim', [1 256], ...
    'YLim', [0 max(CNTS)], ...
    'XTick', [], ...
    'YTick', []);
axes(ud.hist1);
title('Original Histogram');

%Show original image
axes(ud.img1)
imshow(img);
title('Original Image');

%Create handle for new histogram data and set it to bar graph of original
%data
ud.hist2data = bar(ud.hist2, ...
    CNTS);
set(ud.hist2, ...
    'YLim', [1 max(CNTS)], ...
    'XLim', [1 256], ...
    'XTick', []);
axes(ud.hist2);
title('Matched Histogram');

%Create check mark buttons and pull down menus
ud.interp = uicontrol(...
    'Style', 'popupmenu', ...
    'String', 'Spline|Linear|Nearest', ...
    'Position', [425 100 100 20], ...
    'Callback', 'ihmdemo(''Update'',0)');
uicontrol(...
    'Style', 'text', ...
    'String', 'Interpolation Method', ...
    'BackgroundColor', get(IHMDemoFig, 'Color'), ...
    'Position', [300 100 100 17], ...
    'HorizontalAlignment', 'left');
ud.update = uicontrol(...
    'Style', 'Checkbox', ...
    'Position', [425 80 15 15]);
uicontrol(...
    'Style', 'text', ...
    'String', 'Continuous Update', ...
    'BackgroundColor', get(IHMDemoFig, 'Color'), ...
    'Position', [300 65 100 30], ...
    'HorizontalAlignment', 'left');

%Save data to UserData
ud.img = img;
set(IHMDemoFig,'UserData', ud, ...
    'Visible', 'On');
%calculate line using interpolation
interp_line = plot_data;
%Calculate and show initial histogram specification
update_img(interp_line);

return



%%%
%%% Sub-Function MyButtonDownFcn
%%%

function MyButtonDownFcn(op)

%Get current x and y points of specification function
ud = get(gcf,'UserData');
xpts = ud.xpts;
ypts = ud.ypts;
%Get current point user clicked
pt = get(gca,'CurrentPoint');
pt = pt(1,1:2);
switch op
    case 0  %User clicked on the plot, so create a new point.
        ud.xpts(length(ud.xpts)+1) = pt(1);
        ud.ypts(length(ud.ypts)+1) = pt(2);
        ud.hmpoint{length(ud.hmpoint)+1} = line( ...
            ud.hmpoint_default, ...
            'XData', [pt(1) pt(1)], ...
            'YData', [pt(2) pt(2)]);
        
    case 1  %User clicked on a point
        for i = 1:size(ud.xpts,2)
            norms(i) = norm([ud.xpts(i) ud.ypts(i)] - pt);
        end
        my_pt =  find(norms == min(norms));
        set(gcf,'WindowButtonMotionFcn', ...
            ['ihmdemo(''Motion'',' num2str(my_pt) ')'], ...
            'WindowButtonUpFcn', ...
            ['ihmdemo(''ButtonUp'',' num2str(my_pt) ')']);
        setptr(gcf, 'fleur');
end
ud.ButtonDownpt = pt;
set(gcf,'UserData',ud); 
yi = plot_data;
update_img(yi);

return



%%%
%%% Sub-Function ButtonUp
%%%

function ButtonUp(pt)
ud = get(gcf,'UserData');
newpt = get(ud.histmatch,'CurrentPoint');
newpt = newpt(1,1:2);
if pt ~= 1 && pt ~= 2 && ...
        ~isempty(ud.ButtonDownpt) && ...
        norm(ud.ButtonDownpt - newpt) < 0.01
    %Delete this point
    %To delete a point, we must completly redraw the graph
    ud.xpts(pt) = [];
    ud.ypts(pt) = [];
    cla(ud.histmatch);
    ud.hmline = line( ...
        'Parent', ud.histmatch, ...
        'LineWidth', 2, ...
        'ButtonDownFcn', 'ihmdemo(''MyButtonDownFcn'',0)');
    ud.hmpoint = [];
    for i = 1:length(ud.xpts)
        ud.hmpoint{i} = line(ud.hmpoint_default, ...
        'XData', [ud.xpts(i) ud.xpts(i)], ...
        'YData', [ud.ypts(i) ud.ypts(i)]);
    end
end

set(gcf,'WindowButtonMotionFcn','', ...
    'WindowButtonUpFcn','');
setptr(gcf, 'arrow');
set(gcf,'UserData',ud);
yi = plot_data;
update_img(yi);
return



%%%
%%% Sub-Function Motion
%%%

function Motion(pt)

%get current location of mouse
ud = get(gcf,'UserData');
newpt = get(ud.histmatch,'CurrentPoint');
newpt = newpt(1,1:2);

%set [pt] to this new point only if within limits
if pt ~= 1 && pt ~= 2 && ...
        isempty(find(ud.xpts == newpt(1)))
    %only allow vertical movement for first and last points
    if newpt(1) < 0
        ud.xpts(pt) = 0.0001;
    elseif newpt(1) > 1
        ud.xpts(pt) = 0.9999;
    else
        ud.xpts(pt) = newpt(1);
    end
end

if newpt(2) < 0
    %very close to zero, but not zero because histeq needs non-zero values
    ud.ypts(pt) = 0.0001;
elseif newpt(2) > 1
    ud.ypts(pt) = 1;
else
    ud.ypts(pt) = newpt(2);
end

%Update location of point on axes

set(ud.hmpoint{pt}, ...
    'XData', ud.xpts(pt), ...
    'YData', ud.ypts(pt));

%Save new point data
ud.ButtonDownpt = [];
set(gcf,'UserData',ud);
%Update histogram and image
yi = plot_data;
if get(ud.update,'Value') == 1
    update_img(yi);
end

return


%%%
%%% Sub-Function plot_data
%%%

function yi = plot_data
ud = get(gcf,'UserData');

%Interpolate data
xi = linspace(0,1,256);%Which interpolation method to use
switch get(ud.interp,'Value')
    case 1
        method = 'spline';
    case 2
        method = 'linear';
    case 3
        method = 'nearest';
end
yi = interp1(ud.xpts,ud.ypts,xi,method);
too_high = find(yi > 1);
too_low = find(yi < 0);
yi(too_high) = 1;
yi(too_low) = 0;
%Plot new data
set(ud.hmline, ...
    'XData', xi, ...
    'YData', yi);
set(gcf,'NextPlot','add')
return



%%%
%%% Sub-Function update_img
%%%

function update_img(yi)

ud = get(gcf,'UserData');

new_img = histeq(ud.img,yi);
NEW_CNTS = imhist(new_img,256);

%only update new image if setting is set
set(ud.hist2data, ...
    'YData', NEW_CNTS);
set(ud.hist2, ...
    'XTick', [], ...
    'YTick', []);

%Show initial image matched  
axes(ud.img2)
imshow(new_img);
set(ud.img2, ...
    'Tag', 'img2');
title('Matched Image');

set(gcf,'UserData',ud);
return