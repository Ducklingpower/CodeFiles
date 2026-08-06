# PAIRSim tyre model in MATLAB

A standalone port of the tyre model in the Purdue AI Racing simulator, so the
curves can be swept and re-tuned without rebuilding Unity.

Source of truth in the sim:
`Purdue-AI-Racing-Simulator/Assets/Autonoma/Scripts/VehicleDynamics/WheelController.cs`
(`calcTyreForcesNonlinear`, line 181) and
`.../HelperFunctions.cs` (`lut1DNonlinear`, line 142).

## Files

| file | what it is |
|---|---|
| `run_slip_angle_sweep.m` | **run this.** Slip-angle sweep at several normal loads, plus slip-ratio, combined-slip, friction-ellipse and thermal-map plots, the measured-data overlay below, a summary table and a CSV dump. |
| `measured_slip_ratio_{front,rear}.csv` | measured longitudinal slip from a real run, written by `notmal_force_estimation.m` (see below). Not checked in — regenerate per run. |
| `tire_forces.m` | the model itself — line-by-line port of `calcTyreForcesNonlinear`. Edit here to change the physics. |
| `tire_params.m` | front/rear defaults, the previous set as `front_old` / `rear_old`, or load a live `PAIRSIM_config` JSON. |
| `lut1d_nonlinear.m` | natural cubic spline for the thermal friction map (verified to machine precision against a reference natural spline). |
| `tire_params_to_json.m` | write a tuned parameter set back out in the format the sim reads. |

## The model

```
S      = sqrt(sy^2 + sx^2)                        combined slip magnitude
By     = tan(pi/(2*Cy)) / syPeak                  stiffness factor
Dy_eff = Dy + Dy2*(clamp(Fz, FzNom/3, 3*FzNom) - FzNom)/FzNom
Fy     = k_T * Fz * (sy/S) * Dy_eff * sin(Cy*atan(By*S))
Fx     = k_T * Fz * (sx/S) * Dx_eff * sin(Cx*atan(Bx*S))
```

A Pacejka magic formula with **no curvature term E** and **no Sh/Sv shifts**;
the friction circle comes from the `sy/S`, `sx/S` direction cosines rather than
a separate combined-slip weighting function. `k_T` is the temperature grip
scaling, active only when `IsThermalTyre` is set in the sim's vehicle setup.

`syPeak` is in **radians** and is exactly where `Fy` peaks (the `By` definition
guarantees it) — 0.08725 rad = 5.00° front, 0.078525 rad = 4.50° rear.

Things to know before tuning:

* `S` adds an angle in radians to a dimensionless slip ratio, so the
  lateral/longitudinal blend is only isotropic in those mixed units.
* Load sensitivity clamps `Fz` to `[FzNom/3, 3*FzNom]`, but the `Fz` that
  multiplies the force is **not** clamped — past 3×`FzNom` peak μ stops falling
  and `Fy` grows linearly with load. Front `FzNom` is 1700 N, so that ceiling
  is 5100 N.
* No camber, no `Mz`, no `Mx`. Relaxation length (`relaxLenX/Y`) lives in
  `calcSySx` and is a pure first-order lag — it does not change these
  steady-state curves, so it is not in the sweep.

## Typical use

```matlab
% sweep the shipped front defaults
run_slip_angle_sweep

% ...or sweep what this machine actually runs
% (set `axle` at the top of the script to:)
axle = '~/PAIRSIM_config/Parameters/FrontAxleTireParams.json';

% one-off evaluation
p = tire_params('rear');
[Fx, Fy, info] = tire_forces(p, deg2rad(3), 0.02, 2500);

% tune, then push back to the sim
p.Dy = 1.62; p.syPeak = deg2rad(4.2);
tire_params_to_json(p, '~/PAIRSIM_config/Parameters/RearAxleTireParams.json');
```

## Checking the model against a real run (figure 3)

`../brake_anylisis/notmal_force_estimation.m` writes two CSVs into this folder,
one per axle, from the data behind its fig S8:

