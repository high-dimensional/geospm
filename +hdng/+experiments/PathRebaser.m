% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef PathRebaser < hdng.experiments.ValueModifier
    
    %Convenience implementation of ValueModifier for re-basing path-related values.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=public, SetAccess=public)
        dir_regexp
        dir_replacement
        dir_mode
        source_ref
    end
    
    properties (GetAccess=public, SetAccess=private)
        json_format
    end
    
    methods
        
        function obj = PathRebaser()
            obj = obj@hdng.experiments.ValueModifier();

            obj.dir_regexp = '^.+$';
            obj.dir_replacement = '';
            obj.dir_mode = 'replace';

            obj.set_handler('builtin.slice_shapes', @handle_slice_shapes);
            obj.set_handler('builtin.volume', @handle_volume_reference);
            obj.set_handler('builtin.image_file', @handle_image_reference);
            obj.set_handler('builtin.file', @handle_file_reference);
            obj.set_handler('builtin.list', @handle_list);
            obj.set_handler('builtin.dict', @handle_dict);
            obj.set_handler('builtin.model_samples', @handle_model_samples);
            obj.set_handler('builtin.image_layer', @handle_image_layer);
            obj.set_handler('builtin.records', @handle_records);

            obj.json_format = hdng.experiments.JSONFormat();
            obj.source_ref = '';
        end

        function result = modify_path(obj, path)

            result = path;

            tokenExtents = regexp(path, obj.dir_regexp, 'tokenExtents');
            
            if isempty(tokenExtents) || isempty(tokenExtents{1})
                return
            end

            switch obj.dir_mode
                case 'before'
                    result = [path(1:tokenExtents{1}(1) - 1) obj.dir_replacement path(tokenExtents{1}(1):end)];
                case 'after'
                    result = [path(1:tokenExtents{1}(1) - 1) obj.dir_replacement path(tokenExtents{1}(2) + 1:end)];
                case 'replace'
                    result = [path(1:tokenExtents{1}(2)) obj.dir_replacement path(tokenExtents{1}(2) + 1:end)];
            end
        end
        
        function result = modify_source_ref(obj, source_ref)

            if isempty(obj.source_ref)
                result = source_ref;
                return;
            end

            result = obj.source_ref;
        end

        function result = handle_slice_shapes(obj, value)
            
            modified = hdng.experiments.SliceShapes();
            modified.origin = value.content.origin;
            modified.span = value.content.span;
            modified.resolution = value.content.resolution;
            modified.shape_paths = cell(size(value.content.shape_paths));

            if ~isempty(value.content.shape_paths)
                for i=1:numel(value.content.shape_paths)
                    modified.shape_paths{i} = obj.modify_path(value.content.shape_paths{i});
                end
            end

            modified.source_ref = obj.modify_source_ref(value.content.source_ref);
            modified.slice_names = value.content.slice_names;
            
            result = hdng.experiments.Value.from(modified, value.label);
        end
        
        function result = handle_volume_reference(obj, value)
            
            modified = hdng.experiments.VolumeReference();

            if ~isempty(value.content.image)
                modified.image = hdng.experiments.ImageReference( ...
                    obj.modify_path(value.content.image.path), ...
                    obj.modify_source_ref(value.content.image.source_ref));
            end

            if ~isempty(value.content.scalars)
                modified.scalars = hdng.experiments.FileReference( ...
                    obj.modify_path(value.content.scalars.path), ...
                    obj.modify_source_ref(value.content.scalars.source_ref));
            end

            modified.slice_names = value.content.slice_names;

            result = hdng.experiments.Value.from(modified, value.label);
        end

        function result = handle_image_reference(obj, value)
            
            modified = hdng.experiments.ImageReference();
            modified.path = obj.modify_path(value.content.path);
            modified.source_ref = obj.modify_source_ref(value.content.source_ref);

            label = value.label;

            if label == value.content.path
                label = modified.path;
            end

            result = hdng.experiments.Value.from(modified, label);
        end

        function result = handle_file_reference(obj, value)
            
            modified = hdng.experiments.FileReference();
            modified.path = obj.modify_path(value.content.path);
            modified.source_ref = obj.modify_source_ref(value.content.source_ref);
            
            label = value.label;

            if label == value.content.path
                label = modified.path;
            end


            result = hdng.experiments.Value.from(modified, label);
        end
        
        function result = handle_list(obj, value)
            
            modified = {};

            for index=1:numel(value.content)
                element = value.content{index};
                element_value = hdng.experiments.Value.from(element);
                element_value = obj.apply(element_value);
                modified{index} = element_value.content; %#ok<AGROW> 
            end
            
            result = hdng.experiments.Value.from(modified, value.label);
        end
        
        function result = handle_dict(obj, value)
            
            modified = hdng.utilities.Dictionary();

            keys = value.content.keys();

            for index=1:numel(keys)
                key = keys{index};
                key_value = value.content(key);
                key_value = hdng.experiments.Value.from(key_value);
                key_value = obj.apply(key_value);
                modified(key) = key_value.content;
            end
            
            result = hdng.experiments.Value.from(modified, value.label);
        end
        
        function result = handle_model_samples(obj, value)
            
            modified = geospm.validation.ModelSamples();
            
            modified.file = hdng.experiments.FileReference( ...
                obj.modify_path(value.content.file.path), ...
                obj.modify_source_ref(value.content.file.source_ref));
            modified.image = hdng.experiments.ImageReference( ...
                obj.modify_path(value.content.image.path), ...
                obj.modify_source_ref(value.content.image.source_ref));

            result = hdng.experiments.Value.from(modified);
        end
        
        function result = handle_image_layer(obj, value)
            
            modified = geospm.validation.ImageLayer();
            modified.identifier = value.content.identifier;
            modified.category = value.content.category;
            modified.blend_mode = value.content.blend_mode;
            modified.opacity = value.content.opacity;
            modified.priority = value.content.priority;

            modified.image = hdng.experiments.ImageReference( ...
                obj.modify_path(value.content.image.path), ...
                obj.modify_source_ref(value.content.image.source_ref));

            result = hdng.experiments.Value.from(modified);
        end
        
        function result = handle_records(obj, value)

            records = value.content;
            
            proxy = obj.json_format.build_proxy_from_records(records.records, records.attribute_map, struct(), @(name) records.value_index_for_name(name));
            
            modified_records = hdng.experiments.RecordArray();

            obj.json_format.build_records_from_proxy(proxy, modified_records, obj);
            modified_records.attachments = records.attachments;
            
            result = hdng.experiments.Value.from(modified_records, value.label);
        end

    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
end
