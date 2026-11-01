%%
% ============================================================
%  10 最终集成项目 — 北斗抗干扰全链路仿真
%
%  这是整个学习工程的最终交付物。
%  把前面 01~09 的知识串成一个完整故事：
%
%  北斗 B1I 信号生成 → 加干扰 → 抗干扰处理 → 捕获验证 → 性能报告
%
%  运行方法：F5 直接运行
%  依赖阶段：建议学完 01~09 后再来跑这个
%
%  ⚠️  状态：已实现（2026-10-21），但只在无 MATLAB 的机器上编写，
%      尚未实际运行。首次 F5 若报错，把行号发我。
% ============================================================

clear; close all; clc;
rng(42);

fprintf('╔══════════════════════════════════════════════╗\n');
fprintf('║   北斗 B1I 抗干扰 全链路仿真                 ║\n');
fprintf('║   Beidou B1I Anti-Jamming Full Chain        ║\n');
fprintf('║   最终集成项目 · 阶段 3/4 交付物             ║\n');
fprintf('╚══════════════════════════════════════════════╝\n\n');

%% 参数
Fs        = 20.46e6;      % 采样率：每码片 10 个点
code_rate = 2.046e6;      % B1I 码率
IF        = 4.098e6;      % 中频
T         = 1e-3;         % 1 ms 数据
N         = round(Fs * T);
t         = (0:N-1) / Fs;
spc       = round(Fs / code_rate);
JSR_dB    = 30;           % 干信比

fprintf('[1/6] 信号参数：Fs=%.2f MHz, 每码片 %d 点, 共 %d 点\n', Fs/1e6, spc, N);

%% 第 1 步：北斗 B1I 信号生成（11 级 m 序列，取 2046 码片）
lfsr = ones(1, 11);                 % 全 1 初始化（避开全零死锁）
mseq = zeros(1, 2^11 - 1);          % 2047
for k = 1:length(mseq)
    mseq(k) = lfsr(end);
    fb = xor(lfsr(end), lfsr(3));   % 反馈抽头
    lfsr = [fb, lfsr(1:end-1)];
end
prn = 2 * double(mseq(1:2046) > 0.5) - 1;   % ±1
code = repelem(prn, spc);                    % 20460
code = code(1:N);

sig = code .* cos(2*pi*IF*t);
Ps  = mean(sig.^2);
fprintf('▶ [2/6] 信号生成：%d 码片 × %d 采样，功率 = %.3f\n', numel(prn), spc, Ps);

%% 第 2 步：CW 干扰（JSR = 30 dB）
A_jam = sqrt(10^(JSR_dB/10) * Ps * 2);       % 正弦功率 = A^2/2
f_jam = IF + 0.3e6;
rx    = sig + A_jam * sin(2*pi*f_jam*t);
fprintf('▶ [3/6] 加入 CW 干扰：偏移 %.1f MHz，JSR = %d dB\n', (f_jam-IF)/1e6, JSR_dB);

%% 第 3 步：抗干扰 — LMS 自适应陷波（两权，参考 cos/sin）
w1 = 0; w2 = 0; mu = 0.01;
aj = zeros(1, N);
for n = 1:N
    jam_est = w1 * cos(2*pi*f_jam*t(n)) + w2 * sin(2*pi*f_jam*t(n));
    e = rx(n) - jam_est;
    aj(n) = e;
    w1 = w1 + mu * e * cos(2*pi*f_jam*t(n));
    w2 = w2 + mu * e * sin(2*pi*f_jam*t(n));
end
fprintf('▶ [4/6] LMS 陷波完成：|w| = %.3f\n', sqrt(w1^2 + w2^2));

%% 第 4 步：捕获（并行码相位搜索）
% 先把中频搬到基带，再与本地码做频域相关
base_rx = rx .* exp(-1j * 2*pi * IF * t);
base_aj = aj .* exp(-1j * 2*pi * IF * t);

Nfft = 2^nextpow2(2*N);
CODE = fft(code, Nfft);

R_rx = ifft(fft(base_rx, Nfft) .* conj(CODE));
R_aj = ifft(fft(base_aj, Nfft) .* conj(CODE));

peak_rx = max(abs(R_rx));
noise_rx = median(abs(R_rx));
peak_aj = max(abs(R_aj));
noise_aj = median(abs(R_aj));

m_before = 20*log10(peak_rx / noise_rx);
m_after  = 20*log10(peak_aj / noise_aj);
gain_dB  = m_after - m_before;

[~, idx_before] = max(abs(R_rx));
[~, idx_after]  = max(abs(R_aj));

fprintf('▶ [5/6] 捕获：峰/噪底 前 %.1f dB → 后 %.1f dB（改善 %.1f dB）\n', ...
    m_before, m_after, gain_dB);

