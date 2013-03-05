function NETCDFsave(filename,Dataset,Compression)
%NETCDFSAVE
%   NETCDFsave(filename,Dataset,Compression) saves all data and metadata to
%   a SOFA file.

% SOFA API - function matlab/NETCDFsave
% Copyright (C) 2012 Acoustics Research Institute - Austrian Academy of Sciences
% Licensed under the EUPL, Version 1.1 or � as soon they will be approved by the European Commission - subsequent versions of the EUPL (the "Licence")
% You may not use this work except in compliance with the Licence.
% You may obtain a copy of the Licence at: http://www.osor.eu/eupl
% Unless required by applicable law or agreed to in writing, software distributed under the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the Licence for the specific language governing  permissions and limitations under the Licence. 

%% --------------------- check and prepare variables ----------------------
varNames = fieldnames(Dataset);
numVars = size(varNames,1);
dimNames = SOFAgetDimensions();
SourceListenerVars=SOFAgetVariables('sourcelistener');
TransmitterReceiverVars=SOFAgetVariables('transmitterreceiver');
[M,R,N,T]=SOFAcheckDimensions(Dataset);

%% --------------------------- N E T C D F save ---------------------------
try
    ncid = netcdf.create(filename,'netcdf4');

    % define some constants and fixed dimensions
    float = netcdf.getConstant('NC_FLOAT');
    ScalarDimId = netcdf.defDim(ncid,dimNames.Scalar,1);
    CoordDimId = netcdf.defDim(ncid,dimNames.Coordinates,3);
