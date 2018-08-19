function glsdemo(action,value)
%GLSDEMO Gray Level Slicing Demo
%   This demo allows you to interactively create a transformation function
%   to be used for Gray Level Slicing.
%
%GLSDEMO(img)
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

% Sub-function descriptions
%
%   Initialize              Initializes the figure and all defaults
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
    Initialize()
elseif nargin == 1
    %User specified an image when started
    Initialize(action)
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
%%%  Sub-Function Initialize()
%%%

function Initialize(imgname)
% imgname: User specified image name

%If demo is already running, close it
h = findobj(allchild(0), 'tag', 'GLSDemoFig');
if ~isempty(h)
   close(h(1))
end

if nargin<1
    %Load with default image
    img = imread('circuit.tif');
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
GLSDemoFig = figure( ...
    'Name', 'Gray Level Slicing Demo', ...
    'NumberTitle', 'Off', ...
    'Resize', 'Off', ...
    'Tag', 'GLSDemoFig', ...
    'Toolbar', 'None', ...
    'Units', 'Pixels', ...
    'Visible', 'Off');

%Calculate new position for figure
curpos = get(GLSDemoFig,'Position');
screen = get(0,'ScreenSize');
new_height = 325;
new_width = 815;
new_left = (screen(3) / 2) - 400;
new_bottom = (screen(4) / 2) - (new_height / 2);
set(GLSDemoFig, ...
    'Position', [new_left new_bottom new_width new_height]);

%Create both image axes
ud.img1 = axes( ...
    'Units', 'Pixels', ...
    'Position', [40 75 200 200]);
 
ud.img2 = axes( ...
    'Units', 'Pixels', ...
    'Position', [575 75 200 200]);
 
%Create gray level slicing axes
ud.slice = axes( ...
    'Units', 'Pixels', ...
    'Position', [300 75 225 200], ...
    'Xlim', [0 255], ...
    'Ylim', [0 255], ...
    'Drawmode', 'fast', ...
    'GridLineStyle',':');
title('Transformation Function');
grid on

%Default points and function line object (not the actual interpolated
%function line, but just the object.  This will be update later).
ud.xpts = [0 255];
ud.ypts = [0 255];
ud.glsline = line( ...
    'LineWidth', 2, ...
	'ButtonDownFcn', 'glsdemo(''MyButtonDownFcn'',0)');

%Initial gls points
ud.glspoint_default.LineStyle = 'none';
ud.glspoint_default.Marker = 'o';
ud.glspoint_default.MarkerFaceColor = 'g';
ud.glspoint_default.Color = 'k';
ud.glspoint_default.ButtonDownFcn = ...
    'glsdemo(''MyButtonDownFcn'',1)';
ud.glspoint_default.parent = ud.slice;

ud.glspoint{1} = line(ud.glspoint_default, ...
    'XData', [ud.xpts(1) ud.xpts(1)], ...
    'YData', [ud.ypts(1) ud.ypts(1)]);
ud.glspoint{2} = line(ud.glspoint_default, ...
    'XData', [ud.xpts(2) ud.xpts(2)], ...
    'YData', [ud.ypts(2) ud.ypts(2)]);

%Show original image
axes(ud.img1)
imshow(img);
title('Original Image');

%Create check mark buttons and pull down menus
ud.update = uicontrol(...
    'Style', 'Checkbox', ...
    'Position', [425 25 15 15]);
uicontrol(...
    'Style', 'text', ...
    'String', 'Continuous Update', ...
    'BackgroundColor', get(GLSDemoFig, 'Color'), ...
    'Position', [300 10 100 30], ...
    'HorizontalAlignment', 'left');

%Save data to UserData
ud.img = img;
set(GLSDemoFig,'UserData', ud, ...
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
        ud.glspoint{length(ud.glspoint)+1} = line( ...
            ud.glspoint_default, ...
            'XData', [pt(1) pt(1)], ...
            'YData', [pt(2) pt(2)]);
        
    case 1  %User clicked on a point
        for i = 1:size(ud.xpts,2)
            norms(i) = norm([ud.xpts(i) ud.ypts(i)] - pt);
        end
        my_pt =  find(norms == min(norms));
        set(gcf,'WindowButtonMotionFcn', ...
            ['glsdemo(''Motion'',' num2str(my_pt) ')'], ...
            'WindowButtonUpFcn', ...
            ['glsdemo(''ButtonUp'',' num2str(my_pt) ')']);
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
newpt = get(ud.slice,'CurrentPoint');
newpt = newpt(1,1:2);
if pt ~= 1 && pt ~= 2 && ...
        ~isempty(ud.ButtonDownpt) && ...
        norm(ud.ButtonDownpt - newpt) < 0.01
    %Delete this point
    %To delete a point, we must completly redraw the graph
    ud.xpts(pt) = [];
    ud.ypts(pt) = [];
    cla(ud.slice);
    ud.glsline = line( ...
        'Parent', ud.slice, ...
        'LineWidth', 2, ...
        'ButtonDownFcn', 'glsdemo(''MyButtonDownFcn'',0)');
    ud.glspoint = [];
    for i = 1:length(ud.xpts)
        ud.glspoint{i} = line(ud.glspoint_default, ...
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
newpt = get(ud.slice,'CurrentPoint');
newpt = newpt(1,1:2);

%set [pt] to this new point only if within limits
if pt ~= 1 && pt ~= 2 && ...
        isempty(find(ud.xpts == newpt(1)))
    %only allow vertical movement for first and last points
    if newpt(1) < 0
        ud.xpts(pt) = 0.0001;
    elseif newpt(1) > 255
        ud.xpts(pt) = 254.9999;
    else
        ud.xpts(pt) = newpt(1);
    end
end

if newpt(2) < 0
    %very close to zero, but not zero because histeq needs non-zero values
    ud.ypts(pt) = 0.0001;
elseif newpt(2) > 255
    ud.ypts(pt) = 255;
else
    ud.ypts(pt) = newpt(2);
end

%Update location of point on axes

set(ud.glspoint{pt}, ...
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
xi = 0:255;
yi = interp1(ud.xpts,ud.ypts,xi,'linear');
too_high = find(yi > 255);
too_low = find(yi < 0);
yi(too_high) = 255;
yi(too_low) = 0;
%Plot new data
set(ud.glsline, ...
    'XData', xi, ...
    'YData', yi);
return



%%%
%%% Sub-Function update_img
%%%

function update_img(yi)

ud = get(gcf,'UserData');

new_img = uint8(yi(ud.img + 1));

%Show initial image matched  
axes(ud.img2)
imshow(new_img);
set(gcf,'NextPlot','add')
set(ud.img2, ...
    'Tag', 'img2');
title('Adjusted Image');

set(gcf,'UserData',ud);
return