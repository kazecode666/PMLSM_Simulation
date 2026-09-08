# PMLSM_Simulation

AUM3-S4 永磁同步直线电机 MATLAB/Simulink MIL 仿真。

新增独立算法模型：`PMLSM_ThreeLoop_Simple.slx`，上位机→原计数器调度的三环→比较计数→Ts/2 更新延迟及死区逆变器→电机。运行 `run_PMLSM_ThreeLoop_Simple(100)`。当前位置指令带平滑加速、匀速和平滑减速段，100 mm 默认为 1 s 加速、4 s 匀速、1 s 减速。详情见 [轨迹及验证说明](docs/ThreeLoop_SCurve.md) 与 [三环整定](docs/ThreeLoop_Tuning.md)。

简化模型必须连同 `init_PMLSM_ThreeLoop_Simple.m`、`design_PMLSM_three_loop.m`、`pmlsm_scurve_profile.m` 一起下载。仓库保留验证图和 JSON 摘要，大型原始仿真 MAT/FIG 文件仅保留在本地。

## 运行

根目录保存当前 R2026a 源模型。将 MATLAB 当前目录切换到仓库根目录，打开 `PMLSM_MIL_ControlCore_Sim.slx` 并点击 Run。模型初始化回调会加载全部参数。原初始化包含 `clear; clc;`，请先保存基础工作区中需要保留的数据。

需要 MATLAB、Simulink、Stateflow、Motor Control Blockset。主模型通过 Model Reference 引用 `PMLSM_ControlCore_Block.slx`；必须一起下载。

R2023b 电脑请完整解压 [R2023b 仿真包](compatibility/PMLSM_MIL_R2023b.zip)，在解压目录运行 `start_PMLSM_MIL`，或运行 `out = check_PMLSM_MIL;` 自检。不要把不同版本的同名模型同时加入路径。

## 给 ChatGPT / Codex

先读 [AI_PROJECT_CONTEXT.md](AI_PROJECT_CONTEXT.md) 和 [AGENTS.md](AGENTS.md)。`.slx` 是 ZIP/XML 容器，GitHub 网页通常不能直接展示其内部逻辑；本仓库提供自动提取的 [模型文本索引](docs/model_index.md) 与 `docs/model_source/` 下的 XML，供没有 MATLAB 的工具检索。它们是只读衍生文件，权威来源仍是 `.slx`。

在另一台电脑克隆：

```sh
git clone https://github.com/kazecode666/PMLSM_Simulation.git
```

公开仓库可直接读取脚本/XML；使用 ChatGPT/Codex 的 GitHub 连接器时仍需按连接器要求授权。没有 MATLAB 的环境可以分析脚本/XML，但不能声称完成 Simulink 仿真验证。

## 范围与验证

上传主 MIL 仿真及必要初始化，未包含硬件代码生成模型、编译缓存、历史日志、参考论文或硬件资料。

2026-09-07 导出的 R2023b 包在本机 R2026a Update 5 的隔离目录完成默认 7 秒仿真，76 路记录信号与源模型逐点一致，最大绝对差为 0。未在实际 R2023b 环境执行；该结果只覆盖默认工况。详见 [验证说明](docs/R2023b_VALIDATION.txt)。

更新模型后运行 `python tools/export_model_text.py` 刷新文本索引，并重新导出兼容包。R2023b 包是有日期的快照，不会随源模型自动更新。
