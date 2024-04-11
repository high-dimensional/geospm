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
    
    properties (GetAccess = private, SetAccess = private)
        N_
        C_
    end
    
    methods
        
        function value = get.N(obj)
            value = obj.N_;
        end
        
        function value = get.C(obj)
            value = obj.C_;
        end

        function obj = TabularData(N, C)
            %Construct a TabularData object with the given number of rows.
            % N ? The number of rows in the data.
            
            if ~exist('N', 'var') || isempty(N)
                N = 0;
            end

            if ~exist('C', 'var') || isempty(C)
                C = 0;
            end
            
            obj.N_ = N;
            obj.C_ = C;
        end
        
        function result = select(obj, row_selection, column_selection, transform)
            % Clone this data object using the selected rows, columns and transform.
            %   row_selection - a numeric vector of row indices
            %   column_selection - a numeric vector of column indices
            %   transform - a function handle that expects an argument struct and returns a result struct
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
