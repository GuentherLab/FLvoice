function w=flvoice_hamming(n)
if ~rem(n,2),%even
    w = .54 - .46*cos(2*pi*(1:n/2)'/(n+1)); 
    w=[w;flipud(w)];
else,%odd
   w = .54 - .46*cos(2*pi*(1:(n+1)/2)'/(n+1));
   w = [w; flipud(w(1:end-1))];
end
end