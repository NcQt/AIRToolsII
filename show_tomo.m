function [] = show_tomo(A,idx,timedelay)
%SHOW_TOMO  Illustrate tomographic test problems from matrix
%
% show_tomo(A)
% show_tomo(A,idx)
% show_tomo(A,idx,timedelay)
%
% Illustrates a tomographic test problem represented using a matrix or a
% function A as generated by the AIR Tools test problem functions. Each
% row of A is reshaped into a square image and displayed. If a second input
% idx is given, it specifies which rows to use; if not specified or empty,
% by default all rows will be used. If a third input timedelay is given, it
% specifies the time (in secs) to wait between display of rows; default is
% 0.1 second.

% Jakob Sauer Jorgensen, 2017, DTU Compute.

% Check if A is matrix or function.
is_matrix = isnumeric(A);

% Default rows to display.
if nargin < 2 || isempty(idx)
    if is_matrix
        idx = 1:size(A,1);
    else
        idx = A([],'size');
        idx = 1:idx(1);
    end
end

% Default time to wait between display of rows.
if nargin < 3 || isempty(timedelay)
    timedelay = 0.1;
end

% If A is matrix, use a fixed color range from the minimum and maximum
% values of A. If A is a function, set an initial range, and update with
% min and max as stepping through rows.
if is_matrix
    ca = full([min(A(:)),max(A(:))]);
else
    ca = [0,eps];
end

% Get the size of the matrix.
if is_matrix
    M = size(A,1);
    N = sqrt(size(A,2));
else
    MN = A([],'size');
    M = MN(1);
    N = sqrt(MN(2));
end

% Initialize figure using empty image.
h = imagesc(zeros(N,N));
axis image off
colorbar
caxis(ca)

% Loop over specified rows, extract, reshape and update existing image
% object with new image data (for efficiency over creating new image),
% pause by specified time. 
if is_matrix
    for k = idx
        set(h,'CData',reshape(A(k,:),N,N))
        title(sprintf('Row %d of %d',k,M));
        pause(timedelay)
    end
else
    for k = idx
        e = zeros(M,1);
        e(k) = 1;
        ray = A(e,'transp');
        ca = [min([ca(1);ray]),max([ca(2);ray])];
        set(h,'CData',reshape(ray,N,N));
        title(sprintf('Row %d of %d',k,M));
        caxis(ca);
        pause(timedelay)
    end
end