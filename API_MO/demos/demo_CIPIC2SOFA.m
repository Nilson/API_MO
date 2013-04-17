% Copyright (C) 2012-2013 Acoustics Research Institute - Austrian Academy of Sciences;
% Licensed under the EUPL, Version 1.1 or � as soon they will be approved by the European Commission - subsequent versions of the EUPL (the "Licence")
% You may not use this work except in compliance with the Licence.
% You may obtain a copy of the Licence at: http://joinup.ec.europa.eu/software/page/eupl
% Unless required by applicable law or agreed to in writing, software distributed under the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the Licence for the specific language governing  permissions and limitations under the Licence. 

%% Define parameters
% Subject index of the file to convert
subject=3;
% File name of the CIPIC file
CIPICfile='hrir_final';
% Data compression (0..uncompressed, 9..most compressed)
compression=1; % results in a nice compression within a reasonable processing time

%% start SOFA
[databasepath,f]=SOFAstart;

%% load CIPIC file
CIPICfn=[databasepath filesep 'CIPIC' filesep 'subject_' sprintf('%03d',subject) filesep CIPICfile '.mat'];
disp(['Loading: ' CIPICfn]);
CIPIC=load(CIPICfn);

%% convert
Obj=SOFAconvertCIPIC2SOFA(CIPIC);

%% save SOFA file
SOFAfn=[databasepath filesep 'SOFA' filesep 'CIPIC ' 'subject_' sprintf('%03d',subject) ' ' CIPICfile '.sofa'];
disp(['Saving:  ' SOFAfn])
SOFAsave(SOFAfn, Obj, compression); 