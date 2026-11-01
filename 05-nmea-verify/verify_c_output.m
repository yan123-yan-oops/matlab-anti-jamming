%% ============================================================
%  verify_c_output.m — 真正的 C ↔ MATLAB 双端交叉验证
%
%  与 verify_with_matlab.m 的区别：
%    那个脚本是自己重新解析一遍 .nmea，画图好看，但没有"对比"。
%    这个脚本读 C 解析器导出的 CSV（dump_csv.exe 生成），
%    再在 MATLAB 里独立解析一次，逐点比对，输出差异表。
%
%  工作流：
%    1) C 侧：
%       gcc -g -Wall -Wextra -std=c11 dump_csv.c nmea_parser.c -o dump_csv.exe
%       dump_csv.exe sample_track.nmea > c_output.csv
%    2) MATLAB 侧：F5 运行本脚本
%
%  验收标准：所有点 |Δlat|、|Δlon| < 1e-6 度，整型字段完全相等。
%
%  ⚠️ 本脚本在未装 MATLAB 的机器上编写，尚未实际运行过。
%     首次 F5 若报错，把报错行号发我，我按你的版本改。
% ============================================================

clear; close all; clc;
fprintf('===== C ↔ MATLAB 双端交叉验证 =====\n\n');

%% 0. 定位文件（支持从任意目录运行）
c_csv   = 'c_output.csv';
nmea_f  = 'sample_track.nmea';

if ~exist(c_csv, 'file')
    c_csv = '../08-nmea-parser/c_output.csv';
end
if ~exist(c_csv, 'file')
    c_csv = '../../embed-c-learning/08-nmea-parser/c_output.csv';
end
if ~exist(nmea_f, 'file')
    nmea_f = '../08-nmea-parser/sample_track.nmea';
end
if ~exist(nmea_f, 'file')
    nmea_f = '../../embed-c-learning/08-nmea-parser/sample_track.nmea';
end

if ~exist(c_csv, 'file')
    error(['找不到 %s。请先在 08-nmea-parser 目录执行：\n' ...
           '  dump_csv.exe sample_track.nmea > c_output.csv'], c_csv);
end
fprintf('C 侧数据 : %s\n', c_csv);
fprintf('原始语句 : %s\n\n', nmea_f);

%% 1. 读 C 侧结果
T = readtable(c_csv, 'Delimiter', ',');
c_type = T.type;
c_lat  = T.lat;
c_lon  = T.lon;
c_fix  = T.fix_quality;
c_sat  = T.satellites;
c_alt  = T.altitude;

fprintf('C 侧：%d 条记录（GGA %d 条 / RMC %d 条）\n', ...
    height(T), sum(strcmp(c_type, 'GGA')), sum(strcmp(c_type, 'RMC')));

%% 2. MATLAB 侧独立解析（同一套公式，独立实现）
lines = read_nmea_lines(nmea_f);
m_lat = []; m_lon = []; m_fix = []; m_sat = []; m_alt = [];

for i = 1:numel(lines)
    line = strtrim(lines{i});
    if isempty(line) || line(1) ~= '$' || numel(line) < 10
        continue;
    end
    head  = extractBetween(line, 2, 6);
    isGGA = strcmp(head, 'GPGGA') || strcmp(head, 'GNGGA');
    isRMC = strcmp(head, 'GPRMC') || strcmp(head, 'GNRMC');
    if ~(isGGA || isRMC)
        continue;
    end

    f = strsplit(line, ',');
    if isGGA
        if numel(f) < 10, continue; end
        m_lat(end+1,1) = ddmm2deg(f{3}, f{4}, 2, 'S'); %#ok<SAGROW>
        m_lon(end+1,1) = ddmm2deg(f{5}, f{6}, 3, 'W'); %#ok<SAGROW>
        m_fix(end+1,1) = str2double(f{7}); %#ok<SAGROW>
        m_sat(end+1,1) = str2double(f{8}); %#ok<SAGROW>
        m_alt(end+1,1) = str2double(f{10});%#ok<SAGROW>
    else
        if numel(f) < 10, continue; end
        m_lat(end+1,1) = ddmm2deg(f{4}, f{5}, 2, 'S'); %#ok<SAGROW>
        m_lon(end+1,1) = ddmm2deg(f{6}, f{7}, 3, 'W'); %#ok<SAGROW>
        m_fix(end+1,1) = 0;  %#ok<SAGROW>
        m_sat(end+1,1) = 0;  %#ok<SAGROW>
        m_alt(end+1,1) = 0;  %#ok<SAGROW>
    end
