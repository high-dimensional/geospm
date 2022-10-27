% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef EmpiricalVariogram < handle
    %EmpiricalVariogram 
    %   
    
    properties
        name
    end
    
    properties (Dependent, Transient)
        size
        distance
        gamma
        pairs
        
        max_distance
        max_gamma
    end
    
    properties (GetAccess=private, SetAccess=private)
        size_
        distance_
        gamma_
        pairs_
    end
    
    methods
        
        function obj = EmpiricalVariogram()
            obj.name = '';
            obj.size_ = 0;
            obj.distance_ = [];
            obj.gamma_ = [];
            obj.pairs_ = [];
        end
        
        function result = get.size(obj)
            result = obj.size_;
        end
        
        function result = get.distance(obj)
            result = obj.distance_;
        end
        
        function result = get.gamma(obj)
            result = obj.gamma_;
        end
        
        function result = get.pairs(obj)
            result = obj.pairs_;
        end
        
        function result = get.max_distance(obj)
            result = max(obj.distance_);
        end
        
        function result = get.max_gamma(obj)
            result = max(obj.gamma_);
        end
        
        function define(obj, distance, gamma, pairs)
            N_distance = numel(distance);
            
            if numel(gamma) ~= N_distance
                error('EmpiricalVariogram.define(): Length of gamma does not match length of distance.');
            end
            
            if numel(pairs) ~= N_distance
                error('EmpiricalVariogram.define(): Length of pairs does not match length of distance.');
            end
            
            obj.size_ = N_distance;
            obj.distance_ = distance;
            obj.gamma_ = gamma;
            obj.pairs_ = pairs;
        end
        
        function result = max_gamma_at_distance(obj, distance)
            selector = obj.distance_ <= distance;
            result = max(obj.gamma_(selector));
        end
        
        function plot(obj, varargin)
            
            [~] = gcf;
            
            %ax = gca;
            %axis(ax, 'equal', 'auto');
            
            obj.plot_impl(varargin{:});
        end
        
        function plot_impl(obj, varargin)
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'distance_limit')
                options.distance_limit = obj.max_distance;
            end
            
            x_selector = obj.distance <= options.distance_limit;
            x = obj.distance(x_selector);
            y = obj.gamma(x_selector);
            
            h = scatter(x, y);
            ax = gca;
            axis(ax, 'square');
            ax.FontSizeMode = 'manual';
            ax.FontSize = 8;
            ax.TitleFontWeight = 'normal';
            %ax.LabelFontWeight = 'bold';
            %ax.LabelFontSizeMultiplier = 1.2;
            
            if isfield(options, 'LineWidth')
                h.LineWidth = options.LineWidth;
            end
            
            if isfield(options, 'MarkerSize')
                h.SizeData = options.MarkerSize;
            end
        end
        
        function result = as_json(obj)
            
            result = struct();
            result.name = obj.name;
            result.distance = obj.distance;
            result.gamma = obj.gamma;
            result.pairs = obj.pairs;
        end
    end
    
    methods (Static)
        
        function result = from_json(json_struct)
            
            result = geospm.variograms.EmpiricalVariogram();
            result.name = json_struct.name;
            result.size_ = numel(json_struct.distance);
            result.distance_ = json_struct.distance;
            result.gamma_ = json_struct.gamma;
            result.pairs_ = json_struct.pairs;
        end
    end
    
    methods (Access=protected)        
    end
end
