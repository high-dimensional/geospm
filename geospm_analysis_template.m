
file_path = 'some_data_file.csv';

% Define the columns in the CSV file we are interested in

data_columns = {
    'eid', 'easting', 'northing', ...
    'sex', 'age', 'bmi', 'household_income', ...
};

% Load the CSV file into a geospm.SpatialData object.
% The data are geographically registered via 'crs_identifier',
% in this instance the Ordnance Survey National Grid.
% For other coordinate systems, check https://epsg.io/.

spatial_data = geospm.load_data(file_path, ...
    'crs_identifier', 'EPSG:27700', ...
    'csv_delimiter', ',', ...
    'eastings_label', 'easting', ...
    'northings_label', 'northing', ...
    'mask_columns_with_missing_values', true, ...
    'mask_rows_with_missing_values', true, ...
    'include', data_columns );

output_directory = hdng.utilities.make_timestamped_directory();


parameters = geospm.Parameters();

% Define a grid for the analysis in the geographic coordinate system:
% The grid has its origin at min_location. Here, we specify that the longer
% side of the rectangle defined by min_location and max_location is
% subdivided into 70 cells, while the shorter side is aligned to the
% closest number of cells in proportion to the original rectangle. The
% resulting cells are square in geographic space.

parameters.define_grid(...
    spatial_data, ...
    'min_location', [388000, 269000], ...
    'max_location', [423000, 304000], ...
    'spatial_resolution_max', 70 ...
);

% We specify two levels of smoothing, the first Gaussian containing
% 95% of its probability mass within a diameter of 3500 metres, while the
% corresponding diameter for the second Gaussian is 7000 metres. The units
% are metres because of the chosen reference EPSG:27700.

parameters.smoothing_levels = [35, 70] * 100.0;
parameters.smoothing_levels_p_value = 0.95;
parameters.smoothing_method = 'default';

% We specify a two-sided t-test at a level of significance of 5 percent
% using family-wise error correction.

parameters.thresholds = {'T[1,2]: p<0.05 (FWE)'};

% Indicate that any significant areas should be traced and rendered as .shp
% files, which can be imported into QGIS.

parameters.trace_thresholds = true;

% Only analyse grid cells whose smoothing densities are at least 10 times
% the peak value of the respective Gaussian kernel, implying the presence
% of at least 10 observations or more at the location or in its
% neighbourhood.

parameters.apply_density_mask = true;
parameters.density_mask_factor = 10.0;

% Save images as geo-referenced TIFF files, which can be imported into
% QGIS.

parameters.add_georeference_to_images = true;

% Run the computation

[result, record] = geospm.compute(...
    output_directory, ... 
    spatial_data, ...
    true, ...
    parameters ...
);

