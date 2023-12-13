%% COM DSA MODEL %%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code calculates minimum yearly adjustment for four year adjustment plan
% for Finland considering only criteria A (debt must decline during the 10
% year period 2028-2038.

% Code produces debt projections following the structure of 
% the European Commission's 2022 Debt Sustainability Monitor. 
% Scenarios are defined as in Commission proposal (May 2023) and
% info based on publicly available sources. I have extensively used
% Darvas et al 2023 analysis and their Python code (open access) to 
% write this MATLAB implementation of COM DSA model.

% Darvas et al (2023) working paper:
% "A quantitative evaluation of the European Commission’s fiscal 
% governance proposal"

% Python code:
% https://github.com/lennardwelslau/eu-debt-sustainability-analysis

% Currently, 2 scenarios are available: baseline, lower SPB
% Also SFA method can be choose to follow eiher Commission assumption 
% or an alternative assumption based on linearly declining SFA.
% Selection for scenario and SFA method can be made at the end of 
% this section. Data 

% TIMING: First observation corresponds to year 2024 in data matrix
%           the years run from 2024 to 2038 (15 obs)
%
% NOTE: Code uses function project_debt2v.m to find minimum 
%           yearly adjustment which satisfy criteria A
%
% For comments and suggestions please contact peetu.keskinen[at]vtv[dot]fi
% 
% Author: Peetu Keskinen
% Date: 15/12/2023

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;clear;close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% SELECT SCENARIO AND SFA METHOD %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


        % SELECT SFA METHOD:
        %  0) COM ZERO ASSUMPTION
        % -1) ALTERNATIVE ASSUMPTION
        sfa_method = 0;
        % SELECT SCENARIO:
        % 1) ADJUSTMENT
        % 2) LOWER SPB
        scenario = 1;


%% DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load data from the file
data = readmatrix('AmecoFinlandDataFinal.xlsx', 'Range', 'B2:L18','Sheet','COM');

% Name variables 
iir = data(3:end,9)./100; % implicit interest rate
potgdp = data(3:end,4); % potential gdp level
inflation = data(3:end,6)./100; % inflation rate
og = data(3:end,5); % output gap
dcoa=data(3:end,11); % delta cost of ageing reference year 2028

% constants related to the adjustment phase 
adjustment_periods = 4; % number of adjustment years (2025 - 2028)
pre_plan_periods = 1;   % number of years before the adjustment plan (2024)
adjustment_end = pre_plan_periods + adjustment_periods; % end period of adjustment
post_plan_periods = 10; % number of years after the adjustment plan (2028-38)
total_periods = pre_plan_periods + adjustment_periods + post_plan_periods;

step_size=0.01; % define step size for adjustment
a = -0.5:step_size:1;  % Grid of possible values of a

%% PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fiscal multiplier 
phi = 0.75; % COM assumption on fiscal multiplier
% yearly fiscal multiplier from 2024-2038
m = [0 phi phi*(5/3) phi*(6/3) phi*(6/3) phi phi*(1/3) zeros(1,8)]';

epsilon = 0.582; %semi-elasticity of budget balance for Finland
debt_initial = 76.2; %debt in 2024 (t-1) COM forecast (VM 76.8)
spb_initial = -0.667;  %spb in 2024 (t) COM forecast
lower_spb_shock = 0.5; %lower spb shock in the scenario 2

%% SFA METHOD
% stock-flow adjustment with T+2 on sfa=0
if sfa_method==0
sfa=data(3:end,10); 

% linear sfa correction
elseif sfa_method==-1
sfa=data(3:end,10); 
% Take value for SFA 2000-2024 AMECO DATA
%sfa(1)=3.8; %initial SFA median value 3.8
for j=2:11
sfa(j)=sfa(j-1)-sfa(1)/10;
end
end

%% FIND MINIMUM YEARLY ADJUSTMENT
% Loop over each a value of adjustment in the grid
D = zeros(total_periods,length(a)); % shell for debt
G = zeros(total_periods,length(a)); % shell for nominal growth
Gr = zeros(total_periods,length(a)); % shell for real growth

% Calculate paths for all values of a
for i = 1:length(a)
    [D(:,i),G(:,i),Gr(:,i)] = project_debt2v(scenario,a(i), iir, potgdp,...
        og, epsilon,phi,dcoa,sfa,...
        inflation, debt_initial, spb_initial);
end

declining = false;    % find minimum adjustment until declining=true
solution_column = 0;  % Initialize to 0 to indicate no solution found

for j = 1:size(D,2)  % Loop through columns of D
    if all(diff(D(adjustment_end:end,j)) < 0)
        declining = true;
        solution_column = j;
        break;  % Exit the loop once the condition is met
    end
end

if solution_column == 0
    disp('No value could be found that satisfies the condition.');
else
    optimal_a = a(solution_column); % minimum consolidation a*
    disp(['Optimal adjustment is a=', num2str(optimal_a)]);
end

