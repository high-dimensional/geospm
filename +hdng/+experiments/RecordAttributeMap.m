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

classdef RecordAttributeMap < handle
    
    %RecordAttributeMap Holds a collection of record attributes.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        attributes
        names
    end
    
    properties (GetAccess=private, SetAccess=private)
        attributes_
    end
    
    methods
        
        function obj = RecordAttributeMap()
            obj.attributes_ = hdng.utilities.OrderedMap('KeyType', 'char', 'ValueType', 'any');
        end
        
        function result = get.attributes(obj)
            result = values(obj.attributes_);
        end
        
        function result = get.names(obj)
            result = keys(obj.attributes_)';
        end
        
        function result = has_attribute(obj, name)
            
            result = isKey(obj.attributes_, name);
        end
        
        function result = attribute_for_name(obj, name)
            
            result = hdng.experiments.RecordAttribute.empty;
            
            if ~isKey(obj.attributes_, name)
                return
            end
            
            result = obj.attributes_(name);
        end
        
        function result = define(obj, identifier, create_if_missing, is_persistent)
            
            if ~exist('create_if_missing', 'var')
                create_if_missing = true;
            end
            
            if ~exist('is_persistent', 'var')
                is_persistent = true;
            end
            
            if isKey(obj.attributes_, identifier)
               result = obj.attributes_(identifier);
               return
            end
            
            if ~create_if_missing
                result = hdng.experiments.RecordAttribute.empty;
                return
            end
            
            result = hdng.experiments.RecordAttribute(identifier, is_persistent);
            obj.attributes_(identifier) = result;
        end
        
        function remove(obj, identifier)
            if isKey(obj.attributes_, identifier)
                remove(obj.attributes_, identifier);
            end
        end
        
    end
    
    methods (Static, Access=protected)

    end
end
