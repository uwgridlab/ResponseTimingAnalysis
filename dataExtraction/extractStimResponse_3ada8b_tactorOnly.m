%% load in subject
%close all;clear all;clc
% this is from my z_constants
Z_ConstantsStimResponse;

DATA_DIR = 'C:\Users\djcald.CSENETID\Data\Subjects\3ada8b\data\d10\MATLAB_conversions\3ada8b_ParamSweep\';
sid = SIDS{6};
%
% ui box for input
list_str = {'1st block','2nd block'};

[s,v] = listdlg('PromptString','Pick experiment',...
    'SelectionMode','single',...
    'ListString',list_str);

% load in data
if (strcmp(sid, '3ada8b'))
    
    if s == 1
        load(fullfile(DATA_DIR,'stimParamSweep-2.mat'))
        block = '1';
    elseif s == 2
        load(fullfile(DATA_DIR,'stimParamSweep-3.mat'))
        block = '2';
    end
    
end
plotIt = 1;
%% load in data of interest

[stim,sing,tact,fsStim,fsSing,fsData,fsTact] = load_stim_data(Stim,Sing,ECO1,Butt);

clear Stim Tact Sing

%%
figure
plot(tact(:,6));
hold on
plot(1000*tact(:,7) - 4);
%%

tButton = (0:size(tact,1)-1)/fsTact;
tactorDataClip = tact(:,6);
tactorDataClip(tactorDataClip >= 2) = 2;
[tactPks,tactLocs] = findpeaks(tactorDataClip,tButton,'MinpeakDistance',0.5,'Minpeakheight',1.9);
[tactPksSamps,tactLocsSamps] = findpeaks(tactorDataClip,'MinpeakDistance',fsTact*0.5,'Minpeakheight',1.9);

figure
findpeaks(tactorDataClip,tButton,'MinpeakDistance',0.5,'Minpeakheight',1.9);

tactLocsSamps = round(tactLocsSamps/2);


% adjust 10 ms?

adjust = 1;

if adjust
    
    tactLocsSamps = tactLocsSamps - round(10*fsData/1e3);
end


%%
eco1 = ECO1.data;
fsData = ECO1.info.SamplingRateHz;
ecoFs = fsData;
clear ECO1
eco2 = ECO2.data;
clear ECO2

eco3 = ECO3.data;
clear ECO3


data = [eco1 eco2 eco3];
clearvars eco1 eco2 eco3

data = data(:,1:64);

%%

% additional parameters
postStim = 2000;
sampsPostStim = round(postStim/1e3*fsData);

preStim = 1000;
sampsPreStim = round(preStim/1e3*fsData);
tEpoch = round([-sampsPreStim:sampsPostStim-1])/fsData;
epochedCortEco = squeeze(getEpochSignal(data,tactLocsSamps-sampsPreStim,tactLocsSamps+ sampsPostStim));
stimTime = zeros(length(tactLocsSamps),1);
rerefMode = 'mean';
badChannels = [];
response = zeros(length(tactLocsSamps),1);
stimChans = [];
processedSig = rereference_CAR_median(epochedCortEco,rerefMode,badChannels);

tactorEpoched = squeeze(getEpochSignal(decimate(tactorDataClip,2),tactLocsSamps-sampsPreStim,tactLocsSamps+ sampsPostStim));


%%
%%%%%%% wavelet
timeRes = 0.01; % 25 ms bins

% [powerout,fMorlet,tMorlet] = wavelet_wrapper(processedSig,fsData,stimChans);
[powerout,fMorlet,tMorlet,~] = waveletWrapper(processedSig,fsData,timeRes,stimChans);
%
tMorlet = linspace(-preStim,postStim,length(tMorlet))/1e3;
% normalize data
dataRef = powerout(:,tMorlet<0.05 & tMorlet>-0.8,:,:);
%
[normalizedData] = normalize_spectrogram(dataRef,powerout);
%%
individual = 0;
average = 1;
chanIntList = [3 4 5 12 13];
%chanIntList = 3;
trainDuration = [];
modePlot = 'avg';
xlims = [-200 1000];
ylims = [-40 40];
vizFunc.small_multiples_time_series(processedSig,tEpoch,'type1',stimChans,'type2',0,'xlims',xlims,'ylims',ylims,'modePlot',modePlot,'highlightRange',trainDuration)

%%
% chanIntList = chanInt;
for chanInt = chanIntList
    visualize_wavelet_channel(normalizedData,tMorlet,fMorlet,processedSig,...
        tEpoch,epochedCortEco,chanInt,stimTime,response,individual,average)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

HGPowerWavelet = squeeze(mean(squeeze(normalizedData(fMorlet < 150 & fMorlet > 70,:,:,:)),1));

