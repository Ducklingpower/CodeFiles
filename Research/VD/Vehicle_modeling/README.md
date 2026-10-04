# Vehicle_modeling: load-aware slip angle and understeer gradient for the fbl_mpc controller

This folder holds the vehicle dynamics research for Purdue's autonomous race car (Dallara IAC-type, Firestone Firehawk slicks,
815 kg) on Laguna Seca. It is written so a new agent (or person) can pick the work up cold. Read sections 1 to 3 first; to build the
on-vehicle package, section 2a and `observer_block_diagrams.html` section 7.

All numbers below come from the 2026-09-03 comp log unless stated, evaluated on near pure cornering or on all samples
above 10 m/s as noted. Dates: the work ran 2026-09-28 to 2026-10-01.

---

## 1. The goal in one paragraph

The on-vehicle MPC (`fbl_mpc_controller`) computes a **dynamic understeer gradient k_us** from a **brush tire model** to
turn a lateral acceleration command into a steering angle. Its brush uses **fixed static axle loads**, so in high-load
corners (C9 and C10: banking + compression after the Corkscrew + speed) it thinks the front is saturated and k_us jumps
to ~0.003. Feedforward and feedback then fight and the car oscillates. The quick fix in the controller was a **k_us clamp
at 0.0012**. The aim of this work is a k_us that **uses the observed normal load** and does not blow up at the tire limit,
so the clamp can go. The user **trusts** the axle lateral force estimate (force balance) and the strain gage + model
normal force observer, and **does not trust the localization (odom) v_y**, so slip angle must come from tire models + IMU,
not from v_y. The measured slip (from odom v_y) is used only as the reference to score against.

## 2. Where things stand

**2026-10-02: `vehicle_model.m` is now the MATLAB reference for the on-vehicle `vehicle_model` package (dual track).** It
holds the final product of the slip work: road wheel angles from the Ackermann table (`yaw_moment/ackerman_sweep_50.xlsx`)
+ static toe (0 until confirmed, yaw_moment.m has -0.451 deg) in every per tire calculation; lf / lr 1.724 / 1.248 m (URDF);
fc 3 Hz (the Fz observer keeps 0.3 / 0.5 Hz); the bicycle v_y observer (MPC brush at the observed axle Fz, full trust,
tau 0.2 s) and bicycle k_us; the per tire Fy split by normal load and corrected with the brush at the dual track observer's own slip of the
previous sample; the dual track v_y observer fed by that corrected split, and dual track k_us. The brush inverse is the closed form
`alpha = atan(t_th (1 - (1 - |F|/(mu Fz))^(1/3)))`, identical to the controller's cubic. Plots are one tabbed window.
2026 log: v_y rms 0.202 (bicycle) / 0.173 m/s (dual track), per tire slip 0.30 deg, k_us median |error| 0.00021 / 0.00046.

**2026-10-04: the bicycle and dual track models are fully separate** (the architecture of the on-vehicle package, section
2a). The dual track Fy correction used the bicycle observer slip before; it now uses its own previous-sample slip
(`dualTrackObserver`, one sample at a time), for the same accuracy (0.172 -> 0.173 m/s, 0.00045 -> 0.00046; the plain normal
load split gives 0.168 m/s, 0.00046). The bicycle model uses its own axle Fz observer (`FzB`), the dual track model its own
tire observer (`FzT`), and the locked wheel Fx cap uses the load model, so the two share only stateless functions of the
inputs. Debug flags per model (`dbgB`, `dbgD`) are computed and saved.

Later on 2026-10-04: **no a_y bias term** (accel_filtered a_y is already bias corrected upstream), the **Fz observer output
is clamped at 0** (`max(model + correction, 0)`, a tire can not pull on the road; the correction state is not clamped), and
a **Fastest lap** tab (Fz, Fy per tire, v_y, axle slips, k_us, a_y with C1 to C11 marked, lap timed at C11). Results:
v_y rms 0.201 / 0.172 m/s, k_us |error| 0.00021 / 0.00046.

**Load sensitive brush, rig exponent, equal weights (later 2026-10-04).** One tire model everywhere (both models, observer
and k_us): per tire `Ca_i = Ca/2 (Fz_i / Fz0)^p` (`brushCa`), Ca = MPC 174k / 290k N/rad, Fz0 = static corner load
1679 / 2319 N, **p = 0.76 / 0.78 from the rig MF 6.2 files** (secant of Ky(Fz) = PKY1 Fz0 sin(PKY4 atan(Fz / (PKY2 Fz0)))
from 800 to 3000 N; local exponent falls from ~0.97 at 600 N to ~0.35 at 3500 N). A bicycle axle is two such tires at half
the axle load. p was first swept against the measured k_us (0.7 matched); the rig value is what is used. With a fixed Ca
the light inside front (~640 N in C10) saturated at ~2 deg and the dual track k_us doubled in the high transfer corners.
The dual track weights were retuned for this brush: **equal weights, gain 1** (`obs.dtWeights = false`) beat every
conditioning / load share / floor variant (v_y 0.190 vs 0.214 m/s with c^2 x share); the weighted version stays as the
comparison in the plots. Results: v_y rms 0.202 (bicycle) / 0.190 m/s (dual), slip 0.32 deg, k_us |error| 0.00027 /
0.00026 (before: 0.172 m/s, 0.00021 / 0.00046). The two k_us now agree; scores are against the localization v_y and the
measured k_us, which are references, not ground truth.

