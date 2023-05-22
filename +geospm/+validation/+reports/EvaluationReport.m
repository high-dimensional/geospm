% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef EvaluationReport < hdng.documents.Generator
    
    %EvaluationReport [Description]
    %
    
    properties
        table_row_key
    end
    
    properties (Dependent, Transient)
        ordered_table_keys
    end
    
    properties (GetAccess=private, SetAccess=private)
        table_keys_
        table_map_
        table_defaults_
    end
    
    methods
        
        function result = get.ordered_table_keys(obj)
            
            keys = obj.table_keys_.keys();
            order = zeros(numel(keys), 1);
            
            for k=1:numel(keys)
                key = keys{k};
                order(k) = obj.table_keys_(key);
            end
            
            result = keys(order);
        end
        
        function obj = EvaluationReport()
            obj = obj@hdng.documents.Generator();
            
            obj.table_keys_ = containers.Map('KeyType', 'char', 'ValueType', 'int64');
            obj.table_map_ = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.table_defaults_ = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            %{
            obj.table_keys_('threshold') = 1;
            obj.table_defaults_('threshold') = [];
            %}
            
            obj.table_row_key = '';
        end
        
        function add_table_key(obj, key, default)
            
            order = length(obj.table_keys_) + 1;
            obj.table_keys_(key) = order;
            
            if exist('default', 'var')
                obj.table_defaults_(key) = default;
            end
        end    
        
        function gather(obj, evaluation, experiment)
            
            if ~exist('experiment', 'var')
                experiment = {};
            end
            
            configuration = evaluation.configuration;
            method = configuration('method');
            
            contrast_field = 'contrast';
            
            if strcmp(method, 'Kriging')
                contrast_field = 'prediction';
            end
            
            parameters = struct();
            keys = obj.table_keys_.keys();
            
            for k=1:numel(keys)
                key = keys{k};
                
                value = configuration.values(key);
                
                if isa(value, 'hdng.utilities.DictionaryError')
                    if isKey(obj.table_defaults_, key)
                        value = obj.table_defaults_(key);
                    else
                        value = '-';
                    end
                else
                    value = value.label;
                end
                
                parameters.(key) = value;
            end
            
            row_value = configuration.values(obj.table_row_key).label;
            
            all_term_results = evaluation.results('terms').content;
            threshold_index = all_term_results.value_index_for_name('threshold');
            thresholds = threshold_index.values;
            
            for t=1:numel(thresholds)
                threshold = thresholds{t};

                if threshold.is_null
                    continue;
                end
                
                if strcmp(obj.table_row_key, 'threshold')
                    row_value = threshold.label;
                end
                
                selection = struct();
                selection.threshold = threshold;

                term_results = all_term_results.select(selection);

                term_index = term_results.value_index_for_name('term');
                terms = term_index.values;
                
                parameters.('threshold') = threshold.label;

                for i=1:numel(terms)
                    term = terms{i};
                    term_records = term_index.records_for_value(term);

                    if numel(term_records) ~= 1
                        error('Unexpected number of records for term: %s', term.label);
                    end

                    term_record = term_records{1};

                    contrast = term_record(contrast_field).content;
                    result = term_record('result').content;
                    map = term_record('map').content;

                    column_label = term.label;

                    row_label = [row_value ' [Contrast]'];
                    obj.record_image(experiment, contrast.image.path, row_label, column_label, parameters);

                    row_label = [row_value ' [Mask]'];
                    obj.record_image(experiment, result.image.path, row_label, column_label, parameters);

                    row_label = [row_value ' [Map]'];
                    obj.record_image(experiment, map.image.path, row_label, column_label, parameters);
                end
            end
        end
        
        function document = layout(obj)
            document = hdng.documents.Document();
            
            tables = obj.table_map_.values();
            
            for i=1:numel(tables)
                entry = tables{i};
                table = entry{1};
                configuration = entry{2};
            
                obj.layout_table(document, table, configuration);
            end
        end
    end
    
    methods (Access=protected)
        
        
        function layout_table(obj, document, table, configuration)
            
            page_rows = 4;
            page_columns = 6;
            
            cell_counts = table.size;
            k_horizontal = idivide(cast(cell_counts(2), 'int64'), cast(page_columns, 'int64'), 'ceil');
            
            page_rows = cell_counts(1);

            for i=1:k_horizontal
                page = obj.create_page(document);
                page_number = numel(document.pages);
                
                options = struct();
                options.window = [1, (i - 1) * page_columns + 1, cell_counts(1), i * page_columns];
                options.window(4) = min(options.window(4), cell_counts(2));
                options.layout_size = [page_rows, page_columns];
                
                arguments = hdng.utilities.struct_to_name_value_sequence(options);
                view = hdng.documents.nodes.TableView(arguments{:});
                view.table = table;
                
                page.add_child(view);
                
                options = struct();
                options.content = sprintf('Page %d', page_number);
                
                keys = obj.ordered_table_keys;
                
                for k=1:numel(keys)
                    key = keys{k};
                    value = configuration.(key);
                    options.content = [options.content '  ' key ': ' value];
                end
                
                arguments = hdng.utilities.struct_to_name_value_sequence(options);
                text = hdng.documents.nodes.Text(arguments{:});
                
                text_container = hdng.documents.nodes.TextContainer();
                text_container.text = text;
                
                page.add_child(text_container);
            end
        end
        
        function page = create_page(~, document)
            
            options = struct();
            options.size = [sqrt(2), 1];
            options.margin = [0.05, 0.05];
            
            arguments = hdng.utilities.struct_to_name_value_sequence(options);
            
            page = hdng.documents.Page(arguments{:});
            
            document.add_page(page);
        end
        
        function record_image(obj, experiment, ...
                image_path, row_label, column_label, ...
                parameters)
            image = hdng.documents.nodes.ExternalImage('url', image_path);
            
            has_diagnostics = false;
            
            if ~isempty(experiment)
                has_diagnostics = ~isempty(experiment.diagnostics);
            end
            
            attributes = struct();
            attributes.class = {};
            
            if has_diagnostics
                attributes.class = [attributes.class; {'incomplete'}];
            end
            
            arguments = hdng.utilities.struct_to_name_value_sequence(parameters);
            table = obj.table_for_configuration(arguments{:});
            
            table(row_label, column_label) = image;
            table(row_label, column_label, 'html') = attributes;
        end
        
        function table = table_for_configuration(obj, varargin)
            
            configuration = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            keys = obj.ordered_table_keys;
            
            table_key = '';
            
            for k=1:numel(keys)
                key = keys{k};
                value = '–';
                
                if isfield(configuration, key)
                    value = configuration.(key);
                end
                
                if ~isempty(value)
                    table_key = [table_key value]; %#ok<AGROW>
                end
                
                if k < numel(keys)
                    table_key = [table_key ':']; %#ok<AGROW>
                end
            end
            
            if ~isKey(obj.table_map_, table_key)
                table = hdng.documents.nodes.Table();
                obj.table_map_(table_key) = {table, configuration};
            else
                entry = obj.table_map_(table_key);
                table = entry{1};
            end
        end
    end
    
    methods (Static, Access=public)
    end
    
end
