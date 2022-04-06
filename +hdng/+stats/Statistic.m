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

classdef Statistic < handle
    %Statistic Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        index
        identifier
        method
        context
    end
    
    properties (Dependent, Transient)
        parameters
    end
    
    properties (GetAccess=private, SetAccess=private)
        parameter_names_
        parameters_
    end
    
    methods
        
        function obj = Statistic(index, identifier, method, parameters)
            obj.index = index;
            obj.identifier = identifier;
            obj.method = method;
            obj.context = struct();
            obj.parameters_ = parameters;
            obj.parameter_names_ = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            
            names = fieldnames(parameters);
            
            for i=1:numel(names)
                name = names{i};
                obj.parameter_names_(name) = true;
            end
        end
        
        function result = get.parameters(obj)
            result = obj.parameters_;
        end
        
        function result = matches(obj, identifier, parameters)
            
            result = false;
            
            if ~strcmp(obj.identifier, identifier)
                return;
            end
            
            names = fieldnames(parameters);

            result = numel(names) > 0 && numel(names) ~= length(obj.parameter_names_);

            for j=1:numel(names)
                name = names{j};

                if ~isKey(obj.parameter_names_, name)
                    result = false;
                    break;
                end
                
                match_value = parameters.(name);
                parameter_value = obj.parameters_.(name);
                
                if ischar(parameter_value)
                    if ~ischar(match_value) || ~strcmp(parameter_value, match_value)
                        result = false;
                        break;
                    end
                    
                    continue;
                end
                
                if isnumeric(parameter_value)
                    if ~isnumeric(match_value) || ~isequal(parameter_value, cast(match_value, class(parameter_value)))
                        result = false;
                        break;
                    end
                    
                    continue;
                end
                
                result = false;
                break;
            end
        end
        
    end
end
