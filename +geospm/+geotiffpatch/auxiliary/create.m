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

function create()
    
    [directory, ~, ~] = fileparts(mfilename('fullpath'));
    patch_path = fullfile(directory, 'patch.m');
    patch_text = hdng.utilities.load_text(patch_path);
    
    parts = split(directory, filesep);
    directory = join(parts(1:end - 1), filesep);
    directory = directory{1};
    
    patch = hdng.patch.Patch(directory);
    
    check = hdng.patch.actions.Check();
    check.function_path = 'auxiliary/is_required.m';
    
    patch.impl.add_action(check);
    
    cf = hdng.patch.actions.ChangeFunction();
   
    cf.file_name = 'geotiffwrite.m';
    
    cf.file_location = hdng.patch.WhichContainer();
    cf.file_location.which_item = 'geotiffwrite';
    cf.file_location.local_path = '';
    
    cf.function_name = 'validatePhotometricWithImage';
    cf.match_arguments = {'TiffTags', 'A'};
    cf.match_return_values = 0;
    cf.body_text = patch_text;
    
    cf.install_location = hdng.patch.Local();
    cf.install_location.path = '+patched';
    
    patch.impl.add_action(cf);
    
    intercept = hdng.patch.actions.FileIntercept();
    intercept.file_name = 'geotiffwrite.m';
    
    intercept.file_location = hdng.patch.Local();
    intercept.file_location.path = '+patched';
    
    intercept.intercept_location = hdng.patch.Local();
    intercept.intercept_location.path = '';
    
    intercept.variables.function_name = 'geotiffwrite';
    intercept.variables.function_prefix = 'geospm.geotiffpatch.patched.';
    intercept.variables.arguments = 'varargin';
    intercept.variables.forward_arguments = 'varargin{:}';
    intercept.variables.return_values = '';
    
    patch.impl.add_action(intercept);
    
    copy = hdng.patch.actions.Copy();
    copy.source_location = hdng.patch.WhichContainer();
    copy.source_location.which_item = 'geotiffwrite';
    copy.source_location.local_path = 'private';
    copy.destination_location = hdng.patch.Local();
    copy.destination_location.path = '+patched/private';
    
    patch.impl.add_action(copy);
    
    patch.save();
    patch.apply();
    patch.load();
end
