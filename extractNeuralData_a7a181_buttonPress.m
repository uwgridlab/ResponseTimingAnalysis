%% load in subject
close all;clear all;clc

DATA_DIR = 'C:\Users\david\Data\Subjects\a7a181\data\d8\MATLAB_Converted\StimParamSweep_d8';
sid = 'a7a181';
sVec = [1];

for s = sVec
    % load in data
    if s == 1
        load(fullfile(DATA_DIR,'StimParamSweep-8.mat'))
        block = '1';
    elseif s == 2
        load(fullfile(DATA_DIR,'StimParamSweep-9.mat'))
        block = '2';
    end
    
    %% neural data
    
    % the eco data is crashing it right now
    clearvars -except ECO1 ECO2 ECO3 Butt sid block s DATA_DIR s sVec
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
    
    % only 64 channels grid
    
    % data = data(:,1:64);
    
    % get train times
    
    % look at stim from file saved (this is the sample where things were
    % delivered
    butt = Butt.data;
    fsButt = Butt.info.SamplingRateHz;
    stimFromFile = butt(:,1);
    stimChans = [23 24];
    
    [stimOnset] = butt(:,1)>0.5;
    stimOnsetDiff = diff(stimOnset);
    stimTrigger = find(stimOnsetDiff>0);
    % convert sample times for eco
    button = butt(:,6);
    buttonOnset = button>0.008;
    buttonOnsetDiff = diff(buttonOnset);
    buttonTrigger = find(buttonOnsetDiff>0);
    diffButtonTrigger = diff(buttonTrigger);
    buttonOff = find(diffButtonTrigger>1000);
    buttonOffsets = buttonTrigger(buttonOff);
    buttonOnsets = [buttonTrigger(1); buttonTrigger(buttonOff+1)];
    convertSamps = fsButt/fsData;
    
    trainTimesConvert = round(buttonOnsets/convertSamps);
    
    trainTimesCell = {};
    trainTimesCellThresh = {};
    
    % ARTIFACT
    
    postStim = 2000;
    sampsPostStim = round(postStim/1e3*ecoFs);
    
    preStim = 2000;
    sampsPreStim = round(preStim/1e3*ecoFs);
    
    epochedCortEco = squeeze(getEpochSignal(data,trainTimesConvert-sampsPreStim,trainTimesConvert+ sampsPostStim));
    epochedCortEco = epochedCortEco(:,1:64,:);
    epochedCortEco_cell = epochedCortEco;
    
    tEpoch = (-sampsPreStim:sampsPostStim-1)/ecoFs;
    current_direc = pwd;
    
    [vals,indices] = max(squeeze(epochedCortEco(:,15,:)),[],1);
    stimTrials = vals>0.005;
    
    epochedDataStim =  epochedCortEco(:,:,stimTrials);
    epochedDataNoStim = epochedCortEco(:,:,~stimTrials);
    %     %%
    %%
    type = 'dictionary';
    
    useFixedEnd = 0;
    %fixedDistance = 2;
    fixedDistance = 4; % in ms
    plotIt = 0;
    
    %pre = 0.4096; % in ms
    %post = 0.4096; % in ms
    
    pre = 0.8; % started with 1
    post = 1; % started with 0.2
    % 2.8, 1, 0.5 was 3/19/2018
    
    % these are the metrics used if the dictionary method is selected. The
    % options are 'eucl', 'cosine', 'corr', for either euclidean distance,
    % cosine similarity, or correlation for clustering and template matching.
    minDuration = 0.5; % minimum duration of artifact in ms
    
    distanceMetricDbscan = 'eucl';
    distanceMetricSigMatch = 'eucl';
    amntPreAverage = 3;
    normalize = 'preAverage';
    %normalize = 'firstSamp';
    
    onsetThreshold = 1.5;
    
    recoverExp = 0;
    threshVoltageCut = 75;
    threshDiffCut = 75;
    expThreshVoltageCut = 95;
    expThreshDiffCut = 95;
    bracketRange = [-6:6];
    chanInt = 29;
    minPts = 15;
    minClustSize = 10;
    outlierThresh = 0.95;
    
    [processedSigStim,templateDictCell,templateTrial,startInds,endInds] = analyFunc.template_subtract(epochedDataStim,'type',type,...
        'fs',fsData,'plotIt',plotIt,'pre',pre,'post',post,'stimChans',stimChans,...
        'useFixedEnd',useFixedEnd,'fixedDistance',fixedDistance,...,
        'distanceMetricDbscan',distanceMetricDbscan,'distanceMetricSigMatch',distanceMetricSigMatch,...
        'recoverExp',recoverExp,'normalize',normalize,'amntPreAverage',amntPreAverage,...
        'minDuration',minDuration,'bracketRange',bracketRange,'threshVoltageCut',threshVoltageCut,...
        'threshDiffCut',threshDiffCut,'expThreshVoltageCut',expThreshVoltageCut,...
        'expThreshDiffCut',expThreshDiffCut,'onsetThreshold',onsetThreshold,'chanInt',chanInt,...
        'minPts',minPts,'minClustSize',minClustSize,'outlierThresh',outlierThresh);
    %%
    % visualization
    % of note - more visualizations are created here, including what the
    % templates look like on each channel, and what the discovered templates are
    xlims = [-2000 1000];
    trainDuration = [0 0];
    %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     vizFunc.multiple_visualizations(processedSigStim,epochedDataStim,'fs',fsData,'type',type,'tEpoch',...
%         tEpoch,'xlims',xlims,'trainDuration',trainDuration,'stimChans',stimChans,...,
%         'chanIntList',chanIntList,'templateTrial',templateTrial,'templateDictCell',templateDictCell,'modePlot','confInt')
%     %
    average = 1;
    %%
    rerefMode = 'mean';
    badChannels = stimChans;
    channelsToUse = [1:4 9:12 17:21 25:29 33:37];
    
    reref = 1;
    if reref
        epochedDataNoStim = analyFunc.rereference_CAR_median(epochedDataNoStim,rerefMode,badChannels,[],[],channelsToUse);
        processedSigStim = analyFunc.rereference_CAR_median(processedSigStim,rerefMode,badChannels,[],[],channelsToUse);
    end
    
    %
    %%%%%%% wavelet
    timeRes = 0.025; % 25 ms bins
    
    % [powerout,fMorlet,tMorlet] = wavelet_wrapper(processedSig,fsData,stimChans);
    stimChans = [23 24];
    [poweroutNoStim,fMorlet,tMorlet,~] = analyFunc.waveletWrapper(epochedDataNoStim,fsData,timeRes,stimChans);
    %
    [poweroutStim,fMorlet,tMorlet,~] = analyFunc.waveletWrapper(processedSigStim,fsData,timeRes,stimChans);
    
    tMorlet = linspace(-preStim,postStim,length(tMorlet))/1e3;
    % normalize data
    dataRef = poweroutNoStim(:,tMorlet<0.05 & tMorlet>-0.8,:,:);
    %
    [normalizedData] = analyFunc.normalize_spectrogram_wavelet(dataRef,poweroutNoStim);
    individual = 0;
    average = 1;
    %
    chanIntList = [ 8 13 14 15 22 27 29 30];
    %
    HGPowerWaveletNoStim = squeeze(mean(squeeze(poweroutNoStim(fMorlet < 150 & fMorlet > 70,:,:,:)),1));
    HGPowerWaveletStim = squeeze(mean(squeeze(poweroutStim(fMorlet < 150 & fMorlet > 70,:,:,:)),1));
    
    %%
         processedSigHGNoStim = zeros(size(epochedDataNoStim));
        for trial = 1:size(epochedDataNoStim,3)
            [amp] = log(hilbAmp(squeeze(epochedDataNoStim(:,:,trial)), [70 150], fsData).^2);
            processedSigHGNoStim(:,:,trial) = amp;
        end
       
        
         processedSigHGStim = zeros(size(epochedDataStim));
        for trial = 1:size(processedSigStim,3)
            [amp] = log(hilbAmp(squeeze(processedSigStim(:,:,trial)), [70 150], fsData).^2);
            processedSigHGStim(:,:,trial) = amp;
        end
    %%
    % chanIntList = chanInt;
    for chanInt = chanIntList
        vizFunc.visualize_wavelet_channel_no_raw_not_normalized(poweroutNoStim,tMorlet,fMorlet,epochedDataNoStim,...
            tEpoch,chanInt,individual,average)
        
        figure
        plot(1e3*tMorlet,mean(squeeze(HGPowerWaveletNoStim(:,chanInt,:)),2))
        xlim([-2000 2000])
        vline(0)
        xlabel('time (ms)')
        ylabel('power normalized to baseline')
        title(['no stim average wavelet amplitude - channel ' num2str(chanInt)])
        set(gca,'fontsize',14)
        
                    figure
        plot(1e3*tEpoch,mean(squeeze(processedSigHGNoStim(:,chanInt,:)),2))
        xlim([-2000 2000])
        vline(0)
        xlabel('time (ms)')
        ylabel('power normalized to baseline')
        title(['stim average wavelet amplitude - channel ' num2str(chanInt)])
        set(gca,'fontsize',14)
        
        
        vizFunc.visualize_wavelet_channel_no_raw_not_normalized(poweroutStim,tMorlet,fMorlet,processedSigStim,...
            tEpoch,chanInt,individual,average)
        
        figure
        plot(1e3*tMorlet,mean(squeeze(HGPowerWaveletStim(:,chanInt,:)),2))
        xlim([-2000 2000])
        vline(0)
        xlabel('time (ms)')
        ylabel('power normalized to baseline')
        title(['stim average wavelet amplitude - channel ' num2str(chanInt)])
        set(gca,'fontsize',14)
        
                figure
        plot(1e3*tEpoch,mean(squeeze(processedSigHGStim(:,chanInt,:)),2))
        xlim([-2000 2000])
        vline(0)
        xlabel('time (ms)')
        ylabel('power normalized to baseline')
        title(['stim average wavelet amplitude - channel ' num2str(chanInt)])
        set(gca,'fontsize',14)
        
    end
    %
    figure
    for i = 1:64
        subplot(8,8,i)
        plot(1e3*tMorlet,mean(squeeze(HGPowerWaveletNoStim(:,i,:)),2))
        xlim([-2000 2000])
        vline(0)
        title(['No Stim Channel ' num2str(i)])
    end
    figure
    for i = 1:64
        subplot(8,8,i)
        plot(1e3*tMorlet,mean(squeeze(HGPowerWaveletStim(:,i,:)),2))
        xlim([-2000 2000])
        vline(0)
        title(['Stim Channel ' num2str(i)])
    end
    %%
    
        figure
    for i = 1:64
        subplot(8,8,i)
        plot(1e3*tEpoch,mean(squeeze(processedSigHGNoStim(:,i,:)),2))
        xlim([-2000 2000])
        vline(0)
        title(['No Stim Channel ' num2str(i)])
    end
    figure
    for i = 1:64
        subplot(8,8,i)
        plot(1e3*tEpoch,mean(squeeze(processedSigHGStim(:,i,:)),2))
        xlim([-2000 2000])
        vline(0)
        title(['Stim Channel ' num2str(i)])
    end
    %%
    for chanInt = chanIntList
        vizFunc.visualize_wavelet_channel(poweroutNoStim,tMorlet,fMorlet,epochedDataNoStim,...
            tEpoch,epochedDataNoStim,chanInt,individual,average)
        
          vizFunc.visualize_wavelet_channel(poweroutStim,tMorlet,fMorlet,processedSigStim,...
            tEpoch,epochedDataStim,chanInt,individual,average)
    end
    %%
    for chanInt = chanIntList
        vizFunc.visualize_wavelet_channel_small(normalizedData,tMorlet,fMorlet,processedSig,...
            tEpoch,dataInt,chanInt,individual,average)
    end
    %%
    ylimsSpect = [5 300];
    xlims = [-2000 1000];
    vizFunc.small_multiples_spectrogram(normalizedData,tMorlet,fMorlet,'type1',stimChans,'type2',0,'xlims',xlims,'ylims',ylimsSpect);
    vizFunc.small_multiples_spectrogram(poweroutNoStim,tMorlet,fMorlet,'type1',stimChans,'type2',0,'xlims',xlims,'ylims',ylimsSpect);
    
    % save(fullfile(current_direc, [sid '_button_press_' num2str(s) '.mat']),'-v7.3','epochedCortEco','fsData','tEpoch','stimTrials');
    
    
end