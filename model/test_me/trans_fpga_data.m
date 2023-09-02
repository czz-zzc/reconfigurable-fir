function data_out = trans_fpga_data(fid)
dds_data = textscan(fid,'%f');
load_data= dds_data{1,1};
trans_data = zeros(1,length(load_data));
for i= 1:length(load_data)
    if load_data(i) >= 2^36
        trans_data(i) = load_data(i) - 2^37;
    else
        trans_data(i) = load_data(i);
    end 
end
data_out = double(trans_data);
end