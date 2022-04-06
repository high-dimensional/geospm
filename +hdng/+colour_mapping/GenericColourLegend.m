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

classdef GenericColourLegend < hdng.colour_mapping.ColourLegend
    %GenericColourLegend Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        
        stop_values
        stop_labels
    end
    
    methods
        
        function obj = GenericColourLegend(colour_map, stop_labels, stop_values)
            
            obj = obj@hdng.colour_mapping.ColourLegend(colour_map);
            
            obj.stop_values = stop_values;
            obj.stop_labels = stop_labels;
        end
        
        function result = render_and_save_as(obj, resolution, filename, title) %#ok<STOUT>
            
            if ~exist('title', 'var')
                title = '';
            end
            
            t = zeros(resolution, 1);
            
            for i=1:resolution
                t(i) = 2 * (i - 1) / (resolution - 1) - 1;
            end
            
            colours = obj.colour_map.apply({t});
            colours = reshape(colours{1}, [resolution 3]);
            
            f = figure;
            ax = gca;
            
            set(f,'renderer','Painters', 'Position', [0 0 80 600]);
            axis(ax, 'equal', 'auto');

            axis off;
            
            colormap(colours);
            
            caxis([0, 1]);
            
            c = colorbar('east');
    
            if numel(title) ~= 0
                c.Label.String = title;
            end
            
            c.LimitsMode = 'manual';
            c.Limits = [0, 1];
            c.TicksMode = 'manual';
            c.Ticks = 0:1/(numel(obj.stop_labels) - 1):1;
            
            labels = cell(numel(obj.stop_labels), 1);
            
            for i=1:numel(obj.stop_labels)
                labels{i} = num2str(obj.stop_labels(i), '%.2e');
            end
            
            c.TickLabels = labels;

            saveas(f, filename, 'png');
        end
        
        function result = as_json_struct(obj, resolution) 
            
            result = struct();
            
            result.resolution = resolution;
            result.stop_values = obj.stop_values;
            result.stop_labels = obj.stop_labels;
            
            t = zeros(resolution, 1);
            
            for i=1:resolution
                t(i) = ((resolution - i) / (resolution - 1)) * obj.stop_values(1) ...
                        + ((i - 1) / (resolution - 1)) * obj.stop_values(end);
            end
            
            [result.ramp, ~] = obj.colour_map.apply({t});
        end
        
        function result = as_html(obj, size) %#ok<STOUT,INUSD>
            error('ColourLegend.as_json_struct() must be implemented by a subclass.');
        end
        
    end
end
