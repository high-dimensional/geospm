% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%#ok<*CPROPLC>

classdef TransformDomain < handle
    %TransformDomain Summary of this class goes here
    %   Detailed explanation goes here
    
    methods    
        
        function obj = TransformDomain()
        end
        
        function result = create_identity_transform(obj) %#ok<MANU,STOUT>
            error('TransformDomain.create_identity_transform() must be implemented by a subclass.');
        end
        
        function result = create_transform(obj, initialiser) %#ok<STOUT,INUSD>
            error('TransformDomain.create_transform() must be implemented by a subclass.');
        end
        
        function result = transform_to_string(obj, t) %#ok<STOUT,INUSD>
            error('TransformDomain.transform_to_string() must be implemented by a subclass.');
        end
        
        function result = create_sequence(obj, length_or_initialisers) %#ok<STOUT,INUSD>
            error('TransformDomain.create_sequence() must be implemented by a subclass.');
        end
        
        function result = multiply_transforms(obj, left, right) %#ok<STOUT,INUSD>
            error('TransformDomain.multiply_transforms() must be implemented by a subclass.');
        end
        
        function [x, y] = compute_step(obj, x, y, transform) %#ok<INUSD>
            error('TransformDomain.compute_step() must be implemented by a subclass.');
        end
    end
end
