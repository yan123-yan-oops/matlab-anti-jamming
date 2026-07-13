# 04 习题：文件 I/O
# 对应 C 06-strings、07-ringbuffer、08-nmea-parser

---

### ✅ 概念题

1. `fwrite(fid, data, 'uint8')` 和 C 的 `fwrite(data, 1, n, fp)` 对应关系？
2. `textscan` 和 C 的 `fscanf` 有什么异同？
3. 二进制文件 vs 文本文件，嵌入式里各自什么场景？
4. C 把数据采集到文件 → MATLAB 读文件分析，这个工作流好在哪？

---

### 🔍 代码阅读题

**题 A：**
```matlab
fid = fopen('data.bin', 'wb');
fwrite(fid, [1 2 3 4], 'uint32');
fclose(fid);
% 这个文件有多大？(字节)
```

**题 B：**
```matlab
data = fread(fid, inf, 'int16');
% 如果文件是 100 字节，读出多少个 int16？
```

---

### 💻 编程题

**题 1：C 写一个二进制文件，MATLAB 读它并画图。**
```c
// C 代码：生成 1000 个 int16 正弦波采样点，写入 data.bin
// 然后用 MATLAB 的 file_io_demo.m 读取并画图
```

**题 2：写一个 MATLAB 函数，合并多个 NMEA 文件。**
```matlab
function merge_nmea(file_list, output_file)
% 输入: 多个 .nmea 文件的路径列表
% 输出: 合并到一个文件
% 去除重复的 $ 行
% 统计总语句数
```

**题 3：模拟 C 串口数据流 → MATLAB 实时处理。**
```matlab
% 生成一个文本文件，模拟 UART 每秒输出一行 NMEA
% MATLAB 逐行读取（像 C 的主循环一样）
% 每读一行就更新轨迹图
```
