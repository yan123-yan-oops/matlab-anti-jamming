%%
% ============================================================
%  08 滤波基础 — 从移动平均到陷波器
%
%  学习目标：
%    1. 移动平均滤波（时域最简单）
%    2. FIR 与 IIR 的区别
%    3. 陷波器（Notch Filter）— 抗窄带干扰的核心
%    4. MATLAB filter 设计工具
%
%  前置知识：02 FFT / 07 干扰模型
%  运行方法：F5 直接运行
% ============================================================

clear; close all; clc;
rng(42);
fprintf('===== 08 滤波基础 =====\n\n');

%% 1. 移动平均滤波（理解"滤波"的最直观方式）
fprintf('--- 1. 移动平均滤波 ---\n');

Fs = 1000; T = 1;
t = (0:round(Fs*T)-1)/Fs;

% 带噪声的信号
clean = sin(2*pi*5*t);
noise = 0.5 * randn(size(t));
rx = clean + noise;

% 移动平均（N=5, N=20）
N1 = 5;
N2 = 20;
ma5 = filter(ones(1,N1)/N1, 1, rx);
ma20 = filter(ones(1,N2)/N2, 1, rx);

fprintf('  移动平均 N=5  → 滤掉部分噪声\n');
fprintf('  移动平均 N=20 → 滤掉更多噪声（但信号也会变钝）\n');
fprintf('  🔑 关键 trade-off：N 越大噪声越小，但信号延迟越大\n');

figure('Name', '移动平均', 'Position', [100, 100, 1000, 500]);

subplot(3,1,1);
plot(t(1:200), rx(1:200), 'r-', 'LineWidth', 0.8);
title('原始信号 + 噪声'); ylabel('幅度');
ylim([-2 2]); grid on;

subplot(3,1,2);
plot(t(1:200), ma5(1:200), 'b-', 'LineWidth', 1.5); hold on;
plot(t(1:200), clean(1:200), 'k--', 'LineWidth', 1);
title('N=5 移动平均（红色=原始，黑色虚线=理想）');
ylabel('幅度'); legend('滤波后', '理想', 'Location', 'best');
ylim([-2 2]); grid on;

subplot(3,1,3);
plot(t(1:200), ma20(1:200), 'b-', 'LineWidth', 1.5); hold on;
plot(t(1:200), clean(1:200), 'k--', 'LineWidth', 1);
title('N=20 移动平均（更平滑，但延迟更大）');
xlabel('时间 (s)'); ylabel('幅度');
ylim([-2 2]); grid on;

sgtitle('移动平均滤波：N 越大越平滑，但延迟越大', 'FontSize', 13, 'FontWeight', 'bold');

%% 2. 陷波器 — 干掉特定频率
fprintf('\n--- 2. 陷波器（Notch Filter）---\n');

% 信号 + 50Hz 干扰
f_sig = 10;
f_jam = 50;
x = sin(2*pi*f_sig*t) + 2*sin(2*pi*f_jam*t);  % 干扰强度是信号的 2 倍

% 设计陷波器（干掉 50Hz）
wo = f_jam / (Fs/2);  % 归一化频率
bw = wo / 35;         % 带宽
[b_notch, a_notch] = iirnotch(wo, bw);

% 滤波
y = filter(b_notch, a_notch, x);

fprintf('  信号: 10Hz, 干扰: 50Hz（幅度2倍）\n');
fprintf('  设计 50Hz 陷波器 → 保留 10Hz, 抑制 50Hz\n');

figure('Name', '陷波器', 'Position', [100, 100, 1000, 500]);

% 频响
freqz(b_notch, a_notch, 512, Fs);
title('陷波器频率响应（50Hz 处 -40dB）');

figure('Name', '陷波效果', 'Position', [100, 100, 1000, 400]);

N_fft = 2^nextpow2(length(x));
f = (0:N_fft-1) * Fs / N_fft;

subplot(1,2,1);
X_before = abs(fft(x, N_fft)) / N_fft * 2;
stem(f(1:100), X_before(1:100), 'r-', 'LineWidth', 1);
title('❌ 陷波前：10Hz + 50Hz');
xlabel('Hz'); ylabel('幅度'); xlim([0 80]); grid on;

subplot(1,2,2);
X_after = abs(fft(y, N_fft)) / N_fft * 2;
stem(f(1:100), X_after(1:100), 'b-', 'LineWidth', 1);
title('✅ 陷波后：50Hz 被干掉');
xlabel('Hz'); ylabel('幅度'); xlim([0 80]); grid on;

sgtitle('陷波器效果：保留信号，抑制特定频率干扰', 'FontSize', 13, 'FontWeight', 'bold');

fprintf('  ✅ 陷波器就是抗窄带干扰的核心工具\n');
fprintf('  ✅ 面试会问：IIR 阶数 / 陷波深度 / 带宽设计\n\n');

fprintf('✅ 08 学完！下一步：09 抗干扰综合\n');
