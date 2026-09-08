# 独立三闭环仿真：原环内逻辑与使能接口

打开 `PMLSM_ThreeLoop_Simple.slx` 后直接 Run，或执行：

```matlab
out = run_PMLSM_ThreeLoop_Simple(10);
```

默认 0.1 s 给定 10 mm，位置、速度、PWM 使能均打开。初始化参数集中在 `init_PMLSM_ThreeLoop_Simple.m`，由模型工作区加载，不调用原实机初始化脚本。

当前已完成三环整定：电流 PI 为 8.725/11850，速度 PI 为 0.01803347/1.44267799，位置 P 为 22。增益由初始化脚本调用 `design_PMLSM_three_loop.m` 计算；跨电脑复制模型时需要同时带上这两个 .m 文件。计算依据、候选对比及最新验证见 [三闭环整定说明](ThreeLoop_Tuning.md)。下文较早的使能验证数值属于整定前记录。

## 当前观测记录

记录统一保存为 `out.logsout`，仅包含以下 13 个信号；原 `Record_*` To Workspace 块及额外调试日志已移除或关闭。

| 分组 | 信号 |
|---|---|
| 位置 | `x_ref_mm`、`x_mm` |
| 三相电流 | `ia`、`ib`、`ic` |
| q 轴电流 | `iq_ref`、`iq` |
| d 轴电流 | `id_ref`、`id` |
| 电压 | `ud`、`uq` |
| 速度 | `v_ref`、`v_mmps` |

实际电流、位置和速度来自电机模型输出；`ud`、`uq` 为死区及 PWM 使能之后施加给电机的 dq 电压。dq 电流参考与速度参考来自 `Reference_Manager` 的有效指令。例：`out.logsout.get('iq').Values`。运行辅助函数会显示上述六组曲线。

已运行 3 s 仿真，核对记录名称恰好为上述 13 项且数据均有限。下文此前使能、计数器和内部 PI 验证报告为精简日志前的历史结果；对应旧验证脚本依赖已删除的调试记录，不能直接用于当前日志接口。

## 左侧上位机与使能

`Simple_Host` MATLAB Function 输出三个使能及位置、速度、电流测试参考。设置：

```matlab
% 每行：[时间(s), Close_Loop_EN, Position_Loop_EN, PWM_EN]
Host_Enable_Schedule = [0 1 1 1];
```

按时间顺序追加行，可在一次仿真中切换。例如：

```matlab
Host_Enable_Schedule = [
    0.0  1 1 1   % 三闭环位置控制
    0.4  0 1 1   % 关闭外环；FOC继续调节电流
    0.6  1 0 1   % 手动速度闭环
    0.8  1 0 0   % PWM输出关闭
    1.0  1 0 1   % PWM重新使能
    1.2  1 1 1   % 回到位置闭环
];
Host_Speed_mmps = 5;
```

| 信号 | 对应原模型 | 保留的行为 |
|---|---|---|
| Close_Loop_EN | close_loop_en_cmd / Close_Loop_EN_cmd | 关闭时速度参考归零；原速度环在速度节拍清零输出、复位积分。不是关闭 FOC，也不是停计数器。 |
| Position_Loop_EN | pos_loop_en_cmd / Pos_Loop_EN | 1 选择位置环的速度参考；0 选择手动速度参考。位置环继续按原计数器运行。 |
| PWM_EN | MIL pwm_enable | 将死区逆变器最终 vd、vq 乘以使能，关闭时输出为零。保留比较计数及 Ts/2 更新链。 |

手动速度参考保留原斜坡限制（上升/下降 50 mm/s²）和 ±20 mm/s 限幅。`Host_Speed_mmps` 设置手动速度，`Host_Target_mm` 设置位置目标。

同时恢复原逻辑的相关独立指令：

- `Host_PI_Reset_EN`：1 时复位原速度 PI，以及 d/q 电流 PI 的积分更新并将对应输出置零，默认 0。
- `Host_Iq_Test_Mode`、`Host_Iq_A`：独立电流测试选择与参考，默认关闭/0 A。测试模式下原速度环输出清零，FOC 使用测试 iq 参考。
- `Host_Id_A`：d 轴电流参考，默认 0 A。

有效复位命令为 `PI_Reset_EN OR NOT PWM_EN`。PWM 关闭时，速度 PI 与 d/q 电流 PI 在各自控制节拍清零积分更新及输出，并在 PWM 关闭期间持续复位；PWM 输出门控仍保持零电压。关闭外环不禁止独立电流测试，但 PWM 关闭时电流 PI 同样复位。

