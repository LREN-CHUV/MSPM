 function mspm_run_results(job)
%%%MSPM%%%

MSPM = job.spmmat;
load(MSPM{1}) % load structures (named SPM and L) that contains vQ, SSR, Vbeta, swd, K and X.
cd(SPM.swd)

% % contrast c (on X) and contrast L (on Y)
% [j,xCon]    = spm_conman(SPM.yCon,'T&F',Inf,'    Select contrasts L',' for inference',1);
% L           = xCon(j).c;
% SPM.yCon.xCon = xCon;
% clear xCon 
% 
% [i,xCon]    = spm_conman(SPM,'T&F',Inf,'    Select contrasts c',' for inference',1); % spm_conman crée une SPM.mat dans "current folder" (pas dans le workspace)
% c           = xCon(i).c;
% SPM.xCon  = xCon;
addpath(fullfile(spm('dir'),'toolbox','MSPM_toolbox'))
[a b SPM]=mspm_go; % a=indice for contrast L, b=indice for contrast c
%delete SPM.mat
if ~isfield(SPM.try{a,b}, 'Vspm') || isempty(SPM.try{a,b}.Vspm)==1
    [VW, VF, df1, df2, aa]             = mspm_FW(SPM.vQ, SPM.SSR, SPM.Vbeta, SPM.swd, SPM.xCon(b).c, SPM.K, SPM.xX.X, SPM.yCon.xCon(a).c,a,b); % function that compute the Wilks and f-values images.
%     SPM.xCon(b).Vspm    = VF;
%     SPM.xCon(b).Vcon    = VW;
%     SPM.McF{a,b}=VF;
%     SPM.McW{a,b}=VW; 
    SPM.try{a,b}            = SPM.xCon(b);
    SPM.try{a,b}.Vspm       = VF;
    SPM.try{a,b}.Vcon       = VW;
    SPM.try{a,b}.eidf       = unique(df1);
    SPM.try{a,b}.STAT       = 'F';
    SPM.ttry{a,b}           = aa;
    save('MSPM.mat','SPM')

    SPM.xCon                = [];
    SPM.xCon                = SPM.try{a,b};
    SPM.xX.erdf             = unique(df2);
else
    SPM.xCon                = [];
    SPM.xCon                = SPM.try{a,b};

% else
%     VF=SPM.McF{a,b};
%     VW=SPM.McW(a,b);
end
r=fullfile(SPM.ttry{a,b},'SPM.mat');
save((r), 'SPM')
end

%%
function [VW, VF, df1, df2, aa] = mspm_FW(vQ, SSR, Vbeta, swd,c, K,X,L,cL,cc)

[M,XYZ]          = spm_read_vols(vQ); % create the matrices of statistical values from the vQ volume structure
M                = logical(M(:)); % cast into logical for memory efficiency
XYZ(4,:)         = 1; % add 4th "dimension"
XYZ              = vQ.mat\XYZ(:,M); %inv(vQ.mat)*XYZ(:,M); % convert from mm to voxel 
iM               = find(M);

chk              = 40000;
chk              = 1:chk:size(XYZ,2)+chk;
W1               = nan(vQ.dim);
Wall             = nan(vQ.dim);
F1               = nan(vQ.dim);
Fall             = nan(vQ.dim);
V                = nan([rank(L) vQ.dim]);
P                = size(X,2);

% if we have the linear contrast ABM - C = 0, with A (X*c) the qxk response
% transformation matrix on X, and M (L) pxl hypothesis matrix
n = size(X,1);
q = rank(X*c);
l = rank(L);
u = (l*q-2)/4;
r = n - rank(X) - (l-q+1)/2;
if l^2+q^2-5 > 0
    t = (l^2*q^2-4)/(l^2+q^2-5);
else
    t = 1;
end

df2 = r*t-2*u;
df1 = l*q;

