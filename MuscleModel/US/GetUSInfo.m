function [DatStore] = GetUSInfo(Misc,DatStore)
%GetEMGInfo Reads the file with EMG information (.sto)., runs activation
%dynamics on the EMG data when asked and puts the EMG data in the right
%format (handles copies and so on).



% Author: Maarten Afschrift

boolUS = 0;
% check if the input is correct
if isfield(Misc,'UStracking') && Misc.UStracking == 1
    boolUS = 1;
    nF = length(Misc.USfile);
    if nF ~=length(DatStore)
        disp('Warning: number of US files is not equal to the number of IK or ID files.');
    end
end


if boolUS    
    % file information
    nFiles = length(Misc.USfile);
    % Load the data and check for errors
    % ERROR IN FOR LOOP PARAMETERS FIXED - 24/01/2020 JPCB
    for iF = 1:nFiles        
        % get information for the EMG constraints
        USfile(iF)      = importdata(Misc.USfile{iF});        
    end    
    % prevent errors with the headers
    for iF = 1:nF
        if ~isfield(USfile(iF),'colheaders')
            USfile(iF).colheaders = strsplit(USfile(1).textdata{end});
        end
    end
%     TOD0
%     check if we have to update the headers based on user input, but here
%     for the US input??
%     bool_updateheader   = 0;
%     if isfield(Misc,'EMGheaders') && ~isempty(Misc.EMGheaders);        
%         bool_updateheader=1;
%     end
    % verify if the selected muscles are in the model
    iF       = 1;    
    bool_error  = 0;
    IndError=zeros(length(Misc.USSelection),1);
    for i=1:length(Misc.USSelection)
        if ~any(strcmp(Misc.USSelection{i},DatStore(iF).MuscleNames))
            disp(['Could not find ' Misc.USSelection{i} ' in the model, update the Misc.USSelection structure']);
            bool_error=1;
            IndError(i)=1;
        end
    end
    % verify if the muscles in the .mot files are in the model
    USheaders  = USfile(iF).colheaders;
%     TOD0 see couple lines higher
%     check if we have to update the headers based on user input, but here
%     for the US input??
%     if bool_updateheader
%        USheaders      = Misc.USheaders; 
%     end
    for i=1:length(Misc.USSelection)
        if ~any(strcmp(Misc.EMGSelection{i},USheaders))
            if bool_updateheader == 0
                disp(['Could not find ' Misc.USSelection{i} ' in the header of the US file, Updata the headers of file: ' Misc.USfile]);
            else
                disp(['Could not find ' Misc.USSelection{i} ' in the header of the US file, Update the headers in:  Misc.USheaders']);
            end
            bool_error=1;
            IndError(i)=1;
        end
    end
    if bool_error ==1
        warning(['Removed several muscles with US information from the',...
            ' analysis because these muscles are not in the model, or do not span the selected DOFs (see above)']);
        Misc.USSelection(find(IndError)) = [];
    end    
    
    %% Process the data    
    for iF = 1:nF
        USdat              = USfile(iF).data;        
        [nfr, nc] = size(USdat);  
        % get the US data
        nIn = length(Misc.USSelection);
        USsel = nan(nfr,nIn);   USindices = nan(nIn,1);
        USselection = Misc.USSelection;
        for i=1:length(Misc.USSelection)
            ind = strcmp(Misc.USSelection{i},USheaders);
            USsel(:,i) = USdat(:,ind);
            USindices(i) = find(strcmp(Misc.USSelection{i},DatStore(iF).MuscleNames));
        end        

        DatStore(iF).US.nUS           = length(USindices);
        DatStore(iF).US.USindices     = USindices;
        DatStore(iF).US.USsel         = USsel;
        DatStore(iF).US.USselection   = USselection;
        DatStore(iF).US.time           = USdat(:,1);
        DatStore(iF).US.boolUS         = boolUS;
        DatStore(iF).US.USspline      = spline(DatStore(iF).US.time',DatStore(iF).US.USsel');        
    end   
else
    for iF = 1:length(DatStore)
        % Boolean in DatStore that US info is not used ?       
        DatStore(iF).US.nUS           = [];
        DatStore(iF).US.USindices     = [];
        DatStore(iF).US.USsel         = [];
        DatStore(iF).US.USselection   = [];
        DatStore(iF).US.boolUS         = boolUS;
    end    
end
