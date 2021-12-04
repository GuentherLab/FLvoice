function [Indices, Energy]=flvoice_pathsearch(C,D,varargin);
% PATHSEARCH Optimal path full Viterbi search
% [Idx, E]=flvoice_pathsearch(C,D)
% find Idx that maximizes E = sum_t{ C(idx(t),t) } + sum_{t>1}{ D(idx(t-1),idx(t),t-1) } ...
% C [N x T] is the energy function over the N path nodes over the T time steps
% D [N x N x T-1] is the energy distance function between consecutive nodes i and j between time t and t+1
%
% C and/or D can also be specified in a functional form as: {F,x1,...xn}
% where F is a function handle or function name of the form F(t,x1,...xn), 
% and x1,...,xn are optional arguments for the function F. 
% F must accept as a first argument the time-step index t (from 1 to T) and
% must return a [Nx1] vector (for C) or a [NxN] matrix (for D).
% Note that if both C and D are specified in this functional form PATHSEARCH uses 
% an additional argument to specify the number of time steps T (e.g. flvoice_pathsearch({@F1},{@F2},T);)
%
% e.g. #1
% X=10*randn(10,20);
% C=X;
% D=[]; for n1=1:size(X,2)-1, D(:,:,n1)=-dist(X(:,n1),X(:,n1+1)').^2; end
% [idx,E]=flvoice_pathsearch(C,D);
% plot(X.','ko'); hold on;plot(X(idx'+size(X,1)*(0:size(X,2)-1)),'.-'); hold off;
% xlabel('time'); ylabel('values'); title('smooth trajectory along the high values');
%
% e.g. #2 (same in functional form)
% X=10*randn(10,20);
% C=X;
% D=inline('-dist(X(:,t),X(:,t+1)'').^2','t','X');
% [idx,E]=flvoice_pathsearch(C,{D,X});
% plot(X.','ko'); hold on;plot(X(idx'+size(X,1)*(0:size(X,2)-1)),'.-'); hold off;
% xlabel('time'); ylabel('values'); title('smooth trajectory along the high values');
%


% alfnie@bu.edu
% 12/00
%

if nargin<2||isempty(D), % default D squared difference between index
    C0=-abs(repmat(1:size(C,1),size(C,1),1)-repmat(1:size(C,1),size(C,1),1)').^2;
    D={@(varargin)C0};
end
isfunctionalC=iscell(C);
isfunctionalD=iscell(D);
M=nan; idxargin=0;
if isfunctionalC, c=feval(C{1},1,C{2:end}); 
else, c=C(:,1); M=size(C,2); end
if ~isfunctionalD, lD=size(D,3); if size(D,3)>1, M=size(D,3)+1; end; end
if isnan(M), M=varargin{1}; idxargin=1; end
N=size(c,1); 
if nargin<3+idxargin, option=0; else, option=varargin{idxargin+1}; end


% Forward search

E=[c, zeros(N,M-1)];
IDX=zeros([N,M-1]);
if option, hmsg=waitbar(0,'Processing'); end
zerosN=zeros(1,N); onesN=ones(1,N);
for n1=1:M-1,
   if isfunctionalC, c=feval(C{1},n1+1,C{2:end}); else, c=C(:,n1+1); end
   if isfunctionalD, d=feval(D{1},n1,D{2:end}); else, d=D(:,:,min(lD,n1)); end
   [E(:,n1+1),IDX(:,n1)]=max(c(:,onesN)+E(:,n1+zerosN)'+d',[],2); % for each "to", find optimal "from"
   if option, waitbar(n1/M,hmsg); end
end
if option, close(hmsg); end

% Back-trace the indices list
if 1, % return optimal path
   Indices=zeros(M,1);
   [Energy Indices(end)]=max(E(:,end));
   for n1=M-1:-1:1,
      Indices(n1)=IDX(Indices(n1+1),n1);
   end
   Energy=E(Indices+N*(0:length(Indices)-1)');
   %Energy=E(:,end);
else % return optimal path to each end point (sorted by Energy)
   Indices=zeros(N,M);
   [Energy,idx]=sort(E,1);
   for n1=M-1:-1:1,
      Indices(:,n1)=IDX(Indices(:,n1+1),n1);
   end
   Energy=flipud(Energy);
   Indices=flipud(Indices);
end
end   
