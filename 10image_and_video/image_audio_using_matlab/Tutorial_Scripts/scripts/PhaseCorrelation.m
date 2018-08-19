temp=size(frame);
dimy=temp(1);   %height of frame
dimx=temp(2);   %width of frame

blockx=16;      %block sizes
blocky=16;

%intialize mvf matrix
matchy=zeros(dimy/blocky,dimx/blockx);
matchx=zeros(dimy/blocky,dimx/blockx);
halfy=zeros(dimy/blocky,dimx/blockx);
halfx=zeros(dimy/blocky,dimx/blockx);

%window the FFT area
T=32;
winv=1:T;
alpha=0;
window=sinc((winv-T/2-1)/T)...
       .*cos(alpha*pi*(winv-T/2-1)/T)...
       ./(1-(2*alpha*(winv-T/2-1)/T).^2);
%plot(window);
window=window.'*window;

tic;
for loopi=2:dimy/blocky-1,
	%loopi
	for loopj=2:dimx/blockx-1,
		ybound1=(loopi-1)*blocky+1;
                ybound2=loopi*blocky;
                xbound1=(loopj-1)*blockx+1;
                xbound2=loopj*blockx;

                %divide frame2 into blocks
		%32x32 size for frames used to calculate correlation phase
 
		previous=frame(ybound1-8:ybound2+8,xbound1-8:xbound2+8,1);
                block...
		=frame(ybound1-8:ybound2+8,xbound1-8:xbound2+8,2); %current block
		B_prev=fft2(previous,blocky*2,blockx*2);
		B_curr=fft2(block.*window,blocky*2,blockx*2);
		mul=B_curr.*conj(B_prev);
		mag=abs(mul);
		mag(mag==0)=1e-31;
		C=mul./mag;
		c=fftshift(abs(ifft2(C)));

		[tempy tempx]=find(c==max(max(c)));
                matchy(loopi,loopj)=tempy(1)-blocky-1;
                matchx(loopi,loopj)=tempx(1)-blockx-1;
	
		%half-pixel ME using cubic spline method

		if (tempy(1)-1>=1&tempy(1)+1<=32)	
		tt=-1:1;
		ppy=[c(tempy(1)-1,tempx(1)) ...
			c(tempy(1),tempx(1)) ...
			c(tempy(1)+1,tempx(1))];
		ii=-1:.5:1;
		iiy=interp1(tt,ppy,ii,'spline');
		if iiy(2)>c(tempy(1),tempx(1))
			halfy(loopi,loopj)=-1;
		elseif iiy(4)>c(tempy(1),tempx(1))
			halfy(loopi,loopj)=1;
		end
		end

		if (tempx(1)-1>=1&tempx(1)+1<=32)
		tt=-1:1;
                ppx=[c(tempy(1),tempx(1)-1) ...
                        c(tempy(1),tempx(1)) ...
                        c(tempy(1),tempx(1)+1)];
                ii=-1:.5:1;
                iix=interp1(tt,ppx,ii,'spline');
                if iix(2)>c(tempy(1),tempx(1))
                        halfx(loopi,loopj)=-1;
                elseif iix(4)>c(tempy(1),tempx(1))
                        halfx(loopi,loopj)=1;
		end
		end
	end
end	

time_log=toc;

figure(6);
quiver(matchx,matchy);
axis ij;axis image;
title('Motion Vector Field, Phase Correlation');

%MC prediction
predict=zeros(dimy,dimx);

for loopi=1:dimy/blocky,
        loopi
        for loopj=1:dimx/blockx,

                ybound1=(loopi-1)*blocky+1;
                ybound2=loopi*blocky;
                xbound1=(loopj-1)*blockx+1;
                xbound2=loopj*blockx;

                offy=-matchy(loopi,loopj);
                offx=-matchx(loopi,loopj);
	
		pred=frame(ybound1+offy:ybound2+offy,xbound1+offx:xbound2+offx,1);

		%halp-pixel interpolation (simple linear method)
		if (halfy(loopi,loopj))==1
			average=frame(ybound1+offy-1:ybound2+offy-1,xbound1+offx:xbound2+offx,1);
			pred=.5*(pred+average);
		elseif (halfy(loopi,loopj))==-1
			average=frame(ybound1+offy+1:ybound2+offy+1,xbound1+offx:xbound2+offx,1);
                        pred=.5*(pred+average);
		end

		if (halfx(loopi,loopj))==1
                        average=frame(ybound1+offy:ybound2+offy,xbound1+offx-1:xbound2+offx-1,1);
                        pred=.5*(pred+average);
                elseif (halfx(loopi,loopj))==-1
                        average=frame(ybound1+offy:ybound2+offy,xbound1+offx+1:xbound2+offx+1,1);
                        pred=.5*(pred+average);
                end

		predict(ybound1:ybound2,xbound1:xbound2)=pred;

        end
end

figure(3);
colormap(gray(256));
subplot(2,1,1);
imagesc(frame(blocky+1:dimy-blocky,blockx+1:dimx-blockx,2));
axis image;
title('Current Frame');

%entropy of motion vector fields
matchyy=matchy+.5*halfy;
matchxx=matchx+.5*halfx;

dy=matchyy(2:dimy/blocky-1,2:dimx/blockx-1);
dx=matchxx(2:dimy/blocky-1,2:dimx/blockx-1);
rangey=min(dy(:)):.5:max(dy(:));
rangex=min(dy(:)):.5:max(dy(:));
[county,tmp]=hist(dy(:),rangey);
[countx,tmp]=hist(dx(:),rangex);
proby=county/sum(county);
probx=countx/sum(countx);
proby(proby==0)=1;
probx(probx==0)=1;
H=-sum(proby.*log(proby)/log(2))...
  -sum(probx.*log(probx)/log(2))

%PSNR between the two frames
DFD=abs(frame(:,:,2)-frame(:,:,1));
DFD_ins=DFD(blocky+1:dimy-blocky,blockx+1:dimx-blockx);
psnr1=sum(sum(DFD_ins.^2));
PSNR_frame=10*log10(255*255*(dimy-2*blocky)*(dimx-2*blockx)/psnr1)

DFD=abs(frame(:,:,2)-predict);
%inside part of the error image
DFD_ins=DFD(blocky+1:dimy-blocky,blockx+1:dimx-blockx);
psnr1=sum(sum(DFD_ins.^2));
PSNR_ph=10*log10(255*255*(dimy-2*blocky)*(dimx-2*blockx)/psnr1)

subplot(2,1,2);
imagesc(predict(blocky+1:dimy-blocky,blockx+1:dimx-blockx));
axis image;

str=sprintf('Prediction from Prev Frame and ME\nPhase Correlation Method, PSNR=%5.2fdB',PSNR_ph);
title(str);

time_log

figure(5);
mesh(c);
title('Phase-correlation');
xlabel('X displacement');
ylabel('Y displacement');