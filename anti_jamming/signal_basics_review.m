%% ============================================================
%  信号基础复习 — 导航抗干扰前置知识
%  配套学习计划：阶段 2→3
%  运行方法：在 MATLAB 中 F5 直接跑
% ============================================================

clear; close all; clc;
fprintf('===== 信号基础复习 =====\n\n');

%% 1. 时域 vs 频域 — 信号的两个视角
% 一个 10Hz 的正弦波
fprintf('--- 1. 时域 vs 频域 ---\n');

Fs = 1000;          % 采样率 1000Hz（大于信号频率的2倍）
T  = 1;             % 时长 1 秒，指仿真总时长
t  = 0:1/Fs:T-1/Fs; % 时间轴->冒号语法 起始:步长:终点  

f0 = 10;            % 信号频率 10Hz
x  = sin(2*pi*f0*t); % 时域信号

% 画时域图
figure('Name', '时域 vs 频域', 'Position', [100, 100, 800, 400]);
subplot(1,2,1);
plot(t(1:200), x(1:200), 'b-', 'LineWidth', 1.5);
xlabel('时间 (s)'); ylabel('幅度');
title('时域：信号随时间变化');
grid on;

% FFT 转到频域
X     = fft(x);
f_axis = (0:length(X)-1) * Fs / length(X);  % 频率轴
amp   = abs(X) / length(X) * 2;              % 幅度

subplot(1,2,2);
plot(f_axis(1:200), amp(1:200), 'r-', 'LineWidth', 1.5);
xlabel('频率 (Hz)'); ylabel('幅度');
title('频域：信号在哪些频率上有能量');
grid on;
xlim([0, 50]);

fprintf('  10Hz 正弦波 → 频谱上在 10Hz 处有一个尖峰\n\n');

%% 2. 采样定理 — 采样率不够会怎样？
fprintf('--- 2. 采样定理 ---\n');

f_signal = 30;     % 信号 30Hz
Fs_bad   = 40;     % 采样率 40Hz (< 60Hz，违反采样定理)
Fs_good  = 200;    % 采样率 200Hz (>> 60Hz，满足)

t_bad  = 0:1/Fs_bad:1;
t_good = 0:1/Fs_good:1;

x_bad  = sin(2*pi*f_signal*t_bad);
x_good = sin(2*pi*f_signal*t_good);

figure('Name', '采样定理', 'Position', [100, 100, 800, 400]);

subplot(1,2,1);
plot(t_bad, x_bad, 'ro-', 'MarkerSize', 3);
hold on;
t_cont = 0:0.001:1;
plot(t_cont, sin(2*pi*f_signal*t_cont), 'b--');
title(sprintf('采样率 %dHz — ❌ 混叠', Fs_bad));
xlabel('时间 (s)'); ylabel('幅度');
legend('采样点', '原始信号', 'Location', 'northeast');

subplot(1,2,2);
plot(t_good, x_good, 'go-', 'MarkerSize', 3);
hold on;
plot(t_cont, sin(2*pi*f_signal*t_cont), 'b--');
title(sprintf('采样率 %dHz — ✅ 完整重建', Fs_good));
xlabel('时间 (s)'); ylabel('幅度');
legend('采样点', '原始信号', 'Location', 'northeast');

fprintf('  采样率 < 信号频率×2 → 混叠（虚线是原始信号，红点是采到的）\n');
fprintf('  北斗信号在 1.5GHz 附近 → ADC 采样率至少要 3GHz 以上\n\n');

%% 3. 加噪声 — 信号 vs 干扰
fprintf('--- 3. 信号 + 噪声 / 干扰 ---\n');

% 干净的信号
clean = sin(2*pi*10*t);

% 加高斯白噪声（模拟热噪声）
noise = 0.3 * randn(size(t));
noisy = clean + noise;

% 加单频干扰（模拟敌方干扰机）
jam_freq  = 200;             % 干扰频率 200Hz
jam_amp   = 2;               % 干扰幅度（比信号大）
jamming   = jam_amp * sin(2*pi*jam_freq*t);
jammed    = clean + jamming; % 信号 + 干扰

