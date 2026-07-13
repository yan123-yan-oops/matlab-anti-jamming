%%
% ============================================================
%  09 抗干扰算法综合 — 三种算法 vs 三种干扰
%
%  学习目标：
%    1. 自适应陷波器 → 窄带 CW 干扰
%    2. 频域抑制 → 宽带噪声干扰
%    3. 脉冲消隐 → 脉冲干扰
%    4. 综合性能对比
%
%  前置知识：06 GNSS 信号 / 07 干扰 / 08 滤波
%  运行方法：F5 直接运行
% ============================================================

clear; close all; clc;
rng(42);
fprintf('===== 09 抗干扰算法综合 =====\n\n');

%% 0. 生成模拟信号
fprintf('--- 生成北斗 B1I 模拟信号 ---\n');

% 简化参数
Fs = 20e6; T = 1e-3;
t = (0:round(Fs*T)-1) / Fs;
IF = 4.098e6;

% PRN 码（m序列）
n_stages = 11;
lfsr = ones(1, n_stages);
mseq = zeros(1, 2^n_stages-1);
for i = 1:length(mseq)
    mseq(i) = lfsr(end);
    lfsr = [xor(lfsr(end), lfsr(2)), lfsr(1:end-1)];
end
prn = 2 * (mseq(1:2046) > 0.5) - 1;

% 上采样
code_rate = 2.046e6;
spc = round(Fs / code_rate);
code = repelem(prn, spc);
code = code(1:length(t));
carrier = cos(2*pi*IF * t);
signal = code .* carrier;
sig_power = mean(signal.^2);
fprintf('  ✅ 信号生成完成，功率 = %.2e\n', sig_power);

%% 1. 场景 A：CW 干扰 + 自适应陷波器
fprintf('\n--- 场景 A：CW 干扰 → 自适应陷波器 ---\n');

JSR_CW = 30;
f_jam = IF + 0.3e6;
A_jam = sqrt(10^(JSR_CW/10) * sig_power * 2);
jam_cw = A_jam * sin(2*pi*f_jam*t);
rx_cw = signal + jam_cw;

% 自适应陷波器（LMS 2权重）
omega = 2*pi*f_jam;
ref_cos = cos(omega*t);
ref_sin = sin(omega*t);

w1 = 0; w2 = 0; mu = 0.01;
notch_out = zeros(1, length(t));
for n = 1:length(t)
    jam_est = w1*ref_cos(n) + w2*ref_sin(n);
    e = rx_cw(n) - jam_est;
    notch_out(n) = e;
    w1 = w1 + mu*e*ref_cos(n);
    w2 = w2 + mu*e*ref_sin(n);
end

%% 2. 场景 B：宽带干扰 + 频域抑制
fprintf('\n--- 场景 B：宽带干扰 → 频域抑制 ---\n');

JSR_WB = 25;
noise = randn(1, length(t));
[b, a] = butter(4, [2e6, 6e6] / (Fs/2), 'bandpass');
jam_wb_raw = filter(b, a, noise);
jam_wb_raw = jam_wb_raw / sqrt(mean(jam_wb_raw.^2));
jam_wb = sqrt(10^(JSR_WB/10) * sig_power) * jam_wb_raw;
rx_wb = signal + jam_wb;

% 频域抑制
N_fft = 2^nextpow2(length(rx_wb));
X = fftshift(fft(rx_wb, N_fft));
power_spec = abs(X).^2 / N_fft;
thresh = mean(power_spec) + 3*std(power_spec);
excise = power_spec > thresh;
X(excise) = 0;
fd_out = real(ifft(ifftshift(X), N_fft));
fd_out = fd_out(1:length(t));

fprintf('  切除频点数: %d / %d (%.1f%%)\n', sum(excise), N_fft, sum(excise)/N_fft*100);

%% 3. 场景 C：脉冲干扰 + 脉冲消隐
fprintf('\n--- 场景 C：脉冲干扰 → 脉冲消隐 ---\n');

