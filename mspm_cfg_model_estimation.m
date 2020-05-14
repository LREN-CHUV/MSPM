function results = mspm_cfg_model_estimation
%
%
%
%
rev = '$Rev: 3993 $';%??
if ~isdeployed, addpath(fullfile(spm('dir'),'toolbox','MSPM_toolbox')); end
% ---------------------------------------------------------------------
% spmmat Select SPM.mat
% ---------------------------------------------------------------------
spmmat         = cfg_files;
spmmat.tag     = 'spmmat';
spmmat.name    = 'Select SPM.mat';
spmmat.help    = {'Select (at least 2) SPM.mat file '};
spmmat.filter  = 'mat';
spmmat.ufilter = '^SPM\.mat$';
spmmat.num     = [1 inf];

% ---------------------------------------------------------------------
% cwd Directory
% ---------------------------------------------------------------------
swd         = cfg_files;
swd.tag     = 'swd';
swd.name    = 'Directory';
swd.help    = {'Select a directory where the MSPM.mat file containing the specified SPM and L structures will be written.'};
swd.filter  = 'dir';
swd.ufilter = '.*';
swd.num     = [1 1];

% ---------------------------------------------------------------------
% model estimation branch
% ---------------------------------------------------------------------
model_estimation          = cfg_exbranch;
model_estimation.tag      = 'model_estimation';
model_estimation.name     = 'Model estimation';
model_estimation.val      = {spmmat swd};
model_estimation.help     = {'Provide at least 2 SPM.mat in order to estimate the MSPM.mat for a MANOVA, and choose a directory where all the files and images will be written. Then use the analyse module... '};
model_estimation.prog     = @mspm_run_model_estimation;
model_estimation.modality = {'FMRI' 'PET' 'EEG'};

%%
% ---------------------------------------------------------------------
% spmmat Select SPM.mat
% ---------------------------------------------------------------------
spmmat         = cfg_files;
spmmat.tag     = 'spmmat';
spmmat.name    = 'Select MSPM.mat';
spmmat.help    = {'Select MSPM.mat file that contains SPM and L structures'};
spmmat.filter  = 'mat';
spmmat.num     = [1 1];

% ---------------------------------------------------------------------
% analyse branch
% ---------------------------------------------------------------------
analyse        = cfg_exbranch;
analyse.tag    = 'analyse';
analyse.name   = 'Analyse ';
analyse.val    = {spmmat};
analyse.help   = {'Choose the MSPM file containing the SPM and L structure. The first contrast to provide is the contrast concerning the design matrix X. The second contrast is the L; concerning the Y space.'
                    ''
                    'Test diff. among groups ->  Are there differences among the groups?'
                    'c=[1 -1]''      L=[1  0  0  0  0'
                    '                         0  1  0  0  0'                
                    '                         0  0  1  0  0'
                    '                         0  0  0  1  0'
                    '                         0  0  0  0  1]'};
analyse.prog     = @mspm_run_results;
analyse.modality = {'FMRI' 'PET' 'EEG'};

% ---------------------------------------------------------------------
% results Report
% ---------------------------------------------------------------------
results          = cfg_choice;
results.tag      = 'results';
results.name     = 'MSPM';
results.values      = {model_estimation analyse};
results.help     = {''};