% 同时加噪声 + 干扰（最真实的场景）
realistic = clean + noise + jamming;

figure('Name', '信号 + 干扰', 'Position', [100, 100, 1000, 600]);

subplot(2,2,1);
plot(t(1:300), clean(1:300), 'b-');
title('① 干净信号 (GPS 北斗)');
ylabel('幅度');

subplot(2,2,2);
plot(t(1:300), jammed(1:300), 'r-');
title('② 信号 + 单频干扰');
ylabel('幅度');

subplot(2,2,3);
plot(t(1:300), noisy(1:300), 'g-');
title('③ 信号 + 白噪声');
xlabel('时间 (s)'); ylabel('幅度');

subplot(2,2,4);
plot(t(1:300), realistic(1:300), 'm-');
title('④ 信号 + 噪声 + 干扰 (真实场景)');
xlabel('时间 (s)'); ylabel('幅度');

fprintf('  干扰幅度 2.0，信号幅度 1.0 → 干扰功率是信号的 4 倍\n');
fprintf('  这就是干信比 JSR = 6dB，你后面要设计的抗干扰算法就是要抑制它\n\n');

%% 4. 频谱分析 — 看干扰在哪里
fprintf('--- 4. FFT 频谱分析 ---\n');

% 对含干扰的信号做频谱分析
X_clean = fft(clean);
X_jam   = fft(jammed);

f_axis = (0:length(X_clean)-1) * Fs / length(X_clean);
amp_clean = abs(X_clean) / length(X_clean) * 2;
amp_jam   = abs(X_jam)   / length(X_jam)   * 2;

figure('Name', '频谱分析', 'Position', [100, 100, 800, 400]);

subplot(1,2,1);
plot(f_axis(1:500), amp_clean(1:500), 'b-', 'LineWidth', 1.5);
title('干净信号频谱');
xlabel('频率 (Hz)'); ylabel('幅度');
xlim([0, 500]); grid on;

subplot(1,2,2);
plot(f_axis(1:500), amp_jam(1:500), 'r-', 'LineWidth', 1.5);
title('被干扰信号频谱 → 200Hz 处多了一个大尖峰');
xlabel('频率 (Hz)'); ylabel('幅度');
xlim([0, 500]); grid on;

fprintf('  看右边的图：10Hz 是北斗信号，200Hz 是干扰\n');
fprintf('  阶段 3 的 Notch 陷波器就是把这个 200Hz 的尖峰削掉\n\n');

%% 5. 相关 — 卫星捕获的本质
fprintf('--- 5. 相关 — 找信号 ---\n');

% 生成一个简单的扩频码（模拟 C/A 码）
code_len = 32;
code = 2 * (randi([0,1], 1, code_len) - 0.5);  % ±1 的序列

% 把码重复几次做成信号
signal = repmat(code, 1, 5);

% 自己做自相关
corr_result = xcorr(signal, code);

figure('Name', '相关', 'Position', [100, 100, 800, 400]);

subplot(1,2,1);
stem(code, 'b-', 'MarkerFaceColor', 'b');
title('扩频码 (±1 序列)');
xlabel('码片'); ylabel('幅度'); xlim([1, 32]);

subplot(1,2,2);
lags = -length(signal)+1 : length(signal)-1;
plot(lags, corr_result, 'b-', 'LineWidth', 1.5);
title('自相关 → 峰值在 0 偏移处');
xlabel('偏移 (码片)'); ylabel('相关值');
grid on;

fprintf('  接收机收到信号后，拿本地 C/A 码和信号做相关\n');
fprintf('  有峰值 → 捕获到卫星；无峰值 → 没有这颗卫星\n');
fprintf('  加上干扰后相关峰会变矮 → 抗干扰就是要恢复这个峰值\n\n');

%% 总结
fprintf('===== 复习完毕 =====\n');
fprintf('  今天学的 5 个概念，就是你阶段 3 抗干扰仿真的全部基础\n');
fprintf('  下一步可以用 Communications Toolbox 生成真正的北斗 B1I 信号了\n');
