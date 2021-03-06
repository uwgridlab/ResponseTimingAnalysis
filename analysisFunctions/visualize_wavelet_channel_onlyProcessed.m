function [] = visualize_wavelet_channel_onlyProcessed(powerout,tMorlet,fMorlet,processedSig,tEpoch,chanInt,stimTime,response,individual,average)
% set colormap using cbrewer
%CT = cbrewer('div','RdBu',11);
% flip it so red is increase, blue is down
%CT = flipud(CT);
load('america');
CT = cm;
if individual
    
    for i = 1:size(powerout,4)
        totalFig = figure;
        totalFig.Units = 'inches';
        totalFig.Position = [12.1806 3.4931 6.0833 7.8056];
        subplot(2,1,1);
        s = surf(1e3*tMorlet,fMorlet,powerout(:,:,chanInt,i),'edgecolor','none');
        xlimsVec = [-200 1000];
        ylimsVec = [0 300];
        %%Create vectors out of surface's XData and YData
        x=x(1,:);
        y=y(1,:);
        interestX = [xlimsVec(1) xlimsVec(end)];
        interestY = [ylimsVec(1) ylimsVec(end)];
        % Divide the lengths by the number of lines needed
        
        % Plot the mesh lines
        % Plotting lines in the X-Z plane
        hold on
        for i = 1:2
            Y1 = interestY(i)*ones(size(x)); % a constant vector
            Z1 = zeros(size(x));
            plot3(x,Y1,Z1,'-k');
        end
        % Plotting lines in the Y-Z plane
        for i = 1:2
            X2 = interestX(i)*ones(size(y)); % a constant vector
            Z1 = zeros(size(X2));
            plot3(X2,y,Z1,'-k');
        end
        
        view(0,90);
        axis tight;
        xlabel('time (ms)');
        ylabel('frequency (Hz)');
        title(['Wavelet decomposition Channel ' num2str(chanInt) ' Trial ' num2str(i)]);
        xlim(xlimsVec);
        ylim(ylimsVec);
        set(gca,'fontsize',14)
        colormap(CT);
        set_colormap_threshold(gcf, [-0.5 0.5], [-6 6], [1 1 1])
        plot3([stimTime(i),stimTime(i)],[0 300],[1000,1000],'r','linewidth',2)
        plot3([1e3*response(i),1e3*response(i)],[0 300],[1000,1000],'g','linewidth',2)
                colorbar()
        
        h1 = subplot(2,1,2);
        plot(1e3*tEpoch,1e6*processedSig(:,chanInt,i))
        vline(stimTime(i),'r','stim')
        xlabel('time (ms)');
        ylabel('microvolts')
        title(['Processed Channel ' num2str(chanInt) ' Trial ' num2str(i)]);
        vline(1e3*response(i),'g','response')
        ylims = [-(max(abs(1e6*processedSig(:,chanInt,i))) + 10) (max(abs(1e6*processedSig(:,chanInt,i))) + 10)];
        ylim(ylims);
        ylim_h1 = ylims;
        xlim([-200 1000]);
        set(gca,'fontsize',14)
        
        
    end
    
end
% now average
if average
    
    poweroutAvg = mean(squeeze(powerout(:,:,chanInt,:)),3);
    
    totalFig2 = figure;
    totalFig2.Units = 'inches';
    totalFig2.Position = [12.1806 3.4931 6.0833 7.8056];
    subplot(2,1,1);
    s = surf(1e3*tMorlet,fMorlet,poweroutAvg,'edgecolor','none');
    hold on
    xlimsVec = [-200 1000];
    ylimsVec = [0 300];
    % Extract X,Y and Z data from surface plot
    x=s.XData;
    y=s.YData;
    z=s.ZData;
    
    %%Create vectors out of surface's XData and YData
    x=x(1,:);
    y=y(1,:);
    interestX = [xlimsVec(1) xlimsVec(end)];
    interestY = [ylimsVec(1) ylimsVec(end)];
    % Divide the lengths by the number of lines needed
    
    % Plot the mesh lines
    % Plotting lines in the X-Z plane
    hold on
    for i = 1:2
        Y1 = interestY(i)*ones(size(x)); % a constant vector
        Z1 = zeros(size(x));
        plot3(x,Y1,Z1,'-k');
    end
    % Plotting lines in the Y-Z plane
    for i = 1:2
        X2 = interestX(i)*ones(size(y)); % a constant vector
        Z1 = zeros(size(X2));
        plot3(X2,y,Z1,'-k');
    end
    
    view(0,90);
    
    axis tight;
    xlabel('time (ms)');
    ylabel('frequency (Hz)');
    title(['Wavelet decomposition Channel ' num2str(chanInt)]);
    xlim(xlimsVec);
    ylim(ylimsVec);
    set(gca,'fontsize',14)
    colormap(CT);
    set_colormap_threshold(gcf, [-0.5 0.5 ], [-6 6], [1 1 1])
    colorbar();
    plot3([mean(stimTime),mean(stimTime)],[0 300],[1000,1000],'r','linewidth',2)
    plot3([1e3*mean(response),1e3*mean(response)],[0 300],[1000,1000],'g','linewidth',2)
    
    h3 = subplot(2,1,2);
    plot(1e3*tEpoch,1e6*nanmean(squeeze(processedSig(:,chanInt,:)),2))
    xlabel('time (ms)');
    ylabel('microvolts')
    title(['Processed Channel ' ]);
    ylims = [-(max(abs(1e6*nanmean(squeeze(processedSig(:,chanInt,:)),2))) + 10) (max(abs(1e6*nanmean(squeeze(processedSig(:,chanInt,:)),2))) + 10)];
    ylim(ylims);
    ylim_h1 = ylims;
    xlim([-200 1000]);
    vline(nanmean(stimTime),'r','stim')
    % vline(1e3*nanmean(response),'g','response')
    
    set(gca,'fontsize',14)
    
end

end