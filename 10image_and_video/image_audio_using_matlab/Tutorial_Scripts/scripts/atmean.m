function y = atmean(x,d)

x_sort = sort(x(:));        %sort values, store in x_sort

low_lim = (d / 2) + 1;      %set index of limits to be used
hi_lim = prod(size(x)) - (d / 2);

newx = x_sort(low_lim:hi_lim);  %extract values within limit indicies
y = mean(newx(:));              %return average of those values