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

classdef HTMLContext < hdng.documents.RenderContext
    
    %HTMLContext [Description]
    %
    
    properties (Constant)
        HEAD_SECTION = 1
        BODY_SECTION = 2
    end
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
        sections_
    end
    
    methods
        
        function obj = HTMLContext()
            obj = obj@hdng.documents.RenderContext();
            
            obj.sections_ = cell(2, 1);
            
            for i=1:numel(obj.sections_)
                obj.sections_{i} = '';
            end
        end
        
        function result = format_output(obj)
            
            result = '';
            
            result = [result, sprintf('<!DOCTYPE html>\n')];
            result = [result, sprintf('<html lang="en">\n')];
            result = [result, sprintf('<head>\n')];
            result = [result, sprintf('<meta charset="utf-8">\n')];
            result = [result, obj.sections_{hdng.documents.renderers.HTMLContext.HEAD_SECTION}];
            result = [result, sprintf('</head>\n')];
            result = [result, sprintf('<body>\n')];
            result = [result, obj.sections_{hdng.documents.renderers.HTMLContext.BODY_SECTION}];
            result = [result, sprintf('</body>\n')];
            result = [result, sprintf('</html>\n')];
        end
        
        function save_output(obj, file_path)
            text = obj.format_output();
            hdng.utilities.save_text(text, file_path);
        end
        
        function text_fragment(obj, text, section)
            
            if ~exist('section', 'var')
                section = hdng.documents.renderers.HTMLContext.BODY_SECTION;
            end
            
            obj.sections_{section} = [obj.sections_{section} text];
        end
        
        function simple_tag(obj, tag, attributes, section)
            
            if ~exist('section', 'var')
                section = hdng.documents.renderers.HTMLContext.BODY_SECTION;
            end
            
            if ~exist('attributes', 'var')
                attributes = struct();
            end
            
            attribute_text = obj.format_attributes(attributes);
            tag_text = sprintf('<%s%s>\n', tag, attribute_text);
            
            obj.sections_{section} = [obj.sections_{section} tag_text];
        end
        
        function open_tag(obj, tag, attributes, section)
            
            if ~exist('section', 'var')
                section = hdng.documents.renderers.HTMLContext.BODY_SECTION;
            end
            
            if ~exist('attributes', 'var')
                attributes = struct();
            end
            
            attribute_text = obj.format_attributes(attributes);
            tag_text = sprintf('<%s%s>\n', tag, attribute_text);
            
            obj.sections_{section} = [obj.sections_{section} tag_text];
        end
        
        function close_tag(obj, tag, section)
            
            if ~exist('section', 'var')
                section = hdng.documents.renderers.HTMLContext.BODY_SECTION;
            end
            
            tag_text = sprintf('</%s>\n', tag);
            
            obj.sections_{section} = [obj.sections_{section} tag_text];
        end
    end
    
    methods (Access=protected)
        
        function result = format_attributes(~, attributes)
            result = '';

            is_dictionary = isa(attributes, 'hdng.utilities.Dictionary');
            
            if ~is_dictionary
                names = fieldnames(attributes);
            else
                names = attributes.keys();
            end

            for i=1:numel(names)
                name = names{i};
                if ~is_dictionary
                    value = attributes.(name);
                else
                    value = attributes(name);
                end
                
                result = [result name '="' char(value) '" ']; %#ok<AGROW>
            end
            
            if numel(result) ~= 0
                result = [' ' result(1:end - 1)];
            end
        end
        
    end
    
    methods (Static, Access=public)
    end
    
end
