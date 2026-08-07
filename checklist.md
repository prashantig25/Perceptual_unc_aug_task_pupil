# Code Checklist

## Setup
- [ ] **Reboot computer:** Perform before deconvolution-based preprocessing check.
- [ ] **Run testing:** Execute unit and integration tests:
  - Behavior: `unitTestsLrAnalyses.m`
  - Pupil: `unit_tests.m`

---

## Behavioral Analysis
- [ ] **Descriptive behavioral analyses:** `descriptive_behv.m`
- [ ] **Behavioral regression:** `LR_analysis_pupil.m`

---

## Pupil Analysis Pipeline
- [ ] **Run pupil preprocessing:** `preprocessing_script.m`
- [ ] **Extract pupil signal:** `get_pupilsignal.m`
- [ ] **Extract gaze data:** `gazeposition.m`
- [ ] **Summarize pupil signal across whole trial:** `fulltrial.m`
- [ ] **Run simplified binned regression:** `get_pupilPEbins.m`
- [ ] **Run main pupil regressions:** `fitOLS_models.m`
- [ ] **Pregenerate random starting points:** `pregenSP.m` *(for heteroskedastic regression)*
- [ ] **Run heteroskedastic regressions:** `fitHet_models.m`
- [ ] **Run main article residual analysis:** `residualUP_analysis.m`
- [ ] **Task G:** `arousal_variabilityInteractions.m`
- [ ] **Run supplementary residual analysis:** `plotPatchResidual.m`

---

## General Checks & Parameter Settings

| Category / Variable | Setting / Rule | Details / Context |
| :--- | :--- | :--- |
| **Directory Check** | Check `prepoc_dir` and `save_dir` | Verify across all scripts that paths point to the correct preprocessing directory (manually and via `checkPathKeywords`). |
| **Filter Settings** | `noFiltering = 1`<br>`noFiltering = 0` | Linear and cubic spline<br>Deconvolution-based pipeline |
| **Interpolation Settings** | `linearInt = 1`<br>`linearInt = 0` | Linear and convolution-based pipeline<br>Cubic spline |
| **`time_pupil`** | `feedback_locked - 1000`<br>`patch_locked - 300`<br>`response_locked - 230` | Applicable for `get_pupilsignal` and `gazeposition` |
| **`time_base`** | `time_base = 10` | Standard setting paired with `baseline = "trial-specific"` |
| **Heteroskedastic Flags** | `reg_het1.use_sp = 1`<br>`reg_het3.use_sp = 0` | Set in `fitHet_models.m`<br>Set in `pregenSP.m` |