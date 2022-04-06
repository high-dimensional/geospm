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

classdef FeatureAttribute < handle
    %FeatureAttribute Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        records
        label
        is_missing
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = FeatureAttribute()
        end
        
        function result = get.records(obj)
            result = obj.access_records();
        end
        
        function result = get.label(obj)
            result = obj.access_label();
        end
        
        function result = get.is_missing(obj)
            result = obj.access_is_missing();
        end
        
        function [missing, value] = nth_value(obj, index) %#ok<INUSD,STOUT>
            error('nth_value() must be implemented by a subclass.');
        end
        
    end
    
    methods (Static)
        
    end
    
    
    methods (Static, Access = protected)
    end
    
    methods (Access = protected)
        
        function result = access_records(~) %#ok<STOUT>
            error('access_records() must be implemented by a subclass.');
        end
        
        function result = access_label(~) %#ok<STOUT>
            error('access_label() must be implemented by a subclass.');
        end
        
        function result = access_is_missing(~) %#ok<STOUT>
            error('access_is_missing() must be implemented by a subclass.');
        end
        
    end
end
