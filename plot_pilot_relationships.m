% ELEC5305 - regenerate all three preliminary SI-SDR figures
% This script reads pilot_results.csv; it does not rerun the experiment.
clearvars; clc; close all;
projectDir=fileparts(fileparts(mfilename('fullpath')));
resultsDir=fullfile(projectDir,'results');
T=readtable(fullfile(resultsDir,'pilot_results.csv'));
noiseNames=string(T.Noise);
noiseNames(noiseNames=="white")="White";
noiseNames(noiseNames=="stationary")="Kitchen";
noiseNames(noiseNames=="traffic")="Traffic";
noiseNames(noiseNames=="public_space")="Public space";
deltaSS=T.SI_SDR_SS_dB-T.SI_SDR_Noisy_dB;
deltaW=T.SI_SDR_Wiener_dB-T.SI_SDR_Noisy_dB;

% Summary chart showing the measured improvement in each condition
fig=figure('Color','w');
b=bar([deltaSS deltaW],'grouped');
xticks(1:height(T)); xticklabels(noiseNames);
ylabel('SI-SDR improvement (dB)'); xlabel('Noise condition');
title('Speech Enhancement at 0 dB Input SNR');
legend('Spectral subtraction','Wiener filtering', ...
    'Location','northoutside','Orientation','horizontal');
grid on; ylim([0 max([deltaSS;deltaW])*1.20]);
for j=1:2
    v=[deltaSS deltaW];
    text(b(j).XEndPoints,b(j).YEndPoints+.08, ...
        compose('%.2f',v(:,j)), ...
        'HorizontalAlignment','center','FontSize',10);
end
exportgraphics(fig,fullfile(resultsDir,'pilot_sisdr_summary.png'),'Resolution',300);
close(fig);

% Same pilot data: separate relationship plots for O and V_N
xValues={T.OverlapO,T.VariationVN};
xNames={'Time-frequency overlap O','Noise spectral variation V_N'};
titles={'Time-Frequency Overlap','Noise Spectral Variation'};
fileNames={'overlap_vs_improvement.png','variation_vs_improvement.png'};
for i=1:2
    fig=figure('Color','w');
    scatter(xValues{i},deltaSS,65,'o','filled'); hold on;
    scatter(xValues{i},deltaW,65,'s','filled');
    xlabel(xNames{i}); ylabel('SI-SDR improvement (dB)');
    title(titles{i}); grid on;
    legend('Spectral subtraction','Wiener filtering','Location','best');
    exportgraphics(fig,fullfile(resultsDir,fileNames{i}),'Resolution',300);
    close(fig);
end
fprintf('Saved three preliminary figures to results/.\n');
