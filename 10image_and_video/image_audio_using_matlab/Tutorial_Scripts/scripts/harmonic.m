function y = harmonic(x)

bad = find(x == 0);         %filter out zeros
newx = x;
newx(bad) = [];             %newx is x without zeros
newx_adj = 1 ./ newx;       %1 / newx
mysum = sum(newx_adj(:));   %sum of all values

y = prod(size(x)) / mysum;