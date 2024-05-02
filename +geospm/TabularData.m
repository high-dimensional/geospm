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

classdef TabularData < handle
    %TabularData A base class for data arranged in rows.
    %
    
    properties (Dependent, Transient)
        N % number of rows
        C % number of columns
    end
    

    methods
        
        function value = get.N(obj)
            value = obj.access_N();
        end
        
        function value = get.C(obj)
            value = obj.access_C();
        end
        
        function obj = TabularData()
        end
        
        function result = select(obj, row_selection, column_selection, transform)
            % Clone this data object using the selected rows, columns and transform.
            %   
            %   row_selection - a numeric vector of row indices
            %   column_selection - a numeric vector of column indices
            %   
            %   transform - a function handle:
            %   
            %   modified_specifier = fn(specifier, modifier)
            %   
            %   specifier is a struct with N, C and data (NxC matrix) fields,
            %   plus substructs per_row and per_column whose fields are arrays
            %   linked to their respective dimension.
            %   
            %   modifier is a TabularDataModifier for
            %   transforming the specifier.
            %
            %   The transform function is passed a struct with at least the
            %   following fields:
            %
            %   Subclasses should extend the define_clone_specifier() and
            %   create_clone_from_specifier() methods.
            

            if ~exist('row_selection', 'var')
                row_selection = [];
            end
            
            if isempty(row_selection)
                row_selection = 1:obj.N;
            end
            
            if ~exist('column_selection', 'var')
                column_selection = [];
            end
            
            if isempty(column_selection)
                column_selection = 1:obj.C;
            end
            
            if ~exist('transform', 'var')
                transform = @(specifier, modifier) specifier;
            end
            
            [specifier, modifier] = obj.define_clone_specifier();
            
            specifier = modifier.select_op(specifier, row_selection, column_selection);
            specifier = transform(specifier, modifier);

            result = obj.create_clone_from_specifier(specifier);
        end
    end
    
    methods (Access = protected)

        function result = access_N(obj) %#ok<STOUT,MANU>
            error('access_N() must be implemented by a subclass.');
        end

        function result = access_C(obj) %#ok<STOUT,MANU>
            error('access_C() must be implemented by a subclass.');
        end
        
        function assign_property(obj, name, value)
            % A helper function for setting a property of this object to 
            % the given value. This needs to be overriden and re-implemented 
            % by subclasses to ensure assignability of protected or private 
            % properties.
            %
            %   name - the name of the property to be assigned
            %   value - the value to be assigned

            obj.(name) = value;
        end
        
        function [specifier, modifier] = define_clone_specifier(obj)
            % Defines a specifier struct representing this object.
            %

            specifier = struct();
            
            specifier.N = obj.N;
            specifier.C = obj.C;

            specifier.data = [];

            specifier.per_row = struct();
            specifier.per_column = struct();

            modifier = geospm.TabularDataModifier();
        end

        function result = create_clone_from_specifier(~, specifier)
            % Creates a new instance of this object using the provided specifier.
            %
            %   specifier - a struct created by define_clone_specifier() and
            %   possibly modified by the transform function passed to
            %   clone().
            
            result = geospm.TabularData();
            
            names = fieldnames(specifier.per_row);
            
            for i=1:numel(names)
                name = names{i};
                obj.assign_property(name, specifier.per_row.(name));
            end

            names = fieldnames(specifier.per_column);
            
            for i=1:numel(names)
                name = names{i};
                obj.assign_property(name, specifier.per_column.(name));
            end
        end
        
    end
end
