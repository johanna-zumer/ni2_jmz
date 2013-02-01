

[data,time]=ni2_activation;
[data2,time2]=ni2_activation('latency',0.4,'frequency',5);

datamix=data+data2;
datacombined=[data;data2];

% either
datamix1=data+data2;
datamix2=sum(datacombined,1);
datamix3=[1 1]*datacombined;
% or
mix=[1 1];
datamix3=mix*datacombined;

mix=[0 1;0.1 0.9;0.25 0.75;0.5 0.5;0.75 0.25;0.9 0.1;1 0];
datamix=mix*datacombined;

% figure;plot(time, datamix);
figure;plot(time, datamix+repmat((1:7)',[1 1000]));

negmix=-[0 1;0.1 0.9;0.25 0.75;0.5 0.5;0.75 0.25;0.9 0.1;1 0];
negdatamix=negmix*datacombined;
figure;plot(time, negdatamix+repmat((1:7)',[1 1000]));

