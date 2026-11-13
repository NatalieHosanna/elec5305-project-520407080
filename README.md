
# Investigating How Noise Characteristics Affect Speech Enhancement Performance

**ELEC5305 — Acoustics, Speech and Signal Processing**

## Project Overview

This project investigates which acoustic characteristics make noisy speech difficult to enhance, even when recordings have the same overall signal to noise ratio (SNR).

Rather than comparing enhancement algorithms only by noise category, the investigation examines two measurable properties:

- **Time frequency overlap:** How much speech and interference energy occupy the same time frequency regions.
- **Noise spectral variation:** How the frequency distribution of background noise changes between consecutive time frames.

Three enhancement methods were evaluated:

- Spectral subtraction
- Wiener type filtering
- Pretrained DeepFilterNet

Enhancement performance was evaluated using Scale Invariant Signal to Distortion Ratio (SI-SDR) and Short Time Objective Intelligibility (STOI).

The main goal was to investigate whether these acoustic characteristics help explain why enhancement methods perform differently under the same overall SNR.

## Research Question

**How do time frequency overlap and changes in background noise over time affect speech enhancement performance at the same overall SNR, and do traditional and modern enhancement methods experience similar difficulties?**

## Experimental Method

The study used clean speech recordings derived from the VCTK corpus, environmental noise recordings from DEMAND, and generated white noise.

| Parameter | Setting |
|---|---|
| Clean speech | 40 utterances from 2 speakers |
| Noise conditions | White, kitchen, traffic, public space |
| Input SNR levels | −5, 0, 5 and 10 dB |
| Total mixtures | 640 |
| Sampling frequency | 48 kHz |
| STFT window | 1024-sample periodic Hann |
| Hop size | 256 samples |
| FFT length | 1024 |
| Classical gain floor | 0.05 |
| Enhancement methods | Spectral subtraction, Wiener type filtering, DeepFilterNet |
| Performance measures | SI-SDR improvement, STOI improvement |

### Experimental Workflow

1. Prepare clean speech and environmental noise recordings.
2. Generate controlled noisy speech mixtures at the required SNR levels.
3. Calculate time frequency overlap, noise spectral variation and an ideal ratio mask for acoustic analysis.
4. Apply spectral subtraction and Wiener type filtering in MATLAB.
5. Validate the classical implementations against independent reference implementations.
6. Process the matched noisy recordings using pretrained DeepFilterNet.
7. Evaluate the enhanced recordings using SI-SDR and STOI.
8. Analyse performance across noise conditions, input SNRs, speakers and acoustic descriptors.
9. Investigate unusual results using numerical measurements and spectrograms.

The classical enhancement methods used noise power estimates from separately available noise recordings. They are therefore **reference assisted implementations**, rather than fully blind enhancement systems.

The external VOICEBOX and Scalart implementations were used as independent comparison methods. They should not be treated as numerically identical versions of the project's algorithms.

## Completed Work

- [x] Research question and literature review
- [x] Clean speech and noise preprocessing
- [x] Controlled SNR mixture generation
- [x] Initial pilot experiment with four noise conditions
- [x] Time frequency overlap calculation
- [x] Noise spectral variation calculation
- [x] Ideal ratio mask calculation for acoustic analysis
- [x] MATLAB spectral subtraction implementation
- [x] MATLAB Wiener type filtering implementation
- [x] STFT/ISTFT reconstruction checks
- [x] Input SNR verification
- [x] Comparison with VOICEBOX spectral subtraction
- [x] Comparison with the Scalart/Plapous TSNR reference implementation
- [x] Expanded classical experiment across 640 mixtures
- [x] Pretrained DeepFilterNet evaluation across 640 matched mixtures
- [x] SI-SDR and STOI evaluation
- [x] Mean and standard deviation analysis
- [x] Acoustic property correlation analysis
- [x] Separate speaker correlation analysis
- [x] Enhancement exception analysis
- [x] Spectrogram investigation of two selected recordings
- [x] Written Results, Discussion and Conclusion

## Project Organisation

The project uses the following folder structure:

