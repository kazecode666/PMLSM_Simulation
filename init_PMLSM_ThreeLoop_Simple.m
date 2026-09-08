% Independent model-workspace parameters. No base-workspace clear or hardware init.
Ts = 1e-4; % PWM carrier period; all task and delay periods derive from Ts.
Ts_ACR = Ts;
CPU_Clock = 200e6; % Legacy SVPWM count conversion only, no hardware dependency.
PMLSM_pwm_period_counts = CPU_Clock*Ts/2;
Ts_ASR = 10*Ts;
Ts_POS = 100*Ts;
PMLSM_Ts_s = Ts/2; % One half-carrier-period plant/PWM-update substep.
PMLSM_deadtime_s = 1e-6;
PMLSM_deadtime_ratio = PMLSM_deadtime_s/Ts;
PMLSM_deadtime_current_eps_A = 1e-4;
Host_Start_s = 0.5;
Host_Target_mm = 100;
% S-curve with smooth acceleration, constant speed, smooth deceleration.
Host_Traj_Vmax = 20; % Must not exceed the position/speed loop velocity limits.
Host_Traj_Amax = 100;
Host_Traj_Jmax = 1000;
Host_Speed_Ramp_s = 1; % Minimum acceleration/deceleration time; speed-mode ramp time.
Host_Load_N = 0;
% Rows: [time_s, Close_Loop_EN, Position_Loop_EN, PWM_EN].
% Add chronological rows to switch modes during a simulation.
Host_Enable_Schedule = [0 1 1 1];
Host_Speed_mmps = 0;
Host_Id_A = 0;
Host_Iq_Test_Mode = 0;
Host_Iq_A = 0;
Host_PI_Reset_EN = 0;
% Original position/speed loop settings and reference/reset manager thresholds.
Pos_deadband = 0.02;
v_ref_max = 20;
v_ref_set_rate_up = 50;
v_ref_set_rate_dn = 50;
v_ref_set_step_up = v_ref_set_rate_up*Ts;
v_ref_set_step_dn = v_ref_set_rate_dn*Ts;
v_ref_zero_eps = 0; % Do not erase load-balancing PI integral at zero reference.
v_ff_eps = 0.5;
v_over_eps = 3;
V_pos_max_mmps = 20;
Speed_loop_Iq_Limit = 1;
Iq_int_limit = 0.5;
PMLSM_Rs_ohm = 2.37;
PMLSM_Ld_H = 1.745e-3;
PMLSM_Lq_H = 1.745e-3;
PMLSM_psi_f_Wb = 0.141;
Udc = 48;
PMLSM_tau_NN_m = 0.06;
PMLSM_theta_offset_rad = 0;
PMLSM_Kf_peak_N_per_Apeak = 31.4/sqrt(2);
PMLSM_M_kg = 0.91;
PMLSM_Bv_N_per_mps = 0;
PMLSM_Fc_N = 0;
PMLSM_v_eps_mps = 1e-3;

% Three-loop tuning, validated with dead time and half-carrier PWM delay.
% Current Ld=Lq: both current axes share the same physical-unit PI gains.
Tuning_Current_Xi = 1/sqrt(2);
Tuning_Speed_h = 10;
Tuning_Position_Separation = 20;
Tuning_Gains = design_PMLSM_three_loop(PMLSM_Rs_ohm,PMLSM_Lq_H, ...
    PMLSM_M_kg,PMLSM_Kf_peak_N_per_Apeak,Ts_ACR,Ts_ASR,Ts_POS, ...
    Tuning_Current_Xi,Tuning_Speed_h,Tuning_Position_Separation);
Kp_ACR = Tuning_Gains.Kp_ACR;
Ki_ACR = Tuning_Gains.Ki_ACR;
Kaw_d = Tuning_Gains.Kaw_d;
Kaw_q = Tuning_Gains.Kaw_q;
Kp_ASR = Tuning_Gains.Kp_ASR;
Ki_ASR = Tuning_Gains.Ki_ASR;
Kaw_s = Tuning_Gains.Kaw_s;
Kp_pos = Tuning_Gains.Kp_pos;
