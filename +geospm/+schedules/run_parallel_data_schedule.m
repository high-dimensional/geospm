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

function run_parallel_data_schedule(study_random_seed, study_directory, ... 
            file_specifier, model_specifiers, run_mode, varargin)
    
    
    %geospm.validation.SpatialExperiment.REGULAR_MODE
    
    %{
    
        model_specifier:
    
        label
        variables
        interactions
    %}
    

    MATLAB_EXEC = fullfile(matlabroot, 'bin', 'matlab');
    PARENT_DIRECTORY = fileparts(mfilename('fullpath'));
    BARRIER_SCRIPT = fullfile(PARENT_DIRECTORY, 'barrier.sh');
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    if ~isfield(options, 'do_debug')
        options.do_debug = false;
    end
    
    PROCESS_ID_FILE = fullfile(study_directory, 'running_pids.txt');
    PROCESS_LOG_FILE = fullfile(study_directory, 'completed.txt');

    INTERVAL = 0;
    WAIT_INTERVAL = 10;
    
    if ~options.do_debug
        hdng.utilities.save_text('', PROCESS_ID_FILE);
    end

    model_directories = cell(numel(model_specifiers), 1);

    for i=1:numel(model_specifiers)
        model_specifier = model_specifiers{i};
        
        model_directory = fullfile(study_directory, model_specifier.label);
        model_directories{i} = model_directory;
        
        [dirstatus, dirmsg] = mkdir(model_directory);
        if dirstatus ~= 1; error(dirmsg); end
        
        log_path = fullfile(model_directory, [model_specifier.label '.log']);
        
        command = create_model_command(study_random_seed, model_directory, file_specifier, model_specifier, run_mode, options);
        
        if options.do_debug
            eval(command);
        else
            matlab_options = ' -nodesktop -nodisplay -nosplash';

            execute = ['(echo "' command '" | ' MATLAB_EXEC matlab_options ' > "' log_path '" 2>&1) & echo $!'];
            [~, cmdout] = system(execute);
            %fprintf(cmdout);

            hdng.utilities.save_text([cmdout(1:end-numel(newline)) ':' model_directory newline], PROCESS_ID_FILE, 'append');
            
            INTERVAL = INTERVAL + 1;

            if mod(INTERVAL, WAIT_INTERVAL) == 0
                timestamp = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy/MM/dd HH:mm:ss');

                fprintf([char(timestamp) ': Waiting for processing slots...' newline]);
                execute = [BARRIER_SCRIPT ' -p ' '"' PROCESS_ID_FILE '" -l "' PROCESS_LOG_FILE '" -w 20'];
                [~, cmdout] = system(execute);
                fprintf(cmdout);
            end
        end
    end

    timestamp = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy/MM/dd HH:mm:ss');

    fprintf([char(timestamp) ': Waiting for completion...' newline]);
    execute = [BARRIER_SCRIPT ' -p ' '"' PROCESS_ID_FILE '" -l "' PROCESS_LOG_FILE '" -w 20'];
    [~, cmdout] = system(execute);
    fprintf(cmdout);
    
    record_arguments = cell(numel(model_specifiers), 1);

    for i=1:numel(record_arguments)
        argument = struct();
        argument.path = fullfile(model_directories{i}, 'records.json.gz');
        argument.rebase_paths = struct();
        argument.rebase_paths.dir_regexp = ['^([^' filesep ']).+$'];
        argument.rebase_paths.dir_replacement = [model_specifiers{i}.label filesep];
        argument.rebase_paths.dir_mode = 'before';
        
        record_arguments{i} = argument;
    end
    
    records = hdng.experiments.load_records(record_arguments{:});
    
    records_path = fullfile(study_directory, 'records.json.gz');
    hdng.experiments.save_records(records, records_path);
    
    records_path = fullfile(study_directory, 'debug_records.json');
    hdng.experiments.save_records(records, records_path);
end

function result = create_model_command(study_random_seed, study_directory, file_specifier, model_specifier, run_mode, options)
    
    optional_arguments = struct_to_literal(options, true, '    ');
    
    if ~isempty(optional_arguments)
        optional_arguments = [', ' optional_arguments];
    end
    
    linesep = '';
    argsep = [linesep '  '];
    
    result = sprintf('geospm.schedules.run_data_schedule(%d,%s%s,%s%s,%s%s,%s%s%s);', ...
                study_random_seed, ...
                argsep, ...
                char_to_literal(study_directory), ...
                argsep, ...
                struct_to_literal(file_specifier, false, '    '), ...
                argsep, ...
                ['{' struct_to_literal(model_specifier, false, '    ') '}'], ...
                argsep, ...
                char_to_literal(run_mode), ...
                optional_arguments);
end

function result = char_to_literal(value)
    result = ['''' regexprep(value,'([[\]{}()=''.(),;:%%{%}!@])', '\\$1') '''' ];
end

function literal = value_to_literal(value, do_inline, indent)

    if ~exist('do_inline', 'var')
        do_inline = false;
    end
    
    if ~exist('indent', 'var')
        indent = '  ';
    end
    linesep = '';
    literal = '';

    if isnumeric(value) || islogical(value)
        rows = num2str(value);

        for r=1:size(rows, 1)
            row = rows(r, :);
            if r > 1
                separator = '; ';
            else
                separator = '';
            end

            literal = [literal separator row]; %#ok<AGROW>
        end

        if ~isscalar(value)
            literal = ['[' literal ']'];
        elseif islogical(value)
            if value
                literal = 'true';
            else
                literal = 'false';
            end
        end
    elseif ischar(value)
        literal = char_to_literal(value);
    elseif iscell(value)
        literal = cell_to_literal(value, do_inline, indent);
    elseif isstruct(value)
        literal = [linesep indent struct_to_literal(value, do_inline, [indent '  '])];
    else
        error('Cannot serialize value of type %s', class(value));
    end
end

function result = struct_to_literal(S, do_inline, indent)

    if ~exist('do_inline', 'var')
        do_inline = false;
    end
    
    if ~exist('indent', 'var')
        indent = '  ';
    end

    if ~do_inline
        result = 'hdng.one_struct(';
    else
        result = '';
    end
    
    linesep = '';
    names = fieldnames(S);
    
    for i=1:numel(names)
        name = names{i};
        
        if i > 1
            result = [result ', ' linesep indent]; %#ok<AGROW>
        end
        
        name_literal = value_to_literal(name);
        result = [result name_literal ', ']; %#ok<AGROW>
        
        value = S.(name);
        literal = value_to_literal(value);
        
        result = [result literal]; %#ok<AGROW>
    end
    
    if ~do_inline
        result = [result ')'];
    end
end


function result = cell_to_literal(C, do_inline, indent)

    if ~exist('do_inline', 'var')
        do_inline = false;
    end
    
    if ~exist('indent', 'var')
        indent = '  ';
    end

    linesep = '';
    
    if ~do_inline
        result = '{';
    else
        result = '';
    end
    
    for r=1:size(C, 1)
        
        row = C(r, :);
        
        row_text = '';
        
        for c=1:size(C, 2)
            value = value_to_literal(row{c});
            
            if c > 1
                row_text = [row_text ' ']; %#ok<AGROW>
            end
            
            row_text = [row_text value]; %#ok<AGROW>
        end
        
        if r > 1
            result = [result '; ' linesep indent]; %#ok<AGROW>
        end
        
        result = [result row_text]; %#ok<AGROW>
        
    end
    
    if ~do_inline
        result = [result '}'];
    end
end
