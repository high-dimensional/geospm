% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2022,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef GenericColourMap < hdng.colour_mapping.ColourMap
    %GenericColourMap Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        stops
        interpolation
    end
    
    properties (Transient, Dependent)
        stop_colours
    end
    
    methods
        
        function obj = GenericColourMap(nan_rgba_colour, stops, interpolation)
            
            obj = obj@hdng.colour_mapping.ColourMap(nan_rgba_colour);
            
            if ~iscell(stops)
                error('Expected stops to be a cell array of colour stops.');
            end
            
            if ~isa(interpolation, 'hdng.colour_mapping.ColourInterpolation')
                error('Expected interpolation to be a hdng.colour_mapping.ColourInterpolation.');
            end
            
            if numel(stops) < 2
                error('Expected at least 2 colour stops.');
            end
            
            obj.stops = stops;
            obj.interpolation = interpolation;
            
            obj.use_apply_2 = true;
        end
        
        function result = get.stop_colours(obj)
            result = cell(1, numel(obj.stops));
            
            for i=1:numel(obj.stops)
                stop = obj.stops{i};
                result{i} = stop.rgba;
            end
        end
        
        
        function [results, legend] = apply_to_scopes(obj, scopes)

            N = numel(scopes);
            S = numel(obj.stops);

            stop_order = hdng.colour_mapping.ColourStop.order(obj.stops);
            ordered_stops = obj.stops(stop_order);
            
            image_statistics = hdng.stats.Collector();
            stop_value_indices = cell(numel(obj.stops), 1);
            
            for i=1:S
                stop = ordered_stops{i};
                stop_index = stop_order(i);
                
                stop_value_indices{stop_index} = stop.register_statistics(image_statistics);
            end
            
            per_image_statistics = cell(N, 1);
            
            for i=1:N
                per_image_statistics{i} = image_statistics.compute_statistics(scopes{i});
                per_image_statistics{i}.stops = cell(1, S);
            end
            
            stop_values = zeros(S, N);
            
            for i=1:S
                stop = ordered_stops{i};
                stop_index = stop_order(i);
                
                value_indices = stop_value_indices{stop_index};
                stop_values(stop_index, :) = stop.compute_locations(value_indices, per_image_statistics);
                
                for j=1:N
                    per_image_statistics{j}.stops{stop_index} = stop_values(stop_index, :);
                end
            end
            
            legend = hdng.colour_mapping.GenericColourLegend(obj, stop_values, stop_values);
            
            
            
            
            results = cell(N, 1);
            
            
            for i=1:N
                
                slices = scopes{i};
                
                [ordered_stop_values, scope_stop_order] = sort(stop_values(:, i));
                
                ordered_stop_colours = obj.stop_colours(scope_stop_order);
                interp = obj.interpolation.with_colours(ordered_stop_colours);
                
                for j=1:numel(slices)
                    slices{j} = obj.map_and_interpolate_scalars(slices{j}, interp, ordered_stop_values);
                end
                
                results{i} = slices;
            end
        end
        
        
        function result = map_and_interpolate_scalars(obj, scalars, interp, stop_values)
            
            nan_selector = isnan(scalars);

            blank = zeros(size(scalars));
            red = blank;
            green = blank;
            blue = blank;

            for index=1:interp.N_segments

                L = stop_values(index);
                R = stop_values(index + 1);

                segment = ~nan_selector;
                
                if index > 1
                    segment = segment & (scalars >= L);
                end
                
                if index < interp.N_segments
                    segment = segment & (scalars < R);
                end
                
                if sum(segment(:)) == 0
                    continue
                end

                segment_scalars = (scalars(segment) - L) ./ (R - L);
                
                [red(segment), ...
                 green(segment), ...
                 blue(segment), ...
                 ~] = interp.apply_segment(index, segment_scalars);
            end

            red(nan_selector)   = obj.nan_rgba_colour(1);
            green(nan_selector) = obj.nan_rgba_colour(2);
            blue(nan_selector)  = obj.nan_rgba_colour(3);

            result = cat(numel(size(scalars)) + 1, red, green, blue);
        end
        
    end
    
    methods (Static)
        
        
        function result = define_gradient(stop_specifiers, colour_factor, colour_mode, interpolation)
            
            if ~exist('colour_factor', 'var')
                colour_factor = 1 / 255.0;
            end
            
            if ~exist('colour_mode', 'var')
                colour_mode = 'rgba';
            end
            
            if ~exist('interpolation', 'var')
                interpolation = 'linear';
            end
            
            if ischar(interpolation)
                interpolation = hdng.colour_mapping.ColourInterpolation.create(interpolation);
            end
            
            stops = cell(1, numel(stop_specifiers));
            
            interpolation_count = 0;
            last_anchor = [];
            
            for i=1:numel(stop_specifiers)
                
                specifier = stop_specifiers{i};
                
                colour = specifier{1} .* colour_factor;
                
                if numel(specifier) >= 2
                    kind = specifier{2};
                else
                    kind = [];
                end
                
                if numel(specifier) >= 3
                    extra = specifier(3:end);
                else
                    extra = {};
                end
                
                if ischar(kind)
                    
                    for j=1:interpolation_count
                        stop_index = i - interpolation_count + j - 1;
                        stop = stops{stop_index};
                        stop{2} = j / (interpolation_count + 1.0);
                        stop{4} = i;
                        stops{stop_index} = stop;
                    end
                    
                    stop = hdng.colour_mapping.SemanticColourStop(colour_mode, colour, kind, extra{:});
                    interpolation_count = 0;
                    last_anchor = i;
                    
                elseif isnumeric(kind) || isempty(kind)
                    
                    interpolation_count = interpolation_count + 1;
                    stop = {colour, kind, last_anchor, []};
                else
                    error('GenericColourMap.define_gradient(): Unknown stop type ''%s''', class(kind));
                end
                
                stops{i} = stop;
            end
            
            for i=1:numel(stops)
                stop = stops{i};
                
                if ~iscell(stop)
                    continue
                end
                
                colour = stop{1};
                position = stop{2};
                previous_index = stop{3};
                next_index = stop{4};
                
                stops{i} = hdng.colour_mapping.InterpolatedColourStop(colour_mode, colour, previous_index, next_index, position);
            end
            
            result = hdng.colour_mapping.GenericColourMap([255, 0, 0, 255] ./ 255, stops, interpolation);
        end
        
        function result = monochrome(at_most, at_least)
            
            if ~exist('at_most', 'var')
                at_most = [];
            end
            
            if ~exist('at_least', 'var')
                at_least = [];
            end
            
            if isempty(at_most) ~= isempty(at_least)
                error('GenericColourMap.monochrome(): at_most and at_least must be specified together or not at all.');
            end
            
            if ~isempty(at_most)
                result = hdng.colour_mapping.GenericColourMap.define_gradient({
                    {[  0,   0,   0, 255], 'at_most', struct('value', at_most)}, ...
                    {[255, 255, 255, 255], 'at_least', struct('value', at_least)}, ...
                });
            else
                result = hdng.colour_mapping.GenericColourMap.define_gradient({
                    {[  0,   0,   0, 255], 'min'}, ...
                    {[255, 255, 255, 255], 'max'}, ...
                });
            end
        end
        
        function result = twilight_27()
        
            result = hdng.colour_mapping.GenericColourMap.define_gradient({
                {[ 60,  91, 120, 255], 'min'}, ...
                {[ 69, 155, 202, 255]}, ...
                {[137, 216, 236, 255]}, ...
                {[199, 243, 248, 255]}, ...
                {[234, 239, 241, 255], 'constant', struct('value', 0)}, ...
                {[255, 231, 196, 255]}, ...
                {[254, 166, 118, 255]}, ...
                {[229, 105,  51, 255]}, ...
                {[146,  38,  42, 255], 'max'}, ...
            });
        
            result.nan_rgba_colour = [234, 239, 241, 255] ./ 255;
        end
    end
    
end
