function [Y,idx_X,idxE]=flvoice_samplewindow(X, Wlength, Nlength, Type, Extent);

% SAMPLE_FUNCTION Signal windowing
% Y=flvoice_samplewindow(X, WINDOW, NOVERLAP, Type, Extent);
%     X        :  Column vector (or N-dimensional array of column vectors)
%     WINDOW   :  # samples of window
%     NOVERLAP :  # overlapping samples
%     Type     :  Windowing function (['none'],'hamming','hanning','triang','boxcar')
%     Extent   :  Border options (['valid'],'same')
% returns matrix Y (or N+1 dimensional array) resulting from splitting
% the signal X into overlapping windowed segments.
% 

% alfnie@bu.edu
% ?/99


sX=[size(X),1];
if nargin<2 | isempty(Wlength), Wlength=sX(1); end 
if nargin<3 | isempty(Nlength), Nlength=floor(Wlength/2); end
if nargin<4 | isempty(Type), Type='none'; end
if nargin<5 | isempty(Extent), Extent='tight'; end
if lower(Type(1))=='c', docentering=1; Type=Type(2:end); else, docentering=0; end
prodsX=prod(sX(2:end));

switch(lower(Extent)),
case {'valid','tight'}, Base=0;
case 'same', Base=floor(Wlength/2);
otherwise, Base=Nlength;
end

X=cat(1,zeros([Base,sX(2:end)]),X,zeros([Wlength-Base-1,sX(2:end)]));
sY=1+floor((size(X,1)-Wlength)/(Wlength-Nlength));

idx_W=repmat((1:Wlength)',[1,sY]); 
idx_X=idx_W + repmat((Wlength-Nlength)*(0:sY-1),[Wlength,1]);

switch(lower(Type)),
case 'hamming',
    W=flvoice_hamming(Wlength);
case 'hanning',
    W=flvoice_hanning(Wlength);
case 'boxcar',
    W=ones(Wlength,1);
case 'triang',
    W=(1:Wlength)'/ceil(Wlength/2);
    W=min(W,2-W);
case 'none',
    W=ones(Wlength,1);
end

if docentering,
    if 0,
        R=1;
        k=Wlength-Nlength+1;
        h=flvoice_hamming(k); h=h/sum(h);
        e=convn(X.^2,h,'same');
        k2=min(Wlength,(Wlength-Nlength+1));
        idx_k2=floor((Wlength-k2)/2)+(1:k2)';
        idx_dk2=repmat((1:k2)-ceil(k2/2),[Wlength,1]);
        onesprodsX=ones(1,prodsX);
        idxE=zeros(sY,prodsX);
        for n1=1:sY,
            if n1==1, E=e(idx_X(idx_k2,n1),:); %.*W(idx_W(:,n1));
            else, E=R*e(idx_X(idx_k2,n1),:)+shiftdim(mean(reshape(repmat(X(idx_X(:,n1-1),:),[k2,1]).*X(max(1,min(size(X,1),repmat(idx_X(:,n1),[1,k2])+idx_dk2)),:),[Wlength,k2,prodsX]),1),1); end
            %X(idx_X(:,n1),:),flipud(W(idx_W(:,n1-1),onesprodsX).*X(idx_X(:,n1-1),:)),'same')/k); end; %.*W(idx_W(:,n1),onesprodsX); end
            %if n1==1, E=e(idx_X(:,n1),:); %.*W(idx_W(:,n1));
            %else, E=(R*e(idx_X(:,n1),:)+convn(X(idx_X(:,n1),:),flipud(W(idx_W(:,n1-1),onesprodsX).*X(idx_X(:,n1-1),:)),'same')/k); end; %.*W(idx_W(:,n1),onesprodsX); end
            [nill,idxE(n1,:)]=max(E,[],1);
            idx_X(:,n1,:)=max(1,min(size(X,1), idx_X(:,n1,:)+idx_dk2(:,idxE(n1,:))));
            %idx_X(:,n1,:)=max(1,min(size(X,1), idx_X(:,n1,:)+repmat(idxE(n1,:)-floor(Wlength/2),[Wlength,1])));
        end
    else,
        k=Wlength-Nlength+1;
        h=flvoice_hamming(k); h=h/sum(h);
        e=convn(X.^2,h,'same');
        k2=Wlength;
        idx_k2=floor((Wlength-k2)/2)+(1:k2)';
        E=e(idx_X(idx_k2,:),:);%.*W(idx_W(:),ones(1,prod(sX(2:end))));
        E=reshape(E,[k2,sY,sX(2:end)]);
        [nill,idxE]=max(E,[],1);
        idx_X=max(1,min(size(X,1),idx_X+repmat(idxE-1+(idx_k2(1)-idx_k2(round(end/2))),[Wlength,1])));
    end
end

if strcmp(lower(Type),'none'), Y=X(idx_X(:),:); else, Y=X(idx_X(:),:).*W(idx_W(:),ones(1,prod(sX(2:end)))); end
Y=reshape(Y,[Wlength,sY,sX(2:end)]);

idx_X=idx_X-Base;
idx_X(idx_X<=0 | idx_X>sX(1))=nan;

switch(lower(Extent)),
case {'valid','tight'},
    idx=~all(~isnan(idx_X),1);
    Y(:,idx,:)=[]; idx_X(:,idx)=[];
case 'same',
    idx=isnan(idx_X(1+floor(end/2),:));
    Y(:,idx,:)=[]; idx_X(:,idx)=[];
end
end
