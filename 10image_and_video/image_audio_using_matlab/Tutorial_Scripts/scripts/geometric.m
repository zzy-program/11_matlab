function y = geometric(x)

bad = find(x == 0);         %filter out zeros
newx = x;
newx(bad) = [];             %newx is x without zeros

newx = power(newx, (1 / prod(size(x))));

y = prod(newx(:));