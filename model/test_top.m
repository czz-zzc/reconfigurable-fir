  
  clc;
  clear all;
  num_coeffs =22;
  fft_size     = 4096;
  data_samples = 4096;
  % Create default filter
  disp('---------------------------------------------------------------------');
  disp('INFO: Create default filter');
  disp('---------------------------------------------------------------------');
  %disp('Press any key to continue...'); pause;
  fir1    = fir_compiler_v7_2_bitacc();
  config1 = get_configuration(fir1);
  % Create an input data vector
  %   - Scaled to match the default models data format; Fix16_0
  disp('INFO: Generate input data...');
  data_in = floor(16e3*(sin(0.5*[1:1:data_samples])+sin(2*[1:1:data_samples])));
  save_s_hex(data_in,16);
 
  %%
  rld_coeff = [-5,0,4,2,-4,-5,5,11,-5,-36,64,64,-36,-5,11,5,-5,-4,2,4,0,-5];
  fir2    = fir_compiler_v7_2_bitacc('num_coeffs',num_coeffs,'coeff',rld_coeff)
  config2 = get_configuration(fir2);
  disp('INFO: Running filter with new coefficients...');
  data_out1 = filter(fir2,data_in);
  
  %%
  rld_coeff = [5,0,4,2,-4,-5,5,11,-5,-36,16384,16384,-36,-5,11,5,-5,-4,2,4,0,5];
  
  fir2    = fir_compiler_v7_2_bitacc('num_coeffs',num_coeffs,'coeff',rld_coeff)
  config2 = get_configuration(fir2);
  % Use same input data and filter again
  disp('INFO: Running filter with new coefficients...');
  data_out2 = filter(fir2,data_in);
  
  
  %%
  rld_coeff = [5,0,4,2,-4,-5,5,11,-5,-36,-16384,-16384,-36,-5,11,5,-5,-4,2,4,0,5];
  
  fir2    = fir_compiler_v7_2_bitacc('num_coeffs',num_coeffs,'coeff',rld_coeff)
  config2 = get_configuration(fir2);
  % Use same input data and filter again
  disp('INFO: Running filter with new coefficients...');
  data_out3 = filter(fir2,data_in);
  
  
  
  %%
  % Plot normalized filter response, input data and output data
%   disp('INFO: Plot filter response, input data and output data');
%   fr_filter   = fft(config2.coeff,fft_size);
%   fr_data_in  = fft(data_in.*window(window_name,data_samples)',fft_size);
%   fr_data_out = fft(data_out1.*window(window_name,data_samples)',fft_size);
%   figure;
%   plot(20*log10(abs(fr_filter(1:fft_size/2))./max(abs(fr_filter))));
%   hold on;
%   grid on;
%   plot(20*log10(abs(fr_data_in(1:fft_size/2))./max(abs(fr_data_in))),'r');
%   plot(20*log10(abs(fr_data_out(1:fft_size/2))./max(abs(fr_data_out))),'g');
%   legend('Filter','Data in','Data out');
%   title('Default filter configuration');
  data_out1 = data_out1';
  data_out2 = data_out2';
  data_out3 = data_out3';
  
  

  
  
  file_id = fopen("data_out1.txt",'r');
  fpga_data_out1 = trans_fpga_data(file_id);
  for i =1:data_samples
      if(fpga_data_out1(i)~= data_out1(i))
          error('data1 compare failed!!!!');
      end
  end
  disp('data1 compare success (-_-)');
  
  file_id = fopen("data_out2.txt",'r');
  fpga_data_out2 = trans_fpga_data(file_id);
  for i =1:data_samples
      if(fpga_data_out2(i)~= data_out2(i))
        error('data2 compare failed!!!!');
      end
  end
  disp('data2 compare success (-_-)');
  
  file_id = fopen("data_out3.txt",'r');
  fpga_data_out3 = trans_fpga_data(file_id);
  for i =1:data_samples
      if(fpga_data_out3(i)~= data_out3(i))
        error('data3 compare failed!!!!');
      end
  end
  disp('data3 compare success (-_-)');
  
  
  data_out_me = filter_fir(data_in,rld_coeff);
  for i =1:data_samples
      if(data_out_me(i)~= data_out3(i))
          error('data me  compare failed!!!!');
      end
  end
  disp('data me compare success (-_-)');
  