

%{

fix timing in get waveforms

play around with waveform detector

consider additional processing (like a notch filter)

%}
tic
%% Parameters
% ieeg parameters
if ~exist('dataName','var')
    dataName = 'HUP212_CCEP';
end

% which waveform to plot
wav = 'N1';
how_to_normalize = 2;

% Stimulation parameters
stim.pulse_width = 300e-6; % pulse width in seconds
stim.train_duration = 30; % train duration (# stims) in seconds
stim.stim_freq = 1; % frequency (in Hz) of stimulation

% Plotting prep
mydir  = pwd;
idcs   = strfind(mydir,'/');
newdir = mydir(1:idcs(end)-1);

%% Get pw and ieeg location
locations = cceps_files; % Need to make a file pointing to you own path
pwfile = locations.pwfile;
if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end

%% Pull clinical info
clinical = pull_clinical_info(dataName);
stim.current = clinical.current;

%% Get EEG data
% Get times; this function needs to be updated as new patients are added
times = [clinical.start_time,clinical.end_time];

data = download_eeg(dataName,pwfile,times);
chLabels = data.chLabels;
% Remove leading zeros
chLabels = remove_leading_zeros(chLabels);

values = data.values;
stim.fs = data.fs;
t = toc;
fprintf('\nGot data in %1.1f minutes\n',t/60);


%% Get anatomic locations
% This function needs to be updated as new patients are added
ana = anatomic_location(chLabels,clinical,1);

%% Identify stimulation artifacts
% Loop over EEG
nchs = size(values,2);
artifacts = cell(nchs,1);
for ich = 1:nchs
    artifacts{ich} = find_stim_artifacts(stim,values(:,ich));
end
old_artifacts = artifacts;

%% Remove those that are not on beat
for ich = 1:nchs
    if isempty(old_artifacts{ich})
        continue;
    else
        on_beat = find_offbeat(old_artifacts{ich}(:,1),stim);
    end
    if ~isempty(on_beat)
        artifacts{ich} = [old_artifacts{ich}(on_beat(:,1),:),on_beat(:,2)]; 
    else
        artifacts{ich} = [];
    end
end


%% Narrow down the list of stimulation artifacts to just one channel each
elecs = define_ch(artifacts,stim,chLabels);


%% Say which electrodes have stim
%stim_chs = true_stim(dataName);
stim_chs = clinical.stim_electrodes;
[extra,missing,elecs] = find_missing_chs(elecs,stim_chs,chLabels);

%filtered_values = do_filters(values,stim.fs);

%% Perform signal averaging
elecs = signal_average(values,elecs,stim,chLabels,1);

%% Plot a long view of the stim and the relevant electrodes
%show_stim(elecs,values,data.chLabels,[])

%% Plot the average for an example
%{
figure
set(gcf,'position',[215 385 1226 413])
tight_subplot(1,1,[0.01 0.01],[0.15 0.10],[.02 .02]);
show_avg(elecs,stim,data.chLabels,'LB02','LA01')
%}

%% Identify CCEP waveforms
elecs = get_waveforms(elecs,stim,chLabels);

%% Build a network
[A,ch_info] = build_network(elecs,stim,wav,nchs,chLabels,ana,how_to_normalize,1);

%% Save info
out.name = dataName;
out.elecs = elecs;
out.stim = stim;
out.chLabels = chLabels;
out.waveform = wav;
out.how_to_normalize = how_to_normalize;
out.A = A;
out.ch_info = ch_info;
out.ana = ana;
out.extra = extra;
out.missing = missing;

save([newdir,'/cceps_results/',sprintf('out_%s',dataName)],'out');

%% Pretty plot
%pretty_plot(out,'LF1','LF6')
pretty_plot(out,'LJ1','LD7')
%pretty_plot(out,'LH5','LE7')

%show_avg(elecs,stim,chLabels,'LC6','LB9',wav,1)

