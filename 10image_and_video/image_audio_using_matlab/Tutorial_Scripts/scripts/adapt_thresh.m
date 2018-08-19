function y = adapt_thresh(x)
y = im2bw(x,graythresh(x));