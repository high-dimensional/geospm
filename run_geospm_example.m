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

function varargout = run_geospm_example(id)

    delim1 = ['====================================' ...
              '===================================='];
         
    delim2 = ['------------------------------------' ...
              '------------------------------------'];
    
    varargout = {};
    where = mfilename('fullpath');
    [base_dir, ~, ~] = fileparts(where);
    examples_dir = fullfile(base_dir, '+geospm', 'examples');
    
    if ~exist('id', 'var')
        
        [~, examples] = hdng.utilities.list_files(examples_dir);
        
        examples = sort(examples);
        
        text = [newline 'List of examples, each identifier is shown in '...
                'square brackets:' newline newline];
        
        ids = {};
        
        for i=1:numel(examples)
            
            path = examples{i};
            [~, example, ~] = fileparts(path);
            
            ids = [ids; {example}]; %#ok<AGROW>
            
            description = fullfile(path, 'description.txt');
            
            if exist(description, 'file')
                description = hdng.utilities.load_text(description);
            else
                description = '[No description available]';
            end
            
            description = hdng.utilities.wrap_text(description, false, 72);
            
            text = [text sprintf(['[%s]' newline ...
                    delim2 newline ...
                    description newline...
                    newline ...
                    newline], example)]; %#ok<AGROW>
        end
        
        if nargout == 0
            fprintf([newline delim1 newline ...
                     'Re-run as ''run_geospm_example x'' ' ...
                     'where x is the example identifier.' ...
                     newline delim1 newline]);
            fprintf(text);
            return
        else
            varargout = {ids};
            return
        end
    end
    
    cwd = pwd;
    
    if strcmp(id, '*')
        
        [~, examples] = hdng.utilities.list_files(examples_dir);
        examples = sort(examples);
    else
        examples = {fullfile(examples_dir, id)};
    end
    
    for i=1:numel(examples)

        try
            example_path = examples{i};
            [~, example_name, ~] = fileparts(example_path);
            
            fprintf(['Running example ''%s'':' newline], example_name);
            
            cd(example_path);
            
            [~] = which('load_geospm_example');

            [spatial_data, options] = load_geospm_example;

            arguments = hdng.utilities.struct_to_name_value_sequence(options);

            cd(cwd);

            result = geospm.compute('', spatial_data, true, arguments{:});
            
            hdng.utilities.save_text([example_name newline], ...
                fullfile(result.directory, [example_name '_example']));

        catch ME
            
            msg = getReport(ME);
            fprintf(['Example ''%s'' failed because of an exception:' newline '%s:' newline], example_name, msg);
        end
    end
end
