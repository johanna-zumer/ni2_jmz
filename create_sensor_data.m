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

save leadfields.mat bem_leadfield con3sphere_leadfield singlesphere_leadfield

%%
load leadfields

state=randomseed(13);
for ii=1:100
  [alphaERD(ii,:),time]=ni2_activation('frequency',9,'phase',2*pi*rand,'powerup',0);
end

state=randomseed(13);
for ii=1:100
  [gammaERS(ii,:),time]=ni2_activation('frequency',50+20*rand,'phase',2*pi*rand);
end

for ii=1:100
  [alphaERS(ii,:),time]=ni2_activation('frequency',11,'phase',1*pi*rand);
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
  heartbeat1(ii,:)=dataIC.trial{ii}(1,1:1000);
  heartbeat2(ii,:)=dataIC.trial{ii}(1,11:1010);
end

  
locind(1)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),[-2 -8 2]);
locind(2)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),[-1 -8 2]);
locind(3)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),[3 3 6]);
locind(4)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),heartloc1);
locind(5)=dsearchn(bem_leadfield.pos(bem_leadfield.inside,:),heartloc2);