**Saturated flag** (fixed Ca numbers; with the rig brush 1 to 4 % per tire, 71 % inner, median 310 N): |Fy_i| >= mu Fz_i in the brush, so the inverse has no unique slip and the tire's observer weight is 0.
Set on 15 / 10 / 6 / 3 % (FL / FR / RL / RR) of observer samples, 93.5 % of them the inner tire at a median 450 N with
|Fy| / mu Fz 1.15 to 1.22: the split gives the unloaded inner front more force than its load allows. Open question.
`observer_block_diagrams.html` documents every block with its math and line, the outputs, and the build plan for the C++.
`debug_slip_angle.m` stays as the exploration script (its own copies of the observers, 1.3 Hz era, MPC lf / lr).
The `tire_fit_data_*.mat` caches were built before the 2026-10-02 and 10-04 changes; delete them to rebuild with the new
`vehicle_model.m`.

## 2a. On-vehicle `vehicle_model` package update (start here to build it)

Target: `on-vehicle/src/control/vehicle_model`. The full guide is `observer_block_diagrams.html`: Fig. P (the package
today) and Fig. P2 (the proposed package), the topic and message field tables, sections 0 to 6 (every equation with its
`vehicle_model.m` line), and **section 7: rules, file layout, code style, node structure, model API, MATLAB to C++ map,
build phases, open items**. This section is the short version.

**Rule: the math must be exactly the math in `vehicle_model.m`.** Every equation, constant, gate, clamp and debug flag the
C++ uses is in it and the C++ must reproduce its numbers. No extra filters, clamps or fixes in the C++. A change goes into
`vehicle_model.m` first (then the HTML and this README), then the C++ follows, then the bag replay comparison is run
again (phase 3 below).

**What `vehicle_model.m` contains (2026-10-04, tightened to the package):** in the order the node runs it

1. `settings`, `load file`, `vehicle parameters (the package params.yaml)`: every package parameter in `vehicleParams`.
2. `calibrations`: wheel speed calibration, R_f / R_r, brake pressure zero, throttle idle, gage offset. Offline in MATLAB
   (printed as `calibration: ...`), **parameters on the vehicle** (the gage offset may be taken at startup at rest).
3. `input conditioning`: units, calibrations, Tustin filters (3 Hz every input, 0.3 Hz load model inputs, 0.5 Hz gages).
4. `SHARED, STATELESS` sections: road wheel angles (Ackermann LUT + toe), accelerations, tire kinematics and kinematic
   slips, slip ratios (vw_min 1 m/s floor, +/-1 clamp, 1 m/s gate: the current ABS slip ratio, now with delta_i) and
   kappa, load model, Fx per wheel, axle Fy force balance, the tire model (load sensitive MPC brush).
5. `BICYCLE MODEL` sections: axle Fz observer, v_y observer and axle slips, k_us, debug flags (`dbgB`).
6. `DUAL TRACK MODEL` sections: per tire Fz observer, Fy split, v_y observer (`dualTrackObserver`, already one sample at
   a time: port its loop), k_us, debug flags (`dbgD`).
7. `NOT IN THE PACKAGE`: references and comparisons (alphaB, the old weighted observer, measured k_us, the Fx IMU split),
   the save for the research scripts (with the Pacejka coefficients), then the plots. Do not port these.

Every block is causal, so it maps to one call per 100 Hz sample; where MATLAB writes NaN the C++ writes 0 and clears the
matching valid flag. Results on the 2026-09-03 log: v_y rms 0.202 (bicycle) / 0.190 m/s (dual track), k_us median
|error| 0.00027 / 0.00026.

**Architecture: one node wrapping two separate model classes.**

* The node subscribes, checks message timeouts, conditions the inputs into one `VehicleModelInput`, runs
  `bicycle_->setInput(in); bicycle_->step();` and `dual_track_->setInput(in); dual_track_->step();` on the same sample,
  publishes `getOutput()` / `getDebug()` of each, and publishes its own `ErrorReport`. It holds no model math.
* `BicycleModel` and `DualTrackModel` have the API of `AccelerationInterface` (`setInput`, `step`, `getOutput`,
  `setParams`, plus `getDebug`), their own state (each its own `FzObserver` and `VyObserver`), no ROS, and never read each
  other. They share stateless functions only.

**Structure and style: follow `src/control/acceleration_interface`.** Read `acceleration_interface_node.hpp/.cpp`,
`acceleration_interface.hpp/.cpp`, `Powertrain/EngineMapCsvLoader`, `Powertrain/RosIceStateProvider`,
`Brakes/BrakeBiasMap` and `config/params.yaml` first; the new node should look like `acceleration_interface_node.cpp`:

* constructor only logs; `initialize()` creates the subscriptions (`rclcpp::SensorDataQoS()`, `std::bind` to
  `receive_*` callbacks), the publishers, declares the parameters into the parameter structs, creates the control timer
  (`control_dt_s` 0.01 s) and the param timer (`ts_param` 1 s), picks the clock (`get_clock()` with `use_sim_time`, else
  `RCL_STEADY_TIME`), stamps every `last_*_time_`, then builds the model instances;
* each `receive_*` callback stores the latest values and `last_*_time_ = this->clock->now()`;
* `checkMsgTimeouts()` exactly like acceleration_interface: one `blackandgold_msgs::msg::ErrorReport` (origin
  `vehicle_model_node`, module `control`, lifetime 1.0), compare `clock->now() - last_*_time_` with `max_msg_timeout_s`,
  set the description and severity per topic (odom, accel, steering, wheel speeds: ERROR_FATAL, outputs invalid;
  tire_report, brake_2_report, pt_report: ERROR_SOFT_FAULT, Fz observer active / Fx valid false), publish when set;
* `controlCallback()`: guard, `checkMsgTimeouts()`, condition the inputs, step both models, publish;
* `updateParamsCallback()`: re-read the live tunables and push them with `setParams`;
* `main()` only in `main.cpp` (`rclcpp::init`, `make_shared`, `initialize()`, `spin`).

