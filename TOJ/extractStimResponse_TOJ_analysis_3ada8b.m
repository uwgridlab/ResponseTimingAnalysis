% this is from my z_constants
close all;clear all;clc
Z_ConstantsStimResponse;

DATA_DIR = 'C:\Users\djcald.CSENETID\Data\Subjects\3ada8b\data\d10\MATLAB_conversions\3ada8b_TOJ';
sid = SIDS{6};

% load in data
% ui box for input
list_str = {'1st block','2nd block'};

[s,v] = listdlg('PromptString','Pick experiment',...
    'SelectionMode','single',...
    'ListString',list_str);

folder_data = strcat(DATA_DIR);
if s == 1
    load(fullfile(folder_data,'TOJ-1.mat'))
    block = '1';
elseif s == 2
    load(fullfile(folder_data,'TOJ-2.mat'))
    block = '2';
end
%%
% load in data of interest
if s == 1
    stim = Stim.data;
else
    stim = [stim; Stim.data];
end
fsStim = Stim.info.SamplingRateHz;

clear Stim

clear ECO1 ECO2 ECO3

if s ==1
    tact = Tact.data;
else
    tact = [tact; Tact.data];
end
fsTact = Tact.info.SamplingRateHz;
clear Tact

plotIt = 1;
%%
% get that button press - threshold it
tact(tact(:,2) >= 0.009,2) = 0.009;

% check to makes ure it all is working
%[buttonPksTemp,buttonLocsTemp] = findpeaks(tact(:,2),fsTact,'minpeakdistance',2,'Minpeakheight',0.008);

tact(tact(:,2) < 0.009,2) = 0;
tact(:,2) = tact(:,2)*1000;

 %plot  inputs continuously through time
if plotIt
    plot_TOJ_concurrently(stim,tact,fsStim)
end
%%
% QUANTIFY RXN TIME TO CORTICAL STIM
[stimTimes,trainTimes] = extract_stimulation_times_TOJ_readIn(tact,fsStim,[]);
%%
[epochedTactor,epochedAudio,epochedStim,epochedButton,t,tSamps] = extract_epochs_TOJ(stim,tact,trainTimes,fsStim);
% epoched button press
%%
load
whichPerceived = 
%%
numTrials = size(epochedAudio,2);

if plotIt
    plot_epochs_TOJ(epochedStim,epochedTactor,epochedAudio,epochedButton,whichPerceived,t,numTrials)
end


%%

[tactorLocsVec,stimLocsVec,buttonLocsVec,tactorStimDiff,responseTimes] = get_response_timing_segs_TOJ(epochedButton,epochedTactor,epochedStim,t,tSamps,numTrials)


%%
saveIt = 0;

if saveIt
    current_direc = pwd;
    
    save(fullfile(current_direc, [sid '_TOJ_matlab.mat']),'tactorStimDiff','responseTimes','t','trainTimes',...,
        'fsStim','epochedButton','epochedTactor','epochedAudio','epochedStim','sampsEnd');
end
%%
% bad trial
bads = 14;
[stimTimes,trainTimes] = extract_stimulation_times_TOJ(tact,fsStim,bads);

% get that button press - threshold it
tact(tact(:,2) >= 0.009,2) = 0.009;

% check to makes ure it all is working
%[buttonPksTemp,buttonLocsTemp] = findpeaks(tact(:,2),fsTact,'minpeakdistance',2,'Minpeakheight',0.008);

tact(tact(:,2) < 0.009,2) = 0;
tact(:,2) = tact(:,2)*1000;


%%
% plot  inputs continuously through time
if plotIt
    plot_TOJ_concurrently(stim,tact,fsStim)
end

% QUANTIFY RXN TIME TO CORTICAL STIM

[epochedTactor,epochedAudio,epochedStim,epochedButton,t,tSamps] = extract_epochs_TOJ(stim,tact,trainTimes,fsStim);
% epoched button press
%%

% give list of which were perceived first
whichPerceived = {'stim','same','stim','stim','tactor','same','tactor','stim','stim','stim','tactor','same','stim',...
    'stim','stim','tactor','stim','tactor','stim','tactor','stim'};
whichPerceiveMoresame = {'stim','same','stim','stim','tactor','same','tactor','stim','same','same','tactor','same','stim',...
    'stim','same','tactor','stim','tactor','stim','tactor','stim'};

numTrials = size(epochedAudio,2);

if plotIt
    plot_epochs_TOJ(epochedStim,epochedTactor,epochedAudio,epochedButton,whichPerceived,t,numTrials)
end


%%

[tactorLocsVec,stimLocsVec,buttonLocsVec,tactorStimDiff,responseTimes] = get_response_timing_segs_TOJ(epochedButton,epochedTactor,epochedStim,t,tSamps,numTrials)

