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

classdef ColourInterpolation < handle
    %ColourInterpolation Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=protected)
        colours
    end
    
    properties (Dependent, Transient)
        N_colours
        N_segments
    end
    
    methods
        
        function obj = ColourInterpolation()
            obj.colours = {};
        end
        
        function result = get.N_colours(obj)
            result = numel(obj.colours);
        end
        
        function result = get.N_segments(obj)
            result = obj.N_colours - 1;
            
            if result < 0
                result = 0;
            end
        end
        
        function result = with_colours(~, colours)
            result = hdng.colour_mapping.ColourInterpolation();
            result.colours = colours;
        end
        
        function [r, g, b, a] = apply_segment(obj, segment_index, scalar_field) %#ok<STOUT,INUSD>
            error('ColourInterpolation.apply_segment() must be implemented by a subclass.');
        end
    end
    
    
    methods (Static, Access=public)
                
        function result = create(interpolation_type, varargin)
            
            builtins = hdng.colour_mapping.ColourInterpolation.builtin_interpolations();
            
            if ~isKey(builtins, interpolation_type)
                error(['ColourInterpolation.create(): Unknown builtin interpolation type: ' interpolation_type]);
            end
            
            ctor = builtins(interpolation_type);
            result = ctor(varargin{:});
        end
        
        function result = builtin_interpolations()
            
            persistent BUILTIN_INTERPOLATIONS;
            
            if isempty(BUILTIN_INTERPOLATIONS)
            
                where = mfilename('fullpath');
                [base_dir, ~, ~] = fileparts(where);
                scan_dir = base_dir;

                result = what(scan_dir);
                    
                BUILTIN_INTERPOLATIONS = containers.Map('KeyType', 'char','ValueType', 'any');
                
                for i=1:numel(result.m)
                    class_file = fullfile(scan_dir, result.m{i});
                    [~, class_name, ~] = fileparts(class_file);
                    
                    if strcmpi('ColourInterpolation', class_name)
                        continue;
                    end
                    
                    class_type = ['hdng.colour_mapping.' class_name];

                    if ~exist(class_type, 'class')
                        continue
                    end
                    
                    mc = meta.class.fromName(class_type);
                    is_interpolation = false;
                    
                    for j=1:numel(mc.SuperclassList)
                        sc = mc.SuperclassList(j);
                        
                        if strcmp(sc.Name, 'hdng.colour_mapping.ColourInterpolation')
                            is_interpolation = true;
                            break;
                        end
                    end
                    
                    if ~is_interpolation
                        continue
                    end
                    
                    parts = hdng.utilities.split_camelcase(class_name);

                    if strcmpi(parts{end}, 'Interpolation')
                        parts = parts(1:end - 1);
                    end

                    identifier = join(lower(parts), '_');
                    identifier = identifier{1};
                    BUILTIN_INTERPOLATIONS(identifier) = str2func(class_type);
                end
            end
            
            result = BUILTIN_INTERPOLATIONS;
        end
    end
end
