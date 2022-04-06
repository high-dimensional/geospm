% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function [smoothing_method] = configure_smoothing_method(smoothing_method)

    if ~exist('smoothing_method', 'var')
        smoothing_method = 'default';
    end
    
    if ~isstruct(smoothing_method)
        
        if ~ischar(smoothing_method)
            error('geospm.validation.configure_smoothing_method(): smoothing_method must be a struct or a char vector.');
        end
        
        smoothing_type = smoothing_method;
        smoothing_method = struct();
        smoothing_method.type = smoothing_type;
    end
    
    if ~isfield(smoothing_method, 'type')
        smoothing_method.type = 'default';
    end
    
    if ~isfield(smoothing_method, 'description')
        smoothing_method.description = smoothing_method.type;
    end
    
    if ~isfield(smoothing_method, 'parameters')
        smoothing_method.parameters = struct();
    end
    
    if ~isfield(smoothing_method, 'diagnostics')
        smoothing_method.diagnostics = struct();
        smoothing_method.diagnostics.active = false;
    end
    
    if islogical(smoothing_method.diagnostics)
        active = smoothing_method.diagnostics;
        smoothing_method.diagnostics = struct();
        smoothing_method.diagnostics.active = active;
    end
    
    smoothing_method.diagnostics = configure_diagnostics(smoothing_method.diagnostics);
    
    if strcmp(smoothing_method.type, 'default')
        smoothing_method.parameters = configure_default_parameters(smoothing_method.parameters);
    end
end

function diagnostics = configure_diagnostics(diagnostics)
end

function parameters = configure_default_parameters(parameters)
    
    if ~isfield(parameters, 'gaussian_method')
        parameters.gaussian_method = [];
    end
end