%     UnlimitedDimId= netcdf.defDim(ncid,dimNames.Unlimited,netcdf.getConstant('NC_UNLIMITED'));
    MDimId = netcdf.defDim(ncid,dimNames.Measurements,M);
    RDimId = netcdf.defDim(ncid,dimNames.Receivers,R);
    NDimId = netcdf.defDim(ncid,dimNames.Samples,N);
		TDimId = netcdf.defDim(ncid,dimNames.Transmitters,T);

    netcdf.endDef(ncid);

    for ii=1:numVars % loop through all input variables
        currentVarName = varNames{ii};
				disp(currentVarName);
        currentVarValue = Dataset.(varNames{ii});
        
        % ------------------ check and prepare variables ------------------
        % -- convert all strings to cells --
        if ~isnumeric(currentVarValue) && ~isstruct(currentVarValue) % if currentVarValue is a string
            currentVarValue = cellstr(currentVarValue);
        end
        % dimensions (for length of string) if a cell only contains one string
        if ~isnumeric(currentVarValue) && ~isstruct(currentVarValue) % -- if currentVarValue is a string
            if size(currentVarValue,1) == 1 && size(currentVarValue,2) == 1 % [1 1]
                DimId = netcdf.defDim(ncid,[currentVarName 'DIM'],length(currentVarValue{1}));
            end
            if size(currentVarValue,1) == 1 && size(currentVarValue,2) > 1 % [1 x]
                xDimId = netcdf.defDim(ncid,[currentVarName 'xDIM'],size(currentVarValue,2));
                lengths=zeros(size(currentVarValue,2));
                for n=1:size(currentVarValue,2) % go through all strings up to x
                    lengths(n) = length(currentVarValue{n}); % store all string lengths
                end
                % length of dimension is maximum of all string lengths
                DimId = netcdf.defDim(ncid,[currentVarName 'DIM'],max(lengths));
            end
            if size(currentVarValue,1) == M && size(currentVarValue,2) == 1 % [M 1]
                lengths=zeros(M);
                for n=1:M % go through all strings up to x
                    lengths(n) = length(currentVarValue{n});
                end
                DimId = netcdf.defDim(ncid,[currentVarName 'DIM'],max(lengths));
            end
            if size(currentVarValue,1) == M && size(currentVarValue,2) > 1 % [M x]
                xDimId = netcdf.defDim(ncid,[currentVarName 'xDIM'],size(currentVarValue,2));
                lengths=zeros(M,size(currentVarValue,2));
                for n=1:M % go through all strings up to M and x (2D)
                    for m=1:size(currentVarValue,2)
                        lengths(n,m) = length(currentVarValue{n,m});
                    end
                end
                DimId = netcdf.defDim(ncid,[currentVarName 'DIM'],max(max(lengths)));
            end
        % dimensions of length x for normal, numeric variables, [1 x] or [M x]
        elseif ~(strcmp(currentVarName,'Data') || sum(strcmp(currentVarName,SourceListenerVars)) || ...
                 sum(strcmp(currentVarName,TransmitterReceiverVars)))
            if size(currentVarValue,2) > 1
                DimId = netcdf.defDim(ncid,[currentVarName 'xDIM'],size(currentVarValue,2)); 
            end
        end

        % ------------------------ variables ---------------------------
        if ~isnumeric(currentVarValue) && ~isstruct(currentVarValue) % --- define string variables ---
            % string variable, [1 1], [1 x], [M 1], [M x]
            if size(currentVarValue,1) == 1 && size(currentVarValue,2) == 1 % [1 1]
                VarId = netcdf.defVar(ncid,currentVarName,2,[ScalarDimId DimId]);
            end
            if size(currentVarValue,1) == 1 && size(currentVarValue,2) > 1 % [1 x]
                VarId = netcdf.defVar(ncid,currentVarName,2,[ScalarDimId xDimId DimId]);
            end
            if size(currentVarValue,1) == M && size(currentVarValue,2) == 1 % [M 1]
                VarId = netcdf.defVar(ncid,currentVarName,2,[MDimId ScalarDimId DimId]);
            end
            if size(currentVarValue,1) == M && size(currentVarValue,2) > 1 % [M x]
                VarId = netcdf.defVar(ncid,currentVarName,2,[MDimId xDimId DimId]);
            end
        else % --- define numeric variables ---
            if strcmp(currentVarName,'Data') % -- Data, float, [M R N]
                dataTypes=fieldnames(currentVarValue);
                for jj=1:length(dataTypes)
                    VarId(jj)=netcdf.defVar(ncid,['Data.' dataTypes{jj}],'double',[MDimId RDimId NDimId]);
                end 
            elseif sum(strcmp(currentVarName,SourceListenerVars))
                % -- positions and vectors, float, [1 3] or [M 3]
                if size(currentVarValue,1) > 1
                    VarId = netcdf.defVar(ncid,currentVarName,float,[MDimId CoordDimId]);
                else
                    VarId = netcdf.defVar(ncid,currentVarName,float,[ScalarDimId CoordDimId]);
                end

            elseif sum(strcmp(currentVarName,'ReceiverPosition'))
                % receiver position, float, [R 3], [R 3 M]
                if (size(currentVarValue,3) > 1)
                    VarId = netcdf.defVar(ncid,currentVarName,float,[RDimId CoordDimId MDimId]);
								else
                    VarId = netcdf.defVar(ncid,currentVarName,float,[RDimId CoordDimId ScalarDimId]);
                end
            elseif sum(strcmp(currentVarName,'TransmitterPosition'))
                % transmitter position, float, [T 3], [T 3 M]
                if (size(currentVarValue,3) > 1)
                    VarId = netcdf.defVar(ncid,currentVarName,float,[TDimId CoordDimId MDimId]);
								else
                    VarId = netcdf.defVar(ncid,currentVarName,float,[TDimId CoordDimId ScalarDimId]);
                end
            else % "normal" numeric variables, float, [1 1], [M 1], [1 x], [M x]
                if (size(currentVarValue,1) == 1) && (size(currentVarValue,2) == 1)
                    VarId = netcdf.defVar(ncid,currentVarName,float,ScalarDimId);
                end
                if (size(currentVarValue,1) == M) && (size(currentVarValue,2) == 1)
                    VarId = netcdf.defVar(ncid,currentVarName,float,[MDimId ScalarDimId]);
                end
                if (size(currentVarValue,1) == 1) && (size(currentVarValue,2) > 1)
                    VarId = netcdf.defVar(ncid,currentVarName,float,[ScalarDimId DimId]);
                end
                if (size(currentVarValue,1) == M) && (size(currentVarValue,2) > 1)
                    VarId = netcdf.defVar(ncid,currentVarName,float,[MDimId DimId]);
                end
            end
            netcdf.defVarDeflate(ncid,VarId,true,true,Compression); % Compression of data
        end

        % ------------------- write values to variables -----------------
        if ~isnumeric(currentVarValue) && ~isstruct(currentVarValue) % write string variables
            if size(currentVarValue,1) == 1 && size(currentVarValue,2) == 1 % [1 1]
                netcdf.putVar(ncid,VarId,char(currentVarValue));
            end
            if size(currentVarValue,1) == 1 && size(currentVarValue,2) > 1 % [1 x]
                for n=1:size(currentVarValue,2) % write elements of cell to variable one-by-one
                    netcdf.putVar(ncid,VarId,[0 n-1 0],[1 1 length(currentVarValue{n})],currentVarValue{n});
                end
            end
            if size(currentVarValue,1) == M && size(currentVarValue,2) == 1 % [M 1]
                for n=1:M % write elements of cell to variable one-by-one
                    netcdf.putVar(ncid,VarId,[n-1 0 0],[1 1 length(currentVarValue{n})],currentVarValue{n});
                end
            end
            if size(currentVarValue,1) == M && size(currentVarValue,2) > 1 % [M x]
                for n=1:M % write elements of cell to variable one-by-one
                    for m=1:size(currentVarValue,2)
                        netcdf.putVar(ncid,VarId,[n-1 m-1 0],[1 1 length(currentVarValue{n,m})],currentVarValue{n,m});
                    end
                end
            end
        elseif strcmp(currentVarName,'Data') % write data variables
            for jj=1:length(VarId)
                netcdf.putVar(ncid,VarId(jj),currentVarValue.(dataTypes{jj}));
            end
        else % numeric variables
            netcdf.putVar(ncid,VarId,currentVarValue);
        end
    end

    netcdf.close(ncid);

catch netcdfError
	disp(netcdfError);
	netcdf.abort(ncid);
	throw(netcdfError)
end

end %of function
