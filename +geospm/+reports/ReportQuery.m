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

classdef ReportQuery < handle
    
    %ReportQuery 
    %

    properties (GetAccess=public, SetAccess=public)
        
        
        slice_index     % the slice index of this data set
        
        min_location    % the min location for this data set
        max_location    % the max location for this data set

        cell_size       % the cell size of the data set grid
        
        record          % A record associated with this dataset
    end
    
    methods
        
        function obj = ReportQuery()

            obj.slice_index = [];
            obj.min_location = [];
            obj.max_location = [];
            obj.cell_size = [];
            obj.record = [];

        end
        
    end
end
