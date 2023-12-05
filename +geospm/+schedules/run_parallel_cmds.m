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

function run_parallel_cmds(cwd, cmd_specifiers, varargin)

    MATLAB_EXEC = fullfile(matlabroot, 'bin', 'matlab');
    PARENT_DIRECTORY = fileparts(mfilename('fullpath'));
    BARRIER_SCRIPT = fullfile(PARENT_DIRECTORY, 'barrier.sh');
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    if ~isfield(options, 'do_debug')
        options.do_debug = false;
    end

    PROCESS_ID_FILE = fullfile(cwd, 'cmd_running_pids.txt');
    PROCESS_LOG_FILE = fullfile(cwd, 'cmd_completed.txt');

    INTERVAL = 0;
    WAIT_INTERVAL = 10;
    
    if ~options.do_debug
        hdng.utilities.save_text('', PROCESS_ID_FILE);
    end

    for i=1:numel(cmd_specifiers)

        cmd_specifier = cmd_specifiers{i};
        
        [dirstatus, dirmsg] = mkdir(cmd_specifier.directory);
        if dirstatus ~= 1; error(dirmsg); end
        
        log_path = fullfile(cmd_specifier.directory, [cmd_specifier.identifier '.log']);
        
        [command, file_path] = create_model_mat_command(cmd_specifier);
        
        if options.do_debug
            geospm.schedules.run_cmd_from(file_path);
        else
            matlab_options = ' -nodesktop -nodisplay -nosplash';

            execute = ['(echo "' command '" | ' MATLAB_EXEC matlab_options ' > "' log_path '" 2>&1) & echo $!'];
            [~, cmdout] = system(execute);
            %fprintf(cmdout);

            hdng.utilities.save_text([cmdout(1:end-numel(newline)) ':' cmd_specifier.directory newline], PROCESS_ID_FILE, 'append');
            
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
end

function [result, filepath] = create_model_mat_command(cmd_specifier)
    
    filename = [cmd_specifier.identifier, '_command.mat'];
    filepath = fullfile(cmd_specifier.directory, filename);
    
    save(filepath, '-struct', 'cmd_specifier');
    
    result = sprintf('geospm.schedules.run_cmd_from(%s);', ...
                char_to_literal(filepath));
end

function result = char_to_literal(value)
    result = ['''' regexprep(value,'([[\]{}()=''.(),;:%%{%}!@])', '\\$1') '''' ];
end

function run(cmd)
    optional_args = hdng.utilities.struct_to_name_value_sequence(cmd.options);
    cmd_function = str2func(cmd.func);
    cmd_function(cmd.arguments{:}, optional_args{:});
end