## 位置环、速度环的保留与简化

`Control_Task_10kHz/Position_Loop` 来自原 `Triggered_Position_loop`；`Speed_Loop` 来自原 `Triggered_Speed_loop`，2026-09-08 按要求清理反馈与复位逻辑。保留：

- 位置死区 `Pos_deadband=0.02 mm`、位置 P、速度限幅、原前馈和复位端口。
- 原速度 PI 结构、积分限幅、输出限幅、延迟抗饱和和超速复位；增益按最新三环整定计算。
- 原来已注释停用的摩擦前馈保持原状态。
- 位置环未修改；速度环仅修改本次指定功能及相关连线，保留其余模块位置和尺寸。

仅关闭了位置输出信号对实机 `Simulink.Signal` 对象的强制解析，并添加少量观测记录；这不改变算法。三个使能相关命令通过控制任务内的局部 Data Store 传给原速度环，使环内不用改接口或读数块。写入优先于原速度环读取。

对齐输入仍接 0；位置前馈/原位置复位输入也接 0。原位置复位端口本来就是 Terminator，未额外虚构复位行为。已删除 `v_ideal_mmps`、速度反馈选择器和 `Speed_Feedback_Mode`，速度环直接使用电机输出的 `v_mmps`，不模拟编码器。

已删除 `travel_fault` 的速度环端口、复位管理端口及复位条件，当前不建模行程限位。已删除 `speed_out_zero` 和接近停止时的 `ASR_Stop_Reset` 判据，不再因为参考速度与反馈速度较小而强制输出归零。使能关闭、主动复位或电流测试时的清零由 `pi_hard_reset` 保留；它不含停止判据。零参考积分复位比较块仍保留，但本次整定将严格小于阈值 `v_ref_zero_eps` 设为 0，使正常零参考不再清掉负载补偿积分。

仓库精简后，本文提及的过程 PNG/JSON 和 `tools/*.m` 仅在原电脑本地保留，不属于运行依赖。

`docs/original_loop_copy_audit.json` 是 2026-09-07 复制时的历史核对记录；本次速度环已按要求简化，不再声称当前速度环与原件完全相同。

## 离散周期和逆变器

周期统一由 `Ts` 决定：电流任务 Ts、速度环 10*Ts、位置环 100*Ts，计数器不受模式使能影响。默认分别为 100 μs、1 ms、10 ms。

`PWM_Update_HalfTs` 固定选用原半载波周期延迟支路，直接使用 `Ts/2`。保留原 1 μs 死区、电流符号阈值 1e-4 A 及平均电压方程，只有最终 PWM 输出门控，没有绕过逆变器或死区的选择接口。

FOC 仍输出比较计数，默认周期计数为 `CPU_Clock*Ts/2=10000`，中点为 5000；未新增整数寄存器量化。电流在控制任务调用时采样，新比较值延后 Ts/2 生效。

## 历史使能验证（整定前）

`tools/validate_enable_logic.m` 覆盖位置模式、速度模式、关闭外环、关闭 PWM、关闭后再次使能、独立电流测试和 PI 复位。检查速度参考门控、积分清零、PWM 零电压及计数器持续运行。结果见 `docs/enable_validation_results.json`。

整定前的使能修改结果见 `docs/enable_validation_results.json`，切换曲线见 `docs/enable_switching_response.png`。当时测试增加了 PWM 关闭时速度积分、d/q 积分和 d/q PI 输出为零的断言，并记录重新使能后 0.2 s 内的速度峰值；当时尚未修改 PI 参数。

当时七类场景检查通过。5 mm/s 指令下，PWM 重新使能后 0.2 s 内速度峰值约 5.926 mm/s；默认 10 mm 位置指令在 3 s 时为 9.9361 mm、-0.00952 mm/s。这些数值已由最新整定报告替代，不代表当前参数的响应。

位置测试检查目标附近 ±0.1 mm 的包络，是回归检查，不是精密定位验收。`docs/three_loop_validation_results.json` 为四个位置目标的结果。旧版本末端误差及停止振荡结论不应直接用于当前版本。

本次数值验证使用 R2026a Update 5；未声称已在 R2023b 中实际运行。模型需要 MATLAB、Simulink，以及原坐标变换库对应工具箱（本机依赖分析列出 Simscape Electrical）。

