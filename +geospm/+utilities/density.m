% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function result = density(data, fwhm, image_path)
    
    w  = fwhm * 2.235;
    wl = ceil(w);
    l  = 2 * wl + 1;
    mu = [0, 0];
    s  = eye(2) * w;
    X  = repmat((-wl:wl)', 1, l);
    Y  = repmat(-wl:wl, l, 1);
    G  = [X(:), Y(:)];
    
    K = mvnpdf(G, mu, s);
    K = reshape(K, size(X));
    k = size(K);
    
    d  = [data.x_range + l, data.y_range + l];
    density = zeros(d);
    
    for i=1:data.N
        
        x = data.x_offset(i) + 1;
        y = data.y_offset(i) + 1;
        
        D = density(x:x+k(1)-1, y:y+k(2)-1);
        density(x:x+k(1)-1, y:y+k(2)-1) = D + K;
    end
    
    density = density(wl:wl+data.x_range, wl:wl+data.y_range);
    result = density;
    
    if exist('image_path', 'var')

        d_max = max(density(:));
        I = cast(255.0 * density ./ d_max, 'uint8');
        imwrite(I, [image_path, '.png']);
    end
end
