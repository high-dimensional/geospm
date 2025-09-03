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

classdef AxisConfiguration < hdng.diagrams.configurations.Configuration
            
    %AxisConfiguration Summary.  
    %   Detailed description 
    
    properties
        style_class
        orientation
        offset
        baseline
        ticks
        labels
        rules
    end
    
    properties (Dependent, Transient)
    end
    
    methods
            
        function obj = AxisConfiguration(varargin)
            obj = obj@hdng.diagrams.configurations.Configuration(varargin{:});
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'style_class')
                options.style_class = true;
            end
            
            if ~isfield(options, 'orientation')
                options.orientation = 'bottom';
            end
            
            if ~isfield(options, 'offset')
                options.offset = 0;
            end
            
            if ~isfield(options, 'baseline')
                options.baseline = hdng.diagrams.configurations.BaselineConfiguration();
            end
            
            if ~isfield(options, 'ticks')
                options.ticks = hdng.diagrams.configurations.TicksConfiguration();
            end

            if ~isfield(options, 'labels')
                options.labels = hdng.diagrams.configurations.LabelsConfiguration();
            end

            if ~isfield(options, 'rules')
                options.rules = hdng.diagrams.configurations.RulesConfiguration();
            end

            obj.style_class = options.style_class;
            obj.orientation = options.orientation;
            obj.offset = options.offset;
            obj.baseline = options.baseline;
            obj.ticks = options.ticks;
            obj.labels = options.labels;
            obj.rules = options.rules;
        end
    end
end
