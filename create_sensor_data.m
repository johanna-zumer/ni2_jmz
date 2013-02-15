%% Create sensor data

%% generate EEG leadfields

load ~/alphaBOLD/eeg/proc_data/rawclean_f01.mat
data=rawcleanrere; clear rawcleanrere;
data.trial=[];
data.time=[];
data.trial{1}=ones(numel(data.label),200);
data.time{1}=1/data.fsample:1/data.fsample:200*1/data.fsample;


elec=ft_read_sens('standard_1005.elc');
load standard_bem; %  'vol' with the Dipoli BEM
load standard_grid3d8mm;  % 'grid' with 5302 points inside MNI head

grid=ft_convert_units(grid,'cm');
elec=ft_convert_units(elec,'cm');
vol=ft_convert_units(vol,'cm');

gridold=grid;
gridold=rmfield(gridold,'inside');gridold=rmfield(gridold,'outside');
cfg=[];
cfg.grid=gridold;
cfg.vol=vol;
grid=ft_prepare_sourcemodel(cfg);

% heartloc1=[-8 8.2 -7];
% grid.inside=sort([grid.inside grid.outside(dsearchn(grid.pos(grid.outside,:),heartloc1))]);
% grid.outside=setdiff(grid.outside,grid.outside(dsearchn(grid.pos(grid.outside,:),heartloc1)));
% heartloc2=[8 -7.8 -7];
% grid.inside=sort([grid.inside grid.outside(dsearchn(grid.pos(grid.outside,:),heartloc2))]);
% grid.outside=setdiff(grid.outside,grid.outside(dsearchn(grid.pos(grid.outside,:),heartloc2)));


cfg=[];
cfg.method='concentricspheres';
c3bnd=ft_prepare_headmodel(cfg,vol.bnd);

cfg=[];
cfg.method='singlesphere';
s1bnd=ft_prepare_headmodel(cfg,vol.bnd(1));

cfg=[];
cfg.elec = elec;
cfg.vol = vol;
cfg.grid = grid;
bem_leadfield = ft_prepare_leadfield(cfg,data);


cfg=[];
cfg.elec = elec;
cfg.vol = c3bnd;
cfg.grid = grid;
con3sphere_leadfield = ft_prepare_leadfield(cfg,data);


cfg=[];
cfg.elec = elec;
cfg.vol = s1bnd;
cfg.grid = grid;
singlesphere_leadfield = ft_prepare_leadfield(cfg,data);

heartloc1=grid.pos(grid.inside(dsearchn(grid.pos(grid.inside,:),[-8 8.2 -7])),:);
heartloc2=grid.pos(grid.inside(dsearchn(grid.pos(grid.inside,:),[8 -7.8 -7])),:);
locind(1)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),[-2 -8 2]); %LV1
locind(2)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),[-1 -8 2]); %LV1
locind(3)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),[3 3 6]); %RF
locind(4)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),heartloc1); % LIFG
locind(5)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),heartloc2); % RIT
locind(6)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),[2 2 2]); % Rcentral

% View five source -> channel projection
topoplot_leadfield(bem_leadfield,locind,data.label(match_str(data.label,elec.label)))
topoplot_leadfield(con3sphere_leadfield,locind,data.label(match_str(data.label,elec.label)))
topoplot_leadfield(singlesphere_leadfield,locind,data.label(match_str(data.label,elec.label)))

save leadfields.mat bem_leadfield con3sphere_leadfield singlesphere_leadfield locind

%% generate MEG leadfields

mri=ft_read_mri('/home/common/matlab/fieldtrip/data/ftp/tutorial/beamformer/Subject01.mri');
% load('/home/common/matlab/fieldtrip/data/ftp/tutorial/beamformer/vol.mat');
% load('/home/common/matlab/fieldtrip/data/ftp/tutorial/beamformer/segmentedmri.mat');

cfg           = [];
cfg.coordsys  = 'ctf';
cfg.output    = 'brain';
segmentedmri  = ft_volumesegment(cfg, mri);
save /home/electromag/johzum/teaching/ni2_jmz/segmentedmri.mat segmentedmri

