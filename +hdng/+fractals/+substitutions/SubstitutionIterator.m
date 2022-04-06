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

%%#ok<*CPROPLC>

classdef SubstitutionIterator < handle
    %SubstitutionIterator Summary of this class goes here
    %
    %   This class encapsulates the basic procedure for generating
    %   a fractal based on recursive substitution of a seed segment
    %   with the segments of a transformed generator sequence.
    %
    %   
    
    properties (SetAccess=private)
        
        domain
        rules
        seed_sequence
        levels
        
        depth
        
        transform_stack
        rule_stack
        rule_position_stack
        
        leaf_count
    end
    
    methods
        
        function obj = SubstitutionIterator(domain, rules, seed_sequence, levels)
            
            obj.domain = domain;
            obj.rules = rules;
            obj.seed_sequence = seed_sequence;
            obj.levels = levels;
            
            obj.leaf_count = 1;
            obj.depth = 1;
            
            max_depth = levels + 1;
            
            obj.transform_stack = obj.domain.create_sequence(max_depth);
            obj.rule_stack = cell(max_depth, 1);
            obj.rule_position_stack = zeros(max_depth, 1, 'uint8');
            
            obj.reset();
        end
        
        function obj = reset(obj)
            
            obj.leaf_count = 1;
            obj.depth = 1;
            
            obj.rule_stack{1} = obj.seed_sequence;
            obj.rule_position_stack(1) = 0;
            
            obj.transform_stack.set_transform(1, obj.domain.create_identity_transform());
        end
        
        function [is_valid, transform] = next(obj)
            
            do_debug = false;
            
            if do_debug
                fprintf('%s\n', '[---'); %#ok<UNRCH>
            end
            
            is_valid = false;
            transform = obj.domain.create_identity_transform();
            
            while obj.depth > 0
                
                % Compute the next position in the current rule
                position = obj.rule_position_stack(obj.depth) + 1;
                rule = obj.rule_stack{obj.depth};
                
                if position > rule.length
                    % We've reached the end of the current rule
                    obj.depth = obj.depth - 1;
                    continue
                end
                
                if is_valid
                    % The current transform is a leaf transform, which we can return
                    break
                end
                
                % Save the new rule position
                obj.rule_position_stack(obj.depth) = position;
                
                % Get the current seed transform
                parent_transform = obj.transform_stack.get_transform(obj.depth);
                
                if do_debug
                    fprintf('[parent]   %03d:\n%s\n', obj.depth, obj.domain.transform_to_string(parent_transform)); %#ok<UNRCH>
                end
                
                if ~parent_transform.reversed
                    rule_transform = rule.get_transform(position);
                else
                    rule_transform = rule.get_transform(rule.length - position + 1);
                end
                
                if do_debug
                    fprintf('[rule]     %03d:\n%s\n', obj.depth, obj.domain.transform_to_string(rule_transform)); %#ok<UNRCH>
                end
                
                transform = obj.domain.multiply_transforms(parent_transform, rule_transform);
                
                if obj.depth == obj.levels + 1
                    is_valid = true;
                    continue
                end
                
                obj.depth = obj.depth + 1;
                obj.transform_stack.set_transform(obj.depth, transform);
                obj.rule_stack{obj.depth} = obj.rules{transform.rule};
                obj.rule_position_stack(obj.depth) = 0;
            end
            
            if is_valid
                if do_debug
                    fprintf('[leaf %03d]   %03d:\n%s\n', obj.leaf_count, obj.depth, obj.domain.transform_to_string(transform)); %#ok<UNRCH>
                end

                obj.leaf_count = obj.leaf_count + 1;
            end
            
            if obj.depth == 0
                obj.reset();
            end
            
            if do_debug
                fprintf('%s\n', '---]'); %#ok<UNRCH>
            end
        end
        
    end
end
