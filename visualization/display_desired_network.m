
%% Get which patient
if ~exist('dataName','var')
    dataName = 'HUP211_CCEP';
end


%% Get results directory
locations = cceps_files;
script_folder = locations.script_folder;
results_folder = locations.results_folder;
addpath(genpath(script_folder));

%% Load the output file
outfile = [results_folder,'out_',dataName,'.mat'];

if ~exist(outfile)
    error('Cannot find output file');
end

out = load(outfile);
out = out.out;

%% Unpack the structure
stim = out.stim;
elecs = out.elecs;
chLabels = out.chLabels;
ana = out.ana;
wav = out.waveform;
dataName = out.name;
how_to_normalize = out.how_to_normalize;
nchs = size(chLabels,1);
A = out.A;
ch_info = out.ch_info;


build_network(elecs,stim,wav,nchs,chLabels,ana,how_to_normalize,1);