cfg=[];
cfg.method = 'singleshell';
vol1 = ft_prepare_headmodel(cfg,segmentedmri);

load standard_grid3d8mm
template_grid = grid; clear grid

cfg = [];
cfg.grid.warpmni   = 'yes';
cfg.grid.template  = template_grid;
cfg.grid.nonlinear = 'yes'; % use non-linear normalization
cfg.mri            = mri;
grid               = ft_prepare_sourcemodel(cfg);
 

load('/home/common/matlab/fieldtrip/data/ftp/tutorial/beamformer/dataFIC.mat');
vol1=ft_convert_units(vol1,'cm');

cfg                 = [];
cfg.grad            = dataFIC.grad;
cfg.vol             = vol1;
cfg.reducerank      = 3;
cfg.channel         = {'MEG','-MLP31', '-MLO12'};
cfg.grid            = grid;
grid3 = ft_prepare_leadfield(cfg);

cfg                 = [];
cfg.grad            = dataFIC.grad;
cfg.vol             = vol1;
cfg.reducerank      = 2;
cfg.channel         = {'MEG','-MLP31', '-MLO12'};
cfg.grid            = grid;
grid2 = ft_prepare_leadfield(cfg);

heartloc1=template_grid.pos(template_grid.inside(dsearchn(template_grid.pos(template_grid.inside,:),[-8 8.2 -7])),:);
heartloc2=template_grid.pos(template_grid.inside(dsearchn(template_grid.pos(template_grid.inside,:),[8 -7.8 -7])),:);
locind(1)=dsearchn(template_grid.pos(template_grid.inside,:),[-2 -8 2]); %LV1
locind(2)=dsearchn(template_grid.pos(template_grid.inside,:),[-1 -8 2]); %LV1
locind(3)=dsearchn(template_grid.pos(template_grid.inside,:),[3 3 6]); %RF
locind(4)=dsearchn(template_grid.pos(template_grid.inside,:),heartloc1); % LIFG
locind(5)=dsearchn(template_grid.pos(template_grid.inside,:),heartloc2); % RIT
locind(6)=dsearchn(template_grid.pos(template_grid.inside,:),[2 2 2]); % Rcentral

topoplot_leadfield(grid3,locind,dataFIC.label,'CTF151')
topoplot_leadfield(grid2,locind,dataFIC.label,'CTF151')

save meg_leadfields.mat grid2 grid3 locind

%% create source time courses
state=randomseed(13);
for ii=1:100
  [alphaERD(ii,:),time]=ni2_activation('frequency',9,'phase',2*pi*rand,'powerup',0,'fsample',500,'length',2);
end

state=randomseed(13);
for ii=1:100
  [gammaERS(ii,:),time]=ni2_activation('frequency',50+20*rand,'phase',2*pi*rand,'fsample',500,'length',2,'ncycle',10);
end

state=randomseed(13);
for ii=1:100
  [alphaERS(ii,:),time]=ni2_activation('frequency',11,'phase',1*pi*rand,'fsample',500,'length',2,'latency',.8);
end

cfg                         = [];
cfg.dataset                 = '~/rewardalpha/sebboeP01_1200hz_20121113_01.ds';
cfg.trialfun                = 'ft_trialfun_general'; % this is the default
cfg.trialdef.eventtype      = 'UPPT002';
cfg.trialdef.eventvalue     = 2; % the value of the stimulus trigger for fully incongruent (FIC).
cfg.trialdef.prestim        = 1; % in seconds
cfg.trialdef.poststim       = 2; % in seconds
cfg = ft_definetrial(cfg);
cfg.channel    = {'EEG059'};
cfg.continuous = 'yes';
dataIC = ft_preprocessing(cfg);

for ii=1:100
  heartbeat1(ii,:)=1000*dataIC.trial{ii}(1,1:2:2000);
  heartbeat2(ii,:)=1000*dataIC.trial{ii}(1,11:2:2010);
end
heartbeat1=heartbeat1-mean(heartbeat1(:));
heartbeat2=heartbeat2-mean(heartbeat2(:));

