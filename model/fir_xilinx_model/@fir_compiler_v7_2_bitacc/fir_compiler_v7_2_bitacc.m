%Create an instance of a fir_compiler_v7_2_bitacc
%  [model]=fir_compiler_v7_2_bitacc
%  [model]=fir_compiler_v7_2_bitacc(config)
%  [model]=fir_compiler_v7_2_bitacc(field,value[,field,value]*)
%
%In
%  config          Configuration structure to use when creating the model object
%  field           Configuration name
%  value           Configuration value
%
%Out
%  model           Created model object
%
%Notes
%  For further information consult the FIR Compiler Product Guide
%
function [model]=fir_compiler_v7_2_bitacc(varargin)

  %Get input config
  if (nargin==1)
    override_config=varargin{1};
    if (~isstruct(override_config)) error('ERROR:Expecting single argument to be a structure'); end
  else
    override_config=struct(varargin{:});
  end
  
  %M-file only parameter
  PersistentMemory = false;
  
  %Now add to default config
  config=fir_compiler_v7_2_bitacc_mex(1);
  fields=fieldnames(override_config);
  for n=1:numel(fields)
    if (strcmpi(fields{n},'PersistentMemory'))
      if (islogical(override_config.(fields{n}) ))
        PersistentMemory = override_config.(fields{n});
      else
        error('ERROR: Expecting logical value for PersistentMemory');
      end
    else
      config.(fields{n})=override_config.(fields{n});
    end
  end
  
  % Check coefficient vector size and assosicated elements
  coeff_len = max(length(config.coeff));
  if ( coeff_len ~= config.coeff_sets * config.num_coeffs)
    config.num_coeffs = floor(coeff_len/config.coeff_sets);
    warning(['WARNING: Setting num_coeffs to: ' num2str(config.num_coeffs)]);
  end
  
  % Create the object
  s.shandle  =fir_compiler_v7_2_bitacc_mex(2,config);
  % Readback model configuration to obtain read only config items
  config_rb =fir_compiler_v7_2_bitacc_mex(8,s.shandle);
  s.config =config;
  fields_rb=fieldnames(config_rb);
  for n=1:numel(fields_rb)
    s.config.(fields_rb{n})=config_rb.(fields_rb{n});
  end
  s.PersistentMemory = PersistentMemory;
	s.cleanup = 0;
  model=class(s,mfilename);
	model.cleanup = onCleanup(@()delete(model));

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
