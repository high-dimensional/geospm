function geotiffwrite(varargin)
    
    persistent is_patch_up_to_date;
    
    if isempty(is_patch_up_to_date) || is_patch_up_to_date == false
        is_patch_up_to_date = false;
        
        [directory, ~, ~] = fileparts(mfilename('fullpath'));
        release_path = fullfile(directory, 'release');
        
        if exist(release_path, 'file')
            patch_release = hdng.utilities.load_text(release_path);
            current_release = version('-release');
            
            if ~strcmp(patch_release, current_release)
                patched_path = fullfile(directory, '+patched');
                hdng.utilities.rmdir(patched_path, true, false);
            else
                is_patch_up_to_date = true;
            end
        end
        
        if ~is_patch_up_to_date
            patch = hdng.patch.Patch(directory);
            patch.load();
            patch.apply();
            
            current_release = version('-release');
            hdng.utilities.save_text(current_release, release_path);
            
            fprintf('Applied patch for %s at %s\n', 'geotiffwrite', patch.path);
            is_patch_up_to_date = true;
        end
    end
    
    geospm.geotiffpatch.patched.geotiffwrite(varargin{:});
end
