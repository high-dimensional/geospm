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

classdef ValueOptions
    %ValueOptions Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = public)
        symbols_are_case_sensitive

        missing_symbols
        logical_symbols
    end
    
    
    properties (GetAccess = public, SetAccess = private)
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function [true_symbols, false_symbols] = get_true_false_symbols(obj)

            
            true_symbols = cell(numel(obj.logical_symbols), 1);
            false_symbols = cell(numel(obj.logical_symbols), 1);

            for index=1:numel(obj.logical_symbols)
                pair = obj.logical_symbols{index};
                true_symbols{index} = pair{1};
                false_symbols{index} = pair{2};
            end
            
        end

        function obj = ValueOptions(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'symbols_are_case_sensitive')
                options.symbols_are_case_sensitive = true;
            end

            if ~isfield(options, 'missing_symbols')
                options.missing_symbols = {''};
            end

            if ~isfield(options, 'logical_symbols')
                options.logical_symbols = {{'t', 'f'}, {'true', 'false'}};
            end

            obj.symbols_are_case_sensitive = options.symbols_are_case_sensitive;

            obj.missing_symbols = options.missing_symbols;
            obj.logical_symbols = options.logical_symbols;
        end

        function result = override_with(obj, value_options)
            
            result = obj;

            if isempty(value_options)
                return;
            end

            if isempty(obj)
                result = value_options;
                return;
            end
            
            result = value_options;
        end

        function options = apply(obj, options, index)
            
            [true_symbols, false_symbols] = obj.get_true_false_symbols();

            args = struct();
            args.TreatAsMissing = obj.missing_symbols;
            args.TrueSymbols = true_symbols;
            args.FalseSymbols = false_symbols;
            args.CaseSensitive = obj.symbols_are_case_sensitive;

            names = fieldnames(args);

            for name_index=1:numel(names)
                name = names{name_index};

                if ~isprop(options.VariableOptions(index), name)
                    args = rmfield(args, name);
                end
            end

            %{
            options = setvaropts(options, index, ...
                'TreatAsMissing', obj.missing_symbols, ...
                'TrueSymbols', true_symbols, ...
                'FalseSymbols', false_symbols, ...
                'CaseSensitive', obj.symbols_are_case_sensitive);
            %}

            args = hdng.utilities.struct_to_name_value_sequence(args);
            options = setvaropts(options, index, args{:});
            
        end
    end
end
