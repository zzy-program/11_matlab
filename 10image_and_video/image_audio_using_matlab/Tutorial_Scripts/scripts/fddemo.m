function fddemo(action, value)
%FDDEMO Frequency Domain Demo
%   This demo allows you to interactively filter images in the frequency
%   domain using Ideal, Gaussian, and Butterworth low and high pass
%   filters.  It provides a method to easily see the effects of the filter
%   parameters, and to compare their effectiveness.  The demo will load
%   default with the eight.tif image.
%
%FDDEMO(img)
%   You can also specify your own image using the syntax fddemo('<your
%   image file name>').  Color images will be converted to monochrome.
%
%The parameters of each filter can be modified either by adjusting values,
%or interactively chaning them on the actual filter.  A description of each
%filter's interface is described below.
%
%   Ideal Low Pass &        To adjust the cutoff value of the filter, 
%   Ideal High Pass         simply click and drag the magenta circle 
%                           displayed on the filter profile.  The circle 
%                           represents the cutoff value.
%
%   Gaussian Low Pass &     To adjust the standard deviation of the filter,
%   Gaussian High Pass      enter a value in the "Standard Deviation" text 
%                           box, and click "Update" to apply the new value.
%
%   Butterworth Low Pass &  To adjust the cutoff value of the filter,
%   Butterworth High Pass   simply click and drag the magenta circle
%                           displayed on the filter profile.  The circle
%                           represents the cutoff value.  To adjust the
%                           order of the filter, enter a value in the
%                           "Order" text box, and click "Update" to apply
%                           the new value.

%Sub-function Descriptions
%
%   Initialize              Initializes the figure and sets all default
%                           values.
%
%   generate_filter         Generates the filter based on current values,
%                           and displays the new filter in the Filter
%                           Profile axes.
%
%   MyButtonDownFcn         Is called when the user clicks and drags a
%                           cutoff value circle.  This only applys to those
%                           filters which have cutoff values.
%
%   Motion                  This function is active after the
%                           MyButtonDownFcn is called - after the user
%                           clicks and drags a cutoff value circle.  It is
%                           called ever time the user moves the mouse with
%                           the button down on the axis.
%
%   ButtonUp                Is called when the mouse is released.
%
%   Update                  Display new DFT image, and new filtered image
%                           based on the filter generated from the
%                           generate_filter function.
%
%   Change_Param            This function is called when parameters (other
%                           than cutoff value) is changed, and the "Update"
%                           button is pressed.

%Modifications
%
%   Oct 31, 2005            Added High-frequency emphasis filtering
%                           checkbox to allow user to switch on/off HFE 
%                           filtering

%   Copyright 2011 O. Marques
%   Practical Image and Video Processing Using MATLAB, Wiley-IEEE, 2011.
%   $Revision: 1.0 Date: 2011/09/06 16:02:00 

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
            MyButtonDownFcn;
        case 'Motion'
            Motion;
        case 'ButtonUp'
            ButtonUp;
        case 'Update'
            Update;
        case 'FiltSelect'
            generate_filter;
            Update;
        case 'Change_Param'
            Change_Param;
            generate_filter;
            Update;
    end
end;

return;



%%%
%%%  Sub-Function Initialize()
%%%

function Initialize(imgname)
% imgname: User specified image name

%If demo is already running, close it
h = findobj(allchild(0), 'tag', 'FDDemoFig');
if ~isempty(h)
   close(h(1))
end

if nargin<1
    %Load with default image
    img = im2double(imread('eight.tif'));
else
    %Try to load user specified image
    try
        img = im2double(imread(imgname));
    catch
        disp 'Bad image filename'
        return
    end
    %Make sure image is monochrome or indexed
    if ndims(img) ~= 2
        img = im2double(rgb2gray(img));
        disp 'Image was converted to monochrome'
    end
end

%Create figure, but keep visibility off until it is complete
FDDemoFig = figure( ...
    'Name', 'Frequency Domain Demo', ...
    'NumberTitle', 'Off', ...
    'Resize', 'Off', ...
    'Tag', 'FDDemoFig', ...
    'Toolbar', 'None', ...
    'Units', 'Pixels', ...
    'Visible', 'Off');

%Calculate new position for figure
curpos = get(FDDemoFig,'Position');
screen = get(0,'ScreenSize');
new_height = 525;
new_width = 725;
new_left = (screen(3) / 2) - (new_width / 2);
new_bottom = (screen(4) / 2) - (new_height / 2);
set(FDDemoFig, ...
    'Position', [new_left new_bottom new_width new_height]);

%Create input image axis
ud.img_in = axes( ...
    'Units', 'Pixels', ...
    'Position', [25 275 200 200]);
 
ud.freq_in = axes( ...
    'Units', 'Pixels', ...
    'Position', [25 25 200 200]);

%Create output image axis
ud.img_out = axes( ...
    'Units', 'Pixels', ...
    'Position', [500 275 200 200]);
 
ud.freq_out = axes( ...
    'Units', 'Pixels', ...
    'Position', [500 25 200 200]);
 
%Create filter profile axis
ud.profile = axes( ...
    'Units', 'Pixels', ...
    'Position', [265 25 200 200], ...
    'Xlim', [0 255], ...
    'Ylim', [0 255], ...
    'Drawmode', 'fast', ...
    'GridLineStyle',':');
title('Filter Profile');
ud.profile_txt = uicontrol(...
    'Style', 'Text', ...
    'String', 'profile_txt', ...
    'BackgroundColor', get(FDDemoFig, 'Color'), ...
    'Position', [265 0 200 20], ...
    'HorizontalAlignment', 'center');


%Load image and its DFT
axes(ud.img_in)
imshow(img);
title('Original Image');

ud.dft = fft2(img);
axes(ud.freq_in)
imshow(log(1 + abs(fftshift(ud.dft))),[]);
title('Original DFT');

%Create check mark buttons and pull down menus
%filter selection
uicontrol(...
    'Style', 'text', ...
    'String', 'Filter', ...
    'BackgroundColor', get(FDDemoFig, 'Color'), ...
    'Position', [265 470 125 20], ...
    'HorizontalAlignment', 'left');
filtermenu = {['Ideal Low Pass'], ...
    ['Gaussian Low Pass'], ...
    ['Butterworth Low Pass'], ...
    ['Ideal High Pass'], ...
    ['Gaussian High Pass'], ...
    ['Butterworth High Pass']};
ud.filter = uicontrol(...
    'Style', 'popupmenu', ...
    'String', filtermenu, ...
    'Position', [265 455 145 20], ...
    'Callback', 'fddemo(''FiltSelect'',0)');

%text input for gaussian and butterworth
ud.param_txt = uicontrol(...
    'Style', 'text', ...
    'String', 'Standard Deviation', ...
    'BackgroundColor', get(FDDemoFig, 'Color'), ...
    'Position', [265 420 125 20], ...
    'HorizontalAlignment', 'left', ...
    'Visible', 'off');
ud.param = uicontrol(...
    'Style', 'edit', ...
    'Position', [265 405 50 20], ...
    'HorizontalAlignment', 'left', ...
    'Visible', 'off');
ud.param_update = uicontrol(...
    'Style', 'pushbutton', ...
    'String', 'Update', ...
    'Position', [320 405 100 20], ...
    'Visible', 'off', ...
    'Callback', 'fddemo(''Change_Param'',0)');

%HFEF check mark
ud.hfef_txt = uicontrol(...
    'Style', 'text', ...
    'String', 'High-frequency Emphasis Filtering', ...
    'BackgroundColor', get(FDDemoFig, 'Color'), ...
    'Position', [285 370 175 20], ...
    'HorizontalAlignment', 'left', ...
    'Visible', 'off');
ud.hfef = uicontrol(...
    'Style', 'checkbox', ...
    'Value', 1, ...
    'BackgroundColor', get(FDDemoFig, 'Color'), ...
    'Position', [265 376 15 15], ...
    'Callback', 'fddemo(''Change_Param'',0)', ...
    'Visible', 'off');

%Set initial filter and parameters
ud.cutoff_iLow = 40;    %Ideal low pass default cutoff
ud.cutoff_bLow = 40;    %Butterworth low pass default cutoff
ud.cutoff_iHigh = 40;   %Ideal high pass default cutoff
ud.cutoff_bHigh = 40;   %Butterworth high pass default cutoff
ud.std_l = 30;          %Gaussian low pass default std
ud.std_h = 30;          %Gaussian high pass default std
ud.order_l = 2;         %Butterworth low pass default order
ud.order_h = 2;         %Butterworth high pass default order

%Save data to UserData
ud.img = img;

axes(ud.profile);
ud.cutoff_pt = line( ...
    'LineStyle', 'none', ...
    'MarkerFaceColor', 'g', ...
    'Marker', 'o', ...
    'XData', [40 40], ...
    'YData', [40 40]);

%save userdata
set(FDDemoFig,'UserData', ud);

%display filter profile
generate_filter;
%display filtered image
Update;
set(FDDemoFig, 'Visible', 'On');



%%%
%%% Sub-Function generate_filter
%%%

function generate_filter

ud = get(gcf,'UserData');

%display options if needed
switch get(ud.filter, 'Value')
    case 2 %Gaussian Low Pass
        set(ud.param_txt, ...
            'String', 'Standard Deviation', ...
            'Visible', 'on');
        set(ud.param, ...
            'String', num2str(ud.std_l), ...
            'Visible', 'on');
        set(ud.param_update, ...
            'Visible', 'on');
    case 3 %Butterworth Low Pass
        set(ud.param_txt, ...
            'String', 'Order', ...
            'Visible', 'on');
        set(ud.param, ...
            'String', num2str(ud.order_l), ...
            'Visible', 'on');
        set(ud.param_update, ...
            'Visible', 'on');
    case 4 %Ideal High Pass
        set(ud.hfef_txt,...
            'Visible', 'on');
        set(ud.hfef, ...
            'Visible', 'on');
        set(ud.param_txt, 'Visible', 'off');
        set(ud.param, 'Visible', 'off');
        set(ud.param_update, 'Visible', 'off');
    case 5 %Gaussian High Pass
        set(ud.param_txt, ...
            'String', 'Standard Deviation', ...
            'Visible', 'on');
        set(ud.param, ...
            'String', num2str(ud.std_h), ...
            'Visible', 'on');
        set(ud.param_update, ...
            'Visible', 'on');  
        set(ud.hfef_txt,...
            'Visible', 'on');
        set(ud.hfef, ...
            'Visible', 'on');
    case 6 %Butterworth High Pass
        set(ud.param_txt, ...
            'String', 'Order', ...
            'Visible', 'on');
        set(ud.param, ...
            'String', num2str(ud.order_h), ...
            'Visible', 'on');
        set(ud.param_update, ...
            'Visible', 'on');
        set(ud.hfef_txt,...
            'Visible', 'on');
        set(ud.hfef, ...
            'Visible', 'on');
    otherwise
        set(ud.param_txt, 'Visible', 'off');
        set(ud.param, 'Visible', 'off');
        set(ud.param_update, 'Visible', 'off');
        set(ud.hfef_txt, 'Visible', 'off');
        set(ud.hfef, 'Visible', 'off');
end

[M, N] = size(ud.img);
%get distance matrix
dist = distmatrix(M, N);
a = 1;  %High-frequency emphasis filtering values a and b
b = 1;
switch get(ud.filter, 'Value')
    case 1 %Ideal Low Pass
        %calculate filter
        H = zeros(M, N);
        ind = dist <= ud.cutoff_iLow;
        H(ind) = 1;
        Hd = double(H);
    case 2 %Gaussian Low Pass
        H = zeros(M, N);
        ud.std_l = str2num(get(ud.param, 'String'));
        Hd = double(exp(-(dist .^ 2) / (2 * ud.std_l ^ 2)));
    case 3 %Butterworth Low Pass
        H = zeros(M, N);
        Hd = 1 ./ (1 + (dist ./ ud.cutoff_bLow) .^ (2 * ud.order_l));
    case 4 %Ideal High Pass
        H = ones(M, N);
        ind = dist <= ud.cutoff_iHigh;
        H(ind) = 0;
        if get(ud.hfef, 'Value') == 1
            Hd = double(a + (b .* H));
        else
            Hd = double(H);
        end
    case 5 %Gaussian High Pass
        H = ones(M, N);
        H = 1 - exp(-(dist .^ 2) / (2 * (ud.std_h ^ 2)));
        if get(ud.hfef, 'Value') == 1
            Hd = double(a + (b .* H));
        else
            Hd = double(H);
        end
    case 6 %Butterworth High Pass
        H = ones(M, N);
        warning off MATLAB:divideByZero 
        H = 1 ./ (1 + (ud.cutoff_bHigh ./ dist) .^ (2 * ud.order_h));
        %High frequency emphasis filtering
        if get(ud.hfef, 'Value') == 1
            Hd = double(a + (b .* H));
        else
            Hd = double(H);
        end
end

%save filter to userdata
ud.myfilter = Hd;

%plot filter
axes(ud.profile);
imshow(fftshift(Hd),[]), title('Filter Profile');

%Show cutoff circle
if ismember(get(ud.filter, 'Value'),[1 3 4 6])
    t = 0: 0.05 : 2 * pi;
    switch get(ud.filter, 'Value')
        case 1 %Ideal Low Pass
            xdata = ud.cutoff_iLow * cos(t) + (size(dist,2)/2 +1);
            ydata = ud.cutoff_iLow * sin(t) + (size(dist,1)/2 +1);
            set(ud.profile_txt, 'String', ['Cutoff Radius: ', ...
                num2str(round(ud.cutoff_iLow))]);
        case 3 %Butterworth low Pass
            xdata = ud.cutoff_bLow * cos(t) + (size(dist,2)/2 +1);
            ydata = ud.cutoff_bLow * sin(t) + (size(dist,1)/2 +1);
            set(ud.profile_txt, 'String', ['Cutoff Radius: ', ...
                num2str(round(ud.cutoff_bLow))]);
        case 4 %Ideal High Pass
            xdata = ud.cutoff_iHigh * cos(t) + (size(dist,2)/2 +1);
            ydata = ud.cutoff_iHigh * sin(t) + (size(dist,1)/2 +1);
            set(ud.profile_txt, 'String', ['Cutoff Radius: ', ...
                num2str(round(ud.cutoff_iHigh))]);
        case 6 %Butterworth High Pass
            xdata = ud.cutoff_bHigh * cos(t) + (size(dist,2)/2 +1);
            ydata = ud.cutoff_bHigh * sin(t) + (size(dist,1)/2 +1);
            set(ud.profile_txt, 'String', ['Cutoff Radius: ', ...
                num2str(round(ud.cutoff_bHigh))]);
    end
    line( ...
        xdata, ydata, ...
        'Color','m', ...
        'LineWidth',2, ...
        'LineStyle','-', ...
        'ButtonDownFcn', 'fddemo(''MyButtonDownFcn'',0)');    
else
    set(ud.profile_txt, 'String', '');
end

set(gcf,'UserData',ud); 





%%%
%%% Sub-Function MyButtonDownFcn
%%%

function MyButtonDownFcn

set(gcf, ...
    'WindowButtonMotionFcn', 'fddemo(''Motion'',0)', ...
    'WindowButtonUpFcn', 'fddemo(''ButtonUp'',0)');
setptr(gcf, 'fleur');




%%%
%%% Sub-Function Motion
%%%

function Motion

ud = get(gcf, 'UserData');
xcenter = size(ud.img,2) / 2;
ycenter = size(ud.img,1) / 2;
curpt = get(ud.profile, 'CurrentPoint');
xcur = curpt(1);
ycur = curpt(3);

%determine new radius
xdif = abs(xcenter - xcur);
ydif = abs(ycenter - ycur);
mydist = sqrt(xdif ^ 2 + ydif ^ 2);
if mydist > max([xcenter ycenter]);
    mydist = max([xcenter ycenter]);
end
%save new cutoff value
switch get(ud.filter, 'Value')
    case 1 %Ideal Low Pass
        ud.cutoff_iLow = mydist;
    case 3 %Butterworth Low Pass
        ud.cutoff_bLow = mydist;
    case 4 %Ideal High Pass
        ud.cutoff_iHigh = mydist;
    case 6 %Butterworth High Pass
        ud.cutoff_bHigh = mydist;
end
set(gcf,'UserData', ud);
%display new filter profile
generate_filter;




%%%
%%% Sub-Function ButtonUp
%%%

function ButtonUp

set(gcf, ...
    'WindowButtonMotionFcn', '');
setptr(gcf, 'arrow');
Update;




%%%
%%% Sub-Function Update
%%%

function Update

ud = get(gcf, 'UserData');
%calculate new DFT image
new_dft = ud.dft .* ud.myfilter;
new_img = real(ifft2(new_dft));
%display new image
axes(ud.img_out);
imshow(new_img);
title('Filtered Image');
%display new dft
axes(ud.freq_out);
imshow(log(1 + abs(fftshift(new_dft))),[]);
title('Filtered DFT');




%%%
%%% Sub-Function Change_Param
%%%

function Change_Param

ud = get(gcf, 'UserData');
switch get(ud.filter, 'Value')
    case 2 %Gaussian Low Pass
        ud.std_l = str2num(get(ud.param, 'String'));
    case 3 %Butterworth Low Pass
        ud.order_l = str2num(get(ud.param, 'String'));
    case 5 %Gaussian High Pass
        ud.std_h = str2num(get(ud.param, 'String'));
    case 6 %Butterworth High Pass
        ud.order_h = str2num(get(ud.param, 'String'));
end
set(gcf, 'UserData', ud);