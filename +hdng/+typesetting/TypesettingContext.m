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

classdef TypesettingContext < handle
    
    %TypesettingContext 
    %
    
    properties (GetAccess=public, SetAccess=private)
        font_family_changed
        font_weight_changed
        font_style_changed
        font_size_changed

        has_changes
    end
    
    properties (GetAccess=public, SetAccess=public)
    end
    
    properties (Dependent, Transient)
        style

        font_family
        font_weight
        font_style
        font_size

        units
    end
    
    properties (GetAccess=private, SetAccess=private)
        current_style_
        font_family_
        font_weight_
        font_style_
        font_size_

        units_
        figure_
        update_widget_
        widget_
    end
    
    methods
        
        function obj = TypesettingContext()
            obj.current_style_ = [];
            obj.font_family_ = 'Helvetica';
            obj.font_weight_ = 'normal';
            obj.font_style_ = 'normal';
            obj.font_size_  = 16;
            
            obj.font_family_changed = false;
            obj.font_weight_changed = false;
            obj.font_style_changed = false;
            obj.font_size_changed = false;
            obj.has_changes = false;
            
            obj.units_ = 'points';
            obj.figure_ = figure('Visible', 'off');
            obj.update_widget_ = true;
            obj.widget_ = uicontrol('Style', 'text', 'Visible', 'off');
        end

        function result = get.style(obj)
            result = obj.current_style_;
        end

        function result = get.font_family(obj)
            result = obj.font_family_;
        end
        
        function set.font_family(obj, value)
            obj.font_family_ = value;
            obj.update_widget_ = true;
        end

        function result = get.font_weight(obj)
            result = obj.font_weight_;
        end

        function set.font_weight(obj, value)
            obj.font_weight_ = value;
            obj.update_widget_ = true;
        end

        function result = get.font_style(obj)
            result = obj.font_style_;
        end
        
        function set.font_style(obj, value)
            obj.font_style_ = value;
            obj.update_widget_ = true;
        end

        function result = get.font_size(obj)
            result = obj.font_size_;
        end
        
        function set.font_size(obj, value)
            obj.font_size_ = value;
            obj.update_widget_ = true;
        end

        function result = get.units(obj)
            result = obj.units_;
        end
        
        function set.units(obj, value)
            obj.units_ = value;
            obj.update_widget_ = true;
        end
        
        function has_changes = update(obj, style)
            
            has_changes = false;

            if ~isempty(obj.current_style_) && obj.current_style_ == style
                return;
            end

            n_changes = 0;
            
            if ~isempty(style)
                
                obj.font_family_changed = ~strcmp(style.font_family, obj.font_family_);

                if obj.font_family_changed
                    obj.font_family = style.font_family;
                    n_changes = n_changes + 1;
                end
    
                obj.font_weight_changed = ~strcmp(style.font_weight, obj.font_weight_);

                if obj.font_weight_changed
                    obj.font_weight = style.font_weight;
                    n_changes = n_changes + 1;
                end

                obj.font_style_changed = ~strcmp(style.font_style, obj.font_style_);
    
                if obj.font_style_changed
                    obj.font_style = style.font_style;
                    n_changes = n_changes + 1;
                end

                obj.font_size_changed = style.font_size ~= obj.font_size_;
    
                if obj.font_size_changed
                    obj.font_size = style.font_size;
                    n_changes = n_changes + 1;
                end
            else
                obj.font_family_changed = true;
                obj.font_weight_changed = true;
                obj.font_style_changed = true;
                obj.font_size_changed = true;
            end
            
            obj.current_style_ = style;
            obj.has_changes = n_changes ~= 0;

            has_changes = n_changes ~= 0;
        end

        function [width, height] = measure(obj, string)

            widget = obj.access_widget();
            widget.String = string;

            result = widget.Extent;
            width = result(3);
            height = result(4);
        end

        function result = to_svg_attributes(obj, changes_only)

            if ~exist('changes_only', 'var')
                changes_only = false;
            end

            result = '';

            if obj.font_family_changed || ~changes_only
                result = [result sprintf('font-family="%s" ', obj.font_family)];
            end

            if obj.font_weight_changed || ~changes_only
                result = [result sprintf('font-weight="%s" ', obj.font_weight)];
            end

            if obj.font_style_changed || ~changes_only
                result = [result sprintf('font-style="%s" ', obj.font_style)];
            end

            if obj.font_size_changed || ~changes_only
                result = [result sprintf('font-size="%gpt"', obj.font_size)];
            end
        end
    end

    methods (Access=protected)

        function result = access_widget(obj)
            if obj.update_widget_
                obj.update_widget_ = false;
                obj.widget_.FontName = obj.font_family;
                obj.widget_.FontSize = obj.font_size;
                obj.widget_.FontUnits = 'points';
                obj.widget_.FontWeight = obj.font_weight;
                obj.widget_.FontAngle = obj.font_style;
                obj.widget_.Units = obj.units_;
                obj.widget_.String = '';
            end

            result = obj.widget_;
        end
    end
    
    methods (Access=public, Static)
    end
end
