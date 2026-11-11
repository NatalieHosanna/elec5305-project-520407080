# Investigating How Noise Characteristics Affect Speech Enhancement Performance

**ELEC5305 — Audio Signal Processing and Machine Learning**  
University of Sydney | Research Project | November 2026

## Project Overview

This project investigates which acoustic characteristics make noisy speech difficult to enhance, even when recordings have the same overall signal-to-noise ratio (SNR).

Rather than comparing enhancement algorithms only by noise category, the investigation examines two measurable properties: **time-frequency overlap** between speech and interference, and **noise spectral variation** over time.

Three enhancement methods were evaluated:

- Spectral subtraction
- Wiener-type filtering
- Pretrained DeepFilterNet3

The main evaluation measures are scale-invariant signal-to-distortion ratio (SI-SDR) and short-time objective intelligibility (STOI).

## Research Question

**How do time-frequency overlap and changes in background noise over time affect speech enhancement performance at the same overall SNR, and do traditional and modern enhancement methods experience similar difficulties?**

## Experimental Method

The study used VCTK-derived clean speech recordings and environmental noise recordings from DEMAND, together with generated white noise.

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
| Enhancement methods | Spectral subtraction, Wiener-type filtering, DeepFilterNet3 |
| Performance measures | SI-SDR improvement, STOI improvement |

The experimental workflow consisted of:

1. Preparing clean speech and noise recordings.
2. Generating controlled mixtures at the required input SNRs.
3. Calculating time-frequency overlap, spectral variation and an ideal ratio mask for acoustic analysis.
4. Applying the two classical enhancement methods in MATLAB.
5. Processing the same mixtures using pretrained DeepFilterNet3 without additional training.
6. Evaluating enhanced speech against the corresponding clean reference.
7. Analysing performance across noise conditions, SNR levels, speakers and acoustic descriptors.
8. Investigating individual recordings with unexpected results.

The classical methods used noise-power estimates from separately available noise recordings. They therefore represent reference-assisted experimental implementations rather than fully blind speech enhancement systems.

## Completed Work

- [x] Research question and literature review
- [x] Clean speech and noise preprocessing
- [x] Controlled mixture generation
- [x] Initial four-condition pilot experiment
- [x] Time-frequency overlap calculation
- [x] Noise spectral variation calculation
- [x] Ideal ratio mask calculation for acoustic analysis
- [x] MATLAB spectral subtraction implementation
- [x] MATLAB Wiener-type filtering implementation
- [x] STFT/ISTFT reconstruction and output-consistency checks
- [x] Comparison with VOICEBOX spectral subtraction
- [x] Comparison with Scalart's decision-directed Wiener implementation
- [x] Expanded classical experiment across 640 mixtures
- [x] Pretrained DeepFilterNet3 processing across 640 matched mixtures
- [x] SI-SDR and STOI evaluation
- [x] Mean and standard-deviation analysis across all SNR levels
- [x] Acoustic-property correlations
- [x] Separate-speaker correlation analysis
- [x] Individual performance-exception analysis
- [x] Spectrogram investigation of two selected recordings
- [x] Written Results, Discussion and Conclusion

The reference implementations use different processing settings. Their outputs were compared as independent references, not as numerically identical versions of the project's methods.

## Main Results

### Enhancement performance

DeepFilterNet3 produced larger mean SI-SDR and STOI improvements than the classical methods across the 16 combinations of noise condition and input SNR.

At **0 dB input SNR**, the mean improvements were:

| Noise | SS ΔSI-SDR (dB) | Wiener ΔSI-SDR (dB) | DeepFilterNet3 ΔSI-SDR (dB) | DeepFilterNet3 ΔSTOI |
|---|---:|---:|---:|---:|
| White | 4.62 | 6.65 | 14.89 | 0.0816 |
| Kitchen | 3.07 | 4.46 | 16.02 | 0.0198 |
| Traffic | 3.56 | 5.07 | 13.59 | 0.0647 |
| Public space | 2.28 | 3.03 | 8.95 | 0.0820 |

Each result is the average of 40 matched recordings.

### Acoustic characteristics

**Time-frequency overlap:** Higher overlap was generally associated with smaller SI-SDR improvements. However, the strength of this relationship varied between noise conditions, and the relationship with STOI improvement was not consistent.

**Noise spectral variation:** Variation in normalised noise spectral shape showed different relationships with SI-SDR and STOI. Greater variation did not consistently indicate greater enhancement difficulty.

These findings suggest that acoustic descriptors can help explain performance differences, but neither descriptor is sufficient to predict individual enhancement outcomes.

### Performance exceptions

Across all 640 mixtures:

| Observation | Count |
|---|---:|
| DeepFilterNet3 had lower SI-SDR improvement than at least one classical method | 8 |
| DeepFilterNet3 had lower STOI improvement than at least one classical method | 58 |
| DeepFilterNet3 produced negative STOI improvement | 47 |
| Unique mixtures meeting either classical-method comparison criterion | 65 |

These categories overlap.

### Individual case studies

