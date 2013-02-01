% Blind Source Separation of simulated data

%% Linear mixing of 5 orignal sources, ignoring projection 
load ~/teaching/sources.mat

% The six sources are arranged in a matrix 'sources' of size 
% [trials X sources X time].  We first reshape so that time is concatenated
% over trials.
sources=reshape(permute(sources,[2 3 1]),[6 100000]);
% Recall that the order of the sources is:
% 1) GammaERS
% 2) AlphaERS
% 3) AlphaERD
% 4) Heartbeat1
% 5) Heartbeat2
% 6) Pink Noise

ni2_subplot(sources(:,1:1000));

% What is the distribution type of each source?
ni2_subplot(sources(:,1:1000),2);

% Now let's create a random linear mixture of these sources.
state=randomseed(5);
mixing=randn(6);
sensors=mixing*sources;

% First try of just 2 sources.
mixing2=mixing([2 4],[2 4]);
sensors2=mixing2*sources([2 4],:);

ni2_subplot(sensors(:,1:1000));
ni2_subplot(sensors2(:,1:1000));

% What is the distribution type of each sensor?
ni2_subplot(sensors(ii,:),2);
ni2_subplot(sensors2(ii,:),2);

% If we knew ground truth mixing matrix, can we reconstruct sources?
% Recall Matlab exercises from Eric Maris
estsource=mixing\sensors;

figure;plot([sources(1,:)-estsource(1,:)])

%% PCA

[U,D,V]=svd(sensors);

[U,D,V]=svd(sensors(:,1:10000));
[U2,D2,V2]=svd(sensors2(:,1:10000));

ni2_subplot(V(1:1000,1:6)')
ni2_subplot(V(1:1000,1:6)',2)

ni2_subplot(V2(1:1000,1:6)')
ni2_subplot(V2(1:1000,1:6)',2)

% Are these components actually orthogonal?
figure;imagesc(corr(V(:,1:6)));caxis([-1 1])



%% ICA 

    ft_hastoolbox('fastica', 1);       % see http://www.cis.hut.fi/projects/ica/fastica
    ft_hastoolbox('eeglab', 1);

      [fastica_mixing, fastica_unmixing] = fastica(sensors2);
      
      estsources2_fastica=fastica_unmixing*sensors2;

      
      
cfg=[];
comp = ft_componentanalysis(cfg, tlock)




%% sensor data
load ~/teaching/tlock.mat

% What distribution does the sensor data have?
figure;hist(squeeze(tlock.trial(1,3,:)))
figure;hist(squeeze(tlock.trial(1,23,:)))

cfg=[];
comp = ft_componentanalysis(cfg, tlock)

