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

classdef FeatureAttributeImpl < hdng.geometry.FeatureAttribute
    %FeatureAttributeImpl Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
        records_
    end
    
    methods
        
        function obj = FeatureAttributeImpl(records)
            obj = obj@hdng.geometry.FeatureAttribute();
            obj.records_ = records;
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
        
        function result = access_records(obj)
            result = obj.records_;
        end
        
        function result = access_label(~) %#ok<STOUT>
            error('access_label() must be implemented by a subclass.');
        end
        
        function result = access_is_missing(~) %#ok<STOUT>
            error('access_is_missing() must be implemented by a subclass.');
        end
        
    end
end
