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

classdef LabelsConfiguration < hdng.diagrams.configurations.Configuration
            
    %TicksConfiguration Summary.  
    %   Detailed description 
    
    properties
        show
        style_class
        style

        show_min_label
        show_max_label

    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = LabelsConfiguration(varargin)
            obj = obj@hdng.diagrams.configurations.Configuration(varargin{:});
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            if ~isfield(options, 'show')
                options.show = true;
            end
            if ~isfield(options, 'style_class')
                options.style_class = true;
            end
            if ~isfield(options, 'style')
                options.style = [];
            end
            if ~isfield(options, 'show_min_label')
                options.show_min_label = false;
            end
            if ~isfield(options, 'show_max_label')
                options.show_max_label = false;
            end
            obj.show = options.show;
            obj.style_class = options.style_class;
            obj.style = options.style;

            obj.show_min_label = options.show_min_label;
            obj.show_max_label = options.show_max_label;
        end
    end
end