**`p257_284.wav`, kitchen noise, 0 dB SNR:** DeepFilterNet3 achieved a 2.91 dB SI-SDR improvement, compared with 4.93 dB for Wiener-type filtering. However, DeepFilterNet3 produced a positive STOI change of 0.01290.

**`p257_311.wav`, kitchen noise, 0 dB SNR:** DeepFilterNet3 achieved a 9.29 dB SI-SDR improvement, but STOI decreased by 0.02092.

These examples demonstrate that improved waveform reconstruction does not always correspond to improved predicted speech intelligibility.

## Validation

The project included the following checks:

- Input SNR verification after mixture generation
- STFT/ISTFT reconstruction testing
- Saved audio and calculated metric consistency checks
- Reference comparisons with VOICEBOX and Scalart implementations
- Alignment checks for DeepFilterNet3 output recordings
- Validation of the expanded experiment's 640 matched mixtures

The initial STFT/ISTFT reconstruction test produced a relative error of approximately \(1.99 \times 10^{-16}\).

These checks support numerical consistency, but do not establish generalisation to unseen speakers and environments.

## Project Organisation

The local project workflow uses the following main directories:

```text
ELEC5305_Project/
├── data/
│   ├── speech/
│   ├── speech_batch/
│   └── noise/
├── matlab/
└── results/
    ├── validation/
    └── extended/
```

The MATLAB folder contains the experimental and analysis scripts. The results directory contains generated measurements, figures and evaluation outputs.

The principal results include the expanded experimental summary, full-SNR comparisons, acoustic correlations, reference validation and selected failure-case investigations.

Large datasets, model weights and third-party software may need to be obtained separately. The repository should document their sources and setup requirements rather than assume every external dependency is included.

## Software and Reproducibility

The experiments used MATLAB for signal generation, enhancement, feature extraction, evaluation and plotting.

DeepFilterNet3 was run locally using its Python command-line interface with a pretrained model and 48 kHz audio.

To reproduce the study, obtain the relevant speech and noise recordings, use the preprocessing and mixture-generation settings documented in the report, run the MATLAB experiment scripts, perform DeepFilterNet3 inference on the matched noisy recordings, and evaluate the saved outputs using the corresponding clean references.

The exact MATLAB toolbox requirements, random seed, selected noise channels and software versions should be documented alongside the runnable scripts.
## Dataset Processing and Reproducibility

The experiment used 40 clean speech recordings from two speakers (`p232` and `p257`), with 20 recordings per speaker.

The environmental noise recordings originated from the DEMAND dataset:

| Source environment | Local filename |
|---|---|
| DKITCHEN | `data/noise/stationary.wav` |
| STRAFFIC | `data/noise/traffic.wav` |
| PCAFETER | `data/noise/public_space.wav` |

White noise was generated directly in MATLAB.

### Random Seeds

The pilot experiment used MATLAB's Mersenne Twister generator:

`rng(5305, 'twister')`

The expanded white-noise mixtures were reproduced using:

`rng(5305 + 1000*i + q, 'twister')`

Here, `i` is the position of the speech recording in the alphabetically sorted file list, and `q` identifies the noise condition in this order:

1. White
2. Stationary (kitchen)
3. Traffic
4. Public space

### Preprocessing

- Sampling frequency: 48 kHz
- Multichannel audio converted to mono by averaging channels
- Speech mean removed and leading/trailing silence trimmed
- Noise scaled to the target global SNR
- Identical noise segments used for different SNR levels of the same speech/noise combination

The expanded results file, `results/extended/extended_results.csv`, records the `NoiseStartSample` used for each mixture.

The full dataset is not included in the repository due to its size. Source recordings must be obtained separately and organised using the folder structure above.
## Limitations

The study used only two speakers and a limited set of environmental noise recordings. The 640 mixtures reuse the same 40 utterances under multiple experimental conditions and should not be treated as independent speech samples.

The classical methods also used reference-assisted noise estimation, while DeepFilterNet3 relied on pretrained model parameters. These differences limit conclusions about which general class of algorithm is inherently superior.

Finally, SI-SDR and STOI are objective measures. Structured listening tests and additional perceptual quality measures would strengthen the evaluation.

## Future Work

Future investigations could include more speakers and independent noise recordings, blind noise estimation for the classical methods, additional acoustic descriptors, controlled listening tests and validation on a separate dataset.

## Project Links

- [GitHub Repository](https://github.com/NatalieHosanna/elec5305-project-520407080)
- [Project Website](https://Nataliehosanna.github.io/elec5305-project-520407080/)

The demonstration video and final report should be linked here once uploaded.

## Key References

- Boll (1979), *Suppression of Acoustic Noise in Speech Using Spectral Subtraction*.
- Scalart and Vieira Filho (1996), *Speech Enhancement Based on a Priori Signal to Noise Estimation*.
- Taal et al. (2011), *An Algorithm for Intelligibility Prediction of Time-Frequency Weighted Noisy Speech*.
- Le Roux et al. (2019), *SDR — Half-Baked or Well Done?*
- Wang, Narayanan and Wang (2014), *On Training Targets for Supervised Speech Separation*.
- Schröter et al. (2022), *DeepFilterNet: A Low Complexity Speech Enhancement Framework for Full-Band Audio Based on Deep Filtering*.