Files: `.hpp` declares (structs, classes, function signatures, member variables, the parameter and LUT structs), `.cpp`
executes (the bodies); parameter values in `config/params.yaml` (nested blocks as acceleration_interface), LUTs as CSV in
`config/` (`ackermann_lut.csv` from `yaw_moment/ackerman_sweep_50.xlsx`, the engine map) loaded into structs declared in
`include/` (as `BrakeBiasMap` / `EngineMapCsvLoader`). Minimal comments, same style as `vehicle_model.m` and the current
`vehicle_model` / `acceleration_interface` sources: one line per block, `// ASSUMPTION:` where MATLAB has one, a short
`/** @brief */` on public functions. Names follow MATLAB. Per tire values as `std::array<double, 4>` (FL, FR, RL, RR).

Topics (proposed names, settle with the controls team):

| Topic | Message | Contents | Readers |
|---|---|---|---|
| `/control/vehicle_model/bicycle/state` | `BicycleState` | delta; per axle slip kinematic / observed, slip ratio, Fz model / observed, Fx, Fy; v_y, k_us | fbl_mpc_controller, telemetry |
| `/control/vehicle_model/bicycle/debug` | `BicycleDebug` | moving, slip angle / ratio valid, observer running, Fz observer active, k_us valid; brush slip, conditioning, saturated, v_y tire model | debugging |
| `/control/vehicle_model/dualtrack/state` | `DualTrackState` | per tire delta, slip kinematic / observed, kappa, s_x, s_y, Fz model / observed, Fx, Fy (2 splits); v_y, k_us | acceleration_interface (ABS), telemetry |
| `/control/vehicle_model/dualtrack/debug` | `DualTrackDebug` | per tire valid flags, lifted (< 300 N), locked (kappa < -0.5), saturated, conditioning (no weights: equal weights, gain 1) | debugging |
| `/control/vehicle_model/errors` | `ErrorReport` | input timeouts per topic, NaN inputs (from the node) | error handling |

Inputs: `/odometry/global_filtered`, `/novatel_bottom/accel_filtered`, `steering_extended_report`, `wheel_speed_report`,
`tire_report`, and new `brake_2_report`, `pt_report` (wheel dynamics Fx); the unused `imu/data_raw` subscription goes.

Build phases (detail in the HTML section 7):

1. C++ blocks and the two model classes without ROS, in the order of the MATLAB sections, each a line for line port.
2. The node, params.yaml (the `vehicle_model.m` parameters and the calibrations it prints), the four new messages in
   `blackandgold_msgs`.
