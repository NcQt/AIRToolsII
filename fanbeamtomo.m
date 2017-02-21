function [A,b,x,theta,p,R,d] = fanbeamtomo(N,theta,p,R,d,isDisp)
%FANBEAMTOMO Creates a 2D tomography test problem using fan beams
%
%   [A,b,x,theta,p,R,d] = fanbeamtomo(N)
%   [A,b,x,theta,p,R,d] = fanbeamtomo(N,theta)
%   [A,b,x,theta,p,R,d] = fanbeamtomo(N,theta,p)
%   [A,b,x,theta,p,R,d] = fanbeamtomo(N,theta,p,R)
%   [A,b,x,theta,p,R,d] = fanbeamtomo(N,theta,p,R,d)
%   [A,b,x,theta,p,R,d] = fanbeamtomo(N,theta,p,R,d,isDisp)
%
% This function creates a 2D tomography test problem with an N-times-N
% domain, using p rays in fan-formation for each angle in the vector theta.
%
% Input:
%   N           Scalar denoting the number of discretization intervals in 
%               each dimesion, such that the domain consists of N^2 cells.
%   theta       Vector containing the projetion angles in degrees.
%               Default: theta = 0:1:359.
%   p           Number of rays for each angle. Default: p =
%               round(sqrt(2)*N).
%   R           The distance from the source to the center of the domain
%               is R*N. Default: R = 2.
%   d           Scalar that determines the angular span of the rays, in
%               degrees. The default value is defined such that from the
%               source at (0,R*N) the first ray hits the corner (-N/2,N/2)
%               and the last ray hits the corner (N/2,N/2).
%   isDisp      If isDisp is non-zero it specifies the time in seconds 
%               to pause in the display of the rays. If zero (the default), 
%               no display is shown.
%
% Output:
%   A           Coefficient matrix with N^2 columns and nA*p rows, 
%               where nA is the number of angles, i.e., length(theta).
%   b           Vector containing the rhs of the test problem.
%   x           Vector containing the exact solution, with elements
%               between 0 and 1.
%   theta       Vector containing the used angles in degrees.
%   p           The number of used rays for each angle.
%   R           The radius in side lengths. 
%   d           The span of the rays.
%
% See also: paralleltomo, seismictomo.

% Jakob Sauer J�rgensen, Maria Saxild-Hansen and Per Christian Hansen,
% Nov. 5, 2015, DTU Compute.

% Reference: A. C. Kak and M. Slaney, Principles of Computerized
% Tomographic Imaging, SIAM, Philadelphia, 2001.

% Default illustration:
if nargin < 6 || isempty(isDisp)
    isDisp = 0;
end

% Default value of R.
if nargin < 4 || isempty(R)
    R = 2;
end

% Default value of d.
if nargin < 5 || isempty(d)
    % Determine angular span. The first and last rays touch points
    % (-N/2,N/2) and (N/2,N/2), respectively.
    d = 2*atand(1/(2*R-1));
end

% Default value of the number of rays p.
if nargin < 3 || isempty(p)
    p = round(sqrt(2)*N);
end

% Default value of the angles theta.
if nargin < 2 || isempty(theta)
    theta = 0:359;
end

% Input check. The source must lie outside the domain.
if R < sqrt(2)/2
    error('R must be greater than half squareroot 2')
end
R = R*N;

% Make sure theta is double precison to prevent round-off issues caused by
% single input.
theta = double(theta);

% The width of the angle of the source.
if d < 0 || d > 180
    error('The angle of the source must be in the interval [0 180]')
end

% Anonymous function rotation matrix
Omega_x = @(omega_par) [cosd(omega_par) -sind(omega_par)];
Omega_y = @(omega_par) [sind(omega_par)  cosd(omega_par)];

% nA denotes the number of angles.
nA = length(theta);

% The starting values both the x and the y coordinates.
x0 = 0;
y0 = R;
xy0 = [x0;y0];

omega = linspace(-d/2,d/2,p);

% The intersection lines.
x = (-N/2:N/2)';
y = x;

