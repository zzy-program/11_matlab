function n = hex2int8(h)
%HEX_TO_INT8 Convert hexadecimal string to int8 number.
%
%   HEX_TO_INT8(H) converts each 1-by-2 sub-array in H into a int8 number.
%
%   If H is a character array, each element in H must be a character in the set
%   '0123456789abcdefABCDEF'.  If H is a numerical array, each value in H must
%   be an integer N, 0 <= N <= 15.
%
%   For example
%
%      hex_to_int8(['80'
%                   '81'
%                   'fe'
%                   'ff'
%                   '00'
%                   '01'
%                   '7e'
%                   '7f'])
%
%   returns
%
%      [-128
%       -127
%         -2
%         -1
%          0
%          1
%        126
%        127]

%   Author:      Peter John Acklam
%   Time-stamp:  2004-04-10 22:09:25 +0200
%   E-mail:      pjacklam@online.no
%   URL:         http://home.online.no/~pjacklam

   % Check number of input arguments.
   error(nargchk(1, 1, nargin));

   % Check size of input array.
   hs = size(h);
   if rem(hs(2), 2)
      error('Number of columns must be a multiple of two.');
   end

   % Make sure input is hexadecimal or give an error.
   if ischar(h)
      if any(   ( (h(:) < '0') | ('9' < h(:)) ) ...
              & ( (h(:) < 'A') | ('F' < h(:)) ) ...
              & ( (h(:) < 'a') | ('f' < h(:)) ) );
         error('Invalid hexadecimal string.');
      end
      h = reshape(sscanf(h, '%1x'), hs);
   elseif isnumeric(h)
      if any((h(:) < 0) | (h(:) > 15))
         error('Invalid hexadecimal numbers.');
      end
      % Trick to find non-integers without "fix".
      if any(feval(class(h), uint8(h(:))) ~= h(:))
         error('Invalid hexadecimal numbers.');
      end
   end

   % Compute size of output array.
   ns = hs;
   ns(2) = ns(2) / 2;

   % Work on a 2D array; we'll reshape later.
   h = uint8(h);
   t = h(:,1:2:end);
   t = bitor(bitshift(t, 4), h(:,2:2:end));

   % Map [2^7, 2^8-1] -> [-2^7, -1].
   i = h(:,1:2:end) >= 8;
   n = int8(t);
   n(i) = double(t(i)) - 256;

   % Reshape to correct size.
   n = reshape(n, ns);