3. **Verify by bag replay against `vehicle_model.m`:**
   * MATLAB: `vehicle_model.m` on `bags/lagoona/comp2/compition_bags/2026-09-03_121638_merged.csv`, which is the bag
     `rosbag2_merged_2026-09-03_121638` merged by `merge_rosbag2_folder_to_csv_v3.py` onto a 0.01 s grid (merge report:
     t0 = 1788463010.696 s, no filter).
   * Node: `ros2 bag play rosbag2_merged_2026-09-03_121638 --clock` **at 1x speed** (the node runs a 100 Hz timer and
     checks timeouts, a faster replay is a different experiment), input topics only (leave the bag's own
     `/control/vehicle_model/*` out), node on `use_sim_time:=true`, replay from the start of the bag so the observers
     start on the same samples as MATLAB; `ros2 bag record --use-sim-time` the four output topics and
     `/control/vehicle_model/errors` (the merge script times samples by the recorder's log time).
   * Convert: `python3 merge_rosbag2_folder_to_csv_v3.py -i <recording> -o <out> -t 0.01 --time-mode union
     --topics-file vehicle_model_node_topics.yaml`, workspace sourced for the new message types, no `-f` (zero phase
     filter). `vehicle_model_node_topics.yaml` maps every message field to a column; keep it, the messages and the
     comparison script's signal list in step. `time_s` is absolute bag time, the same clock as the comp2 CSV.
   * Compare: `compare_vehicle_model_node.m` (set `nodeCsv` at the top). It runs `vehicle_model.m` with plots off,
     interpolates the node CSV onto the MATLAB samples, scores where MATLAB is finite (rms and p99 of node - MATLAB,
     rms / rms, best lag within +/-0.5 s and the rms at that lag, % disagreement per debug flag) and plots a summary, one
     tab per group (overlay | difference) and the fastest lap with the corners. A timing offset shows as a lag with a
     small rms at lag; a math error keeps a large rms at lag. Tested on a synthetic node CSV (delay, noise, a 5 % k_us
     error, flipped flags, a missing column).
   * Expect noise level differences (the CSV inputs are interpolated onto a fixed grid, the node sees each message at
     its own rate on its own timer); a real mismatch is an offset, a sign, a lag, a drift or a diverging observer.
4. The same comparison on a second log (2025 comp), shadow mode on the car, then migrate the readers before retiring the
   old topics (`output`, `output_filtered`, `vehicle_state`, `dualtrack/output`, `dualtrack/output_filtered`):
   `acceleration_interface` ABS to `dualtrack/state` s_x + `dualtrack/debug` slip ratio valid; `telemetry_web`,
   `basestation_com_v2`, `slip_vs_force_plot` to `bicycle/state`. Old and new side by side for one test day.
5. The MPC takes the bicycle k_us (with the same load sensitive brush) and the 0.0012 clamp is replaced by a utilization
   based hold.

Open before the port: static toe, the AV24 brake pressure topic (`brake_2_report` is marked deprecated in raptor_dbw_can),
the saturated flag (1 to 4 % per tire, mostly the unloaded inner tire), Iz, CG height, ARB_f, the topic / message names.

### Earlier state (2026-10-01)

**Chosen bicycle solution (works, closed form, ready to port to C++):**

* Normal load: the observer in `vehicle_model.m` (model + strain gages), summed per axle.
* Slip: a **v_y observer** = IMU integration `dvy/dt = a_y - vx r` pulled toward the slip from the controller's own
  **closed form brush inverse at the observed axle load** (`inverse_brush_tire_slip`), full trust, tau 0.2 s.
* k_us: the controller's brush at the **observer slip** and observed axle load, `C = |F_brush(alpha_obs)| / tan(alpha_obs)`
  per axle, then the controller's formula `k_us = m (lr Cr - lf Cf) / (L Cf Cr)`.
* Result vs measured k_us (steering offset removed): median |error| 0.00024 rad/(m/s^2), above the 0.0012 clamp 9.3 %
  (the measured k_us itself is above it 8.4 %), jitter 2.1e-5 (5x smoother than the MPC as run). C9: 0.0008 vs MPC 0.0020.

**In progress: dual track (per tire) k_us.** A **dual track v_y observer** (each tire's brush inverse at its own load,
weighted by conditioning^2 x load share) is now **better than the bicycle observer** for slip (see 7.4). But computing
k_us from **per tire forces** (dual track stiffness) still over-predicts understeer, because the front axle has much more
load transfer than the rear and the tire models punish that too hard (see 8). Bicycle k_us is still the recommendation.

## 3. Files

| File | What it is |
|---|---|
| `vehicle_model.m` | **The MATLAB reference for the on-vehicle package** (section 2a): parameters, calibrations, input conditioning, shared stateless functions, bicycle model, dual track model, then comparisons not in the package, the save for the research scripts (`saveFitData = true`) and the tabbed plots. |
| `compare_vehicle_model_node.m` | Replay check of the on-vehicle node: node output CSV vs `vehicle_model.m` on the comp2 log, scores and tabbed plots (section 2a, phase 3). |
| `vehicle_model_node_topics.yaml` | `--topics-file` for `merge_rosbag2_folder_to_csv_v3.py`: the node's output message fields as CSV columns. |
| `tire_fit.m` | Fits the Firestone MF 6.2 `.tir` scaling to data, then fits Pacejka 1987 coefficients. Writes `tires/adjusted/*.tir`, `tire_coeffs.csv`. |
| `tire_fz_plots.m` | Load sensitivity evidence, MPC brush port, MPC understeer gradient port, slip / Fy / Fz debug tabs, corner analysis over 8 Laguna logs. Builds the `tire_fit_data_*.mat` files itself by running a temp copy of `vehicle_model.m`. |
| `debug_slip_angle.m` | **The current work.** Slip and k_us without v_y: brush models, MF, v_y observers (bicycle and dual track), trust / tau sweeps, k_us per corner, old vs new comparison. |
| `debug_slip_ratio.m` | *Parked, low priority, needs more validation (section 8b).* Per wheel Fx observer (2026-10-02): wheel torque Fx fused with the Fz sensitive brush at the bias corrected slip ratio. Tabs: Fx observer, slip ratio, slip ratio vs mu_x. Needs `Fx_total`, `Fx_*_fb`, `Vw_*` in the `.mat` (added to `vehicle_model.m`'s save list). |
| `observer_tuning.m` | Grid search of the normal force observer filters (fcObsModel, fcObsGage, K, tau) against a zero phase gage reference. |
| `tire_fz_slide.pdf` | 3 page slide on load sensitivity (from the first session, made with the old observer). |
| `tires/*.tir`, `tires/adjusted/*.tir` | Rig MF 6.2 files and the scaled ones (`tire_fit.m` output, last refit 2026-09-30). |
| `report_figs/` | Figures of the hosted "Firehawk Tire Fit" report (claude.ai artifact FuU4HRXcuiT7SWE5sbgSEh), old observer. |
| `tire_fit_data_*.mat` | Per sample output of `vehicle_model.m` for each log (full log). Delete them to rebuild after changing `vehicle_model.m`. Caches added later: `px py pz` (map position, height), `wz` (yaw rate), `gageRaw` (raw strain gages, 2026 log only). |
| `debug_slip_angle_data.mat`, `observer_tuning_data.mat` | CSV channel caches (IMU a_y, odom v_y, gages ...). |

Nothing of this work is committed yet (`git status`: the 4 new scripts, the pdf, README, and changes to
`vehicle_model.m`, `tire_fit.m`, the 4 adjusted `.tir`). `vehicle_model.asv` is a MATLAB autosave.

### Running

MATLAB R2025b: `/usr/local/MATLAB/R2025b/bin/matlab -batch "run('debug_slip_angle.m')"` (about 1 minute once the
`.mat` caches exist; the first `tire_fz_plots.m` run builds all 8 logs in about 3 minutes). Toolboxes used: Optimization
(lsqnonlin), Signal Processing (butter, filtfilt), Curve Fitting not needed; no Statistics toolbox (use corrcoef, not corr).
MFeval lives at `/home/elijah/MATLAB Add-Ons/Toolboxes/MFeval` (needed by `tire_fit.m` only).

**Plot conventions the user wants:** one figure window, one tab per plot (`uitabgroup` + the `newTab` helper), simple
titles and legends, all data unless told otherwise, one change at a time when comparing methods. The MPC brush observer is
drawn in **white** (`cObM`, dark theme; reference lines are white too, no black lines), width 2 in "Compare old vs new". Turns are named **C1 to C11**, never T# or by name.

## 4. Data

| Log | Path | Use |
|---|---|---|
| 2025 comp | `/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv` | tire fit log |
| 2026 comp | `/home/elijah/PurdueRacing/bags/lagoona/comp2/compition_bags/2026-09-03_121638_merged.csv` | check log, `debug_slip_angle.m` |
| 6 more Laguna | `lagoona/comp/...172638`, `october/spin_out/...`, `control_test/JULY_19_full_test`, `JULY_28_differnt_engine_map_test_acc`, `JULY_28_fastlap_tireLocking_acc`, `JULY_28_HardBraking_feedbackcontroller` | corner comparison only (`cornerLogs` in `tire_fz_plots.m`) |

* 100 Hz merged CSVs (~103 channels). Same odom map frame in every Laguna log.
* Fastest lap of the 2026 log: **87.7 s, t = 1168 to 1256 s** (found automatically, timed at C11, `fastestLap`).
* Corners (odom x, y in m): C1 (-165,-270) fast kink ~64 m/s, C2 (-144,-518), C3 (-100,-302), C4 (149,-345), C5 (148,-797),
  C6 (526,-743), C7 (581,-361), **C8 Corkscrew** (591,-281) at the highest point 252 m, C8A (546,-233), **C9** (487,-73)
  ~41 m/s highest load (a_z road 1.16 g), **C10** (260,-78), C11 (99,139) hairpin and lap timing point. Right handers:
  C3, C4, C7, C8A, C10. The user first thought C9 was the Corkscrew; the height profile proves it is not.
* **Localization v_y** (`/odometry/global_filtered`, `on-vehicle/src/localization/navigation_filter`, custom square-root UKF):
  state = ENU position, ENU velocity, attitude, gyro and accel biases; IMU (VectorNav first) only *rotated* into
  `base_link` (= CG, URDF), no lever-arm correction; GNSS Doppler velocity (4 streams) lever-arm corrected to the CG; GNSS
  baseline (heading) updates are disabled; a "bicycle constraint" pseudo-measurement (steady-state linear bicycle sideslip,
  lf 1.7, lr 1.24, m 787, C_r 210k, variance 0.05) runs after every accepted GNSS velocity update. Published v_y =
  ENU velocity rotated into the body by the estimated attitude. A lever-arm fit of odom v_y against GNSS gave a point
  ~0.57 m ahead of the CG with no GNSS delay but ~0 m with a 30 ms delay (same residual), so whether odom v_y carries the
  IMU lever arm is unresolved. The constraint is weak per update (σ ≈ 9 m/s of v_y at 40 m/s vs GNSS 0.09 m/s), so it acts
  on heading, not v_y directly. 2026-07-28 log, v > 10 m/s: localization v_y vs GNSS (both antennas agreeing) 0.046 m/s
  rms, our MPC brush observer 0.099. An optical OMS sensor was also compared (localization still better) and then
  removed from the code (2026-10-02): it had unflagged bursts of bad readings.
* `est_steer_torque_nm` is the steering actuator effort (unsigned, spikes at every turn in), **not** tire aligning torque; the aligning moment method was dropped.

## 5. vehicle_model.m (the estimator, the MATLAB reference for the package; structure in section 2a)

Pipeline (line numbers and every equation: `observer_block_diagrams.html`, sections 1 to 6). All signals low passed with a
first order Tustin filter (`lpf`, **fc 3 Hz**), the Fz observer paths at 0.3 Hz (model inputs) and 0.5 Hz (gages).

Shared, stateless functions of the inputs:

1. Wheel speed calibration on free rolling; rear rolling radius from engine speed; brake pressure and gage zeros.
2. Road wheel angles: `delta_road = steerOffset + steer / steerRatio` (0.333 deg, 15.015), then the **Ackermann table**
   (`yaw_moment/ackerman_sweep_50.xlsx`) for left / right and the static toe (0 until confirmed). Bicycle delta = mean front.
3. Kinematic slips per tire (`tireKin`: corner speeds vx -/+ r t/2, each tire rotated by its own delta_i) and per axle,
   from the odom v_y: the reference only. Slip ratios kappa, s_x, s_y stay kinematic.
4. **Normal force model**: bicycle `Fz_f = m az_road lr/L - m ax_long h/L + aeroBal_f downforce` (+ rear), az_road with the
   bank term; dual track adds steady state lateral transfer (wheel rates, `ARB_f = 0` TBD, roll centres 0.120 / 0.002 m).
5. Per wheel Fx from wheel dynamics (engine map, gear ratios, brake gain, inertias); a locked wheel is capped at
   mu_x times the load **model** Fz.
6. **Axle Fy**: force and yaw moment balance, `Fyf = (m lr a_y + Iz r_dot)/L` (into the steered tire frame), `Fyr = (m lf
   a_y - Iz r_dot)/L`. `Iz = 1000` is a placeholder.

Bicycle model (own state): axle **Fz observer** (`fzDerivativeObserver` on the axle model and gage sums, K 1.1, tau 8 s,
output clamped at 0, `FzB` into the brush); **bicycle v_y observer** (MPC brush inverse at FzB, full trust,
tau 0.2 s); observed axle slips; **bicycle k_us**; `dbgB`. The brush everywhere has the load sensitive Ca (section 2).

Dual track model (own state): per tire **Fz observer** (`FzT`, clamped at 0); Fy per tire by (1) normal load split
and (2) normal load split + brush correction at the dual track slip of the previous sample (`axleCorrect`); **dual track
v_y observer** (`dualTrackObserver`, per tire brush inverse, equal weights); observed tire slips; **dual track
k_us**; `dbgD`.

Removed: the random walk Kalman filter on the axle Fy (2026-10-02, it did not improve the split), the friction circle and
Pacejka splits, the Fz clamp issue (consumers now use max(Fz, 0)).

### Observer tuning (`observer_tuning.m`)

Reference = raw gage low passed forward and backward at 4 Hz (zero phase). Findings: **K = 1 is best**; a high K with a low
gage cutoff does **not** buy phase (the leaky integral undoes the derivative's +90 deg, `correction = K HP_tau(LP(gage - model))`,
K only scales it). Pareto knee: fcObsGage 0.5 to 1 Hz, K 1, tau 4 to 8 s. The model path, not the gage path, gives the fast
response, so a very low fcObsModel (the current 0.3 Hz) makes the whole estimate lag (more k_us above the clamp at turn in).
Real phase lead needs a separate lead term or faster model inputs (crest / pitch rate, damper pots `*_damper_pot_mm`).

## 6. Tire models

* **Rig files**: Firestone Firehawk MF 6.2 `.tir` (275/40R15 front, 385/30R15 rear). `tire_fit.m` zeroes the mirrored
  left / right offsets, fits LMUY, LKY (lateral) and LMUX, LKX per axle to the data with the rig load sensitivity (PDY2) kept,
  writes `tires/adjusted/`, sweeps them and fits **Pacejka 1987** (Bakker, Nyborg, Pacejka; `c = [C a1..a8]`, Fz in kN,
  alpha in deg, kappa in %). The MF 6.2 pure lateral equations reduce exactly to this form.
* **Current coefficients** (refit 2026-09-30 on the 2025 log with the current observer, pasted in `vehicle_model.m`,
  `tire_fz_plots.m`, `debug_slip_angle.m`):
  `pacFy_f = [1.38674 -126.23 1932.29 2160.01 1.77721 0.234871 -1.61212e-05 -0.0966109 -0.522512]`,
  `pacFy_r = [1.34461 -92.2527 1910.84 3000.88 1.48429 0.25844 0.000450439 0.136008 -2.1887]`.
  Peak mu falls linearly with load (front ~1.69 at 1 kN to 1.10 at 6 kN per tire).
* **Load sensitivity evidence**: at a fixed slip angle, axle Fy rises less than proportionally with Fz (slope dFy/dFz
  0.46 to 1.04 vs 0.68 to 1.42 for no load sensitivity); consistent with Pacejka. The fit itself could not pin PDY2.
* **MPC brush** (the controller's tire): Fiala brush per axle, `mu 1.6`, `Ca 174000 / 290000 N/rad`, fixed `normal_load`
  3256 / 4615 N. Saturates at `t_th = 3 mu Fz / Ca` (5.1 deg front, 4.4 deg rear). Its inverse is a closed form cubic.
* **Refit brush** (`debug_slip_angle.m`): same equation, `mu = mu0 (Fz/Fz0)^q` from the **peak envelope** (95th percentile
  of |Fy|/Fz in load bins, slip > 2 deg; front 1.62, q -0.07; rear 1.70, q -0.52, held constant outside the fitted load range)
  and `Ca = Ca0 (Fz/Fz0)^p` by least squares with mu fixed (front 157k, p 0.85; rear 285k, p 0.90), Fz0 = MPC normal_load,
  fitted on the 2025 log. Fits force and slip better than the MPC brush, but its k_us reads high (the brush saturates
  abruptly, so its effective stiffness collapses near the limit). A plain least squares fit pulled mu down to ~1.53.
* Remaining tire model bias: the MF over-predicts the **rear** force at a given slip by ~640 N even in pure cornering; and
  under braking / throttle every pure lateral model over-predicts (combined slip, the friction ellipse is not used in the
  debug comparisons on purpose).

## 7. Slip angle without v_y (`debug_slip_angle.m`)

### 7.1 The core problem

Near the tire peak dFy/dalpha -> 0, so inverting Fy for slip turns small Fy errors into degrees (4 deg and 7 deg give the
same Fy). Example C4 (34 to 37 s of the fastest lap): front demand / model peak 0.93 to 1.09, a 1 kN force gap became a 2 deg
slip gap. The same happens for a **nearly unloaded tire** (it makes no force at any slip, and the brush with fixed Ca
saturates at ~0.5 deg at 150 N). **Slip angle is kinematic**: both tires on an axle have nearly the same slip (they differ by
track and steer geometry, tenths of a degree); what an unloaded tire lacks is force, not slip.

### 7.2 Methods tried (slip rms error to measured, all samples / front utilization > 0.9)

| Method | Front | Notes |
|---|---|---|
| MF inverse, observed Fz (lookup) | 0.55 / 1.51 | fails at the peak |
| MPC brush inverse, fixed Fz (as the MPC) | 0.61 / 1.53 | flat tops at saturation |
| MPC brush inverse, observed Fz | 0.52 / 1.23 | |
| Refit brush inverse, observed Fz | 0.50 / 1.16 | |
| Rate limited inverse (adaptive 50 -> 0.5 deg/s) | 0.44 / 0.88 | straight ramps, dropped |
| Adaptive low pass on the inverse | 0.53 / 1.12 | smooth but keeps the peak bias |
| Kinematic link alpha_f - alpha_r = delta - L r/v | 0.37 / 0.58 | fails when both axles are at the limit |
| Steering torque / aligning moment | dropped | logged torque is not tire torque |
| **v_y observer (bicycle, MPC brush, full trust, tau 0.2 s)** | **0.33 / 0.66** | the chosen one |
| v_y observer, trust floor 0.1, tau 0.2 s | 0.31 / 0.48 | better slip, same k_us |
| **Dual track v_y observer (cond^2 x load share, tau 0.2 s)** | **0.28 / 0.40** | per tire, newest |

### 7.3 The v_y observer (bicycle)

```
inverse     alpha_axle from the tire model at the trusted axle Fy and observed load (closed form for the brush)
trust       conditioning = local slope / initial slope of the tire curve at that slip (brush exact: (1 - |tan a|/t_th)^2)
            trust = max(trustFloor, conditioning^trustPow), current trustPow 1, trustFloor 1 (full trust)
v_y         rear  vy_r = -vx tan(alpha_r) + lr r,  front  vy_f = vx tan(delta - alpha_f) - lf r,  blended by axle trust
predict     vy <- vy + (a_y - bias - vx r) Ts         (debug_slip_angle.m; vehicle_model.m has no bias term, a_y is already corrected)
correct     vy <- vy + (Ts / tau) trust (vy_tire - vy),   tau 0.2 s (brTau, tauObs)
output      alpha_f = delta - atan((vy + lf r)/vx),  alpha_r = -atan((vy - lr r)/vx)
```

With full trust it is a complementary filter (IMU above ~1/tau, tire model below). Sweeps (tabs "Trust sweep", "Tau sweep"):
slip is best with floor 0.1 / tau 0.2 s or full trust / tau 1 s; **k_us is insensitive to trust and tau** (error 0.00023 to
0.00024 everywhere). The user chose full trust, tau 0.2 s. v_y vs localization: 0.19 m/s rms. The remaining error flips sign
with turn direction (high in right handers, low in left handers), which points to a lever arm in the localization v_y or the
front steering asymmetry below.

### 7.4 The dual track v_y observer (newest)

Each tire: axle Fy split by observed load share, the tire's own MPC brush (Ca/2, mu 1.6, its Fz) inverted, then **its own
kinematics** give a v_y (corner speed vx -/+ r t/2). Weight `w_i = conditioning_i^2 x Fz_i / Fz_axle`: a lifted tire carries
no weight, a saturated tire carries little. (That is `debug_slip_angle.m` with the fixed Ca brush; `vehicle_model.m` now uses the rig load sensitive brush and
equal weights, section 2.) Same IMU integration, tau 0.2 s (`dtTrustPow 2`, `dtTrustFloor 0`, `dtTau 0.2`).
**Full trust breaks it** (v_y 0.38 m/s, 1.9 deg at the limit): one saturated loaded tire then sets v_y. Results:
v_y 0.166 vs 0.194 m/s (bicycle); per tire slip FL 0.28 / 0.41 / 0.49 (all / limit / tire below 300 N) vs 0.34 / 0.66 / 0.74.
The single front tire inverses are poor inputs (0.6 to 0.9 m/s) and the rear ones good (0.27 to 0.32 m/s); the weighting
makes it work. Tab "Dual track observer".

### 7.5 Steering offset and asymmetry

Measured front slip on straight running is +0.20 deg (2026) / +0.23 deg (2025), independent of speed (so a steering offset,
not a v_y bias); rear ~0. The measured slip difference on straights is 0.215 deg, removed in the "measured, steering offset
removed" k_us. Beyond that, for the same Fy/Fz the measured front slip is 0.4 to 1.3 deg smaller in right handers than in
left handers (both logs), growing with load, so the steering ratio / sensor / compliance is not symmetric. The user kept
`steerOffset` unchanged. Check road wheel angle vs steering wheel angle to both locks on the car.

## 8. Understeer gradient

### 8.1 The MPC (where the controller is)

Repo `/home/elijah/PurdueRacing/on_vehicle/on-vehicle/src/control/fbl_mpc_controller` (last commit seen 3b74d6b91):

* `config/param.yaml`: `model_type: UnicycleModel`.
* `config/vehicle_model_param.yaml`: `tire_model: BrushTireModel`, `use_dynamic_understeer: true`,
  `max_understeer_gradient: 0.0012` (the clamp), `understeer_gradient: 0.00035` (used only if dynamic is off),
  `front_wheelbase 1.6785`, `rear_wheelbase 1.2933`, `vehicle_mass 815`, `steering_bias -0.222` deg,
  front `mu 1.6, normal_load 3256, ca 174000`, rear `mu 1.6, normal_load 4615, ca 290000`.
* `src/fbl_mpc.cpp` line ~475: `linearization_law(current_accel_inputs, max(v, 10), heading_error)`; line ~222: the
  basestation toggles the clamp (`clamp_k_ug`).
* `src/vehicle_model/unicycle_model.cpp`: `linearization_law` (yaw_rate = a_lat / max(v,5), then
  `delta = (L + lock_diff + v^2 k_us) a_lat / v^2 + bias`, i.e. `delta = L kappa + k_us a_y`), `under_steer_coefficient`
  (`k_us = m (lr Cr - lf Cf) / (L Cf Cr)` and the clamp), `effective_stiffness` (demand `m v yaw` split by lf, lr, the axle
  that saturates first is capped at mu Fz, `inverse_brush_tire_slip`, `C = Fy / tan(alpha)`; Fz = normal_load +/- m a coh/L
  with a = 0), `brush_tire_force`, `inverse_brush_tire_slip` (cubic). The same functions exist in `bicycle_model.cpp`.
* Exact MATLAB ports: `mpcUndersteer`, `inverseBrush`, `brushTireForce` in `tire_fz_plots.m` / `debug_slip_angle.m`
  (checked: front saturates at a_y 14.7 m/s^2 and k_us rises to 0.0032, as the controller comment says).
* The MPC lateral acceleration command is not logged; offline uses `v r` in its place.

### 8.2 Results (|a_y| > 4 m/s^2, error = median |k - measured with the steering offset removed|, measured median 0.00047)

| k_us | Median | Error | Above clamp | Jitter | C9 | C10 |
|---|---|---|---|---|---|---|
| Measured, offset removed | 0.00047 | - | 8.4 % | 5.0e-5 | 0.00065 | 0.00062 |
| MPC as run (fixed Fz, unclamped) | 0.00070 | 0.00047 | 21.7 % | 1.0e-4 | **0.00203** | 0.00094 |
| MPC brush, observed axle Fz (MPC calc) | 0.00064 | 0.00034 | 13.2 % | 1.1e-4 | 0.00076 | 0.00082 |
| MF, observed axle Fz (MPC calc) | 0.00065 | 0.00031 | 10.9 % | 6.9e-5 | 0.00054 | 0.00079 |
| Refit brush, observed axle Fz | 0.00096 | 0.00052 | 35.8 % | 1.2e-4 | 0.00068 | 0.00115 |
| **MPC brush at the observer slip, observed axle Fz** | **0.00062** | **0.00024** | **9.3 %** | **2.1e-5** | 0.00081 | 0.00061 |
| MF at the observer slip | 0.00085 | 0.00040 | 23.6 % | 2.4e-5 | 0.00102 | 0.00092 |

Measured k_us without v_y: `(delta - L r / v) / a_y`, identical to `(alpha_f - alpha_r)/a_y` from the measured slip (v_y
cancels), so any method built on that identity (kinematic link, v_y observers) matches the measured slip difference by
construction; judge them on the separate front and rear slips. Downforce per corner (tab "k_us by corner" in older runs):
C9 has the most extra load (road geometry ~1.2 kN + aero ~0.5 kN, observer ~1.6 kN above static). Measured k_us at C9 is not
lower than elsewhere once the steering offset is removed; the fixed load model is what inflated it. C5 measured k_us goes
above the clamp too (real understeer at the limit there).

### 8.3 Dual track k_us (open)

Axle stiffness from per tire forces `C = (|F_L| + |F_R|) / tan(alpha_axle)` at each tire's load. With either observer it
**over-predicts** understeer (bicycle obs: MPC brush 0.00024 -> 0.00056 error, MF 0.00023 -> 0.00039; dual obs: dual MPC brush
0.00059, dual MF 0.00041). Cause: front load transfer ratio 0.55 to 0.75 vs rear 0.11 to 0.33 (inside front often fully
unloaded), so per tire load sensitivity costs the front a lot of stiffness, more than the car shows. Either the front transfer
is too high in the load model (roll centres, `ARB_f` TBD) or the tire models' stiffness load sensitivity is too strong (the
brush with fixed Ca per tire is the extreme case), or unmodelled effects (camber gain, compliance) offset it. Force weighted
axle slip `sum |Fy_i| alpha_i / sum |Fy_i|` and each tire's contribution are plotted in "Per tire slip": the outside front
carries almost all the front slip, the rear splits evenly.

## 8b. Fx observer (`debug_slip_ratio.m`, 2026-10-02)

> **Status: parked, low priority.** This is left over exploratory work, kept in the repo for later. It needs more
> validation and work before anyone relies on it (see the next steps at the end of this section); it is not part of
> the k_us / v_y work in sections 7 and 8 and nothing else depends on it.

Per wheel Fx from two sources fused per sample by inverse variance: the wheel torque model (sigma 100 N + 0.2 |Fx|) and
the Fz sensitive brush at the **bias corrected** slip ratio, `Fx = mu Fz (1 - (1 - |k|/k_th)^3)`, `k_th = 3 mu Fz / C_k`
(sigma = brush slope x 0.2 % + 0.1 |Fx_b|, so the brush counts near the peak and less in the linear range). C_k(Fz) from
the Pacejka load dependence; mu_x(Fz) per axle refit from the 98th percentile envelope of |Fx_torque|/Fz (front 0.88,
rear 1.63 at static load). Slip ratio bias (wheel speed / rolling radius, +0.2 to +1.7 %, the 2026 log is not wheel
speed calibrated) learned per wheel where the brush is steep, from the brush inverse at the wheel torque Fx: online RLS
th0 + th1 Fz + th2 vx^2 plus a time bias (tau 2 s).
**Independence:** nothing is fitted or learned from the force balance Fx_total, it is only the score (vehicle frame sum
of the wheel Fx vs m a_x + drag + grade), rms N: wheel torque 1189, brush 1631, **fused 1094** (pure longitudinal 1116 vs
1119, braking 1099 vs 1132, a wheel above 70 % of its peak 1232 vs 1540). An earlier version learned mu_x and the bias
from Fx corrected to Fx_total and scored 950 N, which was optimistic. So the observer helps near the peak (~20 %) and
hardly elsewhere. The rear mu_x 1.63 learned from the torque model is above what the IMU supports: the engine map /
drivetrain efficiency likely over predicts rear drive force. Next: calibrate wheel speeds and the engine map, combined
slip, refit the brush peak slip, validate per axle on straight braking and on a second log, Kalman filter on the wheel
dynamics. Tabs: Fx observer (with the IMU force balance split per tire), slip ratio (raw, 1.3 Hz, bias corrected), slip
ratio vs mu_x per tire and per axle (wheel torque, IMU split, brush, fused).

## 9. What to do next

1. **Settle the dual track question**: fit one stiffness load exponent per axle so the dual track k_us matches the measured
   k_us (no v_y needed). A plausible exponent -> the tire models' load sensitivity is the issue; none -> the front load
   transfer (roll centres, ARB_f) is.
2. Use the **dual track observer** slips for the dual track k_us once (1) is understood; try the refit brush per tire there.
3. **Port to C++**: build the `vehicle_model` package per section 2a and the HTML plan, then in `effective_stiffness`
   feed the observed axle Fz and the observer slip (or take the published bicycle k_us), keep the MPC formula; replace the
   fixed clamp with a utilization based hold (freeze or rate limit k_us when |F| / mu Fz > ~0.9).
4. Steering calibration on the car (offset and left / right ratio); lever arm check of the localization v_y (error vs r).
5. The saturated inner front (split vs load, see 2); consider lowering the Fz observer lag (fcObsModel 0.3 Hz).
6. Combined slip in the comparisons (braking / throttle samples), the ~640 N rear MF force bias, and refitting the brush
   mu / Ca against the **observer slip** so no fit uses the odom v_y.
7. Iz (placeholder 1000) sets the front / rear axle Fy split in transients (force balance); measure it.

## 10. debug_slip_angle.m tab guide

Fastest lap (loads, slip, k_us for every model) - **Compare old vs new** (total load, MPC brush fixed Fz vs observed Fz vs
the brush observer in white) - Per tire slip (measured vs observer vs per tire brush inverse, force split, force weighted
contribution in blue) - Dual track k_us (per tire vs axle stiffness, load transfer) - Dual track observer - Observers vs
measured (v_y, slips, errors, trust) - Trust sweep - k_us vs trust - Tau sweep - Tire models (curves, mu and Ca vs load) -
k_us by corner. Main settings at the top: `trustPow`, `trustFloor`, `tauObs`, `brTau`, `dtTrustPow`, `dtTrustFloor`, `dtTau`,
`fitStride`, `muSlip`, `muPct`, `kAyMin`.
