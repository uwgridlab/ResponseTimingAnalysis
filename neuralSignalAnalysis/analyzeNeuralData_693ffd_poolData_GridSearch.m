%% squeeze data
%%
close all; clearvars ; clc
Z_ConstantsStimResponse;
% add path for scripts to work with data tanks

sid = SIDS{3};

load(fullfile([sid 'pooledData.mat']));
%
block = [1,2];
buttonLocsSamps_cell_ind = {};
buttonlocsSamps_cell = {};
data = {};
t_epoch_good = t_epoch;

for i = block
    load([sid,'_compareResponse_block_',num2str(i),'.mat'])
    
    buttonLocsSamps_cell_ind{i} = buttonLocsSamps;
end

for i = 1:length(buttonLocsSamps)
    buttonLocs{i} = [[buttonLocsSamps_cell_ind{1}{i}] [buttonLocsSamps_cell_ind{2}{i}]];
end

for i = 1:length(buttonLocsSamps)
    data{i} = cat(3,[epochedCortEco_cell{1}{i}(:,1:53,:)], [epochedCortEco_cell{2}{i}(:,1:53,:)]);
end
%%

clearvars epochedCortEco_cell buttonLocsSamps_cell_ind
t_epoch = t_epoch_good;

% get data of interest
condInt = 7;
condIntAns = uniqueCond(condInt);
dataInt = data{condInt};
buttonLocsInt = buttonLocs{condInt};
chanInt = 17;

% additional parameters
post_stim = 2000;
samps_post_stim = round(post_stim/1e3*fs_data);

pre_stim = 1000;
samps_pre_stim = round(pre_stim/1e3*fs_data);

%% 1/22/2018 - template subtraction
pre = 0.9; % started with 0.7
post = 1.8; % started with 0.7, then 1.1, then 1.5, then 1.8
[processedSig,template] = templateSubtract(dataInt,fs_data,'plotIt',0,'pre',pre,'post',post);
%processedSig = templateSubtract(dataInt,fs_data,'plotIt',0);
%%
figure
hold on

chanInt = 2;
for i = 1:size(template{1},2)
    plot(template{chanInt}{i});
end
%%
figure
hold on
for j = 1:size(template,2)
    subplot(8,8,j)
    hold on
    for i = 1:size(template{1},2)
        timeVec = [0:size(template{j}{i},1)-1];

        plotBTLError(timeVec,template{j}{i},'CI');
    end
    title(['Channel ' num2str(j)])
end



%% 1/22/2018 - linear interpolation

processedSig = interpolate_artifact(dataInt,'fs',fs_data,'plotIt',0,'type','pchip');

%% 1-29-2018 - template dictionary method 
stimChans = [1 9 20 24 29 32]; % 29 was bad too, 1 9 29 32 were the stim channels, 20 might also be bad
stimChans = [20 29 57 58]; % 29 was bad too, 1 9 29 32 were the stim channels, 20 might also be bad

pre = 1; % started with 0.7
post = 2; % started with 0.7, then 1.1, then 1.5, then 1.8
[processedSig,templateDict_cell,template,start_inds,end_inds] = templateSubtract_dictionary(dataInt,'fs',fs_data,...
    'plotIt',0,'pre',pre,'post',post,'stimChans',stimChans);

%
bads = [];
badTotal = [stimChans; bads];

% total channels
numChans = 53;
% make logical good channels matrix to index
goods = zeros(numChans,1);

channelsOfInt = 1:numChans;

goods(channelsOfInt) = 1;
% set the goods matrix to be zero where bad channels are
goods(badTotal) = 0;
% make it logical
goods = logical(goods);

%raw_sig = raw_sig(:,goods,:);