```
time_s, tire, vx_mps, ax_mps2, slip_ratio, slip_ratio_vx_ref, Fx_N, Fz_N, Fx_over_Fz
```

One row per sample per tire. The two tires of an axle are **concatenated, not
averaged** — the `tire` column says which one — so FL and FR sit in the front
file as separate points. Samples the analysis vetoed (speed window, slip-ratio
ceiling, brake-bias window, segment seams, `Fz <= 0`, and the zero-speed guard
that pins kappa at exactly 1) never reach the file.

`run_slip_angle_sweep.m` picks them up automatically when `overlayMeasured` is
true and draws figure 3: the measured `Fx/Fz` as a scatter, with the model's
`Fx(sx, Fz)/Fz` over it at the 10th, 50th and 90th percentile of the measured
load. Three curves rather than one because `Fx/Fz` is **not** load-independent
in this model — `Dx_eff` carries `Dx2`.

With `overlayOldModel` true it also draws the previous parameter set
(`tire_params('front_old')` / `('rear_old')`, transcribed from the Unity
`DefaultFrontTyreParams` / `DefaultRearTyreParams` assets) as dashed lines in
the same colour per load — so a matched pair of curves is one load under the
two parameter sets. The console prints the peak `mu_x` of each at the median
measured load, which is the comparison that actually matters:

| set | `Dx` | `Dx2` | `Cx` | `sxPeak` | `FzNom` |
|---|---|---|---|---|---|
| front (old) | 1.2 | −0.2 | 1.3 | 0.07 | 1700 |
| rear (old) | 1.7 | −0.2 | 1.4 | 0.06 | 2200 |

The old sets peak at roughly twice the slip ratio the current ones do
(`sxPeak` 0.06–0.07 against 0.03), so the two disagree most in exactly the
region a braking run spends its time.

Three things to keep straight when reading that figure:

* **Slip-ratio definition.** The log computes `(Vw - Vx)/Vw`; the model's `sx`
  is `(Vw - Vx)/|Vx|`. They agree for small slip and diverge as it grows, so
  both columns are exported and `measuredSlipCol` selects which one the overlay
  plots against. `slip_ratio_vx_ref` is the like-for-like comparison.
* **`Fz` is the observer estimate**, not a load cell, unless
  `use_observed_Fz` is false in the analysis script — so the normalisation
  carries whatever error the dual-track observer has.
* **The measured slip carries a zero offset correction.**
  `measuredSlipOffset` slides the cloud back onto zero to cancel a
  rolling-radius / wheel-speed trim; it is applied to the plot only, and the
  legend and console both report it.

Longitudinal only for now; the lateral equivalent is not wired up.

## Getting changes back into the sim

`WheelController.Start()` reads `~/PAIRSIM_config/Parameters/FrontAxleTireParams.json`
and `RearAxleTireParams.json` once at startup and **overwrites** the
ScriptableObject fields (`ApplyTyreParameters`, `WheelController.cs:289`).
So:

* editing `DefaultFrontTyreParams.asset` in the Unity editor does nothing while
  that JSON exists — the JSON wins;
* the JSON is only auto-created if missing, from the hardcoded defaults at
  `WheelController.cs:348-409`;
* changing the *structure* of the model (not just the parameters) means editing
  `calcTyreForcesNonlinear` and keeping `tire_forces.m` in sync.

## Reference values (front defaults, thermal off)

| Fz [N] | Dy_eff | Fy_peak [N] | α_peak [deg] | μ_y | C_α [N/deg] |
|---|---|---|---|---|---|
| 1000 | 1.582 | 1582 | 5.00 | 1.582 | 822 |
| 1700 | 1.500 | 2550 | 5.00 | 1.500 | 1325 |
| 2500 | 1.406 | 3515 | 5.00 | 1.406 | 1827 |
| 3400 | 1.300 | 4420 | 5.00 | 1.300 | 2297 |
| 5100 | 1.100 | 5610 | 5.00 | 1.100 | 2916 |

Run the script and check the printed table against this to confirm the port is
behaving before you start changing things.