%% PROJECT DEBT USING MINIMUM ADJUSTMENT a*
[debt_path,optimal_g,optimal_gr] = project_debt2v(scenario,optimal_a, iir,...
    potgdp,og, epsilon,phi,dcoa,sfa,...
    inflation, debt_initial, spb_initial);

%% CALCULATE spb AND pb IN THE SELECTED SCENARIO
% shells and initial values for spb and pb
spb_path=zeros(1,total_periods);
pb_path=zeros(1,total_periods);
spb_path(1)=spb_initial;
pb_path(1) = spb_path(1) + epsilon*og(1);

% loop over the periods
for k=2:total_periods
    
    % linear adjustment during the adjustment plan (scenario 1 and 2)
    if k<=adjustment_end 
        spb_path(k) = (k-1)*optimal_a + spb_initial;
        pb_path(k) = spb_path(k) + epsilon*(og(k)-m(k)*optimal_a);
    
        % 0.25 pp. shock a year after the plan (scenario 2)
    elseif scenario == 2 && k == adjustment_end + 1 
        spb_path(k) = adjustment_periods*optimal_a + spb_initial - 0.5*lower_spb_shock;
        pb_path(k) = spb_path(k) + epsilon*(og(k)-m(k)*optimal_a);  
        
        % 0.5 pp. shock until the end of the plan (scenario 2)
    elseif scenario == 2 && k > adjustment_end + 1 
        spb_path(k) = adjustment_periods*optimal_a + spb_initial - lower_spb_shock;
        pb_path(k) = spb_path(k) + epsilon*(og(k)-m(k)*optimal_a);
        
        % no shocks after the end of the plan (scenario 1)
    else
        spb_path(k) = adjustment_periods * optimal_a + spb_initial;
        pb_path(k) = spb_path(k) + epsilon * (og(k) - m(k) * optimal_a);
    end
end

%% Plot 2D the debt path and related variables
FigSize = 600; %set figure size
time = 2024:2038;
figure(1);
set(gca,'fontname','Calibri') 
subplot(1,3,1);
plot(time, debt_path, '-o', 'LineWidth', 2,'Color','#002C5F');
title('(a)','FontSize',20,'FontName', 'Calibri')
ylim([60 max(debt_path)+10])
ylabel('Velkasuhde, %','FontSize',20,'FontName', 'Calibri');
legend('Velka/BKT','Location','southeast','FontName', 'Calibri'...
    ,'FontSize',16);
grid on;

subplot(1,3,2);
plot(time, spb_path, '-o', 'LineWidth', 2,'Color','#002C5F');
hold on
plot(time, pb_path, '--', 'LineWidth', 2,'Color','#FF6875');
title('(b)','FontSize',20,'FontName', 'Calibri')
ylabel('% suhteessa BKT:hen','FontSize',20,'FontName', 'Calibri');
legend('Rakenteellinen perusjäämä','Perusjäämä','Location','southeast',...
    'FontSize',16,'FontName', 'Calibri');
grid on;

subplot(1,3,3);
plot(time, 100*optimal_g, '-o', 'LineWidth', 2,'Color','#002C5F');
hold on
plot(time, 100*iir, '--', 'LineWidth', 2,'Color','#FF6875');
plot(time, 100*optimal_gr, 'LineWidth', 2,'Color','#FDB74A');
title('(c)','FontSize',20,'FontName', 'Calibri')
%title('$g_{t}$ \& $r_{t}$','interpreter','latex',...
%   'FontSize',20,'FontName', 'Calibri')
ylabel('vuosikasvu, %','FontSize',20,'FontName', 'Calibri');
legend('Nimellinen BKT-kasvu','Nimellinen Korkotaso','Reaalinen BKT-kasvu','Location',...
    'southeast','FontName', 'Calibri','FontSize',10);
grid on;
if scenario==1
sgtitle('Perusura','FontSize',24,'FontName', 'Calibri');
elseif scenario==2
sgtitle('Epäsuotuisa SPB','FontSize',24,'FontName', 'Calibri');
end
% Set the figure size
set(gcf, 'Position', [20 20 2*FigSize FigSize]);

% Save figure data %
if scenario==1
PlotDataAdj=[time' debt_path' spb_path' pb_path'...
            100*optimal_g' 100*iir 100*optimal_gr'];
% Assuming PlotDataLowerAdj is a matrix with the correct number of columns to match the headers.
headers = {'vuosi', 'velkasuhde', 'rakenteellinen perusjaama',...
    'perusjaama', 'nimellinen bkt kasvu', 'nimellinen korkotaso', 'reaalinen bkt kasvu'};
% Convert the matrix to a table
T = array2table(PlotDataAdj, 'VariableNames', headers);
% Write the table to a text file with headers
writetable(T, "PlotDataAdj.txt", 'Delimiter', ' ');
print('Adjustment','-dpng', '-r300','-cmyk');

elseif scenario==2
PlotDataLowerSPB=[time' debt_path' spb_path' pb_path'...
            100*optimal_g' 100*iir 100*optimal_gr'];
% Assuming PlotDataLowerSPB is a matrix with the correct number of columns to match the headers.
headers = {'vuosi', 'velkasuhde', 'rakenteellinen perusjaama',...
    'perusjaama', 'nimellinen bkt kasvu', 'nimellinen korkotaso', 'reaalinen bkt kasvu'};
