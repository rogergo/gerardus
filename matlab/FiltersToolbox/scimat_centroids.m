function centroids = scimat_centroids(scimat, p)
% SCIMAT_CENTROIDS  Compute centroid of segmentation in each slice.
%
% X = scimat_centroids(SCIMAT)
%
%   SCIMAT is the struct with the segmentation (see "help scimat" for
%   details).
%
%   X is a 3-column matrix where each row has the real world coordinates of
%   the centroid of a slice in SCIMAT. Empty slices get a 
%   centroid=[NaN NaN NaN].
%
% X = scimat_centroids(SCIMAT, P)
%
%   P is a scalar that allows to smooth out the centroid positions using
%   cubic spline approximation.
%
%   P is the smoothing parameter in Matlab's function csaps(). When P=0,
%   smoothing is maximum and the result is the least squares straight line
%   fit to the centroids. When P=1, no smoothing is applied (default). If
%   P=[], then Matlab computes a value that it considers optimal for P.

% Author: Ramon Casero <rcasero@gmail.com>
% Copyright © 2010,2014 University of Oxford
% Version: 0.2.1
% 
% University of Oxford means the Chancellor, Masters and Scholars of
% the University of Oxford, having an administrative office at
% Wellington Square, Oxford OX1 2JD, UK. 
%
% This file is part of Gerardus.
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details. The offer of this
% program under the terms of the License is subject to the License
% being interpreted in accordance with English Law and subject to any
% action against the University of Oxford being under the jurisdiction
% of the English Courts.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

% check arguments
narginchk(1, 2);
nargoutchk(0, 1);

% defaults
if (nargin < 2)
    p = 1;
end

% compute centroids and number of pixels in each slice
stats = scimat_regionprops(scimat, 'Area', 'Centroid');

% extract centroids (warning: centroid coordinates are given in
% index units, but with the columns before the rows!)
centroids = zeros(length(stats), 3);
for I = 1:length(stats)
    if (~isempty(stats{I})) % are there LV pixels in the slice?
        % extract centroid coordinates
        centroids(I, :) = [stats{I}(1).Centroid, I];
    else
        centroids(I, :) = [nan nan nan];
    end
end
% convert to real world coordinates, taking into account that we have
% columns before rows in centroids
centroids = scimat_index2world(centroids(:, [2 1 3]), scimat);

% if smoothing required
if (p~=1)
    % slices with a centroid
    idx = sum(isnan(centroids), 2) == 0;
    
    % compute Lee's centripetal knot points
    t = cumsum([0;((diff(centroids(idx, :)).^2)...
        *ones(size(centroids(idx, :), 2),1)).^(1/4)]).';
    
    % compute smoothing cubic spline for each coordinate
    ppx = csaps(t,centroids(idx,1), p);
    ppy = csaps(t,centroids(idx,2), p);
    ppz = csaps(t,centroids(idx,3), p);
    
    centroids(idx, :) = [ppval(ppx, t)' ppval(ppy, t)' ppval(ppz, t)'];
end