JSR_Pulse = 35;
pulse_duty = 0.05;
pulse_period = 0.3e-3;
pulse_on = round(pulse_duty * pulse_period * Fs);
pulse_off = round((1-pulse_duty) * pulse_period * Fs);
pulse_one = [ones(1,pulse_on), zeros(1,pulse_off)];
pulse_train = repmat(pulse_one, 1, ceil(length(t)/length(pulse_one)));
pulse_train = pulse_train(1:length(t));
jam_pulse = sqrt(10^(JSR_Pulse/10) * sig_power) * pulse_train .* randn(1,length(t));
rx_pulse = signal + jam_pulse;

% 脉冲消隐
window_len = round(Fs * 2e-6);
energy = conv(rx_pulse.^2, ones(1,window_len)/window_len, 'same');
eng_med = median(energy);
eng_mad = median(abs(energy - eng_med));
thresh_blank = eng_med + 4 * eng_mad * 1.4826;
blank_mask = energy > thresh_blank;
smooth_k = ones(1,5)/5;
blank_mask = conv(double(blank_mask), smooth_k, 'same') > 0.5;
pb_out = rx_pulse;
pb_out(blank_mask) = 0;

fprintf('  消隐比例: %.1f%%\n', sum(blank_mask)/length(blank_mask)*100);

%% 4. 最终对比图
figure('Name', '抗干扰综合对比', 'Position', [100, 100, 1200, 800]);

% 三行：每行一种场景
algorithms = {{rx_cw, notch_out, '自适应陷波器'},
              {rx_wb, fd_out, '频域抑制'},
              {rx_pulse, pb_out, '脉冲消隐'}};

n_plot = 800;
t_plot = t(1:n_plot)*1e6;

for i = 1:3
    before = algorithms{i}{1};
    after = algorithms{i}{2};
    name = algorithms{i}{3};
    
    subplot(3,3,(i-1)*3+1);
    plot(t_plot, before(1:n_plot), 'r-', 'LineWidth', 0.6);
    ylabel('幅度'); title(sprintf('场景%c 干扰后', 'A'+i-1));
    grid on;
    
    subplot(3,3,(i-1)*3+2);
    plot(t_plot, after(1:n_plot), 'b-', 'LineWidth', 0.8);
    title(name); grid on;
    
    subplot(3,3,(i-1)*3+3);
    Nf = 2^nextpow2(length(before));
    f = (-Nf/2:Nf/2-1) * Fs / Nf;
    Xb = fftshift(fft(before, Nf));
    Xa = fftshift(fft(after, Nf));
    plot(f/1e6, abs(Xb)/Nf, 'r--', 'LineWidth', 0.8); hold on;
    plot(f/1e6, abs(Xa)/Nf, 'b-', 'LineWidth', 1);
    xlim([-2, 10]);
    title('频谱对比 红=前 蓝=后');
    xlabel('MHz'); grid on;
end

sgtitle('三种抗干扰算法效果对比', 'FontSize', 13, 'FontWeight', 'bold');

%% 5. 输出性能摘要
fprintf('\n════════════════════════════════════════\n');
fprintf('  抗干扰性能摘要\n');
fprintf('════════════════════════════════════════\n');

% 用信干比改善估算
improvements = {
    '自适应陷波器', sprintf('JSR=%ddB → CW 干扰抑制', JSR_CW);
    '频域抑制    ', sprintf('JSR=%ddB → 宽带噪声抑制', JSR_WB);
    '脉冲消隐    ', sprintf('JSR=%ddB → 脉冲干扰抑制', JSR_Pulse);
    };
for i = 1:3
    before = algorithms{i}{1};
    after = algorithms{i}{2};
    % 简单评估：信号功率 / 干扰功率的变化
    p_before = mean(before.^2);
    p_after = mean(after.^2);
    ratio = 10*log10(p_after / p_before);
    fprintf('  · %s: 功率改善 %.1f dB\n', improvements{i,1}, ratio);
end
fprintf('════════════════════════════════════════\n');
fprintf('\n✅ 09 学完！下一步：10 最终集成项目\n');
