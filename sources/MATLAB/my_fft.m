%*************************************************************%
% function: FFT变换
% Author  : WangYuxiao
% Email   : wyxee2000@163.com
% Data    : 2024.9.12
% Version : V 1.0
%*************************************************************%
function [Amplitude, t, f] = my_fft(data, fs)
    
    N = length(data);
    Bs = fs / 2;
    T = N / fs;
    f = -Bs + [0:N-1] / T;
    t = [0:N-1] / fs;
    
%     hamming_window = hamming(N);
%     data = data .* hamming_window;

%     blackman_window = blackman(N);
%     data = data .* blackman_window;

    S = fftshift(fft(data));
    Amplitude = abs(S);                           % 取模值
    Amplitude(1) = Amplitude(1) / N;              % 0频率处FFT的值为信号值的N倍
    Amplitude(2:end) = Amplitude(2:end) / (N/2);  % 其它频率处FFT的值为信号值的N/2倍
    Amplitude = 20 * log10(Amplitude);            % 进行幅度dB转换
    Amplitude(isinf(abs(Amplitude))) = -200 + max(Amplitude);
    
end