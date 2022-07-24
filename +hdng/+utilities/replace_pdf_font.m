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

function replace_pdf_font(file_path, font_map)
  
  global addedExtensions
  
  if isempty(addedExtensions)
      
      directory = fileparts(mfilename('fullpath'));
      directory = fileparts(directory);
      directory = fileparts(directory);
      jars_path = fullfile(directory, 'jars');
      
      
      javaaddpath(jars_path, '-end');
      addedExtensions = true;
  end
  
  % java.io.File;
  % org.apache.pdfbox.Loader
  
  %  PDType0Font.load(PDDocument, File) 
  
  BASE_FONT = org.apache.pdfbox.cos.COSName.BASE_FONT;
  
  file = java.io.File(file_path);
  document = org.apache.pdfbox.pdmodel.PDDocument.load(file);
  
  
  assigned_fonts = containers.Map('KeyType', 'char', 'ValueType', 'any');
  
  substitutes = keys(font_map);
  
  for index=1:numel(substitutes)
      font_name = substitutes{index};
      substitute_path = font_map(font_name);
      font_file = java.io.File(substitute_path);
      substitute_font = org.apache.pdfbox.pdmodel.font.PDType0Font.load(document, font_file);
      assigned_fonts(font_name) = substitute_font;
  end
  
  
  
  pages = document.getPages();
  
  for index=0:pages.getCount() - 1
      page = pages.get(index);
      resources = page.getResources();
      font_names = resources.getFontNames().toArray();
      
      for font_index=1:font_names.length
          
          font_key = font_names(font_index);
          font = resources.getFont(font_key);
          
          
          font_name = char(font.getName());
          
          if ~isKey(font_map, font_name)
              continue
          end
          
          %substitute_name = java.lang.String(font_map(font_name));
          
          %font.getCOSObject().setString(BASE_FONT, substitute_name);
          
          %if isa(font, 'org.apache.pdfbox.pdmodel.font.PDType1Font')
          %    font = font.getDescendantFont();
          %    font.getCOSObject().setString(BASE_FONT, substitute_name);
          %end
          
          %fontDescriptor = font.getFontDescriptor();
          %fontDescriptor.setFontName(substitute_name);
          
          substitute_font = assigned_fonts(font_name);
          resources.put(font_key, substitute_font);
      end
      
  end
  
  %[directory, name, ext] = fileparts(file_path);
  
  document.save(file);
  document.close();
end
