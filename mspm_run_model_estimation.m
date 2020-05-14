function mspm_run_model_estimation(job) % 
%%%MSPM%%%
%
% function that save the SSR, mask images and the beta in MSPM.mat 
swd         =job.swd{1};
cd(swd)
SPMs        = job.spmmat;

K           = length(SPMs); % number of spm.mat
VY          = [];
Vbeta       = [];
mspm        = cell(1,K);
vm          = cell(1,K);

%%% Read SPM.mat matrices mspm{i}.xX
for i = 1:K
    mspm{i} = load(SPMs{i});
    vm{i}   = fullfile(mspm{i}.SPM.swd,mspm{i}.SPM.VM.fname); % fullfile->slash
    VY      = cat(1,VY,mspm{i}.SPM.xY.VY);
    vb      = mspm{i}.SPM.Vbeta;
    for j = 1:length(vb)
        vb(j).fname   = fullfile(mspm{i}.SPM.swd,vb(j).fname);
    end
    Vbeta   = cat(2,Vbeta,vb);   
end

%%% Check that all design matrices are the same
X                  = mspm{1}.SPM.xX.X; 
z                  = cellfun(@(x) x.SPM.xX.X, mspm,'UniformOutput', false);
zz                 = cell2mat(cellfun(@(x) all(all(z{1}==x)), z,'UniformOutput', false)); 
if all(zz)==0, error('The design of SPM matrix %d is not identical to the others. ',find(zz==0)); end 

[SSR, vQ, XYZ, M, iM]           = mspm_SSR(X, swd, K, VY, Vbeta, vm);
SPM                = var2struct(SSR,vQ,Vbeta,K,swd);% create a structure (named SPM) containing SSR,vQ,Vbeta,K,X,swd

% save xX.X  xX.xXKXs  xX.name in SPM.mat in order to use spm_conman (arbitrary from 1st SPM.mat) 
SPM.xX              = mspm{1}.SPM.xX;
SPM.xVol            = mspm{1}.SPM.xVol;
SPM.xVol.XYZ        = XYZ(1:3,:);
SPM.xVol.S          = size(XYZ,2);
SPM.VResMS          = mspm{1}.SPM.VResMS;
SPM.xY              = mspm{1}.SPM.xY;
SPM.VY              = VY;

SPM.yCon.xCon =[];
SPM.yCon.xX.X             = eye(SPM.K);
SPM.yCon.xX.name          = cell(1,SPM.K);
SPM.yCon.xX.name          = cellstr(num2str([1:SPM.K]'))';
SPM.yCon.xX.xKXs          = spm_sp('set',SPM.yCon.xX.X);

SPM.M               = zeros(20,20);
SPM.McF             = cell(20,20);
SPM.McW             = cell(20,20);
SPM.try             = cell(20,20);

save('MSPM.mat', 'SPM'); 
end
%%
function [SSSR, vQ, XYZ, M, iM] = mspm_SSR(X, mvopt, K, VY, Vbeta, vm)  

% vvQ                 = spm_imcalc(vm,fullfile(mvopt,'mask.nii'),'prod(X)',{1});% apply mask to the image 'prod(X)'

% to avoid issue with interpolation using spm_imcalc I did the conjuntion
% between the masks by hand (Lucien 21.09.2019)
masks               = vm';
mask4d = nan(size(vm,1), 121, 145, 121);
for i = 1:size(masks,1)
   h = spm_vol(masks{i});
   him = spm_read_vols(h);
   mask4d(i,:,:,:) = him;
end
newmask = prod(mask4d, 1);
h.fname             = fullfile(mvopt, 'mask.nii');
spm_write_vol(h, squeeze(newmask));

vQ                  = spm_vol(fullfile(mvopt,'mask.nii')); % apply mask to the image 'prod(X)'[M,XYZ]            = spm_read_vols(vQ); % create the matrices of statistical values from the vQ volume structure
[M,XYZ]             = spm_read_vols(vQ); % create the matrices of statistical values from the vQ volume structure
M                  = logical(M(:)); % cast into logical for memory efficiency
XYZ(4,:)           = 1; % add 4th "dimension"
XYZ                = vQ.mat\XYZ(:,M); %inv(vQ.mat)*XYZ(:,M); % convert from mm to voxel 
iM                 = find(M);
[MI1 MI2 MI3]      = ind2sub(vQ.dim,iM); % (indice pour chaque dimension (MI1 = ligne, MI2 =colonne, MI3= ..) pour les valeurs du vecteur iM dans une matrice (choisie) de size vQ.dim (ex 121x145x121)

[N P]              = size(X);
SSR                = nan([vQ.dim K*K]);
chk                = 40000;
chk                = 1:chk:size(XYZ,2)+chk;

spm_progress_bar('Init',length(chk)-1,'vox','CVA');
for i = 1:length(chk)-1
        blk        = chk(i):min(chk(i+1)-1,size(XYZ,2));
        Y          = reshape(spm_get_data(VY,XYZ(1:3,blk)),N,K,length(blk)); % get Y for each block (read image)
        BB         = reshape(spm_get_data(Vbeta,XYZ(1:3,blk)),P,K,length(blk)); % get beta for each block (read image)
        
        for k = 1:K
            r(:,k,:)    = X*squeeze(BB(:,k,:)); % X*beta
            r(:,k,:)    = Y(:,k,:)-r(:,k,:); % Y - X*beta;
        end
         
        l=0;
        for ki = 1:K
            for kj = 1:K
                l   = l+1;
                ssr(ki,kj,1:length(blk))    = sum(r(:,ki,:).*r(:,kj,:));%SSR = SSR'*SSR 
                SSR(sub2ind(size(SSR),MI1(blk),MI2(blk),MI3(blk),repmat(l,length(blk),1)))  = ssr(ki,kj,1:length(blk)); % pour sauver SSR
            end
        end
        clear r
        spm_progress_bar('Set',i); 
end

SSSR  = [];
for l = 1:K*K
    VSSR          = vQ;
    VSSR.fname    = fullfile(mvopt,['spm_SSR_'  num2str(l,'%04d') '.nii']);
    VSSR.dt       = [16 0];
    VSSR.pinfo    = [1 0 0]';
    VSSR          = spm_create_vol(VSSR);
       
    VSSR          = spm_write_vol(VSSR,squeeze(SSR(:,:,:,l)));
    SSSR          = cat(1,SSSR,VSSR); % save all SSR images in a structure
end
end
function s = var2struct(varargin)
  names    = arrayfun(@inputname,1:nargin,'UniformOutput',false);
  s        = cell2struct(varargin,names,2);
end