```text
ELEC5305_Project/
├── README.md
├── matlab/
│   ├── run_pilot.m
│   ├── validate_pilot.m
│   ├── compare_reference_methods.m
│   ├── run_extended_study.m
│   ├── analyse_acoustic_relationships.m
│   ├── prepare_deepfilter_batch.m
│   ├── evaluate_deepfilter_all_snr.m
│   ├── analyze_deepfilter_all_snr.m
│   ├── plot_deepfilter_all_snr.m
│   ├── investigate_failure_cases.m
│   └── ... other supporting MATLAB scripts
├── voicebox/                        # VOICEBOX functions on GitHub
├── wienernoisereduction-2.1.0/      # reference package in local code ZIP
├── data/
│   ├── speech/clean.wav
│   ├── speech_batch/                 # 40 selected clean WAV files
│   └── noise/
│       ├── stationary.wav
│       ├── traffic.wav
│       └── public_space.wav
└── results/
    ├── pilot_results.csv
    ├── validation/
    └── extended/
```

**Note:** This tree illustrates the main local layout; it is not a claim that every folder is currently hosted on GitHub. The submitted code ZIP stores VOICEBOX at `sap-voicebox-master/voicebox/`, while the GitHub folder is named `voicebox/`. The reference comparison script supports both layouts. Large source datasets and the generated 640-file intermediate audio folders may be absent from GitHub. Those generated folders are created by the scripts below.

The MATLAB scripts use the project folder as the reference location for data and results.

The `matlab/` folder contains the experimental scripts, supporting functions and plotting scripts. Third-party reference code is kept separately from the project's own MATLAB scripts.

The `results/` directory contains generated measurements, figures and evaluation outputs.

## Software Requirements

### MATLAB

MATLAB is used for:

- Audio preprocessing and resampling
- Controlled noise mixing
- STFT and inverse STFT processing
- Spectral subtraction and Wiener type filtering
- Acoustic descriptor calculation
- SI-SDR and STOI evaluation
- Statistical analysis and plotting

The implementation uses functions from:

- MATLAB
- Signal Processing Toolbox
- Audio Toolbox

MATLAB R2024a or later is recommended when using the built in `stoi` function.

### Python and DeepFilterNet

The modern enhancement experiment used:

- Python 3.11
- PyTorch and torchaudio
- DeepFilterNet Python package
- Pretrained DeepFilterNet model

Python was used for pretrained DeepFilterNet inference. The experimental analysis and evaluation were carried out in MATLAB.

External implementation:

