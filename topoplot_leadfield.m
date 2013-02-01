function topoplot_leadfield(leadfield,indices,channels);

numind=numel(indices);
figure;
tlock=[];
for jj=1:numind;
  tlock.avg=leadfield.leadfield{leadfield.inside(indices(jj))};
  tlock.time=1:3;
  tlock.dimord='chan_time';
  tlock.label=channels;
  for ii=1:3
    cfg=[];
    cfg.layout='elec1005';
    cfg.xlim=[tlock.time(ii) tlock.time(ii)];
    subplot(numind,3,(jj-1)*3+ii);ft_topoplotER(cfg, tlock)
  end
end

