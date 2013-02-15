function [mixing, unmixing] = runica_wrapper(dat)

[weights, sphere] = runica(dat);

% Below is what ft_componentanalysis does:
sphere = sphere./norm(sphere);
unmixing = weights*sphere;
if (size(unmixing,1)==size(unmixing,2)) && rank(unmixing)==size(unmixing,1)
  mixing = inv(unmixing);
else
  mixing = pinv(unmixing);
end

