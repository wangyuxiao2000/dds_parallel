%*************************************************************%
% function: 并行DDS输出数据分析
% Author  : WangYuxiao
% Email   : wyxee2000@163.com
% Data    : 2024.9.15
% Version : V 1.0
%*************************************************************%
% 初始化
clear; 
close all;
clc;

% 设定参数
dac_fs = 1e3;      % DAC采样率(单位:MSPS)
dds_channel = 8;   % DDS并行度
data_width = 16;   % DDS IP核中设置的信号输出位宽

% 载入数据
fid_result = fopen("../TB/result.txt",'r');
data = textscan(fid_result, '%s', 'Delimiter', '\n');
data = data{1};
data = num2cell(data);
fclose(fid_result);

% 将每个并行数据拆分为dds_channel个采样点
data = cellfun(@(str) regexp(str, ['.{1,', num2str(data_width), '}'], 'match'), data, 'UniformOutput', false);
data=[data{:}]';
data = [data{:}]';
data = reshape(data, dds_channel, [])'; 
data = fliplr(data);
data = reshape(data', [], 1);

% 将每个采样点转为有符号十进制表示
powers_of_two = [-2^(data_width-1) 2.^((data_width-2):-1:0)];
data = cellfun(@(x) x - '0', data, 'UniformOutput', false);
data = cell2mat(data);
data = sum(data .* powers_of_two, 2);

% 绘制时域、频域波形
[Amplitude, t, f] = my_fft(data, dac_fs);

subplot(2,1,1);
plot(t, data);
xlabel('时间/us');
title('时域波形');
axis([min(t),max(t),-inf,inf]);

subplot(2,1,2);
plot(f, Amplitude - max(Amplitude));
xlabel('频率/MHz');
title('幅度谱');
axis([min(f),max(f),-inf,inf]);
grid on;

clearvars -except dac_fs dds_channel data_width data;