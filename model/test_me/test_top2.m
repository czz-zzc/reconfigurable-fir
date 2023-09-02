  
  clc;
  clear all;
  num_coeffs =22;
  fft_size     = 4096;
  data_samples = 4096;
  window_name  = @hamming;

  data_in = floor(16e3*(sin(0.5*[1:1:data_samples])+sin(2*[1:1:data_samples])));
  save_s_hex(data_in,16);

  
  rld_coeff = [5,0,4,2,-4,-5,5,11,-5,-36,-16384,-16384,-36,-5,11,5,-5,-4,2,4,0,5];
  
  data_out_me = filter_fir(data_in,rld_coeff);
  