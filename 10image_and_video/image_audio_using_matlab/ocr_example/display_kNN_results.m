function display_kNN_results (labels,data4class,out_dir,method)
datadesc = 'test set';
[error_rate,idx_error,match_table] = class_results(labels,data4class,datadesc);
fh = figure;
show_missclassified_images = 0; 
% change to 1 if you want to see the wrongly classified patterns

fh_last = visualise_results(idx_error,match_table,data4class,datadesc,fh,...
    show_missclassified_images);
exportfig(fh_last,[out_dir, sprintf('ocr_results_%s',method)]);