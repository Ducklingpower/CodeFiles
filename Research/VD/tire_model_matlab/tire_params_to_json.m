function tire_params_to_json(p, outFile)
%TIRE_PARAMS_TO_JSON  Write a tuned parameter struct back out in the exact
%   format WheelController expects, i.e. drop-in for
%   ~/PAIRSIM_config/Parameters/{Front,Rear}AxleTireParams.json
%
%   tire_params_to_json(p, '~/PAIRSIM_config/Parameters/FrontAxleTireParams.json')
%
%   Unity's JsonUtility matches fields by name and ignores extras, but it is
%   picky about types, so every scalar is emitted as a float literal and
%   numPointsFrictionMap as an int. Fields that only exist on the MATLAB
%   side (name, useThermal, tAmb) are dropped.
%
%   Restart the sim after writing -- the file is read once in
%   WheelController.Start (WheelController.cs:246).

if nargin < 2 || isempty(outFile)
    error('tire_params_to_json:noFile', 'Give an output path.');
end
if outFile(1) == '~'
    home = getenv('HOME');
    if isempty(home), home = getenv('USERPROFILE'); end
    outFile = fullfile(home, outFile(2:end));
end

scalars = {'FzNom','Dy','Dy2','Cy','syPeak','relaxLenY','Dx','Dx2','Cx', ...
           'sxPeak','relaxLenX','rollResForce','wheelInertia','tyreRadius', ...
           'p1','p2','p3','p4','p5','p6','p7','mT','cT','hT','ACp'};

fid = fopen(outFile, 'w');
if fid < 0
    error('tire_params_to_json:cannotOpen', 'Could not open %s for writing.', outFile);
end
fprintf(fid, '{\n');
for k = 1:numel(scalars)
    fprintf(fid, '    "%s": %.10g,\n', scalars{k}, double(p.(scalars{k})));
end
fprintf(fid, '    "numPointsFrictionMap": %d,\n', round(p.numPointsFrictionMap));
fprintf(fid, '    "thermalFrictionMapInput": [%s],\n',  jsonList(p.thermalFrictionMapInput));
fprintf(fid, '    "thermalFrictionMapOutput": [%s]\n',  jsonList(p.thermalFrictionMapOutput));
fprintf(fid, '}\n');
fclose(fid);

fprintf('Wrote %s\n', outFile);
end

function s = jsonList(v)
v = double(v(:)).';
parts = arrayfun(@(x) sprintf('%.10g', x), v, 'UniformOutput', false);
s = strjoin(parts, ', ');
end
