%%
% ============================================================
%  07 干扰模型 — 三种压制式干扰
%
%  学习目标：
%    1. 窄带连续波干扰（CW）
%    2. 宽带噪声干扰
%    3. 脉冲干扰
%    4. 干信比 JSR 的概念
%
%  前置知识：03 信号生成 / 06 GNSS 信号
%  运行方法：F5 直接运行
% ============================================================

clear; close all; clc;
rng(42);
fprintf('===== 07 干扰模型 =====\n\n');

%% 0. 先产生一个干净信号做参照
Fs = 20e6; T = 2e-3;
t = (0:round(Fs*T)-1) / Fs;
f0 = 1e6;  % 1MHz 信号
clean = sin(2*pi*f0*t);

signal_power = mean(clean.^2);
fprintf('信号功率: %.2e\n', signal_power);

%% 1. 窄带连续波干扰（CW）
fprintf('\n--- 1. 窄带 CW 干扰 ---\n');

JSR_CW_dB = 30;  % 干信比 30dB
jam_freq = 1.3e6;  % 干扰频率（稍偏离信号）
jam_amp = sqrt(10^(JSR_CW_dB/10) * signal_power * 2);
jam_cw = jam_amp * sin(2*pi*jam_freq*t);
rx_cw = clean + jam_cw;

fprintf('  JSR = %d dB\n', JSR_CW_dB);
fprintf('  干扰幅度 = %.1f （信号幅度 = 1）\n', jam_amp);

%% 2. 宽带噪声干扰
fprintf('\n--- 2. 宽带噪声干扰 ---\n');

JSR_WB_dB = 25;
wb_bw = 4e6;

noise = randn(1, length(t));
[b, a] = butter(4, [1e6, 5e6] / (Fs/2), 'bandpass');
jam_wb_raw = filter(b, a, noise);
jam_wb_raw = jam_wb_raw / sqrt(mean(jam_wb_raw.^2));
jam_wb = sqrt(10^(JSR_WB_dB/10) * signal_power) * jam_wb_raw;
rx_wb = clean + jam_wb;

fprintf('  JSR = %d dB, 带宽 = %d MHz\n', JSR_WB_dB, wb_bw/1e6);

%% 3. 脉冲干扰
fprintf('\n--- 3. 脉冲干扰 ---\n');

JSR_Pulse_dB = 35;
pulse_duty = 0.05;
pulse_period = 0.5e-3;

pulse_on = round(pulse_duty * pulse_period * Fs);
pulse_off = round((1-pulse_duty) * pulse_period * Fs);
pulse_one = [ones(1, pulse_on), zeros(1, pulse_off)];
pulse_train = repmat(pulse_one, 1, ceil(length(t)/length(pulse_one)));
pulse_train = pulse_train(1:length(t));

jam_pulse = sqrt(10^(JSR_Pulse_dB/10) * signal_power) * pulse_train .* randn(1,length(t));
rx_pulse = clean + jam_pulse;

fprintf('  JSR = %d dB, 占空比 = %.0f%%\n', JSR_Pulse_dB, pulse_duty*100);

%% 4. 三张图对比
figure('Name', '三种干扰', 'Position', [100, 100, 1200, 700]);

% 时域对比
N_plot = 500;
t_plot = t(1:N_plot)*1e6;

plot_idx = 1;
for jam = {'jam_cw', 'jam_wb', 'jam_pulse'}
    eval(sprintf('sig = %s;', jam{1}));
    
    subplot(3, 2, plot_idx);
    plot(t_plot, sig(1:N_plot), 'r-', 'LineWidth', 0.8);
    title(sprintf('(%s) 时域', jam{1}));
    ylabel('幅度'); grid on;
    
    subplot(3, 2, plot_idx+1);
    N_fft = 2^nextpow2(length(sig));
    f = (-N_fft/2:N_fft/2-1) * Fs / N_fft;
    X = fftshift(fft(sig, N_fft));
    plot(f/1e6, abs(X)/N_fft, 'r-', 'LineWidth', 1);
    xlim([-5, 5]);
    title(sprintf('(%s) 频谱', jam{1}));
    xlabel('频率 (MHz)'); ylabel('幅度'); grid on;
    
    plot_idx = plot_idx + 2;
end

sgtitle('三种压制式干扰', 'FontSize', 13, 'FontWeight', 'bold');

%% 5. 干扰对相关峰的影响（预告03章陷波器）
fprintf('\n--- 干扰影响总结 ---\n');
fprintf('  CW 干扰     → 能量集中在单频 → 陷波器可抑制\n');
fprintf('  宽带干扰   → 能量分布在整个频带 → 频域抑制\n');
fprintf('  脉冲干扰   → 短时高能量 → 脉冲消隐\n\n');

fprintf('✅ 07 学完！下一步：08 滤波基础\n');
