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

classdef FeatureRecords < handle
    %FeatureRecords Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        N_records
        labels
        attributes
        geometry
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = FeatureRecords()
        end
        
        function result = get.N_records(obj)
            result = obj.access_N_records();
        end
        
        function result = get.labels(obj)
            result = obj.access_labels();
        end
        
        function result = get.attributes(obj)
            result = obj.access_attributes();
        end
        
        function result = attribute_for_label(obj, label)
            error('FeatureRecords.attribute_for_label() must be implemented by a subclass.');
        end
        
    end
    
    methods (Static)
        
    end
    
    
    methods (Static, Access = protected)
    end
    
    methods (Access = protected)
        
        function result = access_N_records(~) %#ok<STOUT>
            error('access_N_records() must be implemented by a subclass.');
        end
        
        function result = access_labels(~) %#ok<STOUT>
            error('access_labels() must be implemented by a subclass.');
        end
        
        function result = access_attributes(~) %#ok<STOUT>
            error('access_attributes() must be implemented by a subclass.');
        end
        
    end
end
