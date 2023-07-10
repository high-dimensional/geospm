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

function result = unnest_records(record_array, nested, select, nested_select, nested_prefix)
    
    result = hdng.experiments.RecordArray();
    records = record_array.records;
    
    nested_missing = zeros(numel(records), 1, 'logical');
    nested_not_array = zeros(numel(records), 1, 'logical');

    for i=1:numel(records)
        record = records{i};
        
        if ~record.holds_key(nested)
            nested_missing(i) = true;
            continue
        end

        nested_record_value = record(nested);
        
        if ~strcmp(nested_record_value.type_identifier, 'builtin.records')
            nested_not_array(i) = true;
            continue
        end

        nested_record_array = nested_record_value.content;
        nested_records = nested_record_array.records;

        for j=1:numel(nested_records)
            nested_record = nested_records{j};

            new_record = hdng.utilities.Dictionary();
                        
            copy_attributes(new_record, record, select, '');
            copy_attributes(new_record, nested_record, nested_select, nested_prefix);
            
            result.include_record(new_record);
        end
    end
end

function copy_attributes(new_record, record, select, prefix)

    if isempty(select)
        tmp_select = record.keys();
    else
        tmp_select = select;
    end
    
    for s=1:numel(tmp_select)
        selector = tmp_select{s};

        if ~record.holds_key(selector)
            continue
        end

        new_record([prefix selector]) = record(selector);
    end
end