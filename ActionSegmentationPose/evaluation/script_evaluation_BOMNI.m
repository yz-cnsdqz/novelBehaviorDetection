clear all;
close all;
clc;
addpath(genpath('../../eval_package'));
addpath(genpath('../../aca'));
addpath(genpath('../../TSC'));
addpath(genpath('../../mexIncrementalClustering'));
dataset_path = '/home/yzhang/Videos/Dataset_BOMNI'; %% only scenario1
video_list = importdata([dataset_path '/scenario1/video_list2.txt']);
action_list = {'"walking"','"sitting"', '"drinking"','"washing-hands"','"opening-closing-door"','"fainted"'};

is_show_tracking = 1;
Precision = [];
Recall = [];
CptTime = [];


% detector = vision.ForegroundDetector(...
%        'AdaptLearningRate',false,...
%        'LearningRate',0.025,...
%        'NumTrainingFrames', 150, ... 
%        'InitialVariance', 30*30,...
%        'NumGaussians',5);

% opticFlow = opticalFlowFarneback;   
   
   
% se = strel('disk',3);
rescale_factor = 1;
for vv = 4 : 4
% for vv = 1 : length(video_list)
    video = VideoReader([dataset_path '/scenario1/' video_list{vv} '.mp4']);
    annotation = importdata([dataset_path '/annotations/scenario1/' video_list{vv} '.dat']);
    pattern = [];
    yt = [];
    idx_frame = 0;
    background = [];
    motion1 = []; % motion energy mean
    motion2 = []; % motion energy std
    shape1 = []; % bounding box shape
    shape2 = []; % trajectory shape
    traj = [];
    idx_frame_max = length(annotation)-1;
    for idx_frame = 1:idx_frame_max
        
%         frame = imgaussfilt(double(imresize(readFrame(video),rescale_factor)),1.0);
        img_name = [dataset_path '/scenario1/frame_and_flow/' video_list{vv} sprintf('/image_%05d.jpg', idx_frame) ];
        frame = imresize(imread(img_name), rescale_factor);
        labels = strsplit(annotation{idx_frame},' ');
        bbox = rescale_factor*[str2num(labels{2}) str2num(labels{3}) ...
            str2num(labels{4})-str2num(labels{2}) str2num(labels{5})-str2num(labels{3})];
        is_lost = str2num(labels{7});
        action = labels{end};
        
        
        if is_lost 
%             disp('- skip this frame without person..')
            continue;
        end
       
        
        %%% read mask from mask R-CNN
        mask_name_list = dir([dataset_path '/scenario1/frame_and_flow/' video_list{vv} sprintf('/image_%05d_mask*.jpg', idx_frame) ]);
        frame_mask = zeros(size(frame,1), size(frame,2));
        overlay = 0;
        for ii = 1:length(mask_name_list)
            frame_mask_c = imread([dataset_path '/scenario1/frame_and_flow/' video_list{vv} sprintf('/image_%05d_mask_%d.jpg',idx_frame, ii-1)]);
            frame_mask_c = imresize(frame_mask_c,rescale_factor);
            frame_mask_c = rgb2gray(frame_mask_c);
            frame_mask_c = imbinarize(frame_mask_c);
            frame_mask_crop = imcrop(frame_mask_c, bbox);
            
            if sum(frame_mask_crop(:))/prod(bbox(3:4))>overlay
                frame_mask = frame_mask_c;
                overlay = sum(frame_mask_crop(:))/prod(bbox(3:4));
            end
        end
        
        if sum(frame_mask(:))==0
            continue;
        end
        
        %%% find numerical label
        yt = [yt; find(cellfun(@(x) strcmp(x,action), action_list, 'UniformOutput',1))];
%       

        %%% extract pattern from frame
%         pattern = [motion1 motion2 shape1];
        
        %%% visualize tracking
%         imwrite(uint8(frame),'img.png');
        if is_show_tracking
            B = imoverlay(frame, frame_mask);
            figure(1); imshow(uint8(B));
            hold on;
            rectangle('Position',...
                [bbox(1) bbox(2) bbox(3) bbox(4)],...
                'EdgeColor','red',...
                'LineWidth',2);
            text(bbox(1),bbox(2)-10,action,...
                'HorizontalAlignment','left',...
                'Color','red');
%             figure(2);plot(motion);xlim([1 idx_frame_max]);
%             figure(3);plot(shape);xlim([1 idx_frame_max]);
            
            pause(0.025);
        end
    end


