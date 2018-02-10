function idx = calLocalFeatureAggregationAndClustering(X,Xl,C,n_clusters,varargin)


%%% notice that this function defines the time window using the variation
%%% in the label space. Therefore, long-term movements can be aggregated,
%%% representated and clustered. The assumption is that movements is
%%% composed by a sequence of different body configurations. 

% 
% %%% set params CMUMAD%%%
% moving_variance_window = 31;
% gaussian_filter_sigma = 12.5;
% min_peak_distance = 60;
% sigma_dclustering = 0.0005;
% sigma_dclustering_stationary = 0.5;
% peak_width_weight = 1;
% %%%


% 
% %%% set params TUMKitchen%%%
% moving_variance_window = 25;
% gaussian_filter_sigma = 6.5;
% min_peak_distance = 25;
% sigma_dclustering = 0.05;
% sigma_dclustering_stationary = 5;
% peak_width_weight = 0.75;
% %%%


%%% set params BOMNI scenario1 %%%
moving_variance_window = 25;
gaussian_filter_sigma = 6.5;
min_peak_distance = 30;
sigma_dclustering = 0.0005;
sigma_dclustering_stationary = 0.0005;
peak_width_weight = 0.5;
%%%


%% aggregate action patterns
%%% moving variance computation
Xll = movvarcat(Xl, moving_variance_window);
%%% find the peaks in the label space to determine the time window
labels = imgaussfilt(Xll,gaussian_filter_sigma); %% for CMUMAD
% labels = imgaussfilt(Xl,1.5); %% for TUMKitchen
[pks_label,locs_label, pks_width] = findpeaks(labels, 'MinPeakDistance',min_peak_distance);


% pks_width = 2*pks_width;
pks_width = round(pks_width);
%%% use the time window to aggregate features
features = zeros(length(pks_label), size(C,1));
for pp = 1:length(pks_label)
    lb = max(1,locs_label(pp)-round(peak_width_weight*pks_width(pp)));
    ub = min(size(X,1), locs_label(pp)+round(peak_width_weight*pks_width(pp)));
    XX = X(lb : ub, :);
    dist = pdist2(XX, C);
    ff = exp(-0.1*dist)./ repmat(sum(exp(-0.1*dist),2), 1, size(C,1));
    features(pp,:) = sum(ff,1);
    features(pp,:) = features(pp,:)/(1e-6+norm(features(pp,:),2));
end


if nargin == 4
    method = 'kmeans';
else
    method = varargin{1};
end


if strcmp(method, 'kmeans')
    nc = n_clusters-1;
    if size(features,1) <= nc
        iidx = 1:size(features,1);
    else
        iidx = kmeans(features, nc);
    end    
elseif strcmp(method,'ours')
    time_window = 1;
    is_temporal_reg = 0;
    [iidx, ~] = incrementalClustering(features, time_window,...
        sigma_dclustering,is_temporal_reg,0,2.5);
else 
    error('[Error] calLocalFeatureAggregationAndClustering(): method is incorrect!');
end


idx = zeros(size(Xl));
for pp = 1:length(pks_label)
    lb = max(1,locs_label(pp)-pks_width(pp));
    ub = min(size(X,1), locs_label(pp)+pks_width(pp));
    idx(lb:ub)=iidx(pp);
end


%% aggregate stationary body configs, checking number of different body configs
idx2 = idx;
idx2(idx2~=0) = 1;
idx2 = 1-idx2;
idx3 = bwlabel(idx2);
n_regions = length(unique(idx3))-1;
features_stationary = zeros(n_regions, size(C,1));

for kk = 1:n_regions
    XX = X(idx3==kk, :);
    dist = pdist2(XX, C);
    ff = exp(-0.1*dist)./ repmat(sum(exp(-0.1*dist),2), 1, size(C,1));
    features_stationary(kk,:) = sum(ff,1);
    features_stationary(kk,:) = features_stationary(kk,:)/(1e-6+norm(features_stationary(kk,:),2));
end

if nargin == 4
    method = 'kmeans';
else
    method = varargin{1};
end


if strcmp(method, 'kmeans')
    nc = n_clusters-1;
    if size(features,1) <= nc
        iidx = 1:size(features_stationary,1);
    else
        iidx = kmeans(features_stationary, nc);
    end
    
elseif strcmp(method,'ours')
    time_window = 1;
    is_temporal_reg = 0;
    [iidx, ~] = incrementalClustering(features_stationary, time_window,...
        sigma_dclustering_stationary,is_temporal_reg,0,2.5);
else 
    error('[Error] calLocalFeatureAggregationAndClustering(): method is incorrect!');
end

max_label = max(idx)+1;
% n_regions
% iidx

for kk = 1:n_regions
    idx(idx3==kk) = iidx(kk)+max_label;
end

end


function Xll = movvarcat(Xl, moving_variance_window)

n_samples = length(Xl);
Xll = zeros(size(Xl));
width = round(moving_variance_window/2);
for ii = 1:n_samples
    lb = max(1, ii-width);
    ub = min(n_samples, ii+width);
    seg = Xl(lb:ub);
    n_variations = length(find(diff(seg)));
    Xll(ii) = n_variations/length(seg);
end

end







































