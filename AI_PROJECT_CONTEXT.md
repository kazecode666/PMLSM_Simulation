# AI project context

## Authoritative files

- `PMLSM_ThreeLoop_Simple.slx`: independent three-loop algorithm simulation; current defaults are in `init_PMLSM_ThreeLoop_Simple.m`.
- `design_PMLSM_three_loop.m`: motor-parameter-based three-loop tuning.
- `pmlsm_scurve_profile.m`: smooth acceleration / cruise / deceleration position trajectory; required by Simple_Host.
- `run_PMLSM_ThreeLoop_Simple(100)`: run the simple model with duration based on trajectory length. See `docs/ThreeLoop_SCurve.md` for current cruise-profile validation and historical dead-time comparison.

- `PMLSM_MIL_ControlCore_Sim.slx`: main MIL plant/inverter/sensor/test-bench model.
- `PMLSM_ControlCore_Block.slx`: referenced controller model.
- Main InitFcn: `init_PMLSM_control_params; init_PMLSM_plant_params; init_PMLSM_mil_test_params;`
- `init_PMLSM_control_params.m` calls `PMSLM_Init_Params_MBDL4.m`. Keep this parameter file even though the hardware code-generation model is excluded.
- `init_PMLSM_MIL_params.m`: combined initialization entry point.

## Current defaults (2026-09-07 snapshot)

7 s simulation, 100 us MIL step, MIL_Mode=1, Current_Control_Mode=2 (DPCC), static current-step enabled, injection 1 A, Plant_Input_Mode=2, ideal average inverter, dead-time compensation disabled, half-sample PWM update delay. Read the actual initialization scripts before changing settings; model initialization overwrites base-workspace values.

Control mode map: 1 PI; 2 DPCC; 3 DPICC; 4 half-delay DPICC; 5 half-delay PICDO-DPICC.

## Working rules

Read AGENTS.md. Preserve unrelated layout, wiring, block/port sizes and PI parameters. Do not globally auto-arrange models. Do not bulk-delete files. Only edit the explicitly requested feature.

Use the SLX models as source of truth. `docs/model_source/` is a searchable extraction of model XML, including embedded MATLAB code; regenerate it with `python tools/export_model_text.py`. Do not edit extracted XML to pretend the model was changed.

Model parsing is not simulation. State the actual MATLAB release, tested modes and numerical checks. The R2023b compatibility ZIP was verified on R2026a, not on an installed R2023b runtime. No hardware/board validation is implied.

No code-generation model, old result dataset, hardware archive, or paper archive is included. Historical documents are not automatically authoritative for current parameters.
