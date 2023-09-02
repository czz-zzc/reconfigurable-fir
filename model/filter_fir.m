function y = filter_fir(x,coe)
    l_x=length(x);
    l_coe=length(coe);
    y_local = zeros(1,(l_x+l_coe-1));
    y = zeros(1,l_x);
    y_local = conv(x,coe);
    y = y_local(1:l_x);
end