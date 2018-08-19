% Copyright 2011 O. Marques
% Practical Image and Video Processing Using MATLAB, Wiley-IEEE, 2011.
% Revision: 1.0 Date: 2011/08/17 12:19:00

%% Plot feature space
axisvec = 1.2*[0,1,-1,1];
xticks  = axisvec(1):(axisvec(2)-axisvec(1))/6:axisvec(2);
yticks  = axisvec(3):(axisvec(4)-axisvec(3))/6:axisvec(4);

% options for plotting function pboundary
plotopt.gridx = 500;
plotopt.gridy = 500;
plotopt.line_style = 'k-';
plotopt.fill = 0;
fid = figure(1); clf

neighbours = 1; % temporary 
dataname = 'ocr_demo'; % temporary 

figure(fid);  clf
ppatterns( trn_data_binary ); % display the data
axis(axisvec);  axis square;  grid on
set( gca, 'XTick',xticks, 'YTick',yticks, 'Box','on' )
%   pboundary( model, plotopt );  % display the separating hypersurface
title(sprintf('%d-nearest neighbour classifier',neighbours));
%   % print('-depsc',sprintf('%s_%dnn_class.eps',dataname,neighbours));
exportfig(gcf,[out_dir,sprintf('%s_%dnn_class.eps',dataname,neighbours)])
%   