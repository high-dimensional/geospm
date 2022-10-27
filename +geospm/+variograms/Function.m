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

classdef Function < handle
    %Function 
    %   
    
    properties (Dependent, Transient)
        name
        parameter_names
        
        parameters
    end
    
    properties (GetAccess=protected, SetAccess=protected)
        parameters_
    end
    
    methods
        
        function obj = Function()
            obj.parameters_ = struct();
        end
        
        function result = get.name(obj)
            result = obj.access_name();
        end
        
        function result = get.parameter_names(obj)
            result = obj.access_parameter_names();
        end
        
        function result = get.parameters(obj)
            result = obj.access_parameters();
        end
        
        function set.parameters(obj, value)
            obj.assign_parameters(value);
        end
        
        function plot(obj, range_min, range_max, steps)
            
            [~] = gcf;
            
            ax = gca;
            axis(ax, 'equal', 'auto');
            
            [x, y] = obj.evaluate(range_min, range_max, steps);
            plot(x, y);
        end
        
        function [x, y] = evaluate(obj, range_min, range_max, steps) %#ok<INUSD,STOUT>
            error('Function.evaluate() must be implemented by a subclass.');
        end
    end
    
    methods (Static)
        
        function result = create_correlation_function(name)
            
            switch name
                case {'Bes', 'Bessel'}
                    result = geospm.variograms.correlations.Bessel();
                    
                case {'Cir', 'Circular'}
                    result = geospm.variograms.correlations.Circular();
                    
                case {'Exp', 'Exponential'}
                    result = geospm.variograms.correlations.Exponential();
                    
                case {'Gau', 'Gaussian'}
                    result = geospm.variograms.correlations.Gaussian();
                    
                case {'Mat', 'Matérn'}
                    result = geospm.variograms.correlations.Matern();
                
                case {'Nug', 'Nugget'}
                    result = geospm.variograms.correlations.Nugget();
                    
                case {'Sph', 'Spherical'}
                    result = geospm.variograms.correlations.Spherical();
                    
                case {'Ste', 'Stein'}
                    result = geospm.variograms.correlations.Stein();
                    
                case {'Wav', 'Wave'}
                    result = geospm.variograms.correlations.Wave();
                
                otherwise
                    error(['Function.create(): Unknown correlation function: ''' name '']);
            end
            
        end
    end
    
    methods (Access=protected)
        
        function result = access_name(obj) %#ok<STOUT,MANU>
            error('Function.access_name() must be implemented by a subclass.');
        end
        
        function result = access_parameter_names(obj) %#ok<STOUT,MANU>
            error('Function.access_parameter_names() must be implemented by a subclass.');
        end
        
        function result = access_parameters(obj)
            result = obj.parameters_;
        end
        
        function assign_parameters(obj, value)
            obj.parameters_ = value;
        end
    end
end
