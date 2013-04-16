function Obj=SOFAconvertARI2SOFA(hM,meta,stimPar)
% OBJ=ARI2SOFA(hM,meta,stimPar) converts the HRTFs described in hM, meta, and
% stimPar (see ARI HRTF format) to a SOFA object.
%

% Copyright (C) 2012-2013 Acoustics Research Institute - Austrian Academy of Sciences;
% Licensed under the EUPL, Version 1.1 or � as soon they will be approved by the European Commission - subsequent versions of the EUPL (the "Licence")
% You may not use this work except in compliance with the Licence.
% You may obtain a copy of the Licence at: http://joinup.ec.europa.eu/software/page/eupl
% Unless required by applicable law or agreed to in writing, software distributed under the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the Licence for the specific language governing  permissions and limitations under the Licence. 


%% Get an empy conventions structure
Obj = SOFAgetConventions('SimpleFreeFieldHRIR');

%% Fill data with data
Obj.Data.IR = shiftdim(hM,1); % hM is [N M R], data.IR must be [M R N]
Obj.Data.SamplingRate = stimPar.SamplingRate;

%% Fill with attributes
if isfield(stimPar, 'SubjectID'), Obj.GLOBAL_SubjectID = stimPar.SubjectID; end
Obj.GLOBAL_DatabaseName = 'ARI';
Obj.GLOBAL_ApplicationName = 'ARI2SOFA';
Obj.GLOBAL_ApplicationVersion = '0.0.1';
Obj.GLOBAL_Organization = 'Acoustics Research Institute';
Obj.GLOBAL_AuthorContact = 'piotr@majdak.com';

%% Fill the mandatory variables
Obj.ListenerPosition = [1.2 0 0];
Obj.ListenerView = [0 0 0];
Obj.ListenerUp = [1.2 0 1];
Obj.ListenerRotation = [meta.pos(1:size(hM,2),1) meta.pos(1:size(hM,2),2) zeros(size(hM,2),1)];

%% Update dimensions
Obj=SOFAupdateDimensions(Obj);

%% Fill with some additional data
Obj.GLOBAL_History='Converted from the ARI format';
if size(meta.pos,2)>2, Obj=SOFAaddVariable(Obj,'MeasurementSourceAudioChannel','M',meta.pos(1:size(hM,2),3)); end
Obj=SOFAaddVariable(Obj,'MeasurementAudioLatency','MR',meta.lat);