%     %%% note that jointLocs is relative jointlocs
%     method_list = {'kmeans','spectralClustering','TSC','ACA','ours'};
%     method = method_list{end};
%     
%     is_show = 1; 
%     %%% scenario configuration - end"
% 
% 
% 
%     n_clusters = length(unique(yt));
%     
%     
%     disp('------------------ run methods and make evaluations------------------');
%     startTime = tic;
%     if strcmp(method, 'kmeans')
% %         [idx,C] = kmeans(pattern,n_clusters);
%         [idx,C] = kmeans(pattern,n_clusters);
% 
% %         idx = calLocalFeatureAggregationAndClustering_TUMKitchen(pattern,idx,C, n_clusters,'normal_action'); 
% 
%     elseif strcmp(method, 'spectralClustering')
%         idx = spectralClustering(pattern,500,n_clusters);
%         idx = idx-1; %%% 0-based label
% 
%     elseif strcmp(method, 'TSC')
%         %%%---Normalize the data---%%%
% %             X = normalize(pattern);
% 
%         %%%---Parameter settings---%%%
%         paras = [];
%         paras.lambda1 = 0.01;
%         paras.lambda2 = 15;
%         paras.n_d = 80;
%         paras.ksize = 7;
%         paras.tol = 1e-4;
%         paras.maxIter = 12;
%         paras.stepsize = 0.1;
% 
%         %%%---Learn representations Z---%%%
% %             disp('--first pca to 100d; otherwise computation is prohibitively expensive.');
% %             [comp,XX,~] = pca(pattern, 'NumComponents',100);
%         [D, Z, err] = TSC_ADMM(pattern',paras);
%         disp('clustering via graph cut..');
% %             nbCluster = length(unique(label));
%         vecNorm = sqrt(sum(Z.^2));
%         W2 = (Z'*Z) ./ (vecNorm'*vecNorm + 1e-6);
%         [oscclusters,~,~] = ncutW(W2,n_clusters);
%         idx = denseSeg(oscclusters, 1);
%         idx = idx;
% 
% %         uid = idx(1);
% %         idx(idx==uid) = 10e6;
% %         idx(idx==1) = uid;
% %         idx(idx==10e6) = 1;
%         idx = idx-1; %%% 0-based label
% 
% 
%     elseif strcmp(method, 'ACA')
%         idx = calACAOrHACA(pattern,n_clusters, 'ACA');
%         idx(end) = []; %%% remove redudant frame
% 
% %         uid = idx(1);
% %         idx(idx==uid) = 10e6;
% %         idx(idx==1) = uid;
% %         idx(idx==10e6) = 1;
% %         idx = idx-1; %%% 0-based label
% %         save('ACA_idx_TUMKitchen.mat','idx');
% 
%     elseif strcmp(method, 'HACA')
%         idx = calACAOrHACA(pattern,36, 'HACA');
%         idx(end) = []; %%% remove redudant frame
% 
%     elseif strcmp(method,'ours')
%         time_window = 15;
%         sigma = 0.01;
% 
% %         disp('--online learn the clusters and labels..');
%         [idx1, C] = incrementalClustering(double(pattern), time_window,sigma,0,0,1.0);
% %         idx2 = zeros(size(idx1));
% %         for kk = 2:length(idx1)
% %             if idx1(kk)~=idx1(kk-1)
% %                 idx2(kk) = idx1(kk)+randi(length(unique(idx1)))-1;
% %             else
% %                 idx2(kk) = idx2(kk-1);
% %             end
% %         end
% %         uid = mode(idx2);
% %         idx2(idx2==uid) = 10e6;
% %         idx2(idx2==0) = uid;
% %         idx2(idx2==10e6) = 0;
% %         disp('--postprocessing, merge clusters');
%         idx = calLocalFeatureAggregationAndClustering(pattern,idx1,C, n_clusters,'ours'); 
%         idx = idx1;
%     end
    CptTime = [CptTime toc(startTime)];
    Result= funEvalSegmentation_TUMKitchen(yt, idx, 0.5, is_show);
    Precision = [Precision Result.Prec];
    Recall = [Recall Result.Rec];
end
disp('====================================================')
disp('Evaluation Results:')
fprintf('Method: %s\n',method);
fprintf('ave_precision: %f\n',mean(Precision));
fprintf('ave_recall: %f\n',mean(Recall));
fprintf('ave_runtime: %f\n',mean(CptTime));



    
    
