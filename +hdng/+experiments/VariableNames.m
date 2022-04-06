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

classdef VariableNames < hdng.experiments.ValueGenerator
    
    %VariableNames Provides an iterator over a list of values.
    %
    
    properties
        dataset_url_requirement
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = VariableNames()
            obj = obj@hdng.experiments.ValueGenerator();
            obj.dataset_url_requirement = 'dataset_url';
        end
        
    end
    
    methods (Access=protected)
        
        function result = create_iterator(obj, arguments)
            
            dataset_url = arguments.(obj.dataset_url_requirement);
            
            
            loader = hdng.utilities.DataLoader();

            [~, ~, columns] = loader.load_from_file(dataset_url);
            
            names = cell(numel(columns), 1);
            
            for index=1:numel(columns)
                names{index} = columns{index}.label;
            end
            
            value = hdng.experiments.Value.from(names);
            result = hdng.experiments.ValueListIterator({value});
        end
    end
    
    methods (Static, Access=public)
        
        function generator = from(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            generator = hdng.experiments.VariableNames();
            
            if isfield(options, 'dataset_url_requirement')
                generator.dataset_url_requirement = options.dataset_url_requirement;
            end
        end
    end
    
end
