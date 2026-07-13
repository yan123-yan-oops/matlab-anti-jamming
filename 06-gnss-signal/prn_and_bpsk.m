%%
% ============================================================
%  06 GNSS 信号生成 — PRN 码 + BPSK 调制
%
%  学习目标：
%    1. 理解扩频通信：为什么信号可以淹没在噪声里
%    2. PRN 码生成（m序列 / Gold码）
%    3. BPSK 调制
%    4. 扩频增益 = 处理增益
%
%  前置知识：02 FFT / 03 信号生成
%  运行方法：F5 直接运行
% ============================================================

clear; close all; clc;
rng(42);
fprintf('===== 06 GNSS 信号生成 =====\n\n');

%% 1. PRN 码生成（m序列）
%  北斗 B1I 用 2046 位 Gold 码，这里用 m 序列近似
fprintf('--- 1. PRN 码（伪随机噪声码）---\n');

% m序列生成：多项式 x^11 + x^2 + 1
n_stages = 11;
lfsr = ones(1, n_stages);
mseq_len = 2^n_stages - 1;  % 2047
mseq = zeros(1, mseq_len);

for i = 1:mseq_len
    mseq(i) = lfsr(end);
    fb = xor(lfsr(end), lfsr(2));
    lfsr = [fb, lfsr(1:end-1)];
end

% 截取 2046 位（B1I 标准长度），转为 ±1
prn = 2 * (mseq(1:2046) > 0.5) - 1;

fprintf('  m序列长度: %d chips\n', mseq_len);
fprintf('  截取: 2046 chips（北斗 B1I 标准）\n');

% 画 PRN 码
figure('Name', 'PRN 码', 'Position', [100, 100, 1000, 500]);

subplot(2,2,1);
stem(prn(1:50), 'b-', 'MarkerFaceColor', 'b', 'MarkerSize', 3);
title('PRN 码前 50 chips');
xlabel('chip'); ylabel('幅度'); ylim([-1.5, 1.5]); grid on;

subplot(2,2,2);
[ac, lags] = xcorr(prn, prn, 'normalized');
plot(lags, ac, 'b-', 'LineWidth', 1.5);
title('自相关 → 尖锐峰值（捕获的关键）');
xlabel('偏移 (chips)'); ylabel('相关值');
xlim([-100, 100]); grid on;

subplot(2,2,3);
histogram(prn, 3);
title('±1 分布（等概率）');
xlabel('值'); ylabel('频次'); grid on;

subplot(2,2,4);
X_prn = fft(prn);
f = (0:length(X_prn)-1) / length(X_prn);
plot(f, abs(X_prn), 'r-', 'LineWidth', 1);
title('PRN 码频谱（类似噪声）');
xlabel('归一化频率'); ylabel('幅度'); grid on;

sgtitle('PRN 码特性', 'FontSize', 13, 'FontWeight', 'bold');

fprintf('  ✅ PRN 码特性：\n');
fprintf('     · 看起来像噪声（频谱平坦）\n');
fprintf('     · 自相关有尖锐峰值（捕获信号的关键）\n');
fprintf('     · 不同卫星用不同 Gold 码区分（CDMA）\n\n');

%% 2. BPSK 调制
fprintf('--- 2. BPSK 调制 ---\n');

code_rate = 2.046e6;  % 码速率
IF = 4.098e6;         % 中频（真实北斗下变频后）
Fs = 20.46e6;         % 采样率（10倍码速率）
T = 1e-3;             % 1 个码周期

t = (0:round(Fs*T)-1) / Fs;

% 上采样 PRN 码
samples_per_chip = round(Fs / code_rate);
code_upsampled = repelem(prn, samples_per_chip);
code_upsampled = code_upsampled(1:length(t));

% 载波
carrier = cos(2*pi*IF * t);

% BPSK 调制
bpsk = code_upsampled .* carrier;

figure('Name', 'BPSK 调制', 'Position', [100, 100, 1000, 600]);

subplot(3,1,1);
plot(t(1:500)*1e6, code_upsampled(1:500), 'b-', 'LineWidth', 1.5);
title('① PRN 码（方波）');
ylabel('幅度'); ylim([-1.5, 1.5]); grid on;

subplot(3,1,2);
plot(t(1:500)*1e6, carrier(1:500), 'r-', 'LineWidth', 1);
title('② 载波（4.098 MHz）');
ylabel('幅度'); grid on;

subplot(3,1,3);
plot(t(1:500)*1e6, bpsk(1:500), 'k-', 'LineWidth', 1);
title('③ BPSK = PRN码 × 载波（相位跳变 = 码片翻转）');
xlabel('时间 (μs)'); ylabel('幅度'); grid on;

sgtitle('BPSK 调制过程', 'FontSize', 13, 'FontWeight', 'bold');

%% 3. 扩频增益的直观感受
fprintf('--- 3. 扩频增益 ---\n');

% 生成噪声（比信号大很多）
noise_power = 10;  % 噪声功率是信号的 10 倍
noise = sqrt(noise_power) * randn(1, length(bpsk));

% 加噪声
rx = bpsk + noise;

% 解扩：乘以本地 PRN 码（同步的情况下）
local_code = code_upsampled;  % 假设已同步
despread = rx .* local_code;  % 解扩

% 解扩前后的 SNR
SNR_before = 10*log10(mean(bpsk.^2) / mean(noise.^2));
SNR_after = 10*log10(mean(despread.^2) / mean(noise.^2));
processing_gain = SNR_after - SNR_before;

fprintf('  解扩前 SNR: %.1f dB（信号被噪声淹没）\n', SNR_before);
fprintf('  解扩后 SNR: %.1f dB（信号恢复了）\n', SNR_after);
fprintf('  扩频增益:   %.1f dB\n', processing_gain);
fprintf('  理论增益:   10*log10(2046) = %.1f dB\n', 10*log10(2046));

figure('Name', '扩频增益', 'Position', [100, 100, 1000, 400]);

subplot(1,2,1);
plot(t(1:500)*1e6, rx(1:500), 'r-', 'LineWidth', 0.8);
title(sprintf('解扩前：SNR = %.1f dB（信号被噪声淹没）', SNR_before));
xlabel('时间 (μs)'); ylabel('幅度'); grid on;
ylim([-max(abs(rx)), max(abs(rx))]);

subplot(1,2,2);
plot(t(1:500)*1e6, despread(1:500), 'b-', 'LineWidth', 0.8);
title(sprintf('解扩后：SNR = %.1f dB（信号恢复！）', SNR_after));
xlabel('时间 (μs)'); ylabel('幅度'); grid on;
ylim([-max(abs(rx)), max(abs(rx))]);

sgtitle('扩频增益：信号从噪声中恢复', 'FontSize', 13, 'FontWeight', 'bold');

fprintf('  ✅ 这就是北斗信号能在 -130dBm 极弱功率下被捕获的原因\n\n');
fprintf('✅ 06 学完！下一步：07 干扰模型\n');
