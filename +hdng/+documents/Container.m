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

classdef Container < hdng.documents.Node
    
    %Container [Description]
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        
        transform
        children
        
        margins
        padding
        
        opacity
    end
    
    properties (GetAccess=private, SetAccess=private)
        size_
        transform_
        children_
        
        opacity_
    end
    
    methods
        
        function result = obj.size(obj)
            result = obj.size_;
        end
        
        function result = get.transform(obj)
            result = obj.transform_;
        end
        
        function result = get.children(obj)
            result = obj.children_;
        end
        
        function result = get.opacity(obj)
            result = obj.opacity_;
        end
        
        function obj = Container(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'size')
                options.size = [1, 1];
            end
            
            if ~isfloat(options.size)
                error('hdng.documents.Container(): Expected float value for ''size'' argument.');
            end
            
            if ~isequal(size(options.size), [1, 2])
                error('hdng.documents.Container(): Expected 1x2 value for ''size'' argument.');
            end
            
            if ~isfield(options, 'transform')
                options.transform = eye(3, 3);
            end
            
            if ~isfloat(options.transform)
                error('hdng.documents.Container(): Expected float value for ''transform'' argument.');
            end
            
            if ~isequal(size(options.transform), [3, 3])
                error('hdng.documents.Container(): Expected 3x3 value for ''transform'' argument.');
            end
            
            if ~isfield(options, 'children')
                options.children = {};
            end
            
            if ~iscell(options.children)
                error('hdng.documents.Container(): Expected cell array for ''children'' argument.');
            end
            
            for i=1:numel(options.children)
                child = options.children{i};
                
                if ~isa(child, 'hdng.documents.Container')
                    error('hdng.documents.Container(): Expected child in ''children'' to be a Container.');
                end
            end
           
            if ~isfield(options, 'opacity')
                options.opacity = 1.0;
            end
            
            if ~isfloat(options.opacity)
                error('hdng.documents.Container(): Expected float value for ''opacity'' argument.');
            end
            
            if ~isequal(size(options.opacity), [1, 1])
                error('hdng.documents.Container(): Expected scalar value for ''opacity'' argument.');
            end
            
            if ~isfield(options, 'render_type')
                options.render_type = 'container';
            end
            
            super_options = options;
            super_options = rmfield(super_options, 'size');
            super_options = rmfield(super_options, 'transform');
            super_options = rmfield(super_options, 'opacity');
            
            arguments = hdng.utilities.struct_to_name_value_sequence(super_options);
            
            obj = obj@hdng.documents.Node(arguments{:});
            
            obj.size_ = double(options.size);
            obj.transform_ = double(options.transform);
            obj.children_ = options.children;
            obj.opacity_ = double(options.opacity);
        end
        
        function add_child(obj, child)
            
            if ~isa(child, 'hdng.documents.Container')
                error('Container.add_child(): Child must be a container.');
            end
            
            obj.children_ = [obj.children_; {child}];
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
