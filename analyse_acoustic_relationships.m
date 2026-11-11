
% ELEC5305 - Acoustic relationship analysis
% Calculate correlations within each noise condition and SNR

clear;
clc;

projectDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(projectDir, 'results', 'extended');

inputFile = fullfile(resultsDir, 'extended_results.csv');

if ~isfile(inputFile)
    inputFile = fullfile(projectDir, ...
        'results', 'extended_results.csv');
end

T = readtable(inputFile);

% Check the experiment structure
assert(height(T) == 640, 'Expected 640 results.');

snrs = [-5, 0, 5, 10];
noiseNames = ["white", "stationary", ...
    "traffic", "public_space"];
speakers = ["p232", "p257"];

features = {'OverlapO', 'VariationVN'};

metrics = {'DeltaSI_SDR_SS_dB', ...
    'DeltaSI_SDR_Wiener_dB', ...
    'DeltaSTOI_SS', ...
    'DeltaSTOI_Wiener'};

% Correlations grouped by noise and SNR
snrCol = zeros(16, 1);
noiseCol = strings(16, 1);
nCol = zeros(16, 1);
sdVN = zeros(16, 1);
rValues = NaN(16, 8);

row = 0;

for i = 1:numel(snrs)
    for j = 1:numel(noiseNames)

        row = row + 1;

        G = T(T.TargetSNR_dB == snrs(i) & ...
            string(T.Noise) == noiseNames(j), :);

        assert(height(G) == 40, ...
            'Expected 40 recordings per group.');

        snrCol(row) = snrs(i);
        noiseCol(row) = noiseNames(j);
        nCol(row) = height(G);
        sdVN(row) = std(G.VariationVN);

        col = 0;

        for f = 1:2
            for m = 1:4
                col = col + 1;

                x = G.(features{f});
                y = G.(metrics{m});

                rValues(row, col) = localPearson( ...
                    x, y, f == 2);
            end
        end
    end
end

R = table(snrCol, noiseCol, nCol, sdVN, ...
    rValues(:,1), rValues(:,2), ...
    rValues(:,3), rValues(:,4), ...
    rValues(:,5), rValues(:,6), ...
    rValues(:,7), rValues(:,8), ...
    'VariableNames', { ...
    'SNR_dB', 'Noise', 'N', 'SD_VN', ...
    'r_O_SISDR_SS', 'r_O_SISDR_Wiener', ...
    'r_O_STOI_SS', 'r_O_STOI_Wiener', ...
    'r_VN_SISDR_SS', 'r_VN_SISDR_Wiener', ...
    'r_VN_STOI_SS', 'r_VN_STOI_Wiener'});

writetable(R, fullfile(resultsDir, ...
    'acoustic_correlations_by_noise_snr.csv'));

disp('Correlations at 0 dB SNR:');
disp(R(R.SNR_dB == 0, :));

% Repeat the analysis for each speaker
speakerResults = table();

for i = 1:numel(snrs)
    for j = 1:numel(noiseNames)
        for k = 1:numel(speakers)

            G = T(T.TargetSNR_dB == snrs(i) & ...
                string(T.Noise) == noiseNames(j) & ...
                string(T.Speaker) == speakers(k), :);

            assert(height(G) == 20, ...
                'Expected 20 recordings per speaker.');

            rO_SS = localPearson(G.OverlapO, ...
                G.DeltaSI_SDR_SS_dB, false);

            rO_W = localPearson(G.OverlapO, ...
                G.DeltaSI_SDR_Wiener_dB, false);

            rVN_SS = localPearson(G.VariationVN, ...
                G.DeltaSI_SDR_SS_dB, true);

            rVN_W = localPearson(G.VariationVN, ...
                G.DeltaSI_SDR_Wiener_dB, true);

            newRow = table(snrs(i), noiseNames(j), ...
                speakers(k), height(G), ...
                rO_SS, rO_W, rVN_SS, rVN_W, ...
                'VariableNames', { ...
                'SNR_dB', 'Noise', 'Speaker', 'N', ...
                'r_O_SISDR_SS', 'r_O_SISDR_Wiener', ...
                'r_VN_SISDR_SS', 'r_VN_SISDR_Wiener'});

            speakerResults = [speakerResults; newRow];
        end
    end
end

writetable(speakerResults, fullfile(resultsDir, ...
    'acoustic_correlations_by_speaker.csv'));

disp('Speaker correlations at 0 dB SNR:');
disp(speakerResults(speakerResults.SNR_dB == 0, :));

disp('Correlation analysis completed.');

% Local function for Pearson correlation
function r = localPearson(x, y, checkVariation)

    x = double(x(:));
    y = double(y(:));

    if numel(x) < 3 || std(x) == 0 || std(y) == 0
        r = NaN;
        return;
    end

    % Do not interpret variation correlations when
    % the descriptor barely changes between recordings
    if checkVariation
        relativeRange = (max(x) - min(x)) / ...
            max(abs(mean(x)), eps);

        if relativeRange < 0.02
            r = NaN;
            return;
        end
    end

    C = corrcoef(x, y);
    r = C(1,2);

end
