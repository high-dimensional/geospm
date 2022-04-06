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

classdef ColourMap < handle
    %ColourMap Maps a (y, x, z/t) dimensional data volume to a (y, x, z/t, channels) image volume.
    %   
    
    properties (Constant)
        
        PLANE_XY = 'xy'
        PLANE_XZ = 'xz'
        PLANE_YZ = 'yz'
        
        SLICE_MODE = 'slice'
        LAYER_MODE = 'layer'
        VOLUME_MODE = 'volume'
        BATCH_MODE = 'batch'
    end
    
    properties
        nan_rgba_colour
        use_apply_2
    end
    
    methods
        
        function obj = ColourMap(nan_rgba_colour)
            obj.nan_rgba_colour = nan_rgba_colour;
            obj.use_apply_2 = false;
        end
        
        function [results, legend] = apply(obj, batch, mode, slice_plane) % %#ok<STOUT,INUSD>
            if ~obj.use_apply_2
                error('ColourMap2.apply() must be implemented by a subclass.');
            end
            
            if ~exist('slice_plane', 'var')
                slice_plane = hdng.colour_mapping.ColourMap.PLANE_XY;
            end
            
            if ~exist('mode', 'var')
                mode = hdng.colour_mapping.ColourMap.SLICE_MODE;
            end
            
            [results, legend] = obj.apply2(batch, mode, slice_plane);
        end
        
        function [results, legend] = apply2(obj, batch, mode, slice_plane)
            
            if ~exist('slice_plane', 'var')
                slice_plane = hdng.colour_mapping.ColourMap.PLANE_XY;
            end
            
            if ~exist('mode', 'var')
                mode = hdng.colour_mapping.ColourMap.SLICE_MODE;
            end
            
            slices = obj.disassemble_batch_slices(batch, slice_plane);
            
            N = size(slices, 2);
            L = size(slices, 1);
            
            if strcmp(mode, hdng.colour_mapping.ColourMap.SLICE_MODE)
                
                scopes = slices(:);
                
            elseif strcmp(mode, hdng.colour_mapping.ColourMap.LAYER_MODE)
                
                scopes = cell(L, 1);
                
                for i=1:L
                    scopes{i} = cat(2, slices{i, :});
                end
                
            elseif strcmp(mode, hdng.colour_mapping.ColourMap.VOLUME_MODE)
                
                scopes = cell(N, 1);
                
                for i=1:N
                    scopes{i} = cat(1, slices{:, i});
                end
                
            elseif strcmp(mode, hdng.colour_mapping.ColourMap.BATCH_MODE)
                
                scopes = { batch };
            else
                error('ColourMap.apply(): Unknown mode %s', mode);
            end
            
            [scopes, legend] = obj.apply_to_scopes(scopes);
            
            
            if strcmp(mode, hdng.colour_mapping.ColourMap.SLICE_MODE)
                
                image_slices = reshape(scopes, L, N);
                
            elseif strcmp(mode, hdng.colour_mapping.ColourMap.LAYER_MODE)
                
                
                image_slices = [];
                
                for i=1:L
                    
                    row = cell(1, N);
                    scope = scopes{i};
                    
                    for j=1:N
                        row{j} = scope(j);
                    end
                    
                    image_slices = [image_slices; row]; %#ok<AGROW>
                end
                
            elseif strcmp(mode, hdng.colour_mapping.ColourMap.VOLUME_MODE)
                
                
                image_slices = [];
                
                for i=1:L
                    
                    column = cell(L, 1);
                    scope = scopes{i};
                    
                    for j=1:L
                        column{j} = scope(j);
                    end
                    
                    image_slices = [image_slices, column]; %#ok<AGROW>
                end
                
                
            elseif strcmp(mode, hdng.colour_mapping.ColourMap.BATCH_MODE)
                
                results = scopes{1};
                return;
            else
                error('ColourMap.apply(): Unknown mode %s', mode);
            end
            
            results = obj.assemble_batch_slices(image_slices, slice_plane);
        end
        
        
        function slices = disassemble_batch_slices(~, batch, slice_plane)
            
            if strcmp(slice_plane, hdng.colour_mapping.ColourMap.PLANE_XY)
                layer_dimension = 3;
            elseif strcmp(slice_plane, hdng.colour_mapping.ColourMap.PLANE_XZ)
                layer_dimension = 2;
            elseif strcmp(slice_plane, hdng.colour_mapping.ColourMap.PLANE_YZ)
                layer_dimension = 1;
            else
                error('ColourMap.apply(): Unknown slice plane %s', slice_plane);
            end
            
            N = numel(batch);
            
            blank_row = cell(1, N);
            slices = [];
            layer_index = 1;
            
            while true
                
                volumes_per_layer = 0;
                layer_row = blank_row;
                
                for volume_index=1:N
                    
                    volume = batch{volume_index};

                    d = size(volume);

                    if numel(d) < 3
                        d = [d, 1]; %#ok<AGROW>
                    end
                    
                    L = d(layer_dimension);
                    
                    if layer_index > L
                        continue
                    end
                    
                    S = {':', ':', ':'};
                    S{layer_dimension} = layer_index;
                    S = substruct('()', S);

                    layer_row{volume_index} = { subsref(volume, S) };
                    
                    volumes_per_layer = volumes_per_layer + 1;
                end
                
                if volumes_per_layer == 0
                    break;
                end
                
                slices = [slices; layer_row]; %#ok<AGROW>
                
                layer_index = layer_index + 1;
            end
            
        end
        
        function batch = assemble_batch_slices(~, slices, slice_plane)
            
            if strcmp(slice_plane, hdng.colour_mapping.ColourMap.PLANE_XY)
                layer_dimension = 3;
                slice_dimensions = [1, 2];
            elseif strcmp(slice_plane, hdng.colour_mapping.ColourMap.PLANE_XZ)
                layer_dimension = 2;
                slice_dimensions = [1, 3];
            elseif strcmp(slice_plane, hdng.colour_mapping.ColourMap.PLANE_YZ)
                layer_dimension = 1;
                slice_dimensions = [2, 3];
            else
                error('ColourMap.apply(): Unknown slice plane %s', slice_plane);
            end
            
            N = size(slices, 2);
            L = size(slices, 1);
            
            batch = cell(1, N);
            
            for i=1:N
            
                volume_slices = slices(:, i);
                
                volume = [];
                
                for j=1:L
                    slice = volume_slices{j};
                    slice = slice{1};
                    d = size(slice);

                    if numel(d) < 3
                        d = [d, 1]; %#ok<AGROW>
                    end
                    
                    k = ones(1, 4);
                    k(slice_dimensions(1)) = d(1);
                    k(slice_dimensions(2)) = d(2);
                    k(4) = d(3);
                    
                    slice = reshape(slice, k); 
                    
                    volume = cat(layer_dimension, volume, slice);
                end
                
                batch{i} = volume;
            end
        end
        
        
        function [results, legend] = apply_to_scopes(obj, scopes) %#ok<STOUT,INUSD>
        	error('ColourMap2.apply() must be implemented by a subclass.');
        end
        
    end
    
    methods (Static)
    end
    
    methods (Static, Access=private)
    end
    
end
