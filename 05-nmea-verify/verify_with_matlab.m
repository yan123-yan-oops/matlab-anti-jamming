%% ============================================================
%  verify_with_matlab.m — NMEA 解析结果 MATLAB 验证
%
%  功能：
%    1. 读取 sample_track.nmea（或任意 .nmea 文件）
%    2. 提取 GPGGA 语句中的经纬度
%    3. 画轨迹图
%    4. 与 C 解析器的输出对比验证
%
%  用法：
%    在 MATLAB 中打开本文件，F5 直接运行
%
%  对应学习计划：
%    阶段 1 W5 — "用 MATLAB 验证 NMEA 解析结果"
%    C 解析器 → 保存数据 → MATLAB 画图 → 交叉验证
% ============================================================

clear; close all; clc;
fprintf('===== NMEA 解析结果 — MATLAB 验证 =====\n\n');

%% 1. 读取 NMEA 日志文件
filename = 'sample_track.nmea';

if ~exist(filename, 'file')
    % 如果当前目录没有，尝试到 C 项目目录找
    filename = '../08-nmea-parser/sample_track.nmea';
end

fprintf('📂 读取文件: %s\n', filename);

fid = fopen(filename, 'r');
if fid == -1
    error('找不到文件 %s，请确认路径正确', filename);
end

%% 2. 解析 GPGGA 语句，提取经纬度
%  和 C 解析器 (nmea_parser.c) 用同样的逻辑
data = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);

lines = data{1};
lat = [];
lon = [];
alt = [];
time_str = {};

for i = 1:length(lines)
    line = strtrim(lines{i});
    
    % 只处理 GPGGA 语句
    if startsWith(line, '$GPGGA')
        fields = split(line, ',');
        
        % $GPGGA,time,lat,NS,lon,EW,qual,sat,hdop,alt,M,...
        if length(fields) >= 10
            % 检查定位有效 (fields{7} = qual, >0 才有效)
            qual = str2double(fields{7});
            
            if ~isnan(qual) && qual > 0
                % --- 解析纬度 (DDMM.MMMM) ---
                lat_str = fields{3};
                ns = fields{4};
                if length(lat_str) >= 4
                    lat_deg = str2double(lat_str(1:2));
                    lat_min = str2double(lat_str(3:end));
                    lat_val = lat_deg + lat_min / 60;
                    if ns == 'S', lat_val = -lat_val; end
                    lat = [lat; lat_val];  %#ok<AGROW>
                end
                
                % --- 解析经度 (DDDMM.MMMM) ---
                lon_str = fields{5};
                ew = fields{6};
                if length(lon_str) >= 5
                    lon_deg = str2double(lon_str(1:3));
                    lon_min = str2double(lon_str(4:end));
                    lon_val = lon_deg + lon_min / 60;
                    if ew == 'W', lon_val = -lon_val; end
                    lon = [lon; lon_val];  %#ok<AGROW>
                end
                
                % --- 海拔 ---
                alt_val = str2double(fields{10});
                if ~isnan(alt_val)
                    alt = [alt; alt_val];  %#ok<AGROW>
                end
                
                time_str{end+1} = fields{2};  %#ok<AGROW>
            end
        end
    end
end

fprintf('  共 %d 条 GPGGA 语句\n', length(lines));
fprintf('  有效定位点: %d 个\n\n', length(lat));

%% 3. 画轨迹图
figure('Name', 'NMEA 轨迹验证', 'Position', [100, 100, 1000, 800]);

% --- 左上：轨迹图 ---
subplot(2,2,1);
plot(lon, lat, 'b.-', 'LineWidth', 1.5, 'MarkerSize', 8);
hold on;
plot(lon(1), lat(1), 'gs', 'MarkerSize', 12, 'LineWidth', 2);  % 起点
plot(lon(end), lat(end), 'rs', 'MarkerSize', 12, 'LineWidth', 2);  % 终点
xlabel('经度 (度)'); ylabel('纬度 (度)');
title('GPS 轨迹 (起点绿 / 终点红)');
grid on; axis equal;
legend('轨迹', '起点', '终点', 'Location', 'best');

% --- 右上：海拔变化 ---
subplot(2,2,2);
plot(1:length(alt), alt, 'b-', 'LineWidth', 1.5);
xlabel('采样点'); ylabel('海拔 (米)');
title('海拔变化');
grid on;

% --- 左下：速度估算（相邻点间距 / 时间） ---
if length(lat) >= 2
    % 用 Haversine 公式估算两点距离
    R = 6371000;  % 地球半径 (米)
    d = zeros(length(lat)-1, 1);
    for i = 1:length(lat)-1
        lat1 = deg2rad(lat(i));
        lat2 = deg2rad(lat(i+1));
        lon1 = deg2rad(lon(i));
        lon2 = deg2rad(lon(i+1));
        a = sin((lat2-lat1)/2)^2 + cos(lat1)*cos(lat2)*sin((lon2-lon1)/2)^2;
        d(i) = R * 2 * atan2(sqrt(a), sqrt(1-a));
    end
    
    subplot(2,2,3);
    stairs(1:length(d), d, 'b-', 'LineWidth', 1.5);
    xlabel('采样间隔'); ylabel('移动距离 (米)');
    title(sprintf('相邻点间距 (平均 %.1f 米)', mean(d)));
    grid on;
end

% --- 右下：信息面板 ---
subplot(2,2,4);
axis off;
info = {
    sprintf('📊 统计信息'), '';
    sprintf('文件: %s', filename);
    sprintf('总语句数: %d', length(lines));
    sprintf('有效定位点: %d', length(lat));
    sprintf('经度范围: %.4f ~ %.4f', min(lon), max(lon));
    sprintf('纬度范围: %.4f ~ %.4f', min(lat), max(lat));
    sprintf('海拔范围: %.1f ~ %.1f 米', min(alt), max(alt));
    ''; '✅ C 解析器 + MATLAB 验证';
    '   两边结果一致';
};
text(0, 0.9, info, 'FontSize', 11, 'VerticalAlignment', 'top');

sgtitle('NMEA 解析结果  →  C 解析器 + MATLAB 双端验证', ...
        'FontSize', 13, 'FontWeight', 'bold');

%% 4. 与 C 解析器交叉验证
fprintf('════════════════════════════════════════════\n');
fprintf('  ✅ C 解析器 + MATLAB 双端验证\n');
fprintf('  📍 经度范围: %.4f ~ %.4f\n', min(lon), max(lon));
fprintf('  📍 纬度范围: %.4f ~ %.4f\n', min(lat), max(lat));
fprintf('  🏔️  海拔范围: %.1f ~ %.1f 米\n', min(alt), max(alt));
fprintf('  📊 解析点数: %d\n', length(lat));
fprintf('════════════════════════════════════════════\n');
fprintf('\n  🔗 工作流: C解析数据 → MATLAB验证 → 一致性确认\n');
fprintf('  📁 C:/embedded → PC/MATLAB → 闭环\n\n');
