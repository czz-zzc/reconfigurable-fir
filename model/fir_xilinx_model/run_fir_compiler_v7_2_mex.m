% Run some basic tests demonstrating the fir_compiler_v7_2_bitacc MEX function
%   run_fir_compiler_v7_2_bitacc_mex()
%
function run_fir_compiler_v7_2_mex(varargin)
  % Constants
  fft_size     = 4096;
  data_samples = 4096;
  window_name  = @hamming;

  % Create default filter
  disp('---------------------------------------------------------------------');
  disp('INFO: Create default filter');
  disp('---------------------------------------------------------------------');
  disp('Press any key to continue...'); pause;
  fir1    = fir_compiler_v7_2_bitacc()
  config1 = get_configuration(fir1);

  % Create an input data vector
  %   - Scaled to match the default models data format; Fix16_0
  disp('INFO: Generate input data...');
  data_in = 16e3*(sin(0.5*[1:1:data_samples])+sin(2*[1:1:data_samples]));

  % Filter data
  disp('INFO: Filter...');
  data_out = filter(fir1,data_in);

  % Plot normalized filter response, input data and output data
  disp('INFO: Plot filter response, input data and output data');
  fr_filter   = fft(config1.coeff,fft_size);
  fr_data_in  = fft(data_in.*window(window_name,data_samples)',fft_size);
  fr_data_out = fft(data_out.*window(window_name,data_samples)',fft_size);
  figure;
  plot(20*log10(abs(fr_filter(1:fft_size/2))./max(abs(fr_filter))));
  hold on;
  grid on;
  plot(20*log10(abs(fr_data_in(1:fft_size/2))./max(abs(fr_data_in))),'r');
  plot(20*log10(abs(fr_data_out(1:fft_size/2))./max(abs(fr_data_out))),'g');
  legend('Filter','Data in','Data out');
  title('Default filter configuration');
  disp('Press any key to continue...'); pause;

  % Create reloadable filter
  disp('---------------------------------------------------------------------');
  disp('INFO: Create reloadable filter');
  disp('---------------------------------------------------------------------');
  disp('Press any key to continue...'); pause;
  fir2    = fir_compiler_v7_2_bitacc('reloadable',1)
  config2 = get_configuration(fir2);

  % Create an input data vector
  %   - Scaled to match the default models data format; Fix16_0
  disp('INFO: Generate input data...');
  data_in = 16e3*(sin(0.5*[1:1:data_samples])+sin(2*[1:1:data_samples]));

  % Filter data
  disp('INFO: Filter...');
  data_out = filter(fir2,data_in);

  % Reload filter with new coefficients
  disp('INFO: Reload filter coefficients...');
  rld_coeff = [-5,0,4,2,-4,-5,5,11,-5,-36,64,-36,-5,11,5,-5,-4,2,4,0,-5];
  reload_send(fir2,struct('fsel',0,'coeff',rld_coeff));
  % Trigger use of new coefficient by sending a config update
  config_send(fir2,struct('fsel',[0]));

  % Use same input data and filter again
  disp('INFO: Running filter with new coefficients...');
  data_out2 = filter(fir2,data_in);

  % Plot normalized filter response, input data and output data
  disp('INFO: Plot filter response, input data and output data');
  fr_filter    = fft(config2.coeff,fft_size);
  fr_filter_rld= fft(rld_coeff,fft_size);
  fr_data_in   = fft(data_in.*window(window_name,data_samples)',fft_size);
  fr_data_out  = fft(data_out.*window(window_name,data_samples)',fft_size);
  fr_data_out2 = fft(data_out2.*window(window_name,data_samples)',fft_size);
  figure;
  subplot(2,1,1);
  plot(20*log10(abs(fr_filter(1:fft_size/2))./max(abs(fr_filter))));
  hold on;
  grid on;
  plot(20*log10(abs(fr_data_in(1:fft_size/2))./max(abs(fr_data_in))),'r');
  plot(20*log10(abs(fr_data_out(1:fft_size/2))./max(abs(fr_data_out))),'g');
  legend('Filter','Data in','Data out');
  title('Default filter');
  subplot(2,1,2);
  plot(20*log10(abs(fr_filter_rld(1:fft_size/2))./max(abs(fr_filter_rld))));
  hold on;
  grid on;
  plot(20*log10(abs(fr_data_in(1:fft_size/2))./max(abs(fr_data_in))),'r');
  plot(20*log10(abs(fr_data_out2(1:fft_size/2))./max(abs(fr_data_out2))),'g');
  legend('Filter','Data in','Data out');
  title('Reloaded filter');
  disp('Press any key to continue...'); pause;

  % Create 2 channel upsampling filter
  disp('---------------------------------------------------------------------');
  disp('INFO: Create 2 channel upsampling filter');
  disp('---------------------------------------------------------------------');
  disp('Press any key to continue...'); pause;
  fir3    = fir_compiler_v7_2_bitacc('filter_type',1,'interp_rate',2,'num_channels',2)
  config3 = get_configuration(fir3);

  % Create input data vector
  %   - Scaled to match the default models data format; Fix16_0
  disp('INFO: Generate input data...');
  clear data_in;
  data_in(1,:) = 16e3*(sin(0.5*[1:1:data_samples/2]));
  data_in(2,:) = 8e3*(sin(0.2*[1:1:data_samples/2]));

  % Create upsampled data with no filtering for comparison
  data_up(1,:) = upsample(data_in(1,:),2);
  data_up(2,:) = upsample(data_in(2,:),2);

  % Filter data
  disp('INFO: Filter...');
  data_out = filter(fir3,data_in);

  % Plot normalized filter response, input data and output data
  disp('INFO: Plot filter response, input data and output data');
  wndw(1,:)    = window(window_name,data_samples/2);
  wndw(2,:)    = window(window_name,data_samples/2);
  wndw_up(1,:) = window(window_name,data_samples);
  wndw_up(2,:) = window(window_name,data_samples);
  fr_filter      = fft(config3.coeff,fft_size);
  fr_data_in     = fft(data_in.*wndw,fft_size,2);
  fr_data_up     = fft(data_up.*wndw_up,fft_size,2);
  fr_data_out    = fft(data_out.*wndw_up,fft_size,2);
  figure;
  subplot(3,1,1);
  plot(20*log10(abs(fr_data_in(1,1:fft_size/2))./max(max(abs(fr_data_in)))),'b');
  hold on;
  grid on;
  plot(20*log10(abs(fr_data_in(2,1:fft_size/2))./max(max(abs(fr_data_in)))),'r');
  legend('Data In (ch1)','Data In (ch2)');
  title('Input data');
  subplot(3,1,2);
  plot(20*log10(abs(fr_data_up(1,1:fft_size/2))./max(max(abs(fr_data_up)))),'g');
  hold on;
  grid on;
  plot(20*log10(abs(fr_data_up(2,1:fft_size/2))./max(max(abs(fr_data_up)))),'c');
  legend('Data upsampled (ch1)','Data upsampled (ch2)');
  title('Upsampled no filtering');
  subplot(3,1,3);
  plot(20*log10(abs(fr_filter(1:fft_size/2))./max(abs(fr_filter))),'b');
  hold on;
  grid on;
  plot(20*log10(abs(fr_data_out(1,1:fft_size/2))./max(max(abs(fr_data_out)))),'r');
  plot(20*log10(abs(fr_data_out(2,1:fft_size/2))./max(max(abs(fr_data_out)))),'g');
  legend('Filter','Data upsampled (ch1)','Data upsampled (ch2)');
  title('Upsampled plus filtering');
  disp('Press any key to continue...'); pause;

  % Create filter using coefficients created by firpm
  %   - Coefficients will be quantized by the FIR Compiler object
  disp('---------------------------------------------------------------------');
  disp('INFO: Create filter using coefficients generated by cfirpm');
  disp('---------------------------------------------------------------------');
  disp('Press any key to continue...'); pause;
  disp('INFO: Creating coefficients...');
  fl    = 99;
  f     = [0,0.2,0.3,1];
  coeff = cfirpm(fl,f,@lowpass);
  disp('INFO: Creating filter quantizing coefficients to Fix16_15 ...');
  fir4    = fir_compiler_v7_2_bitacc('coeff',coeff,'num_coeffs',fl+1,'coeff_width',16,'coeff_fract_width',15,'data_width',16,'data_fract_width',14)
  config4 = get_configuration(fir4);

  % Plot source and quantized filter coefficients
  disp('INFO: Plot quantized coefficients vs source coefficients');
  figure;
  fr_filter      = fft(config4.coeff,fft_size);
  fr_filter_quant= fft(filter(fir4,[1,zeros(1,fl)]),fft_size);
  plot(20*log10(abs(fr_filter(1:fft_size/2))./max(abs(fr_filter))),'b');
  hold on;
  grid on;
  plot(20*log10(abs(fr_filter_quant(1:fft_size/2))./max(abs(fr_filter_quant))),'r');
  legend('Source Coefficients','Quantized Coefficients');
  title('Coefficient Quantization');
  disp('Press any key to continue...'); pause;

  % Create an input data vector
  disp('INFO: Generate input data...');
  clear data_in;
  data_in = sin(0.5*[1:1:data_samples])+sin(2*[1:1:data_samples]);

  % Filter data
  disp('INFO: Filter...');
  data_out = filter(fir4,data_in);

  % Plot normalized filter response, input data and output data
  disp('INFO: Plot filter response, input data and output data');
  fr_data_in  = fft(data_in.*window(window_name,data_samples)',fft_size);
  fr_data_out = fft(data_out.*window(window_name,data_samples)',fft_size);
  figure;
  plot(20*log10(abs(fr_filter_quant(1:fft_size/2))./max(abs(fr_filter_quant))));
  hold on;
  grid on;
  plot(20*log10(abs(fr_data_in(1:fft_size/2))./max(abs(fr_data_in))),'r');
  plot(20*log10(abs(fr_data_out(1:fft_size/2))./max(abs(fr_data_out))),'g');
  legend('Filter','Data in','Data out');
  title('Filter using quantized coefficients');
  disp('Press any key to continue...'); pause;

  % Create filter instance with persistent memory
  disp('---------------------------------------------------------------------');
  disp('INFO: Create filter instance with persistent memory');
  disp('---------------------------------------------------------------------');
  disp('Press any key to continue...'); pause;
  fir5    = fir_compiler_v7_2_bitacc('coeff',[1:1:8],'num_coeffs',8,'PersistentMemory',true)
  config5 = get_configuration(fir5);

  disp(['INFO: Coefficients: ',num2str(config5.coeff)]);
  disp(['INFO: Data In: [1 0 0 0] Data Out: ',num2str(filter(fir5,[1,0,0,0]))]);
  disp(['INFO: Data In: [0 0 0 0] Data Out: ',num2str(filter(fir5,[0,0,0,0]))]);

end

%-----------------------------------------------------------------------------
%  (c) Copyright 2011 Xilinx, Inc. All rights reserved.
%
%  This file contains confidential and proprietary information
%  of Xilinx, Inc. and is protected under U.S. and
%  international copyright and other intellectual property
%  laws.
%
%  DISCLAIMER
%  This disclaimer is not a license and does not grant any
%  rights to the materials distributed herewith. Except as
%  otherwise provided in a valid license issued to you by
%  Xilinx, and to the maximum extent permitted by applicable
%  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
%  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
%  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
%  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
%  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
%  (2) Xilinx shall not be liable (whether in contract or tort,
%  including negligence, or under any other theory of
%  liability) for any loss or damage of any kind or nature
%  related to, arising under or in connection with these
%  materials, including for any direct, or any indirect,
%  special, incidental, or consequential loss or damage
%  (including loss of data, profits, goodwill, or any type of
%  loss or damage suffered as a result of any action brought
%  by a third party) even if such damage or loss was
%  reasonably foreseeable or Xilinx had been advised of the
%  possibility of the same.
%
%  CRITICAL APPLICATIONS
%  Xilinx products are not designed or intended to be fail-
%  safe, or for use in any application requiring fail-safe
%  performance, such as life-support or safety devices or
%  systems, Class III medical devices, nuclear facilities,
%  applications related to the deployment of airbags, or any
%  other applications that could lead to death, personal
%  injury, or severe property or environmental damage
%  (individually and collectively, "Critical
%  Applications"). Customer assumes the sole risk and
%  liability of any use of Xilinx products in Critical
%  Applications, subject only to applicable laws and
%  regulations governing limitations on product liability.
%
%  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
%  PART OF THIS FILE AT ALL TIMES.
%-----------------------------------------------------------------------------