%% 第 5 步：图
figure('Name', 'B1I 抗干扰全链路', 'Position', [100, 100, 1200, 800]);

n_plot = min(800, N);
subplot(3,2,1);
plot(t(1:n_plot)*1e6, rx(1:n_plot), 'r-', 'LineWidth', 0.6); hold on;
plot(t(1:n_plot)*1e6, aj(1:n_plot), 'b-', 'LineWidth', 0.6);
xlabel('时间 (\mus)'); ylabel('幅度');
title('时域：抗干扰前（红）vs 后（蓝）'); legend('前', '后'); grid on;

subplot(3,2,2);
[Pxx, F] = periodogram_local(rx, Fs, Nfft);
[Pyy, ~] = periodogram_local(aj, Fs, Nfft);
plot(F/1e6, 10*log10(Pxx), 'r-', 'LineWidth', 0.6); hold on;
plot(F/1e6, 10*log10(Pyy), 'b-', 'LineWidth', 0.8);
xlim([IF/1e6 - 2, IF/1e6 + 2]);
xlabel('频率 (MHz)'); ylabel('功率 (dB)');
title('频谱：干扰被陷波'); legend('前', '后'); grid on;

subplot(3,2,3);
plot(abs(R_rx), 'r-', 'LineWidth', 0.5);
xlabel('码相位'); ylabel('|相关|');
title(sprintf('抗干扰前相关峰（峰/底 = %.1f dB）', m_before)); grid on;

subplot(3,2,4);
plot(abs(R_aj), 'b-', 'LineWidth', 0.5);
xlabel('码相位'); ylabel('|相关|');
title(sprintf('抗干扰后相关峰（峰/底 = %.1f dB）', m_after)); grid on;

subplot(3,2,5);
bar([m_before, m_after]);
set(gca, 'XTickLabel', {'抗干扰前', '抗干扰后'});
ylabel('峰/噪底 (dB)');
title(sprintf('捕获度量改善 %.1f dB', gain_dB)); grid on;

subplot(3,2,6);
axis off;
info = {
    sprintf('参数：Fs=%.2f MHz', Fs/1e6);
    sprintf('      IF=%.3f MHz', IF/1e6);
    sprintf('      JSR=%d dB', JSR_dB);
    '';
    sprintf('捕获度量前：%.1f dB', m_before);
    sprintf('捕获度量后：%.1f dB', m_after);
    sprintf('改  善  量：%.1f dB', gain_dB);
    sprintf('峰位置前：%d', idx_before);
    sprintf('峰位置后：%d', idx_after);
};
text(0.05, 0.95, info, 'FontSize', 11, 'VerticalAlignment', 'top');
title('结果摘要');

sgtitle('北斗 B1I 抗干扰全链路：信号 → 干扰 → 陷波 → 捕获', 'FontSize', 13, 'FontWeight', 'bold');

%% 第 6 步：报告文件
fid = fopen('performance_report.txt', 'w');
if fid == -1
    warning('无法写入 performance_report.txt（目录只读？）');
else
    fprintf(fid, '北斗 B1I 抗干扰全链路 — 性能报告\n');
    fprintf(fid, '生成时间: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, '参数\n');
    fprintf(fid, '  Fs        = %.2f MHz\n', Fs/1e6);
    fprintf(fid, '  IF        = %.3f MHz\n', IF/1e6);
    fprintf(fid, '  JSR       = %d dB\n', JSR_dB);
    fprintf(fid, '  数据长度  = %d 点（%.1f ms）\n\n', N, N/Fs*1e3);
    fprintf(fid, '结果\n');
    fprintf(fid, '  捕获度量（前） = %.2f dB\n', m_before);
    fprintf(fid, '  捕获度量（后） = %.2f dB\n', m_after);
    fprintf(fid, '  改善量         = %.2f dB\n', gain_dB);
    fprintf(fid, '  峰位置（前/后） = %d / %d\n', idx_before, idx_after);
    fclose(fid);
    fprintf('\n📄 报告已写入 performance_report.txt\n');
end

fprintf('\n✅ 全链路仿真完成：捕获度量 %.1f dB → %.1f dB（%+.1f dB）\n', ...
    m_before, m_after, gain_dB);
if gain_dB <= 0
    fprintf('⚠️  改善量不为正：检查 mu、干扰频率偏移、相关前的载波剥离\n');
end

%% 本地函数
function [P, F] = periodogram_local(x, Fs, Nfft)
% 简易单边功率谱（避免依赖 Signal Processing Toolbox）
    X = fft(x, Nfft);
    P2 = abs(X).^2 / Nfft;
    P1 = P2(1:Nfft/2+1);
    P1(2:end-1) = 2 * P1(2:end-1);
    P = P1;
    F = (0:Nfft/2) * Fs / Nfft;
end
