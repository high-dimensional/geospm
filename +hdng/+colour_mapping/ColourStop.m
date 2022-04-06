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

classdef ColourStop < handle
    %ColourStop Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        
        colour_model
        colour_values
        
        requires
    end
    
    properties (Dependent, Transient)
    
        rgba
    
    end
    
    properties (GetAccess=private, SetAccess=private)
        rgba_cached
    end
    
    methods
        
        function obj = ColourStop(colour_model, colour_values, requires)
            
            if ~exist('requires', 'var')
                requires = {};
            end
            
            if strcmpi(colour_model, 'rgba')
                obj.rgba_cached = colour_values;
            else
                error(['Unknown colour model: ' colour_model]);
            end
            
            obj.colour_model = colour_model;
            obj.colour_values = colour_values;
            obj.requires = requires;
        end
        
        function result = get.rgba(obj)
            result = obj.rgba_cached;
        end
        
        function result = compute_location(obj, batch) %#ok<STOUT,INUSD>
            error('ColourStop.compute_location() must be implemented by a subclass.');
        end
        
    end
    
    methods (Static)
        
        function permutation = order(stops)
            [permutation, ~] = ...
                hdng.utilities.sort_topologically(stops, @(stop, ~) cell2mat(stop.requires));
        end
    end
end
