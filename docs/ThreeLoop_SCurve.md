# S 型轨迹与死区对照（2026-09-08）

## 当前更新：带明显匀速段的 S 曲线

当前模型已采用 `pmlsm_scurve_profile.m`：速度先按五次平滑曲线加速，再匀速，再按五次平滑曲线减速；位置为速度的解析积分。以下原始全行程五次曲线说明和死区对照作为历史结果保留。

按当前用户参数 Vmax=20 mm/s、Amax=100 mm/s²、Jmax=1000 mm/s³，`Host_Speed_Ramp_s=1` 同时指定加减速段的最短时长。100 mm 规划如下：

- 0.5–1.5 s：平滑加速，0 → 20 mm/s。
- 1.5–5.5 s：匀速 20 mm/s。
- 5.5–6.5 s：平滑减速，20 → 0 mm/s。

加减速实际峰值加速度 37.5 mm/s²，峰值 jerk 115.47 mm/s³，均低于参数上限。短行程会自动降低峰值速度，必要时无匀速段，不会为了保留匀速段超出约束。负向和零距离端点、短距离限速检查通过。

8 s 完整仿真：最终位置 99.987003628 mm，2–5 s 实际平均速度 19.999999926 mm/s。端口、连线和 Stateflow 检查通过。结果：`scurve/cruise_profile.png` 和 `scurve/cruise_validation.mat`。控制器、逆变器及连线布局未改。运行模型时需一并保留根目录的 `pmlsm_scurve_profile.m`；运行入口自动按新轨迹时长设置仿真时长。

## 历史版本与死区诊断

当前 `Simple_Host` 将固定位置目标从 0 到目标值规划为五次多项式：

`x = D*(10*s^3 - 15*s^4 + 6*s^5)`，`s=clamp((t-Host_Start_s)/T,0,1)`。

起止速度、加速度均为零；这是五次多项式 S 曲线，不是七段恒定 jerk 曲线。时间由速度、加速度和 jerk 三项约束的最大值计算：

`T=max(1.875*abs(D)/Vmax, sqrt(10/sqrt(3)*abs(D)/Amax), (60*abs(D)/Jmax)^(1/3))`。

参数在 `init_PMLSM_ThreeLoop_Simple.m`：`Host_Traj_Vmax=18 mm/s`、`Host_Traj_Amax=30 mm/s^2`、`Host_Traj_Jmax=300 mm/s^3`。应设为正值，速度上限应小于位置环限速。100 mm 对应运动时间 10.4167 s，0.5 s 开始。

速度模式使用 `Host_Speed_Ramp_s=1 s` 的五次平滑过渡。参考管理器中的现有斜率限制器已移至位置/速度模式选择之后，两种模式均限制速度指令变化。位置环/速度环内部和计数器调度未改。离散采样保留，正常使能下速度指令每 100 us 最大变化 0.005 mm/s；关闭闭环时仍立即输出零，这是原有使能逻辑。限斜率不等于对实际电机加速度/jerk 作严格约束。

支持固定参数的正向、负向、零距离点到点运行；本轮未实现运动中动态更改目标时的在线重规划。

## 验证

- 100 mm、12 s：最终位置 99.985312394 mm，速度参考峰值 17.990035 mm/s。
- 电流参考峰值：原阶跃 0.360669497 A；S 曲线 0.010797366 A。
- -1 mm、3 s：最终 -0.989237278 mm。
- 速度模式 10 mm/s、2 s：最终 10.002882075 mm/s。
- 模型端口、连线和 Stateflow lint 检查通过。

死区对照只用 SimulationInput 临时覆盖 `PMLSM_deadtime_s` 与 `PMLSM_deadtime_ratio` 为 0，保留 PI、采样和半载波 PWM 更新延迟。正式模型保持 1 us 死区。相同 S 曲线下，11.5–12 s 停稳窗口：

| 电流 | 1 us 死区峰峰值 | 0 死区峰峰值 |
|---|---:|---:|
| id | 20.2478 mA | 约 9.70e-13 mA |
| iq | 16.4764 mA | 约 3.60e-8 mA |

说明当前模型的持续纹波主要由死区模型引起，不能将这些幅值直接等同实物开关纹波。运动中 iq 还包含加减速和位置环离散更新产生的电流变化。

结果见 `scurve/comparison.png`、`scurve/validation.json`、`scurve/comparison.mat`。`tools/report_scurve_deadtime.m` 可由三组 SimulationOutput 重生成报告。`run_PMLSM_ThreeLoop_Simple(target_mm)` 自动根据轨迹时长留出 1.5 s 停稳时间。
