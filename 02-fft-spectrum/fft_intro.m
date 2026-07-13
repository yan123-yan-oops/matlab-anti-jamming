%%
% ============================================================
%  02 FFT 频谱分析 — 从时域到频域
%
%  学习目标：
%    1. 理解 FT/FFT：时域→频域的桥梁
%    2. 频谱泄露、栅栏效应、补零
%    3. 采样定理的直观感受
%
%  对应 C 02-pointers：
%    指针 = 内存地址的偏移
%    FFT  = 频率偏移的数学工具 ← 概念相通
%
%  运行方法：F5 直接运行
% ============================================================

clear; close all; clc;
fprintf('===== 02 FFT 频谱分析 =====\n\n');

%% 1. 一个正弦波 + FFT = 一条谱线
fprintf('--- 1. 从时域到频域 ---\n');

Fs = 1000;           % 采样率 1000 Hz
T  = 1;              % 时长 1 秒
t  = 0:1/Fs:T-1/Fs;

f0 = 10;             % 信号频率 10 Hz
x  = sin(2*pi*f0*t);

% FFT
N = length(x);
X = fft(x);
f = (0:N-1) * Fs / N;      % 频率轴
mag = abs(X) / N * 2;       % 幅度（单边谱）

figure('Name', 'FFT 入门', 'Position', [100, 100, 1000, 500]);

subplot(1,2,1);
plot(t(1:200), x(1:200), 'b-', 'LineWidth', 1.5);
xlabel('时间 (s)'); ylabel('幅度');
title('时域：正弦波');
grid on;

subplot(1,2,2);
stem(f(1:100), mag(1:100), 'r-', 'LineWidth', 1);
xlabel('频率 (Hz)'); ylabel('幅度');
title('频域：一条谱线 → 10Hz');
xlim([0, 100]); grid on;

sgtitle('时域 ↔ 频域：两种看信号的方式', 'FontSize', 13, 'FontWeight', 'bold');

fprintf('  正弦波 10Hz → FFT 后在 10Hz 处出现一个尖峰\n');
fprintf('  这就是 FT 的本质：把信号拆成不同频率的正弦波\n\n');

%% 2. 两个正弦波叠加 = 两根谱线
fprintf('--- 2. 叠加信号 ---\n');

x2 = sin(2*pi*10*t) + 0.5*sin(2*pi*50*t);

X2 = fft(x2);
mag2 = abs(X2) / N * 2;

figure('Name', '叠加信号 FFT', 'Position', [100, 100, 1000, 400]);

subplot(1,2,1);
plot(t(1:200), x2(1:200), 'b-', 'LineWidth', 1);
xlabel('时间 (s)'); ylabel('幅度');
title('时域：10Hz + 50Hz 叠加');
grid on;

subplot(1,2,2);
stem(f(1:150), mag2(1:150), 'r-', 'LineWidth', 1);
xlabel('频率 (Hz)'); ylabel('幅度');
title('频域：两根谱线');
xlim([0, 100]); grid on;

fprintf('  两根谱线: 10Hz(幅度1.0) + 50Hz(幅度0.5)\n');
fprintf('  👆 这就是频谱分析的核心应用\n\n');

%% 3. 采样率不够 → 混叠（对应 C 里数组越界）
fprintf('--- 3. 采样定理的直观感受 ---\n');

f_sig = 30;      % 信号 30Hz
Fs_bad = 40;     % 采样率 40Hz (< 2×30，违反奈奎斯特定理)
Fs_good = 200;   % 采样率 200Hz (>> 2×30)

t_bad = 0:1/Fs_bad:1;
t_good = 0:1/Fs_good:1;

x_bad = sin(2*pi*f_sig*t_bad);
x_good = sin(2*pi*f_sig*t_good);

fprintf('  信号 30Hz，采样率 40Hz → 违反采样定理\n');
fprintf('  C 里数组越界 → 读到垃圾值\n');
fprintf('  MATLAB 采样率不够 → 频域混叠\n\n');

figure('Name', '采样定理', 'Position', [100, 100, 1000, 400]);

subplot(1,2,1);
t_cont = 0:0.001:1;
plot(t_cont, sin(2*pi*f_sig*t_cont), 'b--'); hold on;
stem(t_bad, x_bad, 'ro-', 'MarkerSize', 4);
title(sprintf('❌ 采样率 %dHz → 混叠', Fs_bad));
xlabel('时间 (s)'); legend('原始', '采样点');

subplot(1,2,2);
plot(t_cont, sin(2*pi*f_sig*t_cont), 'b--'); hold on;
stem(t_good, x_good, 'go-', 'MarkerSize', 4);
title(sprintf('✅ 采样率 %dHz → 完整重建', Fs_good));
xlabel('时间 (s)'); legend('原始', '采样点');

%% 4. FFT 实用技巧
fprintf('--- 4. FFT 实用技巧 ---\n');

% 频谱泄露：非整数周期截断
N_leak = 256;    % 不是信号周期的整数倍
t_leak = (0:N_leak-1)/Fs;
x_leak = sin(2*pi*10*t_leak);  % 10Hz / 1000Hz * 256 = 2.56 周期 → 非整数

X_leak = fft(x_leak);
mag_leak = abs(X_leak) / N_leak * 2;
f_leak = (0:N_leak-1) * Fs / N_leak;

% 加窗改善
win = hann(N_leak)';
x_win = x_leak .* win;
X_win = fft(x_win);
mag_win = abs(X_win) / sum(win) * 2;

figure('Name', '频谱泄露', 'Position', [100, 100, 1000, 400]);

subplot(1,2,1);
stem(f_leak(1:50), mag_leak(1:50), 'r-', 'LineWidth', 1);
title('❌ 不加窗：频谱泄露');
xlabel('频率 (Hz)'); xlim([0, 50]); grid on;

subplot(1,2,2);
stem(f_leak(1:50), mag_win(1:50), 'b-', 'LineWidth', 1);
title('✅ 加窗后：谱线更干净');
xlabel('频率 (Hz)'); xlim([0, 50]); grid on;

sgtitle('频谱泄露 vs 加窗抑制', 'FontSize', 13, 'FontWeight', 'bold');

fprintf('  不加窗 → 能量扩散到旁边频率（像模糊的照片）\n');
fprintf('  加汉宁窗 → 能量集中在主瓣（变清晰了）\n\n');

fprintf('✅ 02 学完！记住：时域和频域是同一个信号的两种语言\n');