% Convert the matrix to a table
T = array2table(PlotDataLowerSPB, 'VariableNames', headers);
% Write the table to a text file with headers
writetable(T, "PlotDataLowerSPB.txt", 'Delimiter', ' ');
print('LowerSPB', '-dpng', '-r300','-cmyk');
end
%% Plot 3D plots (real gdp growth)
% Define the colors in RGB, normalized to [0, 1]
color1 = [204, 213, 223] / 255; % Light blue 2
color2 = [153, 171, 191] / 255; % Light blue 1
color3 = [102, 128, 159] / 255; % Medium blue 2
color4 = [51, 86, 127] / 255;   % Medium blue 1
color5 = [0, 44, 95] / 255;     % Dark blue

% Preallocate an array for the colormap
numColors = 10;
customColormap = zeros(numColors, 3);

% Generate intermediate colors using linspace
for i = 1:3 % For each color channel
    % Combine all five colors' current channel into an array
    originalChannels = [color1(i), color2(i), color3(i), color4(i), color5(i)];
    % Interpolate to find two intermediate colors between each original color
    customColormap(:, i) = interp1(1:length(originalChannels), originalChannels, linspace(1, length(originalChannels), numColors));
end

% Apply the custom colormap to the current figure
colormap(customColormap);
figure(2);
%subplot(1,2,1);
ax1 = gca;  % Get handle to current axes
x1 = time;
y1 = a;
[X1, Y1] = meshgrid(x1, y1);
Z1 = 100 * Gr;
surf(Y1', X1', Z1, 'FaceAlpha', 1);
xlabel('$a$', 'Interpreter', 'latex', 'FontSize', 20)
zlabel('BKT-kasvu, %', 'FontSize', 20, 'FontName', 'Calibri');
zlim([0 max(100*Gr,[], 'all') + 1])
colormap(ax1, customColormap); 
set(gcf, 'Position', [250 250 FigSize FigSize]);

%% Plot 3D plots (debt-to-gdp ratio)
figure(3)
ax2 = gca;  % Get handle to current axes
x2 = time;
y2 = a;
[X2, Y2] = meshgrid(x2, y2);
Z2 = D;
surf(Y2', X2', Z2, 'FaceAlpha', 1);
xlabel('$a$', 'Interpreter', 'latex', 'FontSize', 20)
zlabel('Velka/BKT', 'FontSize', 20, 'FontName', 'Calibri');
view( 156.5618,  12.3745); %adjust view angle
zlim([0  max(D(15,:))+10])
colormap(ax2, customColormap);  % Apply custom colormap to second subplot

% Set color data based on Z-values (debt ratio change)
caxis(ax2, [40, 90]);
% Add colorbar
colorbar('Position', [0.95, 0.17, 0.02, 0.8], 'FontSize', 14, 'FontName', 'Calibri');

% Set the font name for all text objects in the current figure
set(gca, 'FontName', 'Calibri');       % Change font for axes tick labels
set(findall(gcf,'type','text'), 'FontName', 'Calibri'); % Change font for titles, labels, legends, etc.

% Change the font size as well
set(gca, 'FontSize', 20);            % Change font size for axes tick labels
set(findall(gcf,'type','text'), 'FontSize', 20); % Change font size for titles, labels, legends, etc.

% Set the figure size
set(gcf, 'Position', [100 500 1.5*FigSize 1.5*FigSize]);

if scenario==1
% Increase the resolution to 300 dpi
print('Adjustment3D','-dpng', '-r300','-cmyk');
elseif scenario==2
% Increase the resolution to 300 dpi
print('Lower3D','-dpng', '-r300','-cmyk');
end

%% Bird view plot (debt-to-gdp ratio)
figure(4)
ax2 = gca;  % Get handle to current axes
x2 = time;
y2 = a;
[X2, Y2] = meshgrid(x2, y2);
Z2 = D;
surf(Y2', X2', Z2, 'FaceAlpha', 1);
xlabel('$a$', 'Interpreter', 'latex', 'FontSize', 20)
zlabel('Velka/BKT', 'FontSize', 20, 'FontName', 'Calibri');
view(2); % Adjust th view angle
zlim([0  max(D(15,:))+10])
colormap(ax2, customColormap);  % Apply custom colormap to second subplot

% Set color data based on Z-values (debt ratio change)
caxis(ax2, [40, 90]);
colorbar

if scenario==1
sgtitle('Perusura','FontSize',30,'FontName', 'Calibri');
elseif scenario==2
sgtitle('Epäsuotuisa SPB','FontSize',30,'FontName', 'Calibri');
end

% Set the figure size
set(gcf, 'Position', [200 600 FigSize FigSize]);

if scenario==1
% Increase the resolution to 300 dpi
print('Adjustment3Dbird','-dpng', '-r300','-cmyk');
elseif scenario==2
% Increase the resolution to 300 dpi
print('Lower3Dbird','-dpng', '-r300','-cmyk');
end