% Initialize vectors that contains the row numbers, the column numbers and
% the values for creating the matrix A effiecently.
rows = zeros(2*N*nA*p,1);
cols = rows;
vals = rows;
idxend = 0;

% Prepare for illustration
if isDisp
    AA = rand(N);
    figure
end

% Loop over the chosen angles of the source.
for i = 1:nA
    
    % The starting points for the current angle theta.
    x0theta = Omega_x(theta(i))*xy0;
    y0theta = Omega_y(theta(i))*xy0;
    
    % The starting (center) direction vector (opposite xytheta) and
    % normalized.
    xytheta = [x0theta; y0theta];
    abtheta = -xytheta/R;
    
    % Illustration of the domain
    if isDisp % illustration of source
        clf
        pause(isDisp)
        imagesc((-N/2+.5):(N/2-0.5),(-N/2+.5):(N/2-0.5),AA), colormap gray,
        axis xy
        hold on
        axis(1.1*R*[-1,1,-1,1])
        axis equal
        plot(x0theta,y0theta,'o','color',[60 179 113]/255,...
            'linewidth',1.5,'markersize',10)
    end
    
    % Loop over the rays.
    for j = 1:p
        
        % The direction vector for the current ray.
        a = Omega_x(omega(j))*abtheta;
        b = Omega_y(omega(j))*abtheta;
        
        % Illustration of rays
        if isDisp
            plot([x0theta,x0theta+1.7*R*a],[y0theta,y0theta+1.7*R*b],'-',...
                'color',[220 0 0]/255,'linewidth',1.5)
            axis(R*[-1,1,-1,1])
        end
        
        % Use the parametrisation of line to get the y-coordinates of
        % intersections with x = constant.
        tx = (x - x0theta)/a;
        yx = b*tx + y0theta;
        
        % Use the parametrisation of line to get the x-coordinates of
        % intersections with y = constant.
        ty = (y - y0theta)/b;
        xy = a*ty + x0theta;
        
        % Collect the intersection times and coordinates.
        t = [tx; ty];
        xxy = [x; xy];
        yxy = [yx; y];
        
        % Sort the coordinates according to intersection time.
        [~,I] = sort(t);
        xxy = xxy(I);
        yxy = yxy(I);
        
        % Skip the points outside the box.
        I = (xxy >= -N/2 & xxy <= N/2 & yxy >= -N/2 & yxy <= N/2);
        xxy = xxy(I);
        yxy = yxy(I);
        
        % Skip double points.
        I = (abs(diff(xxy)) <= 1e-10 & abs(diff(yxy)) <= 1e-10);
        xxy(I) = [];
        yxy(I) = [];
        
        % Illustration of the rays
        if isDisp
            set(gca,'Xticklabel',{})
            set(gca,'Yticklabel',{})
            pause(isDisp)
        end
        
        % Calculate the length within cell and determines the number of
        % cells which is hit.
        avals = sqrt(diff(xxy).^2 + diff(yxy).^2);
        numvals = numel(avals);
        
        % Store the values inside the box.
        if numvals > 0
            
            % Calculates the midpoints of the line within the cells.
            xm = 0.5*(xxy(1:end-1)+xxy(2:end)) + N/2;
            ym = 0.5*(yxy(1:end-1)+yxy(2:end)) + N/2;
            
            % Translate the midpoint coordinates to index.
            col = floor(xm)*N + (N - floor(ym));
            
            % Create the indices to store the values to vector for
            % later creation of A matrix.
            idxstart = idxend + 1;
            idxend = idxstart + numvals - 1;
            idx = idxstart:idxend;
            
            % Store row numbers, column numbers and values.
            rows(idx) = (i-1)*p + j;
            cols(idx) = col;
            vals(idx) = avals;

        end
        
    end
    
end

% Truncate excess zeros.
rows = rows(1:idxend);
cols = cols(1:idxend);
vals = vals(1:idxend);

% Create sparse matrix A from the stored values.
A = sparse(rows,cols,vals,p*nA,N^2);

if nargout > 1
    % Create phantom head as a reshaped vector.
    x = phantomgallery('shepplogan',N);
    % Create rhs.
    b = A*x;
end

if nargout > 5
    R = R/N;
end