pinksource=reshape(pinknoise(numel(heartbeat1)),size(heartbeat1));


s1=[gammaERS alphaERS alphaERD heartbeat1 heartbeat2 pinksource];

sources=permute(reshape(s1,[100 1000 6]),[1 3 2]);
save ~/teaching/sources.mat sources


%% create EEG data
load leadfields
load sources

data=[];
tlock=[];
data.fsample=500;
for ii=1:100,
  data.trial{ii}=bem_leadfield.leadfield{bem_leadfield.inside(locind(1))}(:,1)*alphaERD(ii,:);
  data.trial{ii}=data.trial{ii}+bem_leadfield.leadfield{bem_leadfield.inside(locind(2))}(:,1)*gammaERS(ii,:);
  data.trial{ii}=data.trial{ii}+bem_leadfield.leadfield{bem_leadfield.inside(locind(3))}(:,1)*alphaERS(ii,:);
  data.trial{ii}=data.trial{ii}+bem_leadfield.leadfield{bem_leadfield.inside(locind(4))}(:,1)*heartbeat1(ii,:);
  data.trial{ii}=data.trial{ii}+bem_leadfield.leadfield{bem_leadfield.inside(locind(5))}(:,1)*heartbeat2(ii,:);
  data.trial{ii}=data.trial{ii}+bem_leadfield.leadfield{bem_leadfield.inside(locind(6))}(:,1)*pinksource(ii,:);
  data.time{ii}=1/data.fsample:1/data.fsample:1000*1/data.fsample;
end
data.label=bem_leadfield.cfg.channel;

cfg=[];
cfg.keeptrials='yes';
tlock=ft_timelockanalysis(cfg,data);

cfg=[];
cfg.layout='elec1005';
ft_topoplotER(cfg,tlock)
cfg=[];
cfg.viewmode='vertical';
ft_databrowser(cfg,tlock)

save ~/teaching/tlock_clean.mat tlock


tlock.trialclean=tlock.trial;

% noiseadd=.0001*norm(tlock.trial(:))*randn(size(tlock.trial));
% tlock.trial=tlock.trialclean+noiseadd;
% ft_databrowser(cfg,tlock)

pnoiseadd=reshape(.001*norm(tlock.trial(:))*pinknoise(numel(tlock.trial)),size(tlock.trial));
tlock.trial=tlock.trialclean+pnoiseadd;
ft_databrowser(cfg,tlock)

tlock=rmfield(tlock,'trialclean');
save ~/teaching/tlock.mat tlock

%% create MEG data

load meg_leadfields;
load sources

data=[];
tlock=[];
data.fsample=500;
for ii=1:100,
  data.trial{ii}=zeros(size(149,1000));
  for ll=1:6
    data.trial{ii}=data.trial{ii}+grid3.leadfield{grid3.inside(locind(ll))}(:,1)*squeeze(sources(ii,ll,:))';
  end
  data.time{ii}=1/data.fsample:1/data.fsample:1000*1/data.fsample;
end
data.label=grid3.cfg.channel;

noise_sources=reshape(pinknoise(numel(sources)),size(sources));
datanoise=data;
for ii=1:100,
  for ll=1:6
    datanoise.trial{ii}=datanoise.trial{ii}+grid3.leadfield{grid3.inside(locind(ll))}(:,1)*squeeze(noise_sources(ii,ll,:))';
  end
end

datanoisenoise=datanoise;
for ii=1:100,
    datanoisenoise.trial{ii}=datanoisenoise.trial{ii}+1e-10*reshape(pinknoise(numel(datanoise.trial{ii})),size(datanoise.trial{ii}));
end
figure;plot([data.trial{1}(53,:); datanoise.trial{1}(53,:); datanoisenoise.trial{1}(53,:)]')

save ~/teaching/megdata.mat data
save ~/teaching/megdatanoise.mat datanoise
save ~/teaching/megdatanoisenoise.mat datanoisenoise

cfg=[];
cfg.keeptrials='yes';
tlock=ft_timelockanalysis(cfg,datanoisenoise);
save ~/teaching/megtlock.mat tlock

