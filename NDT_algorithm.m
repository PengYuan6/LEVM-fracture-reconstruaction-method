%%  use NDT to point cloud registration
%%
clear;clc
source_pc = pcread("D:\m.ply");
target_pc = pcread("D:\n.ply");
 
% downsampling:
ptCloudA = point_downsample(source_pc);
ptCloudB = point_downsample(target_pc);

% Registration operation selection 
% (NDT is chosen in the paper for better performance)
% opt = param_set("icp");
opt = param_set("ndt");
% opt = param_set("cpd");

% Perform point cloud registration:
%[tform,translation,rotation,registered_pc] = icp_r(ptCloudA,ptCloudB,source_pc,opt);
[tform,translation,rotation,registered_pc] = ndt_r(ptCloudA,ptCloudB,source_pc,opt);
% [tform,translation,rotation,registered_pc] = cpd_r(ptCloudA,ptCloudB,opt);

cal_and_print_data(tform,translation,rotation);
data2 = registered_pc.Location;
data1 = target_pc.Location; 
%% visualization
f1 = figure;
s1 = scatter3(data2(:,1), data2(:,2), data2(:,3)+0.2,0.08,[90,90,205]./255,'.');  
hold on;
s2 = scatter3(data1(:,1), data1(:,2), data1(:,3),0.08,[169,169,169]./255,'.'); 
hold off
% --------------------
set(gca,'FontName','Arial Narrow','FontSize',20,'FontWeight','bold');
xlabel('X (mm)','FontSize', 20, 'FontName', 'Calibri','FontWeight','bold');
ylabel('Y (mm)','FontSize', 20, 'FontName', 'Calibri','FontWeight','bold');
zlabel('Z (mm)','FontSize', 20, 'FontName', 'Calibri','FontWeight','bold');
%----------------
% daspect([1 1 1])
xlabel('X'); ylabel('Y');zlabel('Z');
%%
function[opt] = param_set(name, varargin)
    p = inputParser;
    addParameter(p,'Metric','pointToPoint');
    addParameter(p,'Extrapolate',true);
    addParameter(p,'InlierRatio',0.9);
    addParameter(p,'Tolerance',[0.001, 0.001]); % 默认是0.1
    addParameter(p,'MaxIterations',100);
    addParameter(p,'Verbose',true);
    addParameter(p,'method','rigid');
    addParameter(p,'viz',0);
    addParameter(p,'max_it',100);
    addParameter(p,'tol',1e-6);
    parse(p,varargin{:});
    Metric = p.Results.Metric;
    Extrapolate = p.Results.Extrapolate;
    InlierRatio = p.Results.InlierRatio;
    Tolerance = p.Results.Tolerance;
    MaxIterations = p.Results.MaxIterations;
    Verbose = p.Results.Verbose;
    method = p.Results.method;
    viz = p.Results.viz;
    max_it = p.Results.max_it;
    tol = p.Results.tol;
    opt = containers.Map();
    if name=="icp" || name == "ndt"
        opt('Metric') = Metric;
        opt('Extrapolate') = Extrapolate;
        opt('InlierRatio') = InlierRatio;
        opt('Tolerance') = Tolerance;
        opt('MaxIterations') = MaxIterations;
        opt('Verbose') = Verbose;
    elseif name == "cpd"
        opt('method') = method;
        opt('viz') = viz;
        opt('max_it') = max_it;
        opt('tol') = tol;
    end
end
%%
function [tform,translation,rotation,registered_pc] = icp_r(ptCloudA, ptCloudB, source_pc, opt)
 

tform = pcregistericp(ptCloudA,ptCloudB, 'Metric', opt('Metric'), ...
                       'Extrapolate', opt('Extrapolate'), ...
                       'InlierRatio', opt('InlierRatio'), ...
                       'Tolerance', opt('Tolerance'), ...
                       'MaxIterations', opt('MaxIterations'), ...
                       'Verbose', opt('Verbose'));

translation = tform.T(4, 1:3);

rotation = tform.T(1:3, 1:3);

registered_pc = pctransform(source_pc, tform);
 
end
%%
function[tform,translation,rotation,registered_pc] = ndt_r(ptCloudA, ptCloudB, source_pc,opt)
%Rough registration using ICP algorithm to obtain initial transformation matrix
tform = pcregistericp(ptCloudA,ptCloudB, 'Metric', opt('Metric'), ...
                       'Extrapolate', opt('Extrapolate'), ...
                       'InlierRatio', opt('InlierRatio'), ...
                       'Tolerance', opt('Tolerance'), ...
                       'MaxIterations', opt('MaxIterations'), ...
                       'Verbose', opt('Verbose'));
% 
% Parameter Description:
gridStep = 0.5; 
tform = pcregisterndt(ptCloudA, ptCloudB, gridStep, ...
                       'MaxIterations', opt('MaxIterations'), ...
                       'Tolerance', opt('Tolerance'), ...
                       'InitialTransform', tform, ... 
                       'Verbose', opt('Verbose'));

translation = tform.T(4, 1:3);

rotation = tform.T(1:3, 1:3);

registered_pc = pctransform(source_pc, tform);
end
%%
function[tform,translation,rotation,registered_pc] = cpd_r(ptCloudA,ptCloudB, opt)

X = double(ptCloudA.Location);
Y = double(ptCloudB.Location);

op.method = opt('method');
op.viz = opt('viz');            
op.max_it = opt('max_it');        
op.tol = opt('tol');         
 
[tform, C] = cpd_register(Y, X, op);
translation = tform.t;
 
rotation = tform.R;
registered_pc = pointCloud(tform.Y);
end
%%
function[ptCloud] = point_downsample(pc)
gridStep = 0.005;
ptCloud = pcdownsample(pc,'gridAverage',gridStep);
end
%%
function[] = cal_and_print_data(tform,translation,rotation)
 
eulerAngles = rotm2eul(rotation);
quat = rotm2quat(rotation);

fprintf('transformation matrix:')
disp(tform)
fprintf('translation  (x, y, z): %.4f, %.4f, %.4f\n', translation(1), translation(2), translation(3));
fprintf('Euler angles (rx, ry, rz): %.4f, %.4f, %.4f\n', rad2deg(eulerAngles(3)), rad2deg(eulerAngles(2)), rad2deg(eulerAngles(1)));
fprintf('quaternion (w, x, y, z): %.4f, %.4f, %.4f, %.4f\n', quat(1), quat(2), quat(3), quat(4));
end

%%