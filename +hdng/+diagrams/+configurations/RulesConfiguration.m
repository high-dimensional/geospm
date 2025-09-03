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

classdef RulesConfiguration < hdng.diagrams.configurations.Configuration
            
    %RulesConfiguration Summary.  
    %   Detailed description 
    
    properties
        show
        style_class
        at
        show_labels
        label_style
        label_style_class;
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = RulesConfiguration(varargin)
            obj = obj@hdng.diagrams.configurations.Configuration(varargin{:});
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            if ~isfield(options, 'show')
                options.show = true;
            end
            if ~isfield(options, 'style_class')
                options.style_class = true;
            end
            if ~isfield(options, 'at')
                options.at = [];
            end
            if ~isfield(options, 'show_labels')
                options.show_labels = true;
            end
            if ~isfield(options, 'label_style')
                %{
                options.label_style = hdng.typesetting.Style();
                options.label_style.font_family = 'Barlow';
                options.label_style.font_size = 44;
                %}
                options.label_style = [];
            end
            if ~isfield(options, 'label_style_class')
                options.label_style_class = '';
            end

            obj.show = options.show;
            obj.style_class = options.style_class;
            obj.at = options.at;
            obj.show_labels = options.show_labels;
            obj.label_style = options.label_style;
            obj.label_style_class = options.label_style_class;
        end
    end
end
