
% ELEC5305 - Acoustic correlation analysis across SNR levels
% Compare associations for classical methods and DeepFilterNet

clear;
clc;

projectDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(projectDir, 'results', 'extended');

T = readtable(fullfile(resultsDir, ...
    'deepfilter_all_snr_metrics.csv'));

assert(height(T) == 640, ...
    'Expected 640 matched experimental results.');

snrLevels = [-5, 0, 5, 10];

noiseNames = ["white", "stationary", ...
    "traffic", "public_space"];

speakerGroups = ["all", "p232", "p257"];

sisdrCols = {'SI_SDR_SS', ...
    'SI_SDR_Wiener', 'SI_SDR_DeepFilterNet'};

stoiCols = {'STOI_SS', ...
    'STOI_Wiener', 'STOI_DeepFilterNet'};

R = table();

% Analyse each noise and SNR separately
for snrDB = snrLevels

    for noise = noiseNames

        for speaker = speakerGroups

            G = T( ...
                T.SNR_dB == snrDB & ...
                string(T.Noise) == noise, :);

            if speaker ~= "all"
                G = G(string(G.Speaker) == speaker, :);
            end

            if speaker == "all"
                assert(height(G) == 40, ...
                    'Expected 40 recordings per group.');
            else
                assert(height(G) == 20, ...
                    'Expected 20 recordings per speaker.');
            end

            % Twelve correlation coefficients:
            % O and V_N versus SI-SDR and STOI
            % for each of the three methods
            r = NaN(1,12);

            for j = 1:3

                si = G.(sisdrCols{j});
                st = G.(stoiCols{j});

                r(j) = safePearson(G.OverlapO, si);

                r(3+j) = safePearson(G.OverlapO, st);

                % White noise has extremely small
                % variation in V_N; do not interpret
                % correlations with this descriptor.
                if noise ~= "white"

                    r(6+j) = safePearson( ...
                        G.VariationVN, si);

                    r(9+j) = safePearson( ...
                        G.VariationVN, st);

                end

            end

            newRow = table( ...
                snrDB, noise, speaker, height(G), ...
                r(1), r(2), r(3), ...
                r(4), r(5), r(6), ...
                r(7), r(8), r(9), ...
                r(10), r(11), r(12), ...
                'VariableNames', { ...
                'SNR_dB', 'Noise', 'Speaker', 'N', ...
                'r_O_SI_SS', 'r_O_SI_Wiener', ...
                'r_O_SI_DeepFilterNet', ...
                'r_O_STOI_SS', 'r_O_STOI_Wiener', ...
                'r_O_STOI_DeepFilterNet', ...
                'r_VN_SI_SS', 'r_VN_SI_Wiener', ...
                'r_VN_SI_DeepFilterNet', ...
                'r_VN_STOI_SS', 'r_VN_STOI_Wiener', ...
                'r_VN_STOI_DeepFilterNet'});

            R = [R; newRow];

        end
    end
end

assert(height(R) == 48, ...
    'Expected 48 group/speaker summaries.');

% Save every correlation
writetable(R, fullfile(resultsDir, ...
    'all_snr_acoustic_correlations.csv'));

% Display the pooled-speaker analysis
overall = R(R.Speaker == "all", :);

disp(' ');
disp('Correlations for each noise and SNR:');
disp(overall);

% Identify DeepFilterNet exceptions
bestClassicalSI = max( ...
    T.SI_SDR_SS, T.SI_SDR_Wiener);

bestClassicalSTOI = max( ...
    T.STOI_SS, T.STOI_Wiener);

lowerSI = T.SI_SDR_DeepFilterNet < bestClassicalSI;

lowerSTOI = T.STOI_DeepFilterNet < bestClassicalSTOI;

negativeSTOI = T.STOI_DeepFilterNet < 0;

fprintf('\nDeepFilterNet exception counts:\n');

fprintf('Lower SI-SDR improvement than a classical method: %d\n', ...
    sum(lowerSI));

fprintf('Lower STOI improvement than a classical method: %d\n', ...
    sum(lowerSTOI));

fprintf('Negative STOI improvement: %d\n', ...
    sum(negativeSTOI));

% Save every case where DeepFilterNet performs
% worse than a classical method on either metric
exceptionRows = T(lowerSI | lowerSTOI, :);

writetable(exceptionRows, ...
    fullfile(resultsDir, ...
    'all_snr_exception_cases.csv'));

disp(' ');
disp('Correlation and exception analysis completed.');

% ============================================
% LOCAL FUNCTION
% ============================================

function r = safePearson(x, y)

    x = double(x(:));
    y = double(y(:));

    valid = isfinite(x) & isfinite(y);

    x = x(valid);
    y = y(valid);

    if numel(x) < 5 || ...
            std(x) < 1e-10 || ...
            std(y) < 1e-10

        r = NaN;
        return;

    end

    C = corrcoef(x, y);
    r = C(1,2);

end
