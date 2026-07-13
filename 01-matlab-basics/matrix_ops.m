%% ============================================================
%  01 矩阵运算与画图 — MATLAB 基础（对标 C 01-basics）
%
%  学习目标：
%    1. MATLAB 矩阵操作（对标 C 的数据类型）
%    2. 画图基础（对标 C 的 printf 输出）
%    3. 向量化运算 vs for 循环（性能对比）
%
%  运行方法：F5 直接运行
% ============================================================

clear; close all; clc;
fprintf('===== 01 MATLAB 基础：矩阵与画图 =====\n\n');

%% 1. 矩阵就是 MATLAB 的基本数据类型
%  对应 C 里的 int/float/uint8_t —— 只是 MATLAB 默认全是矩阵
fprintf('--- 1. 矩阵创建 ---\n');

% 标量
a = 5;
fprintf('  标量 a = %d\n', a);

% 向量
v = [1 2 3 4 5];
fprintf('  行向量 v = [1 2 3 4 5]\n');

% 矩阵
M = [1 2 3; 4 5 6; 7 8 9];
fprintf('  3×3 矩阵 M:\n');
disp(M);

% 嵌入式常用：按指定数据类型创建
u8_val = uint8(255);     % 和 C 的 uint8_t 一样：0~255
u16_val = uint16(65535);
fprintf('  uint8  = %d (范围 0~255)\n', u8_val);
fprintf('  uint16 = %d (范围 0~65535)\n\n', u16_val);

%% 2. 索引与切片（对标 C 的指针偏移）
fprintf('--- 2. 矩阵索引（对标指针运算）---\n');

v = 10:10:50;  % [10 20 30 40 50]
fprintf('  向量 v = [10 20 30 40 50]\n');
fprintf('  v(1)   = %d  (← 注意：MATLAB 从 1 开始，不是 0)\n', v(1));
fprintf('  v(end) = %d  (最后一个元素)\n', v(end));
fprintf('  v(2:4) = [%d %d %d]  (切片)\n\n', v(2), v(3), v(4));

%% 3. 向量化运算（嵌入式优化思维）
%  在 C 里你要 for 循环才能算每个元素
%  在 MATLAB 里直接写数学公式
fprintf('--- 3. 向量化运算（对比 for 循环）---\n');

t = 0:0.01:1;        % 时间轴 101 个点（对标 C 的数组）
y_for = zeros(size(t));
y_vec = zeros(size(t));

% C 风格：for 循环
tic;
for i = 1:length(t)
    y_for(i) = sin(2*pi*5*t(i));
end
t_for = toc;

% MATLAB 风格：向量化
tic;
y_vec = sin(2*pi*5*t);
t_vec = toc;

fprintf('  for 循环耗时:   %.6f 秒\n', t_for);
fprintf('  向量化运算耗时: %.6f 秒 (%.0f倍快)\n', t_vec, t_for/t_vec);
fprintf('  👆 这就是为什么 MATLAB 里别写 for 循环\n\n');

%% 4. 画图基础（对标 C 的 printf 输出）
%  C 用 printf 看数据，MATLAB 用 plot 看图
fprintf('--- 4. 画图基础 ---\n');

figure('Name', 'MATLAB 画图基础', 'Position', [100, 100, 1000, 700]);

subplot(2,2,1);
plot(t, y_vec, 'b-', 'LineWidth', 1.5);
xlabel('时间 (s)'); ylabel('幅度'); title('① 正弦波 5Hz');
grid on;

subplot(2,2,2);
f = 0:0.5:50;
X = abs(fft(y_vec)) / length(y_vec) * 2;
plot(f, X(1:length(f)), 'r-', 'LineWidth', 1.5);
xlabel('频率 (Hz)'); ylabel('幅度'); title('② 频谱');
grid on;

subplot(2,2,3);
stairs(t(1:20), y_vec(1:20), 'k-', 'LineWidth', 1);
xlabel('时间 (s)'); ylabel('幅度'); title('③ 阶梯图（像 DAC 输出）');
grid on;

subplot(2,2,4);
stem(t(1:20), y_vec(1:20), 'b-', 'MarkerFaceColor', 'b');
xlabel('时间 (s)'); ylabel('幅度'); title('④ 茎状图（像 ADC 采样）');
grid on;

sgtitle('MATLAB 画图基础', 'FontSize', 13, 'FontWeight', 'bold');

fprintf('  ✅ 图已生成，看 Figure 1\n\n');

%% 5. 数据分析基础
fprintf('--- 5. 数据分析函数 ---\n');

data = randn(1, 1000);  % 1000 个高斯随机数
fprintf('  均值: %.3f  (期望 ≈ 0)\n', mean(data));
fprintf('  方差: %.3f  (期望 ≈ 1)\n', var(data));
fprintf('  标准差: %.3f\n', std(data));
fprintf('  最大值: %.3f\n', max(data));
fprintf('  最小值: %.3f\n\n', min(data));

fprintf('✅ 01 学完！下一步：02 FFT 频谱分析\n');