%%
vizFunc.small_multiples_spectrogram(normalizedData,tMorlet,fMorlet,'type1',stimChans,'type2',0,'xlims',xlims);
%% hilb amp HG
processedSigHG = zeros(size(processedSig));
for trial = 1:size(processedSig,3)
    [amp] = log(hilbAmp(squeeze(processedSig(:,:,trial)), [70 150], fsData).^2);
    processedSigHG(:,:,trial) = amp;
end
%%
chanInt = 3;
figure
subplot(2,1,1)
plot(1e3*tEpoch,squeeze(mean(squeeze(processedSigHG(:,chanInt,:)),2)))
xlabel('time (ms)')
ylabel('power (log(HG amplitude squared)')
xlim([-50 500])
vline(0)
title(['hilbert HG amplitude - channel ' num2str(chanInt)])
subplot(2,1,2)
plot(1e3*tMorlet,mean(squeeze(HGPowerWavelet(:,chanInt,:)),2))
xlim([-200 500])
vline(0)
xlabel('time (ms)')
ylabel('power normalized to baseline')
title(['average wavelet amplitude - channel ' num2str(chanInt)])

%%
figure
trials = 1:size(HGPowerWavelet,3);
time = tMorlet;
tLow = -0.2;
tHigh = 1;
imagesc(tMorlet(tMorlet>tLow & tMorlet < tHigh),trials,squeeze(HGPowerWavelet((tMorlet>tLow & tMorlet < tHigh),chanInt,:))')
colormap('jet')
axis('normal')
ylabel('trial')
xlabel('time')
colorbar()
title('average wavelet HG amplitude')

figure
trials = 1:size(HGPowerWavelet,3);
time = tMorlet;
tLow = -0.2;
tHigh = 1;
imagesc(tEpoch(tEpoch>tLow & tEpoch < tHigh),trials,squeeze(HGPowerWavelet((tMorlet>tLow & tMorlet < tHigh),chanInt,:))')
colormap('jet')
axis('normal')
ylabel('trial')
xlabel('time')
colorbar()
title('average wavelet HG amplitude')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return
%% figure out stim times
% vector of condition type - for first subject, looks like condition type
% is what was used , rather than test_condition


[trainTimesTotal,stimFromFile,trainTimes,condType,uniqueCond] = extract_stimulation_times(tact,condType);

%% extract stimulus data, find delay, and get timing of stimuli

[bursts,delay] = extract_stimulus_delivery(stim,sing,condType,trainTimes,fsStim,fsSing,plotIt);

%% extract data
% try and account for delay for the stim times
stimTimes = bursts(2,:)+delay;
trainTimes=stimTimes;

%% look at all simultaneously

tactorData = tact(:,1);
buttonData = tact(:,2);

analyze_all_inputs_simultaneously(tactorData,buttonData,stim,stimFromFile,fsTact)

%%
respLo = 0.150;
respHi = 1;

%% quantifying data

%% quantifying data

[buttonLocs,buttonLocsSamps,tactorLocsVec,tactorLocsVecSamps,tEpoch,epochedButton,epochedTactor,buttonTactDiffSamps] = get_response_timing_segs(tactorData,uniqueCond,stim,buttonData,stimFromFile,fsStim,fsTact,trainTimesTotal,plotIt);
%% get ISI info

%[ISICellSamps,ISICellSeconds,ISICondBefore,ISICellSampsNoNuOt,ISICellSecondsNoNuOt,ISIcondBeforeNoNuOt] = get_ISI(condType,uniqueCond,tactorLocsVecSamps,stimFromFile,fsStim,trainTimesTotal,trainTimes);
%% look at RT vs ISI

% [mdl,mdlNoNuOt] = compare_resp_times_ISI(uniqueCond,buttonLocs,ISICellSecondsNoNuOt,ISICellSeconds);
%% save it
saveIt = 1;

if saveIt
    current_direc = pwd;
    
    %save(fullfile(current_direc, [sid '_compareResponse_block_tactorSub' block '.mat']),'buttonLocsSamps','block','sid','buttonLocs','tactorLocsVec','tEpoch','stimTimes','fsStim','epochedButton','epochedTactor','condType','uniqueCond', 'respLo','respHi');
    save(fullfile(current_direc, [sid '_tactorAnaly_block_' block '_changePts_tactorSub .mat']),'buttonTactDiffSamps','buttonLocsSamps','s','block','sid','buttonLocs','tactorLocsVec','tEpoch','stimTimes','fsStim','epochedButton','epochedTactor','condType','uniqueCond', 'respLo','respHi');
    
    clearvars -except buttonTactDiffSamps buttonLocSamps s buttonLocs block tEpoch stimTimes fsStim epochedButton tactorLocsVec epochedTactor condType uniqueCond respLo respHi SIDS DATA_DIR sid
    
    close all
    
end
