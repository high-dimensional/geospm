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

classdef GatherNestedAttributes < hdng.diagrams.DataTransform
    %GatherNestedAttributes Summary.  
    %   Detailed description 
    
    properties
        specifiers
    end
    
    properties (Dependent, Transient)
    end
    
    properties (Access=private)
    end

    methods
        function obj = GatherNestedAttributes(varargin)

            obj = obj@hdng.diagrams.DataTransform();

            obj.specifiers = varargin;
        end
        
        function result_scope = compute(obj, data_scope, base, parent, siblings) %#ok<INUSD>
            
            stack = {{{data_scope, struct()}}};
            
            for index=1:numel(obj.specifiers)

                specifier = obj.specifiers{index};
                level = stack{index};
                
                next_level = {};

                for s_index=1:numel(level)
                    entry = level{s_index};

                    scope = entry{1};
                    record = entry{2};
                    
                    children = scope.children_by_data_level.(specifier.identifier);
                    
                    for c_index=1:numel(children)
                        child = children{c_index};
                        nested_record = record;

                        for a_index=1:numel(specifier.attributes)
                            attribute = specifier.attributes{a_index};
                            value = child.attributes.(attribute);
                            nested_record.(attribute) = value;
                        end

                        next_level{end + 1} = {child, nested_record}; %#ok<AGROW>
                    end
                end
                
                stack = [stack; {next_level}]; %#ok<AGROW>
            end

            last_level = stack{end};

            records = hdng.utilities.RecordTable();

            for index=1:numel(last_level)
                entry = last_level{index};
                record = hdng.utilities.RecordTable(entry{2}, 1);
                records = records + record;
            end
            
            result_scope = hdng.diagrams.DataScope(data_scope.data_level, data_scope.attributes, records);
        end

        %{

        function result_scope = compute(obj, data_scope)
            
            stack = {{{data_scope}, hdng.utilities.RecordTable()}};
            
            for index=1:numel(obj.specifiers)

                specifier = obj.specifiers{index};
                visit = stack{index};
                scopes = visit{1};
                records = visit{2};


                nested_scopes = [];

                for s_index=1:numel(scopes)
                    scope = scopes{s_index};
                    nested_scopes = [nested_scopes; scope.children_by_data_level.(specifier.identifier)]; %#ok<AGROW>
                end

                nested_records = hdng.utilities.RecordTable();
                
                for s_index=1:numel(nested_scopes)
                    scope = nested_scopes{s_index};
                    scope_records = records;
                    
                    for a_index=1:numel(specifier.attributes)
                        attribute = specifier.attributes{a_index};
                        value = scope.attributes.(attribute);
                        scope_records = scope_records.assign_field(attribute, value);
                    end

                    nested_records = nested_records + scope_records;
                end
                
                stack = [stack; {{nested_scopes, nested_records}}]; %#ok<AGROW>
            end

            visit = stack{end};
            records = visit{2};
            
            result_scope = hdng.diagrams.DataScope(data_scope.data_level, data_scope.attributes, records);
        end
        %}
    end

    methods (Static)
        
        function result = create_specifier(identifier, attributes)
            
            result = struct();
            
            result.identifier = identifier;
            result.attributes = attributes;
        end
    end
end
