%% Create sensor data

%% generate leadfields

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

heartloc1=[-8 8.2 -7];
grid.inside=sort([grid.inside grid.outside(dsearchn(grid.pos(grid.outside,:),heartloc1))]);
grid.outside=setdiff(grid.outside,grid.outside(dsearchn(grid.pos(grid.outside,:),heartloc1)));
heartloc2=[8 -7.8 -7];
grid.inside=sort([grid.inside grid.outside(dsearchn(grid.pos(grid.outside,:),heartloc2))]);
grid.outside=setdiff(grid.outside,grid.outside(dsearchn(grid.pos(grid.outside,:),heartloc2)));


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

% View five source -> channel projection
topoplot_leadfield(bem_leadfield,100*[1:5],data.label(match_str(data.label,elec.label)))

cfg=[];
cfg.elec = elec;
cfg.vol = c3bnd;
cfg.grid = grid;
con3sphere_leadfield = ft_prepare_leadfield(cfg,data);

topoplot_leadfield(con3sphere_leadfield,100*[1:5],data.label(match_str(data.label,elec.label)))

cfg=[];
cfg.elec = elec;
cfg.vol = s1bnd;
cfg.grid = grid;
singlesphere_leadfield = ft_prepare_leadfield(cfg,data);

topoplot_leadfield(singlesphere_leadfield,100*[1:5],data.label(match_str(data.label,elec.label)))

save leadfields.mat bem_leadfield con3sphere_leadfield singlesphere_leadfield heartloc*

%%
load leadfields

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
  heartbeat1(ii,:)=10000*dataIC.trial{ii}(1,1:2:2000);
  heartbeat2(ii,:)=10000*dataIC.trial{ii}(1,11:2:2010);
end

  
locind(1)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),[-2 -8 2]);
locind(2)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),[-1 -8 2]);
locind(3)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),[3 3 6]);
locind(4)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),heartloc1);
locind(5)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),heartloc2);

data=[];
data.fsample=500;
for ii=1:100,
  data.trial{ii}=bem_leadfield.leadfield{bem_leadfield.inside(locind(1))}(:,1)*alphaERD(ii,:);
  data.trial{ii}=data.trial{ii}+bem_leadfield.leadfield{bem_leadfield.inside(locind(2))}(:,1)*gammaERS(ii,:);
  data.trial{ii}=data.trial{ii}+bem_leadfield.leadfield{bem_leadfield.inside(locind(3))}(:,1)*alphaERS(ii,:);
  data.trial{ii}=data.trial{ii}+bem_leadfield.leadfield{bem_leadfield.inside(locind(4))}(:,1)*heartbeat1(ii,:);
  data.trial{ii}=data.trial{ii}+bem_leadfield.leadfield{bem_leadfield.inside(locind(5))}(:,1)*heartbeat2(ii,:);
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

data.trialclean=data.trial;
noiseadd=10*norm(tlock.trial(:))*randn(size(tlock.trial));
data.trial=data.trialclean+noiseadd;






