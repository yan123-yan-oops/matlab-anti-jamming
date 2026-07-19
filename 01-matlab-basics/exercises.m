figure("Name",'编程题','Position',[200,200,800,600]);

t = 1:10;
y = sin(2*pi* 2 *t) + 0.5*sin(2*pi*10*t); 

subplot(1,2,1);
plot(t , y , 'LineStyle','-','Color','b','LineWidth',1.5)
xlabel('x轴t');ylabel('y轴y')
title('图一标题')
grid on;
legend(LineWidth=1);
%已添加图例、标题和网格。

r = rand(5,5);
disp(r);
fprintf('题2沿着行压缩得每列平均值： %d\n沿着列压缩得每行平均值：%d\n矩阵平均值：%d\n',mean(r,1),mean(r,2),mean(r,"all"))

fprintf('C中手动计算平均值：%d',(r(1,1)+r(1,2)+r(1,3)+r(1,4)+r(1,5))/5);
%计算
x = rand(1000,1000);
tic
for i =  

