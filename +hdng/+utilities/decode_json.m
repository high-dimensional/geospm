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

function result = decode_json(argument)
%decode_json Decode argument as a JSON string.
%
    persistent manager;
    persistent engine;
    
    if isempty(manager)
        manager = javax.script.ScriptEngineManager();
        engine = manager.getEngineByName("javascript");
    end
    
    script = ['Java.asJSONCompatible(' argument ')'];
    result = engine.eval(script);
    result = hdng.utilities.value_from_java_json(result);
end
