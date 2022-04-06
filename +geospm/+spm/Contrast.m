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

classdef Contrast < handle
    
    %Contrast 
    %
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    properties (GetAccess=public, SetAccess=public)
        statistic
        weights
        name
        order
        attachments
    end
    
    properties (Dependent, Transient)
        key
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Contrast()
            
            obj.statistic = 'T';
            obj.weights = 1;
            obj.name = 'contrast';
            obj.order = 0;
            obj.attachments = struct();
        end
        
        function result = get.key(obj)
            result = geospm.spm.Contrast.format_key(obj.statistic, obj.weights, obj.name);
        end
    end
    
    methods (Access=public, Static)
        
        function result = from_key(key)
            
            result = Contrast();
            
            string = key;
            parts = split(string, ':');
            result.statistic = parts{1};
            
            string = string(len(statistic) + 1:end);
            parts = split(string, '/');
            weights_string = parts{1};
            
            result.name = string(len(weights_string) + 1:end);
            result.weights = eval(['[' weights_string ']']);
            
        end
        
        function result = format_key(statistic, weights, name)
            
            weights_string = '';
            n_rows = size(weights, 1);
            n_cols = size(weights, 2);
            
            for row=1:n_rows
                for col=1:n_cols
                    value_string = sprintf('%.10g', weights(row, col));
                    
                    if strcmp(value_string, '-0')
                        value_string = '0';
                    end
                    
                    weights_string = [weights_string value_string]; %#ok<AGROW>
                    
                    if col + 1 <= n_cols
                        weights_string = [weights_string ' ']; %#ok<AGROW>
                    end
                end
                
                if row + 1 <= n_rows
                    weights_string = [weights_string ';' newline]; %#ok<AGROW>
                end
            end
            
            result = [statistic ':' weights_string '/' name];
        end
        
    end
end
