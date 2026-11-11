% ELEC5305 - Extended study figures
% Plot acoustic descriptors against STOI improvement at each SNR.

clear; clc; close all;
projectDir = fileparts(fileparts(mfilename('fullpath')));
outDir = fullfile(projectDir, 'results', 'extended');
resultFile = fullfile(outDir, 'extended_results.csv');
if ~isfile(resultFile)
    error('Run run_extended_study.m with smokeTest = false first.');
end
T = readtable(resultFile);
snrLevels = unique(T.TargetSNR_dB)';

% Use separate panels so changes in SNR do not distort the relationships.
for figureNo = 1:2
    fig = figure('Color', 'w', 'Position', [50 50 1350 850]);
    tiledlayout(2,2, 'TileSpacing','compact', 'Padding','compact');
    for k = 1:numel(snrLevels)
        nexttile;
        selection = T.TargetSNR_dB == snrLevels(k);
        part = T(selection,:);
        if figureNo == 1
            x = part.OverlapO;
            xText = 'Time-frequency overlap O';
        else
            x = part.VariationVN;
            xText = 'Noise spectral variation V_N';
        end
        scatter(x, part.DeltaSTOI_SS, 20, 'o', 'filled', ...
            'MarkerFaceAlpha',0.32, 'DisplayName','Spectral subtraction');
        hold on;
        scatter(x, part.DeltaSTOI_Wiener, 20, 's', 'filled', ...
            'MarkerFaceAlpha',0.32, 'DisplayName','Wiener filtering');
        yline(0, 'k:', 'HandleVisibility','off');
        xlabel([xText ' (dimensionless)']);
        ylabel('STOI improvement (dimensionless)');
        title(sprintf('Input SNR = %g dB', snrLevels(k)));
        grid on;
        if k == 1
            legend('Location','best');
        end
    end
    if figureNo == 1
        exportgraphics(fig, fullfile(outDir, 'overlap_vs_stoi_by_snr.png'), ...
            'Resolution',300);
    else
        exportgraphics(fig, fullfile(outDir, 'variation_vs_stoi_by_snr.png'), ...
            'Resolution',300);
    end
end

% A summary at fixed SNR, with individual results still available in the CSV.
noiseNames = {'white','stationary','traffic','public_space'};
noiseLabels = {'White','Kitchen','Traffic','Public space'};
figure('Color','w', 'Position',[100 100 1000 620]);
targetSNR = 0;
means = nan(4,2);
for i = 1:numel(noiseNames)
    mask = T.TargetSNR_dB == targetSNR & strcmp(string(T.Noise),noiseNames{i});
    if any(mask)
        means(i,1) = mean(T.DeltaSTOI_SS(mask));
        means(i,2) = mean(T.DeltaSTOI_Wiener(mask));
    end
end
bar(means, 'grouped');
xticks(1:4); xticklabels(noiseLabels);
yline(0,'k:', 'HandleVisibility','off');
legend('Spectral subtraction','Wiener filtering','Location','best');
ylabel('Mean STOI improvement (dimensionless)');
xlabel('Noise condition');
title('Mean STOI change at 0 dB SNR (utterance averages)');
grid on;
exportgraphics(gcf, fullfile(outDir,'mean_stoi_improvement_at_0db.png'), ...
    'Resolution',300);

% Summarise observed values; do not treat utterances as independent speakers.
summaryRows = cell(numel(snrLevels)*numel(noiseNames),5);
cnt = 0;
for j=1:numel(snrLevels)
    for i=1:numel(noiseNames)
        mask = T.TargetSNR_dB == snrLevels(j) & strcmp(string(T.Noise),noiseNames{i});
        if ~any(mask), continue; end
        cnt=cnt+1;
        summaryRows(cnt,:) = {snrLevels(j),string(noiseLabels{i}),sum(mask), ...
            mean(T.DeltaSTOI_SS(mask)),mean(T.DeltaSTOI_Wiener(mask))};
    end
end
if cnt > 0
    types = {'double','string','double','double','double'};
    summaryTable = table('Size',[cnt,5], 'VariableTypes',types, ...
        'VariableNames',{'SNR_dB','Noise','Utterances','MeanDeltaSTOI_SS', ...
        'MeanDeltaSTOI_Wiener'});
    for r=1:cnt
        summaryTable(r,:) = summaryRows(r,:);
    end
    disp(summaryTable);
    writetable(summaryTable,fullfile(outDir,'extended_summary.csv'));
end
fprintf('Saved extended study figures and descriptive summary to results/extended/.\n');
fprintf('Interpret the two speakers as an intermediate dataset, not population-level evidence.\n');
