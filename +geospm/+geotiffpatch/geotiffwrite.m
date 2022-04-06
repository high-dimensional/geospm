function geotiffwrite(varargin)
    
    persistent is_patch_up_to_date;

    if isempty(is_patch_up_to_date)
        [directory, ~, ~] = fileparts(mfilename('fullpath'));
        patch = hdng.patch.Patch(directory);
        patch.load();
        patch.apply();
        fprintf('Applied patch for %s at %s\n', 'geotiffwrite', patch.path);
        is_patch_up_to_date = true;
    end

    geospm.geotiffpatch.patched.geotiffwrite(varargin{:});
end