XX               = mspm_X1(X, c);    % XX is the design matrix for my formula of SST (not Ferath's formula,slow), XX is used in function SSTWi
                                     % mspm_X1 is removing the effect of no
                                     % interest

spm_progress_bar('Init',length(chk)-1,'vox','CVA');
for i = 1:length(chk)-1
        blk         = chk(i):min(chk(i+1)-1,size(XYZ,2));
        w1          = zeros(1,length(blk));
        wall        = zeros(1,length(blk));
        f1          = zeros(1,length(blk));
        fall        = zeros(1,length(blk));
        v           = zeros(rank(L), length(blk));
        ssr         = reshape(spm_get_data(SSR,XYZ(1:3,blk)),K,K,length(blk));
        B           = reshape(spm_get_data(Vbeta,XYZ(1:3,blk)),P,K,length(blk)); % get betas for each block (read image)
        
        for j = 1:length(blk)
           [w1(j), wall(j), v(:,j)] = mspm_Wi(ssr(:,:,j),q,B(:,:,j),XX,L); % compute the Wilks (through SST (SST not save))
           Ytmp = w1(j)^(1/t);
           f1(j) = ((1-Ytmp)/Ytmp)*(df2/df1);
           Ytmp = wall(j)^(1/t);
           fall(j) = ((1-Ytmp)/Ytmp)*(df2/df1);
        end
        
        W1(iM(blk))     = w1;
        Wall(iM(blk))   = wall;
        F1(iM(blk))     = f1;
        Fall(iM(blk))   = fall;
        V(:,iM(blk))    = v;
       
        spm_progress_bar('Set',i);  
    
end

% create results folder
aa = fullfile(swd, ['L_' num2str(cL,'%02d') '_c' num2str(cc,'%02d')]);
mkdir(aa)

% write image of Wilks first canonical variates
VW          = vQ;
VW.fname    = fullfile(aa,['spm_W_first_L' num2str(cL,'%02d') '_c' num2str(cc,'%02d') '.nii']); 
VW.dt       = [64 0];
VW.pinfo    = [1 0 0]';
VW          = spm_create_vol(VW);
VW          = spm_write_vol(VW,W1);

% write image of Wilks all canonical variates
VW          = vQ;
VW.fname    = fullfile(aa,['spm_W_all_L' num2str(cL,'%02d') '_c' num2str(cc,'%02d') '.nii']); 
VW.dt       = [64 0];
VW.pinfo    = [1 0 0]';
VW          = spm_create_vol(VW);
VW          = spm_write_vol(VW,Wall);

% write image of F-values first canonical variates
VF          = vQ;
VF.fname    = fullfile(aa,['spm_F_first_L' num2str(cL,'%02d') '_c' num2str(cc,'%02d') '.nii']);
VF.dt       = [64 0];
VF.pinfo    = [1 0 0]';
VF          = spm_create_vol(VF);
VF          = spm_write_vol(VF,F1);

% write image of F-values all canonical variates
VF          = vQ;
VF.fname    = fullfile(aa,['spm_F_all_L' num2str(cL,'%02d') '_c' num2str(cc,'%02d') '.nii']);
VF.dt       = [64 0];
VF.pinfo    = [1 0 0]';
VF          = spm_create_vol(VF);
VF          = spm_write_vol(VF,Fall);

% write image of first canonical vectors
for i = 1:rank(L)
    VV          = vQ;
    VV.fname    = fullfile(aa,['spm_CVL_depVar_' num2str(i) '_L' num2str(cL,'%02d') '_c' num2str(cc,'%02d') '.nii']);
    VV.dt       = [64 0];
    VV.pinfo    = [1 0 0]';
    VV          = spm_create_vol(VV);
    VV          = spm_write_vol(VV,squeeze(V(i,:,:,:)));
end
end
function XX = mspm_X1(X, c)
X0     = X - X*c*pinv(c);  
X0     = spm_svd(X0);
XX     = X - X0*(X0'*X);
end
function [W1, Wi_all, v] = mspm_Wi(SSR,q,beta,X,L)
sst     = (beta*L)'*(X'*X)*(beta*L); % regression sum of square (Beta*'X*'X*Beta)
[v,d]   = eig(pinv(L'*SSR*L)*sst); % "correction" of the SSR by L    ??  \ faster than pinv()
                                   % multiplication by L'*L adjust for the
                                   % size of the matrix depending on the
                                   % contrast
[~,r]   = sort(-real(diag(d)));
r       = r(1:q);
d       = real(d(r,r));
W       = 1./(diag(d)+1);
W1      = W(1);
Wi_all  = prod(W);
v       = v(:,1);
if sign(v(1,1)) == -1
    v = v.*sign(v(1,1));
end

% v       = v(:,1:h);

% W     = beta*v;                     % canonical vectors  (design)
% w     = X*W;                       % canonical variates (design)
% C     = c*W;                        % canonical contrast (design)
end
