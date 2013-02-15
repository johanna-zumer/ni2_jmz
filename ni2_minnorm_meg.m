% Minimum norm estimate for source localization

% What do we need to perform source localization with a minimum norm
% method?
% 1) Data
load ~/teaching/megdatanoisenoise.mat 

% 2) Sensor positions

load('/home/common/matlab/fieldtrip/data/ftp/tutorial/beamformer/dataFIC')
datanoisenoise.grad=dataFIC.grad;
clear dataFIC
save ~/teaching/megdatanoisenoise.mat datanoisenoise

%%
cd ~/teaching/ni2_jmz/
load ~/teaching/megdatanoisenoise.mat 


% 3) Head model
% For EEG, we'll be interested to test the effect of using the more
% accurate BEM versus a less accurate 3sphere and 1 sphere model.
load('/home/common/matlab/fieldtrip/data/ftp/tutorial/headmodel_meg/vol.mat')
vol=ft_convert_units(vol,'cm');

cfg=[];
cfg.method = 'singlesphere';
vol_1sph=ft_prepare_headmodel(cfg,vol.bnd);

% 4) Grid points in the head
load meg_leadfields.mat

grid=rmfield(grid2,'leadfield');

cfg = [];
cfg.grid = grid;
cfg.grad = datanoisenoise.grad;
cfg.vol = vol_1sph;
grid_1sph = ft_prepare_leadfield(cfg, datanoisenoise);

% Convert data from 'raw' to 'timelock' and to 'freq';
cfg=[];
cfg.keeptrials='yes';
cfg.covariance='yes';
tlock_tr=ft_timelockanalysis(cfg,datanoisenoise);

cfg=[];
cfg.covariance='yes';
cfg.covariancewindow = [0 0.3];
tlock_avg=ft_timelockanalysis(cfg,datanoisenoise);

% Now we can compute a source inversion, with our three different
% leadfields based on the three different head model options
cfg = [];
cfg.method = 'mne';
cfg.grid = grid2;
cfg.vol = vol;
cfg.snr = 1;
mne_grid2_avg = ft_sourceanalysis(cfg, tlock_avg);

for ll=1:size(mne_grid2_avg.pos,1)
  mne_grid2_avg.avg.normpow(ll,:) = mne_grid2_avg.avg.pow(ll,:)/trace(mne_grid2_avg.avg.noisecov{ll});
end

cfg=[];
cfg.funparameter = 'avg.normpow';
cfg.interactive = 'yes';
ft_sourceplot(cfg,mne_grid2_avg);

mri=ft_read_mri('/home/common/matlab/fieldtrip/data/ftp/tutorial/beamformer/Subject01.mri');
mne_grid2_avg.anatomy = mri.anatomy;
anat


cfg = [];
cfg.method = 'mne';
cfg.grid = grid_3sph;
cfg.vol = vol_3sph;
cfg.elec = elec;
cfg.lambda = '10%';
source_3sph = ft_sourceanalysis(cfg, tlock)

cfg = [];
cfg.method = 'mne';
cfg.grid = grid_1sph;
cfg.vol = vol_1sph;
cfg.elec = elec;
cfg.lambda = '10%';
source_1sph = ft_sourceanalysis(cfg, tlock)


%%
cfg=[];
cfg.keeptrials='yes';
cfg.output = 'powandcsd';
cfg.method = 'mtmconvol';
cfg.taper = 'hanning';
cfg.toi = [0:.1:2];
cfg.foi = 5:2.5:70;
cfg.t_ftimwin = .4*ones(size(cfg.foi));;
freq=ft_freqanalysis(cfg,datanoisenoise);

