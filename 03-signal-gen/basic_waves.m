%%
% ============================================================
%  03 信号生成 — 你将在 GNSS 仿真中用到的基础
%
%  学习目标：
%    1. 生成常用波形（正弦/方波/三角波/锯齿波）
%    2. 噪声模型（高斯/均匀/脉冲）
%    3. 叠加信号（为后面的干扰建模打基础）
%
%  对应 C 03-bitwise：
%    位操作 = 数字域的信号处理
%    波形生成 = 模拟域的信号表示
%    两者在 ADC 采样点交汇
%
%  运行方法：F5 直接运行
% ============================================================

clear; close all; clc;
fprintf('===== 03 信号生成 =====\n\n');

Fs = 1000;
T  = 0.5;
t  = 0:1/Fs:T-1/Fs;

%% 1. 四种基本波形
fprintf('--- 1. 基本波形 ---\n');

f_sig = 5;  % 5 Hz

sine_wave = sin(2*pi*f_sig*t);
square_wave = square(2*pi*f_sig*t);
sawtooth_wave = sawtooth(2*pi*f_sig*t, 0.5);  % 三角波
pulse_wave = square(2*pi*f_sig*t, 20);  % 占空比 20%

figure('Name', '基本波形', 'Position', [100, 100, 1000, 600]);

subplot(4,1,1);
plot(t(1:200), sine_wave(1:200), 'b-', 'LineWidth', 1.5);
title('正弦波'); ylabel('幅度'); grid on;

subplot(4,1,2);
plot(t(1:200), square_wave(1:200), 'r-', 'LineWidth', 1.5);
title('方波'); ylabel('幅度'); grid on;

subplot(4,1,3);
plot(t(1:200), sawtooth_wave(1:200), 'g-', 'LineWidth', 1.5);
title('三角波'); ylabel('幅度'); grid on;

subplot(4,1,4);
plot(t(1:200), pulse_wave(1:200), 'm-', 'LineWidth', 1.5);
title('脉冲波 (占空比20%)'); xlabel('时间 (s)'); ylabel('幅度'); grid on;

sgtitle('四种基本波形', 'FontSize', 13, 'FontWeight', 'bold');

fprintf('  正弦波、方波、三角波、脉冲波\n');
fprintf('  北斗 B1I 用的是 BPSK = 正弦波 × 方波\n\n');

%% 2. 噪声模型
fprintf('--- 2. 噪声模型 ---\n');

n = length(t);

noise_gaussian = 0.5 * randn(1, n);      % 高斯白噪声（热噪声）
noise_uniform  = 0.5 * (2*rand(1,n)-1);  % 均匀分布噪声（量化噪声）
noise_pulse    = 0.5 * (rand(1,n) > 0.95) .* randn(1,n);  % 脉冲噪声

figure('Name', '噪声模型', 'Position', [100, 100, 1000, 600]);

subplot(3,1,1);
plot(t, noise_gaussian, 'b-', 'LineWidth', 0.8);
title('高斯白噪声（模拟热噪声）');
ylabel('幅度'); grid on;

subplot(3,1,2);
plot(t, noise_uniform, 'r-', 'LineWidth', 0.8);
title('均匀噪声（模拟量化噪声）');
ylabel('幅度'); grid on;

subplot(3,1,3);
plot(t, noise_pulse, 'm-', 'LineWidth', 0.8);
title('脉冲噪声（模拟突发干扰）');
xlabel('时间 (s)'); ylabel('幅度'); grid on;

sgtitle('三种噪声模型', 'FontSize', 13, 'FontWeight', 'bold');

fprintf('  高斯噪声 → ... 收音机沙沙声\n');
fprintf('  均匀噪声 → ADC 量化误差\n');
fprintf('  脉冲噪声 → 闪电/电机火花\n\n');

%% 3. 信号 + 噪声（模拟真实接收信号）
fprintf('--- 3. 信号 + 噪声 → 真实场景 ---\n');

signal = sin(2*pi*10*t);
noise = 0.3 * randn(1, n);
rx = signal + noise;

figure('Name', '信号+噪声', 'Position', [100, 100, 1000, 400]);

subplot(1,2,1);
plot(t(1:200), signal(1:200), 'b-', 'LineWidth', 1.5);
title('干净信号');
xlabel('时间 (s)'); ylabel('幅度');
ylim([-1.5 1.5]); grid on;

subplot(1,2,2);
plot(t(1:200), rx(1:200), 'r-', 'LineWidth', 1);
title('信号 + 噪声（北斗接收机真实情况）');
xlabel('时间 (s)'); ylabel('幅度');
ylim([-1.5 1.5]); grid on;

sgtitle('干净信号 vs 加噪声', 'FontSize', 13, 'FontWeight', 'bold');

fprintf('  SNR 信噪比 = 10*log10(信号功率 / 噪声功率)\n');
fprintf('  天线收到的北斗信号 ≈ -130dBm(极弱！)\n');
fprintf('  噪声功率通常比信号大... 要靠扩频增益找到信号\n\n');

fprintf('✅ 03 学完！下一步：04 文件 I/O\n');
