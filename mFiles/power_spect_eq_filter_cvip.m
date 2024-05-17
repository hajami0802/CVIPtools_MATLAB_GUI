function Y = power_spect_eq_filter_cvip(d,h,cutoff,limitGain,noiseImage,originalImage)
% POWER_SPECT_EQ_FILTER_CVIP - Performs power spectrum equalization frequency domain restoration filter.
%
% Syntax :
% ------
%  Y = power_spect_eq_filter_cvip(d,h,cutoff,limitGain,noiseImage,originalImage)
%  
% Input Parameters include :
% ------------------------
%   'd'             The degraded image. A single or multiband image.
%                                  
%   'h'             The degradation function. It can be single band.
%
%   'cutoff'        Cutoff frequency for filtering.
% 
%   'limitGain'     Sets the maximum gain using the DC value as a baseline.
%                   limitGain=1 --> DC value is the maximum gain.
%                   limitGain>1 --> DC_value*limitGain is the maximum gain.
% 
%   'noiseImage'    The noise image. It can be single band.
% 
%   'originalImage' The original image. A single or multiband image. The
%                   number of bands should match with the input 'd'.
% 
% Output Parameter include :
% ------------------------
% 
%  'Y'        Output Image.
%
%
% Example :
% -------
%             origImage = imread('cam.bmp');  % input Image
%             degradIm = imread('cam_noise.bmp'); % degraded image
%             noiseIm = imread('cam_noise.bmp');  % noise image
%             cutoff =32;
%             limitGain = 10;
%             h = [ 2.250 4.500 2.250 ;4.500 9.001 4.500 ; 2.250 4.500 2.250];   % degradation function.
%             figure;imshow(origImage);title('Input Image');
%             y= power_spect_eq_filter_cvip(degradIm,h,cutoff,limitGain,noiseIm,origImage);
%             figure;imshow(remap_cvip(y));title('Output Image');	
%
% Reference
% ---------
% 1. Scott E Umbaugh. DIGITAL IMAGE PROCESSING AND ANALYSIS: Applications with MATLAB and CVIPtools, 3rd Edition.

%==========================================================================
%
%           Author:                 Mehrdad Alvandipour
%           Initial coding date:    10/13/2016
%           Latest update date:     10/19/2016
%           Credit:                 Scott Umbaugh 
%                                   CVIP Lab, SIUE
%           Copyright (C) 2016 Scott Umbaugh and SIUE
%
%==========================================================================
 alpha = .5;
 gamma = 1;

[m , n, o] = size(d);


if o>size(h,3)
    h = repmat(h,[1 1 o]);
end

[~,~,noiseImageSize] = size(noiseImage);
if o>noiseImageSize
    noiseImage = repmat(noiseImage,[1 1 o]);
end



D = fft2(d,m,n);

%%%%%%%%%%%%%%%%%%%%%%%% Create R(u,v) %%%%%%%%%%%%%%%%%%%%%%%%%
H = fft2(h,m,n);    % change the size
Hstar = conj(H);
Hpower = Hstar.*H;

Im = fft2(originalImage,m,n);  %original image
N = fft2(noiseImage,m,n);    %noise

Sn = conj(N).*N;
SIm = conj(Im).*Im;

Rgm = ( (Hstar./Hpower).^(alpha) ).* ( (Hstar./(Hpower + (gamma* ( Sn./SIm)) ) ).^(1-alpha) );

% a = Rgm > 100*Rgm(1,1); % Limit gain of R to a multiple of
% Rgm(a) = 100*Rgm(1,1);  % the DC gain

%%%%%%%%%%%%%%%%%%%%% Limit gain of R to a multiple of the DC gain
M = Rgm;
for i=1:o
    bitPlane = Rgm(:,:,i);
    a = bitPlane > limitGain*bitPlane(1,1); 
    bitPlane(a) = limitGain*bitPlane(1,1);
    M(:,:,i) = bitPlane;
end
Rgm = M;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Ihat = Rgm.*D;          % Apply R(u,v)

Ihat = myFilter2(Ihat,cutoff);  %low pass filter

Y = real(ifft2(Ihat));

end

function Y = myFilter2(X, cutoff)
    [m , n, o] = size(X);
    Y = zeros(m,n,o);
    [U, V] = dftuv(m, n);

    % Compute the distances D(U, V).
    D = sqrt(U.^2 + V.^2);

    H = double(D <=cutoff);
    for i=1:o
        Y(:,:,i) = H.*X(:,:,i);
    end
    
end

function [U, V] = dftuv(M, N)
%DFTUV Computes meshgrid frequency matrices.
%   [U, V] = DFTUV(M, N) computes meshgrid frequency matrices U and
%   V. U and V are useful for computing frequency-domain filter 
%   functions that can be used with DFTFILT.  U and V are both M-by-N.

% Set up range of variables.
u = 0:(M-1);
v = 0:(N-1);

% Compute the indices for use in meshgrid
idx = find(u > M/2);
u(idx) = u(idx) - M;
idy = find(v > N/2);
v(idy) = v(idy) - N;

% Compute the meshgrid arrays
[V, U] = meshgrid(v, u);
end