[DeepFilterNet GitHub Repository](https://github.com/Rikorose/DeepFilterNet)

### Classical Reference Implementations

The initial MATLAB methods were also compared with third-party code:

- [VOICEBOX](https://github.com/ImperialCollegeLondon/sap-voicebox)
- [Scalart Wiener Noise Reduction](https://www.mathworks.com/matlabcentral/fileexchange/24462-wiener-filter-for-noise-reduction-and-speech-enhancement)

The submitted code ZIP includes these external reference implementations, separate from the project's own MATLAB code. The reference script locates VOICEBOX in either `voicebox/` or `sap-voicebox-master/voicebox/`, and the Wiener implementation in `wienernoisereduction-2.1.0/` or the project root. Preserve the original licence and copyright files when copying the third-party code. These implementations are needed for `compare_reference_methods.m`, but not for the project's own classical processing scripts.

## Dataset Setup

### Clean Speech Recordings

The clean speech recordings were obtained from the VoiceBank-DEMAND speech dataset, which contains speech derived from VCTK.

Dataset source:

[VoiceBank-DEMAND — University of Edinburgh](https://datashare.ed.ac.uk/items/6ed35425-bf14-4d2b-93a1-0a4984952757)

The pilot experiment uses:

`data/speech/clean.wav`

The expanded experiment uses 40 recordings from speakers `p232` and `p257`, with 20 recordings from each speaker.

The exact recordings selected were:

```text
p232_010.wav   p232_020.wav
p232_031.wav   p232_049.wav
p232_099.wav   p232_128.wav
p232_129.wav   p232_177.wav
p232_193.wav   p232_199.wav
p232_206.wav   p232_213.wav
p232_271.wav   p232_286.wav
p232_289.wav   p232_303.wav
p232_319.wav   p232_365.wav
p232_385.wav   p232_397.wav

p257_006.wav   p257_011.wav
p257_035.wav   p257_092.wav
p257_094.wav   p257_133.wav
p257_163.wav   p257_167.wav
p257_200.wav   p257_250.wav
p257_256.wav   p257_261.wav
p257_278.wav   p257_284.wav
p257_311.wav   p257_341.wav
p257_383.wav   p257_418.wav
p257_426.wav   p257_433.wav
```

These files should be placed inside:

`data/speech_batch/`

### Environmental Noise Recordings

Environmental noise recordings were obtained from the DEMAND dataset.

Dataset source:

[DEMAND Environmental Noise Dataset](https://zenodo.org/records/1227121)

Three environmental recordings were selected:

| DEMAND environment | Noise condition | Local filename |
|---|---|---|
| DKITCHEN | Kitchen | `stationary.wav` |
| STRAFFIC | Traffic | `traffic.wav` |
| PCAFETER | Public space | `public_space.wav` |

The environmental recordings should be prepared as 48 kHz WAV files using the same source material and preprocessing as the experiment, then placed in:

`data/noise/`

Where recordings contain multiple channels, the project converts them to mono by averaging the channels.

White noise is generated directly in MATLAB and does not require a separate WAV file.

### Audio Preprocessing

The main preprocessing settings were:

- Convert multichannel speech and noise to mono.
- Resample audio to 48 kHz when required.
- Remove the mean from the speech signal.
- Trim leading and trailing silence using a threshold of 2% of the maximum speech amplitude.
- Retain an additional 0.1 seconds around detected speech.
- Scale the clean speech to a peak amplitude of 0.5.
- Scale the interference to achieve the required input SNR.

These preprocessing steps are implemented in the MATLAB scripts.

The original full datasets are not included in the repository because of their size. The relevant recordings must be obtained from their original sources.

## Reproducibility Settings

### Random Seeds

The pilot experiment used MATLAB's Mersenne Twister random number generator:

```matlab
rng(5305, 'twister');
```

The expanded white noise mixtures were reproduced using:

```matlab
rng(5305 + 1000*i + q, 'twister');
```

Here:

- `i` is the speech recording's position in the alphabetically sorted file list.
- `q` is the noise condition index.

The condition order is:

1. White
2. Stationary (kitchen)
3. Traffic
4. Public space

### Noise Segment Selection

For each speech recording and recorded noise condition, the same selected noise segment was used at all four input SNR levels.

This ensures that changing the input SNR changes the relative noise amplitude without changing the underlying interference segment.

The starting position of each environmental noise segment is stored in the `NoiseStartSample` column of:

`results/extended/extended_results.csv`

For generated white noise, `NoiseStartSample` is recorded as zero because no external recording segment is selected.

The recorded starting sample is a MATLAB sample index for the environmental noise recording.

Using the same original dataset files, file ordering, preprocessing and recorded segment positions is important for reproducing the measurements.

## How to Run the Project

The following instructions describe the workflow used for the experiments.

### Step 1 — Download the Repository

Download or clone the project:

```bash
git clone https://github.com/NatalieHosanna/elec5305-project-520407080.git
```

Open the downloaded project folder.

The following directories should be available after dataset preparation:

```text
matlab/
data/speech/
data/speech_batch/
data/noise/
```

If the original datasets are not included, obtain the specific recordings listed above and prepare them at 48 kHz. For exactly matching the reported results, the original processed audio, the same noise channels and the recorded `NoiseStartSample` positions are needed; downloading a different release or processing different channels can change the measurements.

### Step 2 — Set Up MATLAB

Open MATLAB and set the **Current Folder** to the main project directory containing `matlab/` and `data/`.

Run:

```matlab
projectDir = pwd;
addpath(fullfile(projectDir, 'matlab'));
```

This adds the project MATLAB scripts to the search path.

### Step 3 — Run the Pilot Experiment

The pilot experiment tests one speech recording under four noise conditions at 0 dB SNR.

Run:

```matlab
run_pilot
```

This script:

1. Loads the clean speech recording.
2. Loads or generates the four noise conditions.
3. Creates mixtures at 0 dB SNR.
4. Calculates STFT representations.
5. Measures time frequency overlap and noise spectral variation.
6. Applies spectral subtraction and Wiener type filtering.
7. Calculates SI-SDR measurements.
8. Saves example enhanced audio and spectrograms.

The results are saved in the project's `results/` folder.

The main pilot CSV is:

`results/pilot_results.csv`

The script also generates audio recordings and spectrogram figures for the individual noise conditions.

### Step 4 — Validate the Initial Implementation

Run the initial validation:

```matlab
validate_pilot
```

The submitted ZIP bundles `v_specsub.m` (VOICEBOX) and `WienerNoiseReduction.m` (Scalart/Plapous TSNR reference). A GitHub clone needs the same source files, or an equivalent external installation, for this optional reference-comparison step. `compare_reference_methods.m` automatically adds the supported reference folders to the MATLAB path. Run:

```matlab
compare_reference_methods
```

The script checks for both functions before evaluating them. On the tested Mac, the availability checks for both reference functions returned `1`. Those checks confirm the functions can be found; successful completion of `compare_reference_methods` is the stronger check that their required dependencies work. These comparisons help assess the behaviour of the project implementations.

The reference algorithms differ from the project implementations in processing parameters and noise estimation procedures. Matching numerical results are therefore not expected. Retain the original third-party licence and copyright notices with any copies of these functions.

### Step 5 — Run the Expanded Experiment

The expanded experiment uses:

- 40 clean speech recordings
- Four noise conditions
- Four input SNR levels

This produces 640 mixtures.

Run:

```matlab
run_extended_study
```

The experiment records:

- Speech recording and noise condition
- Input SNR
- Selected noise segment information
- Time frequency overlap
- Noise spectral variation
- Classical enhancement SI-SDR and STOI improvements

The primary output file is:

`results/extended/extended_results.csv`

To confirm the expected number of results:

```matlab
T = readtable(fullfile(projectDir, ...
    'results', 'extended', 'extended_results.csv'));

fprintf('Number of mixtures: %d\n', height(T));
```

The expected number is:

```text
Number of mixtures: 640
```

To summarise and analyse the classical experiment, run:

```matlab
summarise_extended_results
analyse_acoustic_relationships
plot_extended_study
```

These scripts generate summary measurements, acoustic correlations and figures describing the expanded experiment.

### Step 6 — Install DeepFilterNet

The modern comparison uses a pretrained model from the DeepFilterNet framework. The original batch commands shown below selected `DeepFilterNet` explicitly using the `-m` option.

From Windows Command Prompt, open the main project directory.

Create a Python virtual environment:

```cmd
py -3.11 -m venv .venv
```

Install the DeepFilterNet package and its dependencies according to the official DeepFilterNet instructions.

For an environment with compatible PyTorch dependencies installed:

```cmd
.venv\Scripts\python.exe -m pip install deepfilternet
```

The complete installation instructions are available from:

[DeepFilterNet — Official GitHub Repository](https://github.com/Rikorose/DeepFilterNet)

The completed experiment used pretrained inference without training or modifying model weights.

The pretrained DeepFilterNet model was used for speech enhancement. The inference command selected the model using `-m DeepFilterNet`, and the enhanced WAV files were saved with the suffix `_DeepFilterNet.wav`, consistent with the MATLAB evaluation scripts.
### Step 7 — Prepare the DeepFilterNet Inputs

Return to MATLAB.

Generate the matched noisy inputs for the expanded experiment:

```matlab
prepare_deepfilter_batch
```

The supplied script is already configured for 40 speech recordings and all four SNR levels (`maxFiles = 40`, `snrLevels = [-5, 0, 5, 10]`).

**These input folders are created when `prepare_deepfilter_batch` is executed. They are not required to already exist in the submitted ZIP or GitHub repository.**

The generated input files are stored in:

- `results/extended/deepfilter_batch_inputs/noisy/` — 640 noisy recordings
- `results/extended/deepfilter_batch_inputs/clean/` — 640 matched clean references
- `results/extended/deepfilter_batch_inputs/batch_manifest.csv` — recording correspondence and scaling information

The expected full experiment contains 640 matched noisy mixtures.

The preparation stage should be checked against the existing experiment results to ensure that the generated mixtures are consistent with those used for the classical methods.

### Step 8 — Run DeepFilterNet Inference

In Windows Command Prompt, from the project directory, an individual recording can be processed using:

```cmd
.venv\Scripts\deepFilter.exe -m DeepFilterNet --output-dir "results\extended\deepfilter_batch_outputs" "results\extended\deepfilter_batch_inputs\noisy\p232_010_white_0dB_noisy.wav"
```

The enhanced recording is saved in:

`results/extended/deepfilter_batch_outputs/`

The submitted ZIP includes selected example enhanced recordings and CSV results, **not** all 640 intermediate enhanced WAV files. The full output collection must be regenerated if repeating the experiment. For this command, the expected filename suffix is `_DeepFilterNet.wav`, which `evaluate_deepfilter_all_snr.m` searches for.

To process all prepared noisy WAV files using a Windows Command Prompt loop:

```cmd
for %F in (results\extended\deepfilter_batch_inputs\noisy\*.wav) do ".venv\Scripts\deepFilter.exe" -m DeepFilterNet --output-dir "results\extended\deepfilter_batch_outputs" "%~fF"
```

This is **Windows Command Prompt** syntax (for an interactive prompt, use `%F`; in a `.bat` file, use `%%F`). It processes the 640 WAV files individually. The command uses the same `DeepFilterNet` model argument and output naming convention as the saved evaluation. Do not silently change `-m` to another model, because that can change the algorithm and the output suffix.

**macOS/Linux alternative:** Create a virtual environment with `python3 -m venv .venv`, activate it using `source .venv/bin/activate`, and install DeepFilterNet using `python -m pip install deepfilternet` after installing compatible PyTorch dependencies. Once `prepare_deepfilter_batch` has been run in MATLAB, the corresponding shell loop is:

```bash
mkdir -p results/extended/deepfilter_batch_outputs
for f in results/extended/deepfilter_batch_inputs/noisy/*.wav; do
    deepFilter -m DeepFilterNet --output-dir results/extended/deepfilter_batch_outputs "$f"
done
```

These commands regenerate intermediate files; they do not require the input folder to be included in the repository. 

The complete experiment requires 640 enhanced WAV files.

To check the number of output recordings in Windows Command Prompt:

```cmd
dir /b "results\extended\deepfilter_batch_outputs\*.wav" | find /c /v ""
```

The expected count is:

```text
640
```

### Step 9 — Evaluate DeepFilterNet Results in MATLAB

After all enhanced WAV recordings have been generated, return to MATLAB.

Run:

```matlab
evaluate_deepfilter_all_snr
```

This evaluates the DeepFilterNet outputs against their corresponding clean references and calculates SI-SDR and STOI improvements.

Next, run:

```matlab
analyze_deepfilter_all_snr
```

This performs the acoustic correlation and exception analysis using the matched enhancement results.

Generate the full SNR figures using:

```matlab
plot_deepfilter_all_snr
```

To investigate selected individual recordings:

```matlab
investigate_failure_cases
```

The results are saved under:

`results/extended/`

### Step 10 — Verify the Generated Results

After running the scripts, check that:

- The expanded experiment contains 640 mixture results.
- The DeepFilterNet evaluation contains 640 matched enhanced recordings.
- The noise and SNR groups contain 40 speech recordings each.
- Achieved input SNR values agree with their targets.
- Saved audio and evaluation metrics correspond to the same mixtures.
- DeepFilterNet outputs are aligned with the clean reference recordings.

These checks provide numerical and processing consistency. They do not establish generalisation beyond the selected dataset.

## Main Results

### Enhancement Performance

DeepFilterNet achieved larger mean SI-SDR and STOI improvements than the classical methods across all 16 tested noise and SNR combinations.

At **0 dB input SNR**, the mean results were:

**Mean SI-SDR improvement (dB)**

| Noise | Spectral subtraction | Wiener type filtering | DeepFilterNet |
|---|---:|---:|---:|
| White | 4.62 | 6.65 | 14.89 |
| Kitchen | 3.07 | 4.46 | 16.02 |
| Traffic | 3.56 | 5.07 | 13.59 |
| Public space | 2.28 | 3.03 | 8.95 |

**Mean STOI improvement**

| Noise | Spectral subtraction | Wiener type filtering | DeepFilterNet |
|---|---:|---:|---:|
| White | +0.0046 | +0.0058 | +0.0816 |
| Kitchen | −0.0032 | −0.0039 | +0.0198 |
| Traffic | +0.0072 | +0.0089 | +0.0647 |
| Public space | −0.0122 | −0.0159 | +0.0820 |

Each noise condition contains 40 recordings from two speakers.

The differences show that performance depends on more than the overall input SNR.

DeepFilterNet generally achieved larger average improvements, but its performance also varied between noise conditions and individual recordings.

### Acoustic Characteristics

**Time frequency overlap**

Higher overlap was generally associated with smaller SI-SDR improvements. However, the strength of the relationship varied between noise conditions and was less consistent when evaluating STOI.

**Noise spectral variation**

Noise spectral variation measured changes in the normalised noise spectrum over time.

Greater variation did not consistently correspond to poorer enhancement performance. The relationships differed between SI-SDR and STOI, showing that spectral variation alone is not a reliable measure of enhancement difficulty.

These findings suggest that both descriptors provide useful information about the acoustic conditions, but neither fully predicts enhancement outcomes.

### Performance Exceptions

Across the 640 matched mixtures:

| Observation | Count |
|---|---:|
| DeepFilterNet had lower SI-SDR improvement than at least one classical method | 8 |
| DeepFilterNet had lower STOI improvement than at least one classical method | 58 |
| DeepFilterNet produced negative STOI improvement | 47 |
| Unique mixtures meeting either classical method comparison criterion | 65 |

These categories overlap.

The exception analysis shows that DeepFilterNet's larger average improvements do not mean that it performs best for every recording.

## Individual Case Studies

Two kitchen noise recordings were selected for closer analysis at 0 dB input SNR.

### Case Study 1 — p257_284.wav

| Method | SI-SDR improvement (dB) | STOI improvement |
|---|---:|---:|
| Spectral subtraction | +3.3504 | −0.00055 |
| Wiener type filtering | +4.9345 | −0.00151 |
| DeepFilterNet | +2.9077 | +0.01290 |

DeepFilterNet produced a smaller SI-SDR improvement than Wiener type filtering, but achieved a positive STOI change.

This demonstrates that the method producing the largest SI-SDR improvement is not necessarily the method producing the largest predicted intelligibility improvement.

### Case Study 2 — p257_311.wav

| Method | SI-SDR improvement (dB) | STOI improvement |
|---|---:|---:|
| Spectral subtraction | +0.6489 | −0.03029 |
| Wiener type filtering | +0.9413 | −0.03650 |
| DeepFilterNet | +9.2852 | −0.02092 |

DeepFilterNet substantially improved SI-SDR, but STOI decreased.

The two case studies show that improvements in waveform level reconstruction do not always correspond to improvements in predicted intelligibility.

The corresponding spectrograms and numerical results are discussed in the project report.

## Experimental Validation

The project included several verification steps.

### Controlled SNR Verification

All mixtures were checked after noise scaling to confirm that the intended input SNR was achieved.

The expanded experiment used matched noise segments across different input SNR levels.

### STFT/ISTFT Reconstruction

The initial STFT/ISTFT implementation was tested by reconstructing a clean speech signal without enhancement.

The relative reconstruction error was approximately:

`1.99 × 10^-16`

This indicates that the reconstruction process introduced negligible numerical error for the tested signal.

### Reference Implementation Comparison

The classical MATLAB methods were compared with external implementations from VOICEBOX and Scalart.

The initial 0 dB SI-SDR improvements were:

| Noise | VOICEBOX (dB) | Scalart/Plapous TSNR (dB) |
|---|---:|---:|
| White | 9.67 | 10.99 |
| Kitchen | 8.41 | 13.03 |
| Traffic | 2.99 | 2.94 |
| Public space | 2.82 | 2.71 |

These are comparisons between different implementations. Their noise estimation methods and processing settings differ, so identical numerical results are not expected.

### DeepFilterNet Evaluation

The 640 DeepFilterNet outputs were evaluated against matched clean speech recordings.

The evaluation included sampling rate and alignment checks, SI-SDR improvement, STOI improvement, and comparisons with the classical results.

The saved CSV results provide the underlying numerical measurements used in the report.

## Example Output Files

The following files are generated by the project scripts and are useful for checking the work:

| File | Description |
|---|---|
| `results/pilot_results.csv` | Initial pilot measurements |
| `results/validation/reference_comparison.csv` | External reference implementation comparison |
| `results/extended/extended_results.csv` | Measurements from the 640-mixture classical experiment |
| `results/extended/acoustic_correlations_by_noise_snr.csv` | Classical acoustic correlations |
| `results/extended/acoustic_correlations_by_speaker.csv` | Speaker specific classical correlations |
| `results/extended/all_snr_acoustic_correlations.csv` | Expanded correlations including DeepFilterNet |
| `results/extended/all_snr_exception_cases.csv` | Individual enhancement exceptions |
| `results/extended/deepfilter_all_snr_metrics.csv` | All 640 matched enhanced results |
| `results/extended/deepfilter_all_snr_summary.csv` | Means and standard deviations for the 16 groups |
| `results/extended/all_snr_sisdr_comparison.png` | Full SNR SI-SDR comparison plot |
| `results/extended/all_snr_stoi_comparison.png` | Full SNR STOI comparison plot |

The MATLAB plotting scripts also produce figures showing:

- SI-SDR improvement across SNR levels
- STOI improvement across SNR levels
- Acoustic characteristics versus enhancement performance
- Spectrogram comparisons for selected individual recordings

If a results file is not included, the corresponding script must be run to generate it.

## Limitations

The study used 40 speech recordings from only two speakers.

Although 640 mixtures were evaluated, the same speech recordings were reused across noise conditions and SNR levels. These are repeated experimental measurements, not 640 independent speech utterances.

The environmental recordings were also drawn from a limited selection of noise environments.

The classical methods used reference assisted noise power estimation, whereas DeepFilterNet used a pretrained model. This affects the interpretation of comparisons between the implementations.

The inference command used for saved outputs is documented above. Finally, SI-SDR and STOI are objective measures; they do not provide a complete assessment of perceived speech quality.

## Future Work

Future investigations could include:

- More speakers and independent speech recordings
- Additional environmental noise recordings
- Practical noise estimation using only the noisy mixture
- Further acoustic descriptors based on time frequency masking
- Structured listening tests
- Additional perceptual quality measures such as ViSQOL
- Evaluation on an independent dataset such as NOIZEUS

These would help determine whether the observed relationships generalise beyond the tested conditions.

## Project Links

- [GitHub Repository](https://github.com/NatalieHosanna/elec5305-project-520407080)
- [Project Website](https://Nataliehosanna.github.io/elec5305-project-520407080/)
- [Project Video](https://youtu.be/rx2VNpIAeMM)

## Key References

- Boll (1979), *Suppression of Acoustic Noise in Speech Using Spectral Subtraction*.
- Scalart and Vieira Filho (1996), *Speech Enhancement Based on a Priori Signal to Noise Estimation*.
- Plapous et al. (2006), *Improved Signal-to-Noise Ratio Estimation for Speech Enhancement*.
- Taal et al. (2011), *An Algorithm for Intelligibility Prediction of Time Frequency Weighted Noisy Speech*.
- Le Roux et al. (2019), *SDR — Half-Baked or Well Done?*
- Wang, Narayanan and Wang (2014), *On Training Targets for Supervised Speech Separation*.
- Liang et al. (2013), *The Optimal Ratio Time Frequency Mask for Speech Separation in Terms of the Signal-to-Noise Ratio*.
- Schröter et al. (2022), *DeepFilterNet: A Low Complexity Speech Enhancement Framework for Full-Band Audio Based on Deep Filtering*.
