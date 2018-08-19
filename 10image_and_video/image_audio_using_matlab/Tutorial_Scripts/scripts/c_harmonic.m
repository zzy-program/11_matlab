function y = c_harmonic(x,r)

num = sum(power(x(:), r + 1));  %calculate numerator
den = sum(power(x(:), r));      %calculate denominator

y = num / den;             