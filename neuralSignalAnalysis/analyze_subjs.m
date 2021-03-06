%% 5.12.2018 - David J. Caldwell
% analyze different response timing subjects one at a time

close all; clearvars ; clc
Z_ConstantsStimResponse;
% add path for scripts to work with data tanks

% sid
% 1 - acabb1
% 2 - c19968
% 3 - 693ffd
% 4 - 2fd831
% 5 - a1355e
% 6 - 3ada8b
SIDSint = {'c19968','693ffd','2fd831','a1355e'};
SIDSblocked = {'c19968','693ffd','2fd831'};
SIDSprimed = {'a1355e','3ada8b'};

% 3ada8b has been multiplied by 4 in the neural analysis prep
SIDSint = {'693ffd'};

primedBlock = 0;
reref = 0;
%%
for sid = SIDSint
    %%
    sid = sid{:};
    if sum(strcmp(sid,SIDSprimed)) == 0
        DATA_DIR = 'C:\Users\david\Data\Subjects\ConvertedTDTfiles\pooled_RT_data';
        load(fullfile(DATA_DIR,[sid 'pooledData_changePts_noDelay.mat']));
        
    elseif sum(strcmp(sid,SIDSprimed)) == 1
        DATA_DIR = 'C:\Users\david\Data\Subjects\ConvertedTDTfiles\priming_data';
        % load(fullfile(DATA_DIR,[sid '_priming_neural_block_' num2str(primedBlock) '.mat']));
        load(fullfile(DATA_DIR,[sid '_priming_neural_block_' num2str(primedBlock) '.mat']));
        
        t_epoch = tEpoch;
        fs_data = fsData;
        if strcmp(sid,'a1355e')
            behaviorFileName = [sid '_priming_behavior_block_' num2str(primedBlock) '.mat'];
        elseif strcmp(sid,'3ada8b')
            behaviorFileName =  ([sid,'_compareResponse_block_',num2str(primedBlock),'.mat']);
        end
        
    end
    
    if ~exist('fsData','var')
        fsData = fs_data;
    end
    %% combine the pooled data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
    if ~exist('tEpoch','var')
        tEpoch = t_epoch;
    end
    
    if any(strcmp(SIDSblocked,sid))
        [buttonLocsSamps,buttonLocs,data,tEpoch,uniqueCond] = combine_pooled_data(sid,epochedCortEco_cell,tEpoch);
    elseif any(strcmp(SIDSprimed,sid))
        [buttonLocsSamps,buttonLocs,data,tEpoch,uniqueCond] = combine_pooled_data_singleBlock(sid,epochedCortEco_cell,tEpoch,behaviorFileName);
    end
    % additional parameters
    postStim = 2000;
    sampsPostStim = round(postStim/1e3*fsData);
    
    preStim = 1000;
    sampsPreStim = round(preStim/1e3*fsData);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    switch sid
        case 'c19968'
            
            stimChans = [9 17 50 58];
            chanIntList = [1 10 51 42];
            chanInt = 10;
            uniqueCond = [-1 0 1 2 3 4 5];
        case '693ffd'
            chanInt = 19;
            stimChans = [20 29];
            chanIntList = [21 28 19 36 44 43 30];
        case '2fd831'
            stimChans = [1 9 24 42];
            chanInt = 10;
            chanIntList = [2 10 51];
        case 'a1355e'
            stimChans = [16 24];
            chanIntList = [8 7 14 15 22 23 31 32];
            chanInt = 23;
        case '3ada8b'
            stimChans = [4 3 24 32];
            
            chanInt = 11;
            chanIntList = [1 2 3 4 5 12 13 30 33 45 51 52 53 54 61 62];
    end
    
    trainDuration = [];
    xlims = [-50 500];
    minDuration = 0.5;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    % params for DBSscan optimization
    % bracketRange = [-5:12];
    bracketRange = [-8:8]; % 11/1/2018
    
    type = 'dictionary';
    
    useFixedEnd = 0;
    %fixedDistance = 2;
    fixedDistance = 4; % in ms
    plotIt = 0;
    
    %pre = 0.4096; % in ms
    %post = 0.4096; % in ms
    
    pre = 1; % started with 1
    % 0.5 9/23/2018
    post = 0.8; % started with 0.2, last was 0.6
    % 2.8, 1, 0.5 was 3/19/2018
    post = 0.8;
    post = 1;
    
    % before 8.31.2018 was 0.8
    
    % these are the metrics used if the dictionary method is selected. The
    % options are 'eucl', 'cosine', 'corr', for either euclidean distance,
    % cosine similarity, or correlation for clustering and template matching.
    
    distanceMetricDbscan = 'eucl';
    distanceMetricSigMatch = 'eucl';
    amntPreAverage = 3;
    normalize = 'preAverage';
    %  normalize = 'firstSamp';
    
    recoverExp = 0;
    %%
    % condIntAns for RT task
    % -1 = tactor
    %  0 = null
    %  1 = off-target
    %  2-5 = conditions 1->4
    
    % condIntAns for priming
    % 0 - unprimed
    % 1 - primed
    
    % for 3ada8b, block 2
    %
    % uniqueCond =
    %
    %      0
    %      5
    %      6 - this is the 2 pulses in isolation
    
    for condInt = 1:1
        %   condInt = 2;
        condIntAns = uniqueCond(condInt);
        dataInt = data{condInt};
        
        if ~strcmp(sid,'3ada8b')
            dataInt = 4*dataInt;
        end
        response = buttonLocs{condInt};
        
        % get additional fake channels on 693ffd so it plots ok
        if strcmp(sid,'693ffd')
            dataInt = cat(2,dataInt,zeros(size(dataInt,1),64-size(dataInt,2),size(dataInt,3)));
            stimChans = [stimChans, [53:64]];
        end
        
        if strcmp(sid,'a1355e') || strcmp(sid,'3ada8b')
            dataInt = (dataInt(:,1:64,:));
        end
        
        buttonLocsInt = buttonLocs{condInt};
        %%%%%%%%%%%%%%%%%%
        if (condIntAns >= 0)
            meanSub = 0;
            %orderPoly = 6;
            orderPoly = 3; %10-12-2017 - djc change
            if meanSub == 1
                for ii = 1:size(dataInt,2)
                    dataInt(:,ii,:) = polyfit_subtract(squeeze(dataInt(:,ii,:)),orderPoly);
                end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [processedSig,templateDictCell,templateTrial,startInds,endInds] = analyFunc.template_subtract(dataInt,'type',type,...
                'fs',fsData,'plotIt',plotIt,'pre',pre,'post',post,'stimChans',stimChans,...
                'useFixedEnd',useFixedEnd,'fixedDistance',fixedDistance,...,
                'distanceMetricDbscan',distanceMetricDbscan,'distanceMetricSigMatch',distanceMetricSigMatch,...
                'recoverExp',recoverExp,'normalize',normalize,'amntPreAverage',amntPreAverage,...
                'minDuration',minDuration,'bracketRange',bracketRange);
            %
            stimTime = zeros(size(processedSig,3),1); % it is centered around zero now
            
        elseif (condIntAns == -1)
            meanSub = 0;
            %orderPoly = 6;
            orderPoly = 3; %10-12-2017 - djc change
            if meanSub == 1
                for ii = 1:size(dataInt,2)
                    processedSig(:,ii,:) = polyfit_subtract(squeeze(dataInt(:,ii,:)),orderPoly);
                end
            else
                processedSig = dataInt;
            end
            %stimTime = 1e3*tactorLocsVec; %
            stimTime = zeros(size(processedSig,3),1); % it is centered around zero now
            t = tEpoch;
        end
        
        %  response = response(~isnan(response));
        % this selects ones with a response time between 0.15 and 1
        responseBool = (response > 0.15 & response<1);
        
        % this selects trials with all response times 
        responseBool = logical(ones(size(response)));
        
        response = response(responseBool);
        % only take ones where they responded within time bins
        if ~strcmp(sid,'3ada8b') & (primedBlock == 2);
            processedSig = processedSig(:,:,responseBool);
        end
        
        rerefMode = 'mean';
        if strcmp(sid,'c19968')
            badChannels = [stimChans [29 32] [64:size(processedSig,2)]];
        elseif strcmp(sid,'693ffd')
            badChannels = [stimChans [53:64]];
        elseif strcmp(sid,'2fd831')
            badChannels = stimChans;
        elseif strcmp(sid,'a1355e')
            badChannels = stimChans;
        elseif strcmp(sid,'3ada8b')
            badChannels = [stimChans [65:128]];
        end
        
        if reref
            processedSig = rereference_CAR_median(processedSig,rerefMode,badChannels);
        end
        
        processedSigReref = rereference_CAR_median(processedSig,rerefMode,badChannels);
        
        % small multiples
        
        individual = 0;
        average = 1;
        %chanIntList = 3;
        trainDuration = [];
        modePlot = 'avg';
        xlims = [-200 1000];
        ylims = [-300 300];
        vizFunc.small_multiples_time_series(processedSig,tEpoch,'type1',stimChans,'type2',0,'xlims',xlims,'ylims',ylims,'modePlot',modePlot,'highlightRange',trainDuration)
        
        vizFunc.small_multiples_time_series(processedSigReref,tEpoch,'type1',stimChans,'type2',0,'xlims',xlims,'ylims',ylims,'modePlot',modePlot,'highlightRange',trainDuration)
        
        %%
        %
        %
        % notch
        %     for trial = 1:size(processedSig,3)
        %     processedSig(:,:,trial) = notch(squeeze(processedSig(:,:,trial)),[60 120 180 240],fsData);
        %     end
        %
        % visualization
        % of note - more visualizations are created here, including what the
        % templates look like on each channel, and what the discovered templates are
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        trainDuration = [];
        vizFunc.multiple_visualizations(processedSig,dataInt,'fs',fsData,'type',type,'tEpoch',...
            tEpoch,'xlims',xlims,'trainDuration',trainDuration,'stimChans',stimChans,...,
            'chanIntList',chanIntList,'modePlot','confInt')
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        
        %% wavelet and plv
        
        %%%%%% PLV
        freqRange = [8 12];
        %[plv] = plvWrapper(processedSig,fsData,freqRange,stimChans);
        %%%%%%% wavelet
        timeRes = 0.01; % 25 ms bins
        
        % [powerout,fMorlet,tMorlet] = wavelet_wrapper(processedSig,fsData,stimChans);
       % [powerout,fMorlet,tMorlet,~] = waveletWrapper(processedSig,fsData,timeRes,stimChans);
        [powerout,fMorlet,tMorlet,~] = analyFunc.waveletWrapper(processedSig,fsData,timeRes,stimChans);

        %
        tMorlet = linspace(-preStim,postStim,length(tMorlet))/1e3;
        % normalize data
        dataRef = powerout(:,tMorlet<0.05 & tMorlet>-0.8,:,:);
        %
        [normalizedData] = normalize_spectrogram_wavelet(dataRef,powerout);
        individual = 0;
        average = 1;
        % chanIntLIst = 42;
        %%
        % chanIntList = chanInt;
        for chanInt = chanIntList
            %visualize_wavelet_channel(normalizedData,tMorlet,fMorlet,processedSig,...
              %  tEpoch,dataInt,chanInt,stimTime,response,individual,average)
            
                  vizFunc.visualize_wavelet_channel(normalizedData,tMorlet,fMorlet,processedSig,...
                tEpoch,dataInt,chanInt,individual,average)
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
        %chanInt = 1;
        figure
        subplot(2,1,1)
        plot(1e3*tEpoch,squeeze(mean(squeeze(processedSigHG(:,chanInt,:)),2)))
        xlabel('time (ms)')
        ylabel('power (log(HG amplitude squared)')
        xlim([-50 500])
        vline(0)
        set(gca,'fontsize',14)
        
        title(['hilbert HG amplitude - channel ' num2str(chanInt)])
        subplot(2,1,2)
        plot(1e3*tMorlet,mean(squeeze(HGPowerWavelet(:,chanInt,:)),2))
        xlim([-50 500])
        vline(0)
        xlabel('time (ms)')
        ylabel('power normalized to baseline')
        title(['average wavelet amplitude - channel ' num2str(chanInt)])
        set(gca,'fontsize',14)
        %%
        figure
        trials = 1:size(HGPowerWavelet,3);
        time = tMorlet;
        tLow = -0.2;
        tHigh = 0.5;
        imagesc(1e3*tMorlet(tMorlet>tLow & tMorlet < tHigh),trials,squeeze(HGPowerWavelet((tMorlet>tLow & tMorlet < tHigh),chanInt,:))')
        colormap(flipud(bone))
        axis('normal')
        ylabel('trial')
        xlabel('time (ms)')
        colorbar()
        title('average wavelet HG amplitude')
        set(gca,'fontsize',14)
    end
    %%
    %vizFunc.small_multiples_time_series(processedSigHG,tEpoch,'type1',stimChans,'type2',0,'xlims',xlims,'ylims',[-40 -20],'modePlot','avg','highlightRange',trainDuration)
    
    %     return
    %
    %     % sort by rxn time
    %     %%
    %     sortByRxnTime = 0;
    %     if sortByRxnTime
    %         [sigShifted,tShift] = shift_by_rxn_time(processedSig,buttonLocs)
    %         smallMultiples_responseTiming(avgResponse,tShift,'type1',stimChans,'type2',0,'average',1)
    %     end
end