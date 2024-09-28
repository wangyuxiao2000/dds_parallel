%*************************************************************%
% function: 并行DDS仿真
% Author  : WangYuxiao
% Email   : wyxee2000@163.com
% Data    : 2024.9.8
% Version : V 1.0
%*************************************************************%
% 初始化
clear; 
close all;
clc;

% 设定参数
dac_fs = 1e3;      % DAC采样率(单位:MSPS)
dac_fo = 180;      % DAC输出信号目标频率(单位:MHz)
dds_channel = 8;   % DDS并行度
pinc_width = 16;   % DDS IP核中设置的相位增量控制字位宽
data_width = 16;   % DDS IP核中设置的信号输出位宽
sim_point = 32768; % 仿真点数

% 计算RTL模块所需参数
pinc = round(dac_fo / dac_fs * 2^pinc_width); % DAC数字量信号的相位增量控制字
dds_clk = dac_fs / dds_channel;               % DDS IP核需要的时钟频率(单位:MHz)

% 仿真并行DDS的行为
dds_pinc = pinc * dds_channel;                % 每个DDS核的相位增量控制字
dds_pinc = bitand(dds_pinc, 2^pinc_width - 1);
dds_point = sim_point / dds_channel;          % 仿真中每个DDS需产生的点数
signal = zeros(dds_point, dds_channel);       % 每行是同一时刻各路DDS的输出; 每列是单路DDS在不同时刻的输出
for i = 1 : dds_point
    for j = 1 : dds_channel
        poff = pinc * j;
        phase = (poff + dds_pinc * (i-1)) * 2 * pi / 2^pinc_width;
        signal(i, j) = round(sin(phase) * 2^(data_width-1));
    end
end
dac_signal = reshape(signal', 1, []) ;

% 绘制时域、频域波形
[Amplitude, t, f] = my_fft(dac_signal, dac_fs);

subplot(2,1,1);
plot(t, dac_signal);
xlabel('时间/us');
title('时域波形');
axis([min(t), max(t), -inf, inf]);

subplot(2,1,2);
plot(f, Amplitude - max(Amplitude));
xlabel('频率/MHz');
title('幅度谱');
axis([min(f), max(f), -inf, inf]);
grid on;

clearvars -except dac_fs dac_fo dds_channel pinc_width sim_point pinc dds_clk;