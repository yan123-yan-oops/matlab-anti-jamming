# 01 MATLAB 基础 · 习题批改报告

> **注意**：本文件不修改你的原始 `exercises.m`，仅指出问题并提供修正方案。

---

## 题 1：画叠加波形

### 📝 你的代码

```matlab
t = 1:10;
y = sin(2*pi* 2 *t) + 0.5*sin(2*pi*10*t); 

subplot(1,2,1);
plot(t , y , 'LineStyle','-','Color','b','LineWidth',1.5)
xlabel('x轴t');ylabel('y轴y')
title('图一标题')
grid on;
legend(LineWidth=1);
```

### ❌ 问题 1：时间轴不对

```matlab
t = 1:10;  
```
`1:10` 生成的是 `[1 2 3 4 5 6 7 8 9 10]`，只有 10 个点、间隔 1 秒。
**10Hz 的信号需要采样率 > 20Hz**，你用 1Hz 采样 → 违反奈奎斯特定理，信号会完全失真。

✅ **修正：**
```matlab
Fs = 1000;                      % 采样率 1000Hz（足够高）
T  = 1;                         % 时长 1 秒
t  = 0:1/Fs:T-1/Fs;            % 0 到 1 秒，1000 个点
```

### ❌ 问题 2：图例语法错误

```matlab
legend(LineWidth=1);
```
`LineWidth` 是坐标轴属性，不是 `legend` 的参数。
`legend` 的输入应该是图例标签文本。

✅ **修正：**
```matlab
legend('叠加信号', 'Location', 'best');
```

### ❌ 问题 3：标题太模糊

```matlab
title('图一标题');
```
面试官看到这个标题会觉得不专业。

✅ **修正：**
```matlab
title('2Hz + 10Hz 叠加波形');
```

### ✅ 完整修正版

```matlab
Fs = 1000;                      % 采样率
T  = 1;                         % 时长 1s
t  = 0:1/Fs:T-1/Fs;            % 时间轴

y = sin(2*pi*2*t) + 0.5*sin(2*pi*10*t);

figure('Name', '题1 叠加波形', 'Position', [200, 200, 1000, 400]);

subplot(1,2,1);
plot(t, y, 'b-', 'LineWidth', 1.5);
xlabel('时间 (s)'); ylabel('幅度');
title('2Hz + 10Hz 叠加波形（时域）');
legend('叠加信号', 'Location', 'best');
grid on;

subplot(1,2,2);
Y = fft(y);
f = (0:length(Y)-1) * Fs / length(Y);
plot(f(1:200), abs(Y(1:200))/length(Y)*2, 'r-', 'LineWidth', 1);
xlabel('频率 (Hz)'); ylabel('幅度');
title('频谱（频域）');
xlim([0, 50]); grid on;
```

---

## 题 2：5×5 随机矩阵，计算行列均值

### 📝 你的代码

```matlab
r = rand(5,5);
disp(r);
fprintf('...%d\n...%d\n...%d\n', mean(r,1), mean(r,2), mean(r,"all"));
fprintf('C中手动计算平均值：%d', (r(1,1)+r(1,2)+r(1,3)+r(1,4)+r(1,5))/5);
```

### ❌ 问题 1：`%d` 不能打印小数

`%d` 是**整数占位符**。`mean()` 返回的是小数，应该用 `%f` 或 `%.4f`。

```matlab
% ❌
fprintf('%d', mean(r,1));   % 输出：0  （小数被截断成 0）

% ✅
fprintf('%.4f\n', mean(r,1));  % 输出：0.5123
```

### ❌ 问题 2：`mean(r,1)` 返回的是向量，不是标量

`mean(r,1)` 返回 1×5 的**行向量**（每列的平均值），不能用一个 `%d` 打印。

✅ **修正：**
```matlab
% 方法一：用循环打印每个值
col_means = mean(r, 1);
for i = 1:5
    fprintf('  第 %d 列平均值 = %.4f\n', i, col_means(i));
end

% 方法二：用 disp 直接显示
fprintf('  每列平均值: '); disp(mean(r, 1));
fprintf('  每行平均值: '); disp(mean(r, 2));
```

### ❌ 问题 3：`mean(r,"all")` 的引号

在 MATLAB R2018b~R2022a 中，`mean(r, 'all')` 用**单引号**。双引号 `"all"` 在 R2022b+ 才支持。
为了兼容性，建议用 `mean(r(:))` 或 `mean(mean(r))`。

✅ **修正：**
```matlab
fprintf('  矩阵整体平均值 = %.4f\n', mean(r(:)));
```

### ❌ 问题 4：手动计算只算了一行

题目要求"和 C 里手动算平均值对比"，应该写一个 for 循环手动算整个矩阵的平均值：

✅ **修正：**
```matlab
% C 风格手动计算
total = 0;
count = 0;
for i = 1:5
    for j = 1:5
        total = total + r(i, j);
        count = count + 1;
    end
end
manual_mean = total / count;
fprintf('  C风格手动计算平均值 = %.4f\n', manual_mean);
fprintf('  MATLAB内置 平均值 = %.4f\n', mean(r(:)));
fprintf('  两者一致: %d\n', abs(manual_mean - mean(r(:))) < 1e-10);
```

---

## 题 3：for 循环 vs 向量化性能对比

### 📝 你的代码

```matlab
x = rand(1000,1000);
tic
for i =
```

只写了一半，没有完成。

### ✅ 完整版

```matlab
N = 10000;                       % 数据量（10000就够了，1000×1000 是 10^6 太大会卡）
x = rand(1, N);

% ----- for 循环版本 -----
y_for = zeros(1, N);
tic;
for i = 1:N
    y_for(i) = x(i)^2 + 2*x(i) + 1;
end
t_for = toc;

% ----- 向量化版本 -----
tic;
y_vec = x.^2 + 2*x + 1;
t_vec = toc;

fprintf('===== 性能对比 =====\n');
fprintf('  for 循环耗时:   %.6f 秒\n', t_for);
fprintf('  向量化运算耗时: %.6f 秒\n', t_vec);
fprintf('  向量化快 %.1f 倍\n', t_for / t_vec);

% 验证结果一致
fprintf('  结果一致: %d\n', isequal(y_for, y_vec));
```

---

## 总结

| 题号 | 错误类型 | 严重程度 | 建议 |
|------|----------|:--------:|------|
| 1 | 采样率不足（别名混叠） | 🔴 致命 | 必须用 Fs > 2×f_max |
| 1 | `legend(LineWidth=1)` 语法错误 | 🟡 语法 | legend 参数是字符串标签 |
| 1 | 标题模糊 | 🟢 规范 | 标题要说明"是什么" |
| 2 | `%d` 打印小数 | 🔴 致命 | 浮点数用 `%f` |
| 2 | `mean()` 返回值类型理解偏差 | 🟡 概念 | `mean(M,1)` 返回行向量 |
| 2 | 引号兼容性 | 🟢 规范 | 老版 MATLAB 用单引号 |
| 2 | 手动计算不完整 | 🟡 概念 | 要手动算全部元素，不是一行 |
| 3 | 未完成 | 🔴 致命 | 补齐代码 |