end

fprintf('MATLAB 侧：%d 条记录\n\n', numel(m_lat));

%% 3. 逐点比对
n = min(height(T), numel(m_lat));
if n == 0
    error('任一侧没有解析出数据，检查文件');
end

d_lat = abs(c_lat(1:n) - m_lat(1:n));
d_lon = abs(c_lon(1:n) - m_lon(1:n));
d_alt = abs(c_alt(1:n) - m_alt(1:n));
tol   = 1e-6;

bad_lat = find(d_lat > tol);
bad_lon = find(d_lon > tol);
bad_alt = find(d_alt > 0.01 & ~isnan(d_alt));
bad_fix = find(abs(c_fix(1:n) - m_fix(1:n)) > 0);
bad_sat = find(abs(c_sat(1:n) - m_sat(1:n)) > 0);

fprintf('── 比对结果（前 %d 条）──\n', n);
fprintf('  纬度最大偏差 : %.3e 度（阈值 %.0e）\n', max(d_lat), tol);
fprintf('  经度最大偏差 : %.3e 度（阈值 %.0e）\n', max(d_lon), tol);
fprintf('  海拔最大偏差 : %.3f 米（阈值 0.01）\n', max([d_alt(~isnan(d_alt)); 0]));
fprintf('  定位质量差异 : %d 处\n', numel(bad_fix));
fprintf('  卫星数差异   : %d 处\n', numel(bad_sat));

if isempty(bad_lat) && isempty(bad_lon) && isempty(bad_alt) ...
        && isempty(bad_fix) && isempty(bad_sat)
    fprintf('\n  ✅ 双端一致：C 解析器与 MATLAB 实现结果相同\n');
    status = "PASS";
else
    fprintf('\n  ❌ 存在不一致，明细如下：\n');
    for k = unique([bad_lat; bad_lon])'
        fprintf('    第 %2d 条: Δlat=%.3e  Δlon=%.3e\n', k, d_lat(k), d_lon(k));
    end
    status = "FAIL";
end

%% 4. 可视化：两条轨迹应当完全重合
figure('Name', 'C ↔ MATLAB 交叉验证', 'Position', [100, 100, 1100, 500]);

subplot(1,2,1);
plot(c_lon(1:n), c_lat(1:n), 'b.-', 'LineWidth', 1.5, 'MarkerSize', 14); hold on;
plot(m_lon(1:n), m_lat(1:n), 'ro', 'MarkerSize', 6, 'LineWidth', 1);
xlabel('经度 (度)'); ylabel('纬度 (度)');
title(sprintf('轨迹重合检查（%s）', status));
legend('C 解析器', 'MATLAB 解析', 'Location', 'best');
grid on; axis equal;

subplot(1,2,2);
semilogy(1:n, max(d_lat, 1e-12), 'b.-', 1:n, max(d_lon, 1e-12), 'r.-');
hold on;
plot([1 n], [1e-6 1e-6], 'k--');
xlabel('语句序号'); ylabel('绝对偏差 (度)');
title('逐点偏差（虚线 = 1e-6 阈值）');
legend('纬度', '经度', 'Location', 'best');
grid on;

sgtitle('C 解析器 ↔ MATLAB 独立实现：逐点比对', 'FontSize', 13, 'FontWeight', 'bold');

fprintf('\n  工作流: dump_csv.exe → c_output.csv → 本脚本独立解析 → 逐点比对\n');

%% 5. 本地函数（MATLAB 脚本末尾允许定义局部函数）

function lines = read_nmea_lines(path)
% 按行读取文本，兼容旧版 MATLAB（readlines 需要 R2020b+）
    fid = fopen(path, 'r');
    if fid == -1
        error('找不到文件 %s', path);
    end
    C = textscan(fid, '%s', 'Delimiter', '\n', 'WhiteSpace', '');
    fclose(fid);
    lines = C{1};
end

function deg = ddmm2deg(raw, hemi, degDigits, negativeMark)
% DDMM.MMMM → 十进制度；负数由半球字母决定
    if strlength(raw) < degDigits + 3
        deg = NaN;
        return;
    end
    d = str2double(extractBefore(raw, degDigits + 1));
    m = str2double(extractAfter(raw, degDigits));
    deg = d + m / 60;
    if hemi == negativeMark
        deg = -deg;
    end
end
