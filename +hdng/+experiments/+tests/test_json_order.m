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

function test_json_order()

    records_path = locale_file('records-1.json');
    records = hdng.experiments.load_records(records_path);
    
    fprintf('Records 1\n');
    print_records(records);
    fprintf('\n\n');
    
    records_path = locale_file('records-2.json');
    hdng.experiments.save_records(records, records_path);
    
    records = hdng.experiments.load_records(records_path);
    
    fprintf('Records 2\n');
    print_records(records);
    fprintf('\n\n');
end

function path = locale_file(local_path)
    
    where = mfilename('fullpath');
    [base_dir, ~, ~] = fileparts(where);
    path = fullfile(base_dir, local_path);
end

function print_records(records)
    ordered_records = records.records;
    N = numel(ordered_records);
    
    for index=1:N
        record = ordered_records{index};
        
        threshold_or_statistic = record('threshold_or_statistic').label;
        term = record('term').label;
        
        fprintf('%s/%s\n', threshold_or_statistic, term);
    end 
end