[~,goodVec] = find(goods'>0);

chanIntList = [12 21 28 19 18 36 44 43 30 33 41 34];

for ind = chanIntList
    
    exampChan = mean(squeeze(processedSig(:,ind,:)),2);
    
    figure
    ax1 = subplot(2,1,1);
    plot(1e3*t_epoch,exampChan,'linewidth',2);
    xlim([-200 1000])
    ylim([-5e-5 5e-5])
    
    title(['Processed Signal - Channel ' num2str(ind)])
    clear exampChan
    
    
    ax2 = subplot(2,1,2);
    exampChan = mean(squeeze(dataInt(:,ind,:)),2);
    plot(1e3*t_epoch,exampChan,'linewidth',2);
    xlim([-200 1000])
    ylim([-5e-5 5e-5])
    xlabel('time (ms)')
    ylabel('Voltage (\muV)')
    title(['Raw Signal Average - Channel ' num2str(ind)])
    
    linkaxes([ax1,ax2],'xy')
    
    clear exampChan
end
%%=

figure
hold on
for j = goodVec
    subplot(8,8,j)
    hold on
    for i = 1:size(templateDict_cell{j},2)
        timeVec = [0:size(templateDict_cell{j},1)-1];

        %plotBTLError(timeVec,templateDict_cell{j}(:,i),'CI');
        plot(timeVec,templateDict_cell{j}(:,i),'linewidth',2);
    end
    title(['Channel ' num2str(j)])
end

%
sig = processedSig;
avgResponse = mean(sig,3);

stimChans = [20 29];

smallMultiples_responseTiming(avgResponse,t_epoch,'type1',stimChans,'type2',0,'average',1,'highlight_range',[0 800])

% plot the average dictionary templates 
figure
for j = goodVec
    subplot(8,8,j)
    hold on
    for i = 1:size(template{j},2)
        timeVec = [0:size(template{j}{:,i},1)-1];

        plotBTLError(timeVec,template{j}{:,i},'CI',rand(1,3)');
        %plot(timeVec,templateDict_cell{j}(:,i),'linewidth',2);
    end
    title(['Channel ' num2str(j)])
end

%% - template trial method 
stimChans = [1 9 20 24 29 32]; % 29 was bad too, 1 9 29 32 were the stim channels, 20 might also be bad
pre = 1; % started with 0.7, then 0.9, adjusted the window, move it to 0.4
post = 2; % started with 0.7, then 1.1, then 1.5, then 1.8
[processedSig_trial,templateDict_cell_trial,template_trial,start_inds,end_inds] = templateSubtract_trial(dataInt,'fs',fs_data,...
    'plotIt',0,'pre',pre,'post',post,'stimChans',stimChans);

%
bads = [];
badTotal = [stimChans; bads];

% total channels
numChans = 53;
% make logical good channels matrix to index
goods = zeros(numChans,1);

channelsOfInt = 1:numChans;

goods(channelsOfInt) = 1;
% set the goods matrix to be zero where bad channels are
goods(badTotal) = 0;
% make it logical
goods = logical(goods);

%raw_sig = raw_sig(:,goods,:);

[~,goodVec] = find(goods'>0);

%
chanIntList = [12 21 28 19 18 36 44 43 30 33 41 34];

for ind = chanIntList
    
    exampChan = mean(squeeze(processedSig_trial(:,ind,:)),2);
    
    figure
    ax1 = subplot(2,1,1);
    plot(1e3*t_epoch,exampChan,'linewidth',2);
    xlim([-200 1000])
    ylim([-5e-5 5e-5])
    
    title(['Processed Signal - Channel ' num2str(ind)])
    clear exampChan
    
    
    ax2 = subplot(2,1,2);
    exampChan = mean(squeeze(dataInt(:,ind,:)),2);
    plot(1e3*t_epoch,exampChan,'linewidth',2);
    xlim([-200 1000])
    ylim([-5e-5 5e-5])
    xlabel('time (ms)')
    ylabel('Voltage (\muV)')
    title(['Raw Signal Average - Channel ' num2str(ind)])
    
    linkaxes([ax1,ax2],'xy')
    
    clear exampChan
end
%
sig = processedSig_trial;
avgResponse = mean(sig,3);

stimChans = [20 29];

smallMultiples_responseTiming(avgResponse,t_epoch,'type1',stimChans,'type2',0,'average',1)

% plot the average dictionary templates 
figure
for j = goodVec
    subplot(8,8,j)
    hold on
    for i = 1:size(template_trial{j},2)
        timeVec = [0:size(template_trial{j}{:,i},1)-1];

        plotBTLError(timeVec,template_trial{j}{:,i},'CI',rand(1,3)');
        %plot(timeVec,templateDict_cell{j}(:,i),'linewidth',2);
    end
    title(['Channel ' num2str(j)])
end

%%
stimChans = [1 9 20 24 29 32]; % 29 was bad too, 1 9 29 32 were the stim channels, 20 might also be bad
pre = 0.3; % started with 0.7, then 0.9, adjusted the window, move it to 0.4
post = 0.8; % started with 0.7, then 1.1, then 1.5, then 1.8
[processedSig_v2,templateDict_cell_v2,template_v2] = templateSubtract_dictionary_iterative(processedSig,'fs',fs_data,'plotIt',0,...
    'pre',pre,'post',post,'stimChans',stimChans,'start_inds',start_inds,'end_inds',end_inds);


%%
chanIntList = [12 21 28 19 18 36 44 43 30 33 41 34];

for ind = chanIntList
    
    exampChan = mean(squeeze(processedSig_v2(:,ind,:)),2);
    
    figure
    ax1 = subplot(2,1,1);
    plot(1e3*t_epoch,exampChan,'linewidth',2);
    xlim([-200 1000])
    ylim([-5e-5 5e-5])
    
    title(['Processed Signal - Channel ' num2str(ind)])
    clear exampChan
    
    
    ax2 = subplot(2,1,2);
    exampChan = mean(squeeze(dataInt(:,ind,:)),2);
    plot(1e3*t_epoch,exampChan,'linewidth',2);
    xlim([-200 1000])
    ylim([-5e-5 5e-5])
    xlabel('time (ms)')
    ylabel('Voltage (\muV)')
    title(['Raw Signal Average - Channel ' num2str(ind)])
    
    linkaxes([ax1,ax2],'xy')
    
    clear exampChan
end
%%=



figure
hold on
for j = goodVec
    subplot(8,8,j)
    hold on
    for i = 1:size(templateDict_cell_v2{j},2)
        timeVec = [0:size(templateDict_cell_v2{j},1)-1];

        %plotBTLError(timeVec,templateDict_cell{j}(:,i),'CI');
        plot(timeVec,templateDict_cell_v2{j}(:,i),'linewidth',2);
    end
    title(['Channel ' num2str(j)])
end

%
sig = processedSig_v2;
avgResponse = mean(sig,3);

stimChans = [20 29];

smallMultiples_responseTiming(avgResponse,t_epoch,'type1',stimChans,'type2',0,'average',1)

% plot the average dictionary templates 
figure
for j = goodVec
    subplot(8,8,j)
    hold on
    for i = 1:size(template_v2{j},2)
        timeVec = [0:size(template_v2{j}{:,i},1)-1];

        plotBTLError(timeVec,template_v2{j}{:,i},'CI',rand(1,3)');
        %plot(timeVec,templateDict_cell{j}(:,i),'linewidth',2);
    end
    title(['Channel ' num2str(j)])
end

%save([sid '

%% 1/22/2018 - single trial ICA
stimChans = [1 9 20 24 29 32]; % 29 was bad too, 1 9 29 32 were the stim channels, 20 might also be bad
i = 15;
trialInt = i;
data_int_temp = dataInt(:,:,i);
[processedSig,reconArtifact] = single_trial_ica(data_int_temp,'fs',fs_data,'plotIt',0,'stimChans',stimChans);
%%
chanIntList = [21 28 19 18 36 44 43 30 33 41];

for ind = chanIntList
    t_epoch = (-samps_pre_stim:samps_post_stim-1)/fs_data;
    
    exampChan = squeeze(processedSig(:,ind,trialInt));
    
    figure
    ax1 = subplot(2,1,1);
    plot(1e3*t_epoch,exampChan);
    xlim([-200 1000])
    %ylim([-5e-4 5e-4])
    title(['Processed Signal - Channel ' num2str(ind)])
    clear exampChan
    
    
    ax2 =subplot(2,1,2);
    exampChan = squeeze(dataInt(:,ind,trialInt));
    plot(1e3*t_epoch,exampChan);
    xlim([-200 1000])
    %ylim([-5e-4 5e-4])
    xlabel('time (ms)')
    ylabel('Voltage (\muV)')
    title(['Raw Signal  - Channel ' num2str(ind)])
    linkaxes([ax1,ax2],'xy')
    
    
    clear exampChan
end
%
%%
meanSub = false;
plotIt = false;
numComponentsSearch = 64;
scale_factor = 1000;
orderPoly = 3;
meanSub = 0;

plotIt = true;
%stimChans = [1 9 24 32];
stimChans = [1 9 20 24 29 32]; % 29 was bad too, 1 9 29 32 were the stim channels, 20 might also be bad

outputsignal = zeros(size(dataInt));
artifact = zeros(size(dataInt));
best_numComponents_m = zeros(size(dataInt,3),1);
best_nonLinear_m ={};

%for i = 1:size(dataInt,3)
    %i = 3;
    %trialInt = i;
    data_int_temp = dataInt(:,:,i);
    [best_numComponents,best_nonLinear,outputSig,recon_artifact] = optimize_ICA_ResponseTiming_gridSearch_singlePulse(data_int_temp,'fs',fs_data,'stimChans',stimChans);
    best_numComponents_m(i) = best_numComponents;
    best_nonLinear_m{i} = best_nonLinear;
    processedSig(:,:,i) = outputSig;
    artifact(:,:,i) = recon_artifact;
    fprintf(['iteration ' num2str(i) ' complete \n'])
%end

stimTime = zeros(size(processedSig,3));

%% ica_optimize
ica_optimize = 0;

if ica_optimize
    
    stimChans = [20 29];
    x0 = 50;
    [x history searchdir] = optimize_ICA(dataInt,'fs',eco_fs,'meansub',0,'orderpoly',1,'stimChans',stimChans,'x0',x0)
    
end

%%
% Process the signal with ICA

icaProcess = 1;
if icaProcess
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if (condIntAns == 2 || condIntAns == 3 || condIntAns == 4 || condIntAns == 5)
        
        meanSub = false;
        plotIt = false;
        numComponentsSearch = 64;
        scale_factor = 1000;
        orderPoly = 3;
        meanSub = 0;
        
        plotIt = true;
        %stimChans = [1 9 24 32];
        stimChans = [1 9 20 24 29 32]; % 29 was bad too, 1 9 29 32 were the stim channels, 20 might also be bad
        
        outputsignal = zeros(size(dataInt));
        artifact = zeros(size(dataInt));
        best_numComponents_m = zeros(size(dataInt,3),1);
        best_nonLinear_m ={};
        
        for i = 1:size(dataInt,3)
            %i = 3;
            %trialInt = i;
            data_int_temp = dataInt(:,:,i);
            [best_numComponents,best_nonLinear,outputSig,recon_artifact] = optimize_ICA_ResponseTiming_gridSearch(data_int_temp,'fs',fs_data,'stimChans',stimChans);
            best_numComponents_m(i) = best_numComponents;
            best_nonLinear_m{i} = best_nonLinear;
            processedSig(:,:,i) = outputSig;
            artifact(:,:,i) = recon_artifact;
            fprintf(['iteration ' num2str(i) ' complete \n'])
        end
        
        stimTime = zeros(size(processedSig,3),1);
        
    elseif (condIntAns == -1)
        
        meanSub = 0;
        %orderPoly = 6;
        orderPoly = 3; %10-12-2017 - djc change
        if meanSub == 1
            for i = 1:size(dataInt,2)
                for j = 1:size(dataInt,3)
                    data_int_temp = squeeze(dataInt(:,i,j));
                    [p,s,mu] = polyfit((1:numel(data_int_temp))',data_int_temp,orderPoly);
                    f_y = polyval(p,(1:numel(data_int_temp))',[],mu);
                    
                    % subtract poly fit
                    processedSig(:,i,j) = data_int_temp - f_y;
                    
                end
                
            end
        else
            processedSig = dataInt;
        end
        
        %stimTime = 1e3*tactorLocsVec; %
        stimTime = zeros(size(processedSig,3),1); % it is centered around zero now
        t = t_epoch;
    end
end

chanIntList = [21 28 19 36 44 43 30];

% evaluate goodness of fit
%% single trial
chanIntList = [21 28 19 18 36 44 43 30];
chanIntList = 12;

for trialInt = 1:size(processedSig,3)
    for ind = chanIntList
        t_epoch = (-samps_pre_stim:samps_post_stim-1)/fs_data;
        
        exampChan = squeeze(processedSig(:,ind,trialInt));
        
        figure
        ax1 = subplot(2,1,1);
        plot(1e3*t_epoch,exampChan);
        xlim([-200 1000])
        ylim([-5e-4 5e-4])
        title(['Processed Signal - Channel ' num2str(ind)])
        clear exampChan
        
        
        ax2 =subplot(2,1,2);
        exampChan = squeeze(dataInt(:,ind,trialInt));
        plot(1e3*t_epoch,exampChan);
        xlim([-200 1000])
        ylim([-5e-4 5e-4])
        xlabel('time (ms)')
        ylabel('Voltage (\muV)')
        title(['Raw Signal  - Channel ' num2str(ind)])
        linkaxes([ax1,ax2],'xy')
        
        
        clear exampChan
    end
end
%%
for ind = chanIntList
    
    exampChan = mean(squeeze(processedSig(:,ind,:)),2);
    
    figure
    ax1 = subplot(2,1,1);
    plot(1e3*t_epoch,exampChan,'linewidth',2);
    xlim([-200 1000])
    ylim([-5e-5 5e-5])
    
    title(['Processed Signal - Channel ' num2str(ind)])
    clear exampChan
    
    
    ax2 = subplot(2,1,2);
    exampChan = mean(squeeze(dataInt(:,ind,:)),2);
    plot(1e3*t_epoch,exampChan,'linewidth',2);
    xlim([-200 1000])
    ylim([-5e-5 5e-5])
    xlabel('time (ms)')
    ylabel('Voltage (\muV)')
    title(['Raw Signal Average - Channel ' num2str(ind)])
    
    linkaxes([ax1,ax2],'xy')
    
    clear exampChan
end

% 9-28-2017 - save intermediate data for plotting response map

%%
sig = processedSig;
avgResponse = mean(sig,3);

stimChans = [20 29];

smallMultiples_responseTiming(avgResponse,t_epoch,'type1',stimChans,'type2',0,'average',1)

%save([sid '_block' num2str(block) '_postICAProcessData'],processsedSig,'-v7.3')

%# sort by rxn time

% load subject data, need sid still
%load([sid,'_compareResponse_block_',block,'.mat'])
%
% for i = 1:length(uniqueCond)
%     % 12-10-2016
%     respLo = 0.150;
%     respHi = 1;
%
%
%     trim = buttonLocs{i};
%     trim = trim(trim>respLo & trim<respHi);
%     zTrim = zscore(trim);
%     buttonLocsThresh{i} = 1e3.*trim(abs(zTrim)<3);
%     %buttonLocsThresh{i} = 1e3.*trim;
%
% end

%%
rxnTimes = buttonLocs{condInt};
[sorted,indexes] = sort(rxnTimes);
sorted_sig = sig(:,:,indexes);

% calculate first response time, shift others based from there
sorted_basedOffFirst = sorted - sorted(1);
sig_shifted = sorted_sig;

num_non_nan = sum(~isnan(rxnTimes));

for i = 2:num_non_nan
    sig_shifted(:,:,i) = circshift(sorted_sig(:,:,i),sorted_basedOffFirst(i),1);
end

avgResponse = mean(sig_shifted,3);
t_shift = t - sorted(1)/fs_stim;
smallMultiples_responseTiming(avgResponse,t_shift,'type1',stimChans,'type2',0,'average',1)

%%
%
% figure
% hold on
%
% plot(t_shift,sorted_sig(:,10,1))
% plot(t_shift,sig_shifted(:,10,1))
% legend({'original','shift'})
% vline(0)
%
%
%
% %%
%
% for i = 1:size(sig,3)
%     figure
%
%     plot(sig_shifted(:,10,i))
%     hold on
%     plot(sorted_sig(:,10,i))
%     legend({'shifted','original'})
% end


%% PROCESS THE DATA
% process the wavelet using morlet process and PLV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% trial by trial wavelet decomp, PLV

%%%%%% PLV
freq_range = [8 12];
[plv] = plvWrapper(processedSig,fs_data,freq_range,stimChans);

%%%%%%% wavelet
time_res = 0.050; % 50 ms bins

[powerout,f_morlet,t_morlet,~] = waveletWrapper(processedSig,fs_data,time_res,stimChans);
%
t_morlet = linspace(-pre_stim,post_stim,length(t_morlet))/1e3;
badChans = [1 9 20 24 29 32];
powerout(:,:,badChans,:) = 0;

%% Visualize wavelets

% example wavelet decomp
%trialInt = 20; % which channel to check out
chanInt = 27;

%t_epoch = (-samps_pre_stim:samps_post_stim-1)/fs_data;

response = buttonLocs{condInt}/(2*fs_data);
cmap=flipud(cbrewer('div', 'RdBu', 13));
colormap(cmap)

powerout_norm = normalize_spectrogram(powerout,t_morlet);


for i = 1:size(powerout,4)
    
    totalFig = figure;
    totalFig.Units = 'inches';
    totalFig.Position = [12.1806 3.4931 6.0833 7.8056];
    subplot(3,1,1);
    imagesc(1e3*t_morlet,f_morlet,powerout_norm(:,:,chanInt,i));
    cmap=flipud(cbrewer('div', 'RdBu', 13));
    colormap(cmap)
    axis xy;
    xlabel('time (ms)');
    ylabel('frequency (Hz)');
    title(['Wavelet decomposition Channel ' num2str(chanInt) ' Trial ' num2str(i)]);
    vline(stimTime(i),'m','stim')
    vline(1e3*response(i),'g','response')
    %xlim([-200 1000]);
    %colorbar()
    caxis([-3 3])
    set(gca,'fontsize',14)
    
    
    
    %figure;
    h1 = subplot(3,1,2);
    plot(1e3*t_epoch,1e6*processedSig(:,chanInt,i))
    vline(stimTime(i),'m','stim')
    xlabel('time (ms)');
    ylabel('microvolts')
    title(['Processed Channel ' num2str(chanInt) ' Trial ' num2str(i)]);
    vline(1e3*response(i),'g','response')
    ylims = [-(max(abs(1e6*processedSig(:,chanInt,i))) + 10) (max(abs(1e6*processedSig(:,chanInt,i))) + 10)];
    ylim(ylims);
    ylim_h1 = ylims;
    %xlim([-200 1000]);
    set(gca,'fontsize',14)
    
    
    h2 = subplot(3,1,3);
    plot(1e3*t_epoch,1e6*dataInt(:,chanInt,i))
    vline(stimTime(i),'m','stim')
    xlabel('time (ms)');
    ylabel('microvolts')
    title(['Raw Channel ' num2str(chanInt) ' Trial ' num2str(i)]);
    vline(1e3*response(i),'g','response')
    ylim(ylim_h1);
    %xlim([-200 1000]);
    set(gca,'fontsize',14);
    
    
    
    linkaxes([h1,h2],'xy');
    
end
%% normalized spectogram

powerout_norm = normalize_spectrogram(powerout,t_morlet);

avg_power_norm = mean(powerout_norm,4);
stimChans = badChans;
smallMultiples_responseTiming_spectrogram(avg_power_norm,t_morlet,f_morlet,'type1',stimChans,'type2',0,'average',1);

return

%%
% plot average spectrogram

avg_power = mean(powerout,4);
smallMultiples_responseTiming_spectrogram(avg_power,t_morlet,f_morlet,'type1',stimChans,'type2',0,'average',1)

% sort by reaction time
%% Visualize PLV

% chan 1 is the lower valued chan, so e.g., 17, 20
chan1 = 3;
chan2 = 58;
figure;

% probably want to discard the number of samples for the order of the
% filter. So for alpha

desired_f = 10;
period = 1/desired_f;
time_4oscil = period*4; % time total in seconds
order = round(time_4oscil*fs_data);
samps_discard = order;


plot(t_epoch, squeeze(plv(:, chan1, chan2)));
ylim([0 1])
vline(0)
xlabel('Time (s)');
ylabel('Plase Locking Value');
title(['PLV between Channel ' num2str(chan1) ' and ' num2str(chan2)])

t1 = 0;
t2 =  0.2;

t_sub = t_epoch((t_epoch>t1 & t_epoch<t2));
plv_sub = plv((t_epoch>t1 & t_epoch<t2),:,:);

figure
max_plv = squeeze(max(plv_sub,[],1));
imagesc(max_plv)
h = colorbar;
h.Limits = [0 1];
xlabel('Channel')
ylabel('Channel')
title(['Max Phase Locking Value between T  = ' num2str(t1) ' seconds and T = ' num2str(t2) ' seconds'])


return

%% Try wavelet denoising

nc = 15;
br = 8;
er = 15;
plotIt = 1;
ec = 10;
et = 10;


processedSig = wavelet_denoise(epochedCortEco,'numComponents',nc,'beginRecon',br,'endRecon',er,...
    'plotIt',plotIt,'exampChan',ec,'exampTrial',et);

stimTime = zeros(size(processedSig,3));
stimChans = [9 17 50 58 ];

% median subtract
processedSig_medianS = processedSig - repmat(mean(processedSig,2),[1,size(processedSig,2),1]);

% Below here is old
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
% plot channel of interest
figure

% channel of interest, plot mean
t_epoch = [artifact_end:artifact_end+size(epochedCortEco,1)-1]/fs_data;
t_epochPre = [-presamps:0-1]/fs_data;

exampChanPost = mean(squeeze(epochedCortEco(:,chanInt,:)),2);
exampChanPre = mean(squeeze(epochedPreStim(:,chanInt,:)),2);

%exampChanPost = mean(squeeze(epochedCortEco(:,chanInt,:)),2)-mean(exampChanPost);
%exampChanPre = mean(squeeze(epochedPreStim(:,chanInt,:)),2)-mean(exampChanPre);


subplot(2,1,1)
plot(1e3*t_epoch,exampChanPost);
xlabel('time (ms)')
ylabel('Voltage (V)')
title(['Post stim Raw data for Channel ', num2str(chanInt)])

subplot(2,1,2)
plot(1e3*t_epochPre,exampChanPre);
xlabel('time (ms)')
ylabel('Voltage (V)')
title(['Pre Stim Raw data for Channel ', num2str(chanInt)])
%         pause(1)

% trial by trial notch and extract power
%%
% from quick screen

% trials
trialHG = zeros(size(epochedCortEco,1),size(epochedCortEco,2),size(epochedCortEco,3));
trialBeta = zeros(size(epochedCortEco,1),size(epochedCortEco,2),size(epochedCortEco,3));

% rest
restHG = zeros(size(epochedPreStim,1),size(epochedPreStim,2),size(epochedPreStim,3));
restBeta = zeros(size(epochedPreStim,1),size(epochedPreStim,2),size(epochedPreStim,3));

% for each trial, run the functions below - only want to filter pre and
% post
for i = 1:size(epochedCortEco,3)
    % notch filter to eliminate line noise
    sigT = squeeze(epochedCortEco(:,:,i));
    sigR = squeeze(epochedPreStim(:,:,i));
    
    sigT = notch(sigT, [60 120 180], fs_data, 4);
    sigR = notch(sigR, [60 120 180], fs_data, 4);
    
    % extract HG and Beta power bands
    logHGPowerT = log(hilbAmp(sigT, [70 200], fs_data).^2);
    logBetaPowerT = log(hilbAmp(sigT, [12 30], fs_data).^2);
    
    logHGPowerR = log(hilbAmp(sigR, [70 200], fs_data).^2);
    logBetaPowerR = log(hilbAmp(sigR, [12 30], fs_data).^2);
    
    trialHG(:,:,i) = logHGPowerT;
    trialBeta(:,:,i) = logBetaPowerT;
    
    
    restHG(:,:,i) = logHGPowerR;
    restBeta(:,:,i) = logBetaPowerR;
end

% part for getting rid of funny filtering at beginning and end
t_min = 0.2; % in seconds
t_max = 1.5; % in seconds

t_minPre = -0.4;
t_maxPre = -0.1;

if strcmp(trimEnds,'y')
    
    %temporary ones
    
    t_epochT = t_epoch(t_epoch>t_min & t_epoch<t_max);
    t_epochPreT = t_epochPre(t_epochPre>t_minPre & t_epochPre<t_maxPre);
    trialHGT = trialHG(t_epoch>t_min & t_epoch<t_max,:,:);
    trialBetaT = trialBeta(t_epoch>t_min & t_epoch<t_max,:,:);
    restHGT = restHG(t_epochPre>t_minPre & t_epochPre<t_maxPre,:,:);
    restBetaT = restBeta(t_epochPre>t_minPre & t_epochPre<t_maxPre,:,:);
    
    clear t_epoch t_epochPre trialHG trialBeta restHG restBeta
    
    t_epoch = t_epochT;
    t_epochPre = t_epochPreT;
    trialHG = trialHGT;
    trialBeta = trialBetaT;
    restHG = restHGT;
    restBeta = restBetaT;
    
end
%%
% sort by reaction time
[sorted,indexes] = sort(cort);

trialHGsort = trialHG(:,:,indexes);
trialBetasort = trialBeta(:,:,indexes);

restHGsort = restHG(:,:,indexes);
restBetasort = restBeta(:,:,indexes);


% find significant differences for all channels

restHG_ave = squeeze(mean(restHGsort,1));
restBeta_ave = squeeze(mean(restBetasort,1));
trialHG_ave = squeeze(mean(trialHGsort,1));
trialBeta_ave = squeeze(mean(trialBetasort,1));

numChans = size(raw_eco,2);
chans = 1:numChans;

ptarg = 0.05 / numChans;

HGSigs = ttest2(restHG_ave, trialHG_ave, ptarg, 'r', 'unequal', 2);
BetaSigs = ttest2(restBeta_ave, trialBeta_ave, ptarg, 'r', 'unequal', 2);

HGSigs = HGSigs == 1; % make boolean
BetaSigs = BetaSigs == 1; % make boolean


HGRSAs = signedSquaredXCorrValue(restHG_ave, trialHG_ave, 2);
BetaRSAs = signedSquaredXCorrValue(restBeta_ave, trialBeta_ave, 2);

%HG figure
figure
plot(chans, HGRSAs);
hold on;
plot(chans(HGSigs), HGRSAs(HGSigs), '*');

xlabel('channel number');
ylabel('R^2');
title('Aggregated HG Response');
legend('aggregate activity');

% Beta
figure;
plot(chans, BetaRSAs);
hold on;
plot(chans(BetaSigs), BetaRSAs(BetaSigs), '*');

xlabel('channel number');
ylabel('R^2');
title('Aggregated Beta Response');
legend('aggregate activity');


% plot example channel
%% plot channel of interest


trial = 1:length(sorted);

figure
imagesc(1e3*t_epoch,trial,squeeze(trialHGsort(:,chanInt,:))')
axis xy
xlabel('Time (ms)')
ylabel('Trial')
title(['High Gamma power in channel ', num2str(chanInt)])

figure
imagesc(1e3*t_epoch,trial,squeeze(trialBetasort(:,chanInt,:))')
axis xy
xlabel('Time (ms)')
ylabel('Trial')
title(['Beta power in channel ', num2str(chanInt)])

%%


%     % from Stavros code - filter ?
%
%     % assume stimulation is over by 210 ms or so, so select segments where
%     % t>210
%
%     % attempt to fit exponential decay to post-stim segment
%     %pp = smooth(c2plot(supsam(2)+1:end),smoothfw);
%     pp = exampChan((t_epoch>210):end);
%     [f,gof] = fit([1:length(pp)]',pp','exp2'); % 2-term exponential
%     if gof.adjrsquare>0.8
%         % subtract exp function if R2>0.8
%         ppc = pp' - f([1:length(pp)]');
%     else
%         ppc = pp';
%     end
%
%     % smooth post-stim segment using Savitzky-Golay filtering
%     smppc = sgolayfilt(ppc,5,81);
%
%     % end of stavros code

%% time frequency wavelet

fw = 1:1:200;


[C_post, ~, C_totPost, ~] = time_frequency_wavelet(squeeze(epochedCortEco(t_epoch>t_min & t_epoch<t_max,chanInt,:)), fw, fs_data, 1, 1, 'CPUtest');
[C_pre, ~, C_totPre, ~] = time_frequency_wavelet(squeeze(epochedPreStim(t_epochPre>t_minPre &t_epochPre<t_maxPre,chanInt,:)), fw, fs_data, 1, 1, 'CPUtest');
C_norm = normalize_data(C_post',C_pre');

figure
imagesc(1e3*t_epoch,fw,C_norm);
set_colormap_threshold(gcf, [-1 1], [-7 7], [1 1 1]);
colorbar
axis xy
xlabel('time (ms)');
ylabel('frequency (hz)');
title(['Normalized wavelet data for Channel ', num2str(chanInt)])


figure
imagesc(1e3*t_epoch,fw,C_post');
%set_colormap_threshold(gcf, [-1 1], [-7 7], [1 1 1]);
colorbar
axis xy
xlabel('time (ms)');
ylabel('frequency (hz)');
title(['Normalized wavelet data for Channel ', num2str(chanInt)])



figure
imagesc(1e3*t_epochPre,fw,C_pre');
%set_colormap_threshold(gcf, [-1 1], [-7 7], [1 1 1]);
colorbar
axis xy
xlabel('time (ms)');
ylabel('frequency (hz)');
title(['Normalized wavelet data for Channel ', num2str(chanInt)])




% pick condition type where stimulation was delivered
if s == 1
    trainTimesCond1 = trainTimes(condType==0);
elseif s == 2
    trainTimesCond1 = trainTimes(condType==0 | condType==1);
end

sampsEnd = round(2*fs_stim);

% epoched button press
epochedButton = squeeze(getEpochSignal(buttonDataClip,trainTimesCond1,(trainTimesCond1 + sampsEnd)));

figure
t_epoch = [0:size(epochedButton,1)-1]/fs_stim;
plot(t_epoch,epochedButton);

%% tactor brain data