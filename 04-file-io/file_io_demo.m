%%
% ============================================================
%  04 文件 I/O — MATLAB 与外部数据交互
%
%  学习目标：
%    1. 读取 .bin 二进制文件（模拟 ADC 采样数据）
%    2. 读取 .txt/.nmea 文本文件
%    3. 输出分析结果到文件
%
%  对应 C 06-strings 和 07-ringbuffer：
%    C 采集/解析数据 → 写入文件 → MATLAB 读取验证
%    这就是"嵌入式→PC"的完整数据流
%
%  运行方法：F5 直接运行
% ============================================================

clear; close all; clc;
fprintf('===== 04 文件 I/O =====\n\n');

%% 1. MATLAB 生成二进制 → C 也能读
fprintf('--- 1. 写入二进制文件（模拟 ADC 输出）---\n');

% 模拟 ADC 采集：生成一段 10Hz 正弦波，12位量化
Fs = 1000; T = 0.1;
t = 0:1/Fs:T-1/Fs;
adc_data = int16(2048 + 1500 * sin(2*pi*10*t));  % 12位 ADC，中心在 2048

% 写入二进制（和 C 的 fwrite 格式一致）
fid = fopen('adc_sample.bin', 'wb');
fwrite(fid, adc_data, 'int16');
fclose(fid);

% 读回来验证
fid = fopen('adc_sample.bin', 'rb');
data_read = fread(fid, inf, 'int16');
fclose(fid);

fprintf('  生成了 %d 个 int16 采样点\n', length(adc_data));
fprintf('  ADC 值范围: %d ~ %d\n', min(adc_data), max(adc_data));
fprintf('  写入 → 读回 → 一致: %s\n\n', ...
        isequal(adc_data, data_read') + "");

%% 2. 读取 NMEA 文件（对接 C 08-nmea-parser）
fprintf('--- 2. 读取 NMEA 文件 ---\n');

% 尝试多个可能的位置
nmea_paths = {
    'sample_track.nmea';
    '../embed-c-learning/08-nmea-parser/sample_track.nmea';
    '../05-nmea-verify/sample_track.nmea';
    };
nmea_file = '';
for i = 1:length(nmea_paths)
    if exist(nmea_paths{i}, 'file')
        nmea_file = nmea_paths{i};
        break;
    end
end

if isempty(nmea_file)
    fprintf('  ⚠️ 找不到 NMEA 文件, 跳过\n');
    fprintf('  复制 sample_track.nmea 到当前目录即可\n\n');
else
    fid = fopen(nmea_file, 'r');
    lines = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);
    lines = lines{1};
    
    gpgga_count = 0;
    gprmc_count = 0;
    for i = 1:length(lines)
        if startsWith(lines{i}, '$GPGGA'), gpgga_count = gpgga_count + 1; end
        if startsWith(lines{i}, '$GPRMC'), gprmc_count = gprmc_count + 1; end
    end
    
    fprintf('  文件: %s\n', nmea_file);
    fprintf('  总行数: %d\n', length(lines));
    fprintf('  $GPGGA: %d 条\n', gpgga_count);
    fprintf('  $GPRMC: %d 条\n\n', gprmc_count);
end

%% 3. 输出分析报告
fprintf('--- 3. 输出分析报告 ---\n');

report = [
    "==========================================";
    "MATLAB 数据分析报告";
    "==========================================";
    sprintf("生成时间: %s", datestr(now));
    sprintf("ADC 采样文件: adc_sample.bin");
    sprintf("采样点数: %d", length(adc_data));
    sprintf("ADC 均值: %.1f", mean(double(adc_data)));
    sprintf("ADC 标准差: %.1f", std(double(adc_data)));
    "";
    "--- 统计 ---";
    sprintf("最大值: %d", max(adc_data));
    sprintf("最小值: %d", min(adc_data));
    sprintf("峰峰值: %d", max(adc_data) - min(adc_data));
    "==========================================";
    ];

fid = fopen('analysis_report.txt', 'w');
for i = 1:length(report)
    fprintf(fid, '%s\n', report{i});
end
fclose(fid);

fprintf('  已生成: analysis_report.txt\n');
fprintf('  可以用 C 的 fread 读取同一份 .bin 文件\n');
fprintf('  C 和 MATLAB 处理同一份数据 → 交叉验证\n\n');

%% 4. 画图
figure('Name', '文件 I/O 演示', 'Position', [100, 100, 1000, 400]);

subplot(1,2,1);
plot(t, adc_data, 'b-', 'LineWidth', 1);
title(sprintf('ADC 采样数据 (%d 点)', length(adc_data)));
xlabel('时间 (s)'); ylabel('ADC 值 (12位)');
grid on;

subplot(1,2,2);
plot(adc_data(1:50), 'ro-', 'MarkerSize', 4);
title('前 50 个采样点');
xlabel('采样序号'); ylabel('ADC 值');
grid on;

sgtitle('文件 I/O：C 采集 → MATLAB 读取 → 分析验证', ...
        'FontSize', 13, 'FontWeight', 'bold');

fprintf('✅ 04 学完！下一步：05 NMEA 验证\n');

% 清理临时文件
delete('adc_sample.bin');
delete('analysis_report.txt');
