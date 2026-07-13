# 北斗导航抗干扰 — MATLAB 仿真学习工程

> 本仓库与 [embed-c-learning](https://github.com/yan123-yan-oops/embed-c-learning) 一一对应
>
> **最终目标**：中森通信 · 嵌入式导航抗干扰工程师

---

## 📌 这是什么

这是一个和 `embed-c-learning` **并行学习**的 MATLAB 工程。每一章都和对应的 C 章节配对：

```
C 做底层采集/算法原型 → MATLAB 做上层验证/可视化
                ↑                     ↑
         embed-c-learning     本仓库 (matlab-anti-jamming)
```

**两条腿走路**，面试官看到的是完整的 C↔MATLAB 闭环能力。

---

## 📂 目录结构（与 embedded-c 对照表）

| 阶段 | C 章节 | 对应 MATLAB 章节 | 核心内容 |
|------|--------|-----------------|----------|
| **1** | 01-basics 数据类型 | **01**-matlab-basics | 矩阵运算、plot画图、数据类型 |
| **1** | 02-pointers 指针 | **02**-fft-spectrum | FFT 频谱分析（指针=地址偏移，FFT=频率偏移） |
| **1** | 03-bitwise 位操作 | **03**-signal-gen | 信号生成、噪声模型 |
| **1** | 06-strings 字符串 | **04**-file-io | 文件读写、数据流处理 |
| **1** | **08-nmea-parser** 🎯 | **05**-nmea-verify | **NMEA 解析结果验证** |
| **2** | 08-10 过渡 | **06**-gnss-signal | PRN 码、BPSK 调制、扩频概念 |
| **2** | — | **07**-interference | 干扰模型（CW/宽带/脉冲） |
| **3** | — | **08**-filtering | 滤波基础（陷波器/LMS） |
| **3** | — | **09**-anti-jamming | 抗干扰综合（原 beidou_anti_jamming_sim 拆分） |
| **4** | 面试冲刺 | **10**-final-project | 最终集成项目 |

---

## 🗺️ 学习路线

### 阶段 1（当前）：MATLAB 基础 + FFT + NMEA 验证
> 和 C 阶段 1 同步学习

| 周 | MATLAB 内容 | 配合 C 章节 |
|----|-----------|-----------|
| W1 | 01 矩阵/画图 | C 01-basics |
| W2 | 02 FFT 频谱分析 | C 02-pointers |
| W3 | 03 信号生成 | C 03-bitwise |
| W4 | 04 文件IO | C 06-strings |
| W5 🚀 | **05 NMEA 验证** | **C 08-nmea-parser** ✅ |

### 阶段 2：GNSS 信号 + 干扰模型
> 学习 DSP 和通信原理后开始

| 周 | MATLAB 内容 | 配合 C 章节 |
|----|-----------|-----------|
| W6-9 | 06 GNSS 信号生成（PRN/BPSK） | C 阶段2 ARM外设 |
| W10-11 | 07 干扰模型 | — |

### 阶段 3：抗干扰算法
> 阶段 2 完成后集中攻克

| 周 | MATLAB 内容 | 配合 C 章节 |
|----|-----------|-----------|
| W12-15 | 08 滤波基础 → 09 抗干扰综合 | C 项目整合 |

---

## 📝 每章内容说明

每章包含三个部分：

```
chapter-XX/
├── XXX.m              ← 可独立运行的 MATLAB 脚本
├── XXX_concepts.md     ← 🔥 难点概念深度解析（FT/FFT/扩频/滤波）
└── EXERCISES.md        ← 练习题（概念题 + 代码阅读题 + 编程题）
```

> 💡 你公司内网有 MATLAB 环境，每学完一章可以直接 F5 跑对应脚本

---

## 🔗 相关仓库

- [embed-c-learning](https://github.com/yan123-yan-oops/embed-c-learning) — 嵌入式 C 学习工程（C 端）

---

> 🎯 **记住目标**：中森通信 · 嵌入式导航抗干扰工程师
> C 做底层，MATLAB 做验证，两条腿走路
