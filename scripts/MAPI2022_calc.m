%% MAPI 2022: Biochar
% JK October 2023
%
% Measurements conducted in summer 2022
% Syd = Biochar
% Nord = NO biochar
%
% This script starts from the pre-processed intermediate data in data/
% (background-subtracted, QC-filtered emission timetables) rather than
% the raw instrument output, so it can be run directly from a clone of
% this repo without the raw-data treatment pipeline.

clear

% Resolve paths relative to this script's location, so it runs
% regardless of the current MATLAB working directory.
scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
addpath(scriptDir);

PATH_DATA = fullfile(repoRoot, 'data');
foldout = fullfile(repoRoot, 'plots');
outDir = fullfile(repoRoot, 'output');

tic

PLOT_SWITCH = 0; % Plot: 0 = NO, 1 = YES
STAT_SWITCH = 1; % Plot: 0 = NO, 1 = YES
SAVE_FIG = 0;
ii = 1;

%% Load
load(fullfile(PATH_DATA, 'TT_emis_N.mat'))
load(fullfile(PATH_DATA, 'TT_emis_S.mat'))
load(fullfile(PATH_DATA, 'TT_CRDS_BG_01_09_2023.mat'))
T_START_S = datetime('2022-05-23 10:30:00'); % Time for start of pile building - starts uncovered
T_COV_S = datetime('2022-05-23 12:30:00'); % Time for start of covering pile
T_UNCOV_S = datetime('2022-06-24 15:30:00'); % Time for start of removing cover
TT_emis_S(TT_emis_S.Time < T_START_S,:) = [];

T_START_N = datetime('2022-05-23 12:00:00'); % Time for start of pile building - starts uncovered
T_COV_N = datetime('2022-05-23 15:00:00'); % Time for start of covering pile
T_UNCOV_N = datetime('2022-07-04 10:30:00'); % Time for start of removing cover
TT_emis_N(TT_emis_N.Time < T_START_N,:) = [];

TT_emis_N(TT_emis_N.ALARM_STATUS_BG > 1, :) = [];
TT_emis_N(TT_emis_N.ALARM_STATUS > 1, :) = [];
TT_emis_S(TT_emis_S.ALARM_STATUS_BG > 1, :) = [];
TT_emis_S(TT_emis_S.ALARM_STATUS > 1, :) = [];

TT_emis_N.Emis_CO2 = (TT_emis_N.CO2 - TT_emis_N.CO2_BG) ./ TT_emis_N.CE;
TT_emis_S.Emis_CO2 = (TT_emis_S.CO2 - TT_emis_S.CO2_BG) ./ TT_emis_S.CE;

% save('TT_emis_N.mat', 'TT_emis_N')
% save('TT_emis_S.mat', 'TT_emis_S')

% writetimetable(TT_emis_N, [PATH_DATA '\EmissionData_Pile_N.txt'], 'Delimiter','\t')
% writetimetable(TT_emis_S, [PATH_DATA '\EmissionData_Pile_S.txt'], 'Delimiter','\t')

%% Change units to mg / m2 / hr
TT_emis_N.Emis_NH3_mg_hr = TT_emis_N.Emis_NH3 / 10^6 * (60*60) * 1000;
TT_emis_N.Emis_CH4_g_hr = TT_emis_N.Emis_CH4 / 10^6 * (60*60);
TT_emis_N.Emis_N20_mg_hr = TT_emis_N.Emis_N20 / 10^6 * (60*60) * 1000;

TT_emis_S.Emis_NH3_mg_hr = TT_emis_S.Emis_NH3 / 10^6 * (60*60) * 1000;
TT_emis_S.Emis_CH4_g_hr = TT_emis_S.Emis_CH4 / 10^6 * (60*60);
TT_emis_S.Emis_N20_mg_hr = TT_emis_S.Emis_N20 / 10^6 * (60*60) * 1000;

%% Statistics
if STAT_SWITCH == 1
    % SOUTH PILE:
    TT_emis_S.GROUP = categorical(zeros(height(TT_emis_S),1));

    % TT_emis_S.GROUP(TT_emis_S.Time < T_COV_S, :) = categorical("UNCOV_1");
    TT_emis_S.GROUP(TT_emis_S.Time > T_COV_S & TT_emis_S.Time < T_UNCOV_S, :) = categorical("COV_S");
    TT_emis_S.GROUP(TT_emis_S.Time > T_UNCOV_S, :) = categorical("UNCOV_S");

    stats_all_S = grpstats(TT_emis_S,"GROUP", ["mean", "std", "numel", "min", "max", "sem", "meanci"], "DataVars", ["Emis_CH4_g_hr", "Emis_NH3_mg_hr", "Emis_N20_mg_hr", "Emis_CO2"]);

    % NORTH PILE:
    TT_emis_N.GROUP = categorical(zeros(height(TT_emis_N),1));

    % TT_emis_N.GROUP(TT_emis_N.Time < T_COV_S, :) = categorical("UNCOV_1");
    TT_emis_N.GROUP(TT_emis_N.Time > T_COV_S & TT_emis_N.Time < T_UNCOV_S, :) = categorical("COV_N");
    TT_emis_N.GROUP(TT_emis_N.Time > T_UNCOV_S, :) = categorical("UNCOV_N");

    stats_all_N = grpstats(TT_emis_N,"GROUP", ["mean", "std", "numel", "min", "max", "sem", "meanci"], "DataVars", ["Emis_CH4_g_hr", "Emis_NH3_mg_hr", "Emis_N20_mg_hr", "Emis_CO2"]);
    % Combine:
    stats_all = [stats_all_S; stats_all_N];
    if ~exist(outDir, 'dir')
        mkdir(outDir)
    end
    writetable(stats_all, fullfile(outDir, 'stats.xlsx'), 'Sheet', 'MyNewSheet', 'WriteRowNames',true, 'WriteVariableNames',true);
end

% Keep only rows in TT_CRDS_BG_raw whose Time is present in either TT_emis_N or TT_emis_S
times_keep = unique([TT_emis_N.Time; TT_emis_S.Time]);
[lia, ~] = ismember(TT_CRDS_BG_raw.Time, times_keep);
TT_CRDS_BG_raw = TT_CRDS_BG_raw(lia, :);

%% Plots
    TimeLim = [datetime('2022-05-23 10:30:00') datetime('2022-08-11 12:00:00')];
if PLOT_SWITCH == 1

    fig100 = figure(ii);
    tiledlayout(2,1, 'TileSpacing', 'tight');

    nexttile % 1
    plot(TT_emis_N.Time, TT_emis_N.Emis_NH3_mg_hr, 'x')
    ylabel('NH_3 (mg m^{-2} h^{-1})')
    grid minor
    % xlim(TimeLim)
    % ylim([-50, 250])
    yline(0)
    xline(T_UNCOV_N)
    text(T_UNCOV_N, max(TT_emis_N.Emis_NH3_mg_hr)*0.9, 'Uncover N')

    nexttile % 2
    plot(TT_emis_S.Time, TT_emis_S.Emis_NH3_mg_hr, 'o')
    ylabel('NH_3 (mg m^{-2} h^{-1})')
    grid minor
    xlim(TimeLim)
    % ylim([-50, 250])
    yline(0)
    xline(T_UNCOV_S)
    text(T_UNCOV_S, max(TT_emis_N.Emis_NH3_mg_hr)*0.9, 'Uncover S')
    ii = ii + 1;

    if SAVE_FIG == 1
        FigFileName = 'Fig100 Flux NH3';
        fullFileName = fullfile(foldout, FigFileName);
        fig100 = gcf;
        fig100.PaperUnits = 'centimeters';
        fig100.PaperPosition = [0 0 19 11];
        print(fullFileName,'-dpng','-r800')
    end

    % % % % % % % % % % % % % % % % % % % %
    fig101 = figure(ii);
    tiledlayout(2,1, 'TileSpacing', 'tight');

    nexttile % 1
    plot(TT_emis_N.Time, TT_emis_N.Emis_CH4_g_hr, 'x')
    ylabel('CH_4 (\mug m^{-2} s^{-1})')
    grid minor
    xlim(TimeLim)
    % ylim([-200, 1000])
    yline(0)
    xline(T_UNCOV_N)
    text(T_UNCOV_N, max(TT_emis_S.Emis_CH4_g_hr)*0.9, 'Uncover N')

    nexttile % 2
    plot(TT_emis_S.Time, TT_emis_S.Emis_CH4_g_hr, 'o')
    ylabel('CH_4 (\mug m^{-2} s^{-1})')
    grid minor
    xlim(TimeLim)
    % ylim([-200, 1000])
    yline(0)
    xline(T_UNCOV_S)
    text(T_UNCOV_S, max(TT_emis_S.Emis_CH4_g_hr)*0.9, 'Uncover S')
    ii = ii + 1;

    if SAVE_FIG == 1
        FigFileName = 'Fig101 Flux CH4';
        fullFileName = fullfile(foldout, FigFileName);
        fig101 = gcf;
        fig101.PaperUnits = 'centimeters';
        fig101.PaperPosition = [0 0 19 11];
        print(fullFileName,'-dpng','-r800')
    end

    % % % % % % % % % % % % % % % % % % % %
    fig102 = figure(ii);
    tiledlayout(2,1, 'TileSpacing', 'tight');

    nexttile % 1
    plot(TT_emis_N.Time, TT_emis_N.Emis_N20_mg_hr, 'x')
    ylabel('N_2O (\mug m^{-2} s^{-1})')
    grid minor
    xlim(TimeLim)
    % ylim([-500, 4500])
    % ylim([-150, 250])
    yline(0)
    xline(T_UNCOV_N)
    text(T_UNCOV_N, max(TT_emis_N.Emis_N20_mg_hr)*0.9, 'Uncover N')

    nexttile % 2
    plot(TT_emis_S.Time, TT_emis_S.Emis_N20_mg_hr, 'o')
    ylabel('N_2O (\mug m^{-2} s^{-1})')
    grid minor
    xlim(TimeLim)
    % ylim([-500, 4500])
    % ylim([-150, 250])
    yline(0)
    xline(T_UNCOV_S)
    text(T_UNCOV_S, max(TT_emis_N.Emis_N20_mg_hr)*0.9, 'Uncover S')
    ii = ii + 1;

    if SAVE_FIG == 1
        FigFileName = 'Fig102 Flux N2O';
        % FigFileName = 'Fig102 Flux N2O zoom';
        fullFileName = fullfile(foldout, FigFileName);
        fig102 = gcf;
        fig102.PaperUnits = 'centimeters';
        fig102.PaperPosition = [0 0 19 11];
        print(fullFileName,'-dpng','-r800')
    end


    % % % % % % % % % % % % % % % % % % % %
    fig103 = figure(ii);
    tiledlayout(2,1, 'TileSpacing', 'tight');

    nexttile % 1
    plot(TT_emis_N.Time, TT_emis_N.Emis_CO2, 'x')
    ylabel('CO2 (\mug m^{-2} s^{-1})')
    grid minor
    xlim(TimeLim)
    % ylim([-500, 4500])
    % ylim([-150, 250])
    yline(0)
    xline(T_UNCOV_N)
    text(T_UNCOV_N, max(TT_emis_N.Emis_CO2)*0.9, 'Uncover N')

    nexttile % 2
    plot(TT_emis_S.Time, TT_emis_S.Emis_CO2, 'o')
    ylabel('CO2 (\mug m^{-2} s^{-1})')
    grid minor
    xlim(TimeLim)
    % ylim([-500, 4500])
    % ylim([-150, 250])
    yline(0)
    xline(T_UNCOV_S)
    text(T_UNCOV_S, max(TT_emis_N.Emis_CO2)*0.9, 'Uncover S')
    ii = ii + 1;


    % % % % % % % % % % % % % % % % % % % %
    fig104 = figure(ii);
    tiledlayout(3,1, TileSpacing="loose")

    nexttile % 1
    plot(TT_emis_S.Time, TT_emis_S.Emis_CH4_g_hr, 'b.', TT_emis_N.Time, TT_emis_N.Emis_CH4_g_hr, 'r.', 'MarkerSize', 8)
    ylabel('CH_4 (g m^{-2} h^{-1})', 'FontSize', 12)
    grid minor
    xlim(TimeLim)
    xline(T_UNCOV_S, 'b--', 'LineWidth', 1);
    xline(T_UNCOV_N, 'r--', 'LineWidth', 1)
    yline(0)
    legend('Biochar', 'No Biochar','Biochar uncover', 'No Biochar uncover', 'Location','northoutside', 'NumColumns', 2, 'FontSize', 12)
    set(gca,'XTickLabel',[]);

    % nexttile % 2
    % plot(TT_emis_S.Time, TT_emis_S.Emis_CO2/1000, 'b.',TT_emis_N.Time, TT_emis_N.Emis_CO2/1000, 'r.',  'MarkerSize', 8)
    % ylabel('CO_2 (mg m^{-2} s^{-1})', 'FontSize', 12)
    % grid minor
    % xlim(TimeLim)
    % xline(T_UNCOV_S, 'b--', 'LineWidth', 1);
    % xline(T_UNCOV_N, 'r--', 'LineWidth', 1)
    % yline(0)
    % set(gca,'XTickLabel',[]);

    nexttile % 2
    plot(TT_emis_S.Time, TT_emis_S.Emis_NH3_mg_hr, 'b.', TT_emis_N.Time, TT_emis_N.Emis_NH3_mg_hr, 'r.', 'MarkerSize', 8)
    ylabel('NH_3 (mg m^{-2} h^{-1})', 'FontSize', 12)
    grid minor
    xlim(TimeLim)
    xline(T_UNCOV_S, 'b--', 'LineWidth', 1);
    xline(T_UNCOV_N, 'r--', 'LineWidth', 1)
    yline(0)
    set(gca,'XTickLabel',[]);

    nexttile % 3
    plot(TT_emis_S.Time, TT_emis_S.Emis_N20_mg_hr, 'b.', TT_emis_N.Time, TT_emis_N.Emis_N20_mg_hr, 'r.', 'MarkerSize', 8)
    ylabel('N_2O (mg m^{-2} h^{-1})', 'FontSize', 12)
    grid minor
    xlim(TimeLim)
    xline(T_UNCOV_S, 'b--', 'LineWidth', 1);
    xline(T_UNCOV_N, 'r--', 'LineWidth', 1)
    yline(0)
    ax = gca;
    ax.XAxis.FontSize = 12;
    ii = ii + 1;

    if SAVE_FIG == 1
        FigFileName = 'Fig104 Flux all';
        fullFileName = fullfile(foldout, FigFileName);
        fig104 = gcf;
        fig104.PaperUnits = 'centimeters';
        fig104.PaperPosition = [0 0 18 18];
        print(fullFileName,'-dpng','-r800')
    end


% Average across - not usefull
fig105 = figure(ii);
tiledlayout(4,1, TileSpacing="loose")

dx = hours(6);               % separation between indicators
xRight = TimeLim(2);

% -------- TILE 1 : CH4 --------
nexttile
hold on

hS = plot(TT_emis_S.Time, TT_emis_S.Emis_CH4_g_hr, ...
    'b.', 'MarkerSize', 8);
hN = plot(TT_emis_N.Time, TT_emis_N.Emis_CH4_g_hr, ...
    'r.', 'MarkerSize', 8);
ylabel('CH_4 (\mug m^{-2} s^{-1})', 'FontSize', 12)
grid minor
xlim(TimeLim)
hUS = xline(T_UNCOV_S, 'b--', 'LineWidth', 1);
hUN = xline(T_UNCOV_N, 'r--', 'LineWidth', 1);
yline(0)
legend([hS hN hUS hUN], ...
    {'Biochar','No Biochar','Biochar uncover','No Biochar uncover'}, ...
    'Location','northoutside','NumColumns',2,'FontSize',12)
set(gca,'XTickLabel',[])
muS = mean(TT_emis_S.Emis_CH4_g_hr,'omitnan');
sdS = std(TT_emis_S.Emis_CH4_g_hr,'omitnan');
muN = mean(TT_emis_N.Emis_CH4_g_hr,'omitnan');
sdN = std(TT_emis_N.Emis_CH4_g_hr,'omitnan');
xS = xRight - 2*dx;
xN = xRight - dx;

errorbar(xS, muS, sdS,'b','LineWidth',1.5,'CapSize',12,'HandleVisibility','off');
plot([xS-minutes(10) xS+minutes(10)], [muS muS],'b','LineWidth',2,'HandleVisibility','off');
errorbar(xN, muN, sdN,'r','LineWidth',1.5,'CapSize',12,'HandleVisibility','off');
plot([xN-minutes(10) xN+minutes(10)], [muN muN],'r','LineWidth',2,'HandleVisibility','off');

hold off

% -------- TILE 2 : CO2 --------
nexttile
hold on
plot(TT_emis_S.Time, TT_emis_S.Emis_CO2/1000,'b.','MarkerSize',8)
plot(TT_emis_N.Time, TT_emis_N.Emis_CO2/1000,'r.','MarkerSize',8)
ylabel('CO_2 (mg m^{-2} s^{-1})','FontSize',12)
grid minor
xlim(TimeLim)
xline(T_UNCOV_S,'b--','LineWidth',1)
xline(T_UNCOV_N,'r--','LineWidth',1)
yline(0)
set(gca,'XTickLabel',[])

muS = mean(TT_emis_S.Emis_CO2/1000,'omitnan');
sdS = std(TT_emis_S.Emis_CO2/1000,'omitnan');
muN = mean(TT_emis_N.Emis_CO2/1000,'omitnan');
sdN = std(TT_emis_N.Emis_CO2/1000,'omitnan');

errorbar(xS, muS, sdS,'b','LineWidth',1.5,'CapSize',12,'HandleVisibility','off');
plot([xS-minutes(10) xS+minutes(10)], [muS muS],'b','LineWidth',2,'HandleVisibility','off');
errorbar(xN, muN, sdN,'r','LineWidth',1.5,'CapSize',12,'HandleVisibility','off');
plot([xN-minutes(10) xN+minutes(10)], [muN muN],'r','LineWidth',2,'HandleVisibility','off');
hold off

% -------- TILE 3 : NH3 --------
nexttile
hold on
plot(TT_emis_S.Time, TT_emis_S.Emis_NH3_mg_hr,'b.','MarkerSize',8)
plot(TT_emis_N.Time, TT_emis_N.Emis_NH3_mg_hr,'r.','MarkerSize',8)
ylabel('NH_3 (mg m^{-2} h^{-1})','FontSize',12)
grid minor
xlim(TimeLim)
xline(T_UNCOV_S,'b--','LineWidth',1)
xline(T_UNCOV_N,'r--','LineWidth',1)
yline(0)
set(gca,'XTickLabel',[])

muS = mean(TT_emis_S.Emis_NH3_mg_hr,'omitnan');
sdS = std(TT_emis_S.Emis_NH3_mg_hr,'omitnan');
muN = mean(TT_emis_N.Emis_NH3_mg_hr,'omitnan');
sdN = std(TT_emis_N.Emis_NH3_mg_hr,'omitnan');

errorbar(xS, muS, sdS,'b','LineWidth',1.5,'CapSize',12,'HandleVisibility','off');
plot([xS-minutes(10) xS+minutes(10)], [muS muS],'b','LineWidth',2,'HandleVisibility','off');
errorbar(xN, muN, sdN,'r','LineWidth',1.5,'CapSize',12,'HandleVisibility','off');
plot([xN-minutes(10) xN+minutes(10)], [muN muN],'r','LineWidth',2,'HandleVisibility','off');
hold off

% -------- TILE 4 : N2O --------
nexttile
hold on
plot(TT_emis_S.Time, TT_emis_S.Emis_N20_mg_hr,'b.','MarkerSize',8)
plot(TT_emis_N.Time, TT_emis_N.Emis_N20_mg_hr,'r.','MarkerSize',8)
ylabel('N_2O (\mug m^{-2} s^{-1})','FontSize',12)
grid minor
xlim(TimeLim)
xline(T_UNCOV_S,'b--','LineWidth',1)
xline(T_UNCOV_N,'r--','LineWidth',1)
yline(0)

muS = mean(TT_emis_S.Emis_N20_mg_hr,'omitnan');
sdS = std(TT_emis_S.Emis_N20_mg_hr,'omitnan');
muN = mean(TT_emis_N.Emis_N20_mg_hr,'omitnan');
sdN = std(TT_emis_N.Emis_N20_mg_hr,'omitnan');

errorbar(xS, muS, sdS,'b','LineWidth',1.5,'CapSize',12,'HandleVisibility','off');
plot([xS-minutes(10) xS+minutes(10)], [muS muS],'b','LineWidth',2,'HandleVisibility','off');
errorbar(xN, muN, sdN,'r','LineWidth',1.5,'CapSize',12,'HandleVisibility','off');
plot([xN-minutes(10) xN+minutes(10)], [muN muN],'r','LineWidth',2,'HandleVisibility','off');
ax = gca;
ax.XAxis.FontSize = 12;
hold off
ii = ii + 1;

    if SAVE_FIG == 1
        FigFileName = 'Fig104 Flux all avg';
        fullFileName = fullfile(foldout, FigFileName);
        fig105 = gcf;
        fig105.PaperUnits = 'centimeters';
        fig105.PaperPosition = [0 0 18 18];
        print(fullFileName,'-dpng','-r800')
    end



    % median(TT_emis_N.Emis_CO2, 'omitmissing')
    % median(TT_emis_S.Emis_CO2, 'omitmissing')
end

%% Concentration
    fig204 = figure(ii);
    tiledlayout(3,1, TileSpacing="loose")

    nexttile % 1
    plot(TT_emis_S.Time, TT_emis_S.CH4, 'b.', TT_emis_N.Time, TT_emis_N.CH4, 'r.', 'MarkerSize', 8)
    hold on
    plot(TT_emis_S.Time, TT_emis_S.CH4_BG, 'k.', TT_emis_N.Time, TT_emis_N.CH4_BG, 'k.', 'MarkerSize', 8)
    ylabel('CH_4 (\mug m^{-3})', 'FontSize', 12)
    grid minor
    xlim(TimeLim)
    ylim([1250 1700])
    xline(T_UNCOV_S, 'b--', 'LineWidth', 1);
    xline(T_UNCOV_N, 'r--', 'LineWidth', 1)
    yline(0)
    legend('CH_4 Biochar', 'CH_4 No Biochar','CH_4 Background','','Biochar uncover', 'No Biochar uncover', 'Location','northoutside', 'NumColumns', 2, 'FontSize', 12)
    set(gca,'XTickLabel',[]);

    nexttile % 2
    plot(TT_emis_S.Time, TT_emis_S.NH3, 'b.', TT_emis_N.Time, TT_emis_N.NH3, 'r.', 'MarkerSize', 8)
    hold on
    plot(TT_emis_S.Time, TT_emis_S.NH3_BG, 'k.', TT_emis_N.Time, TT_emis_N.NH3_BG, 'k.', 'MarkerSize', 8)
    ylabel('NH_3 (\mug m^{-3})', 'FontSize', 12)
    grid minor
    xlim(TimeLim)
    xline(T_UNCOV_S, 'b--', 'LineWidth', 1);
    xline(T_UNCOV_N, 'r--', 'LineWidth', 1)
    yline(0)
    set(gca,'XTickLabel',[]);

    nexttile % 3
    plot(TT_emis_S.Time, TT_emis_S.N2O, 'b.', TT_emis_N.Time, TT_emis_N.N2O, 'r.', 'MarkerSize', 8)
    hold on
    plot(TT_emis_S.Time, TT_emis_S.N2O_BG, 'k.', TT_emis_N.Time, TT_emis_N.N2O_BG, 'k.', 'MarkerSize', 8)
    ylabel('N_2O (\mug m^{-3})', 'FontSize', 12)
    grid minor
    xlim(TimeLim)
    ylim([550 600])
    xline(T_UNCOV_S, 'b--', 'LineWidth', 1);
    xline(T_UNCOV_N, 'r--', 'LineWidth', 1)
    yline(0)
    ax = gca;
    ax.XAxis.FontSize = 12;
    ii = ii + 1;

    if SAVE_FIG == 1
        FigFileName = 'Fig204 Concentrations';
        fullFileName = fullfile(foldout, FigFileName);
        fig204 = gcf;
        fig204.PaperUnits = 'centimeters';
        fig204.PaperPosition = [0 0 18 18];
        print(fullFileName,'-dpng','-r800')
    end

%% Temperature

% % % % % %
% Load Temp 2
opts = delimitedTextImportOptions("NumVariables", 12);

opts.DataLines = [1092, Inf];
opts.Delimiter = ",";

opts.VariableNames = ["Var1", "DOY", "TOD", "Temp1", "Temp2", "Temp3", "Temp4", "Temp5", "Temp6", "Var10", "Var11", "Var12"];
opts.SelectedVariableNames = ["Var1", "DOY", "TOD", "Temp1", "Temp2", "Temp3", "Temp4", "Temp5", "Temp6"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "string", "string", "string"];

opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

opts = setvaropts(opts, ["Var10", "Var11", "Var12"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var10", "Var11", "Var12"], "EmptyFieldRule", "auto");

T2 = readtable(fullfile(PATH_DATA, 'Temperature', '220701_Første stak forsøg.dat'), opts);
clear opts

T2.Time = datetime(2022, 1, 1) + days(T2.DOY - 1) + hours(floor(T2.TOD / 100)) + minutes(mod(T2.TOD, 100));

TT2 = table2timetable(T2, 'RowTimes', 'Time');

TT2{TT2.Temp1 < 25 ,"Temp1"} = NaN;
TT2{TT2.Temp2 < 25 ,"Temp2"} = NaN;
TT2{TT2.Temp3 < 25 ,"Temp3"} = NaN;
TT2{TT2.Temp4 < 25 ,"Temp4"} = NaN;
TT2{TT2.Temp5 < 25 ,"Temp5"} = NaN;
TT2{TT2.Temp6 < 25 ,"Temp6"} = NaN;

clearvars T2

% % % % % %
% Load Temp 4
opts = delimitedTextImportOptions("NumVariables", 9);

opts.DataLines = [2, Inf];
opts.Delimiter = ",";

opts.VariableNames = ["Var1", "DOY", "TOD", "Temp1", "Temp2", "Temp3", "Temp4", "Temp5", "Temp6"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double"];

opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

T4 = readtable(fullfile(PATH_DATA, 'Temperature', '220808_Første stak forsøg.dat'), opts);
clear opts

T4.Time = datetime(2022, 1, 1) + days(T4.DOY - 1) + hours(floor(T4.TOD / 100)) + minutes(mod(T4.TOD, 100));

TT4 = table2timetable(T4, 'RowTimes', 'Time');

TT4{TT4.Temp1 < 25 ,"Temp1"} = NaN;
TT4{TT4.Temp2 < 25 ,"Temp2"} = NaN;
TT4{TT4.Temp3 < 25 ,"Temp3"} = NaN;
TT4{TT4.Temp4 < 25 ,"Temp4"} = NaN;
TT4{TT4.Temp5 < 25 ,"Temp5"} = NaN;
TT4{TT4.Temp6 < 25 ,"Temp6"} = NaN;

clearvars T4

% % % % % %
% Load Temp 5
opts = delimitedTextImportOptions("NumVariables", 9);

opts.DataLines = [2, Inf];
opts.Delimiter = ",";

opts.VariableNames = ["Var1", "DOY", "TOD", "Temp1", "Temp2", "Temp3", "Temp4", "Temp5", "Temp6"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double"];

opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

T5 = readtable(fullfile(PATH_DATA, 'Temperature', '220715_Første stak forsøg.dat'), opts);
clear opts

T5.Time = datetime(2022, 1, 1) + days(T5.DOY - 1) + hours(floor(T5.TOD / 100)) + minutes(mod(T5.TOD, 100));

TT5 = table2timetable(T5, 'RowTimes', 'Time');

TT5{TT5.Temp1 < 25 ,"Temp1"} = NaN;
TT5{TT5.Temp2 < 25 ,"Temp2"} = NaN;
TT5{TT5.Temp3 < 25 ,"Temp3"} = NaN;
TT5{TT5.Temp4 < 25 ,"Temp4"} = NaN;
TT5{TT5.Temp5 < 25 ,"Temp5"} = NaN;
TT5{TT5.Temp6 < 25 ,"Temp6"} = NaN;

clearvars T5

% Combine TT to get full time series and remove data
TT = [TT2; TT5; TT4];

% Times with bad data
TT.Temp2(TT.Time > datetime(2022,6,29,0,0,0)) = NaN;
TT.Temp5(TT.Time > datetime(2022,7,12,2,30,0)) = NaN;
TT.Temp6(TT.Time == datetime(2022,7,7,22,00,0)) = NaN;

clearvars TT2 TT5 TT4


%% Oxygen
opts = spreadsheetImportOptions("NumVariables", 6);

opts.Sheet = "Sheet1";
opts.DataRange = "A3:F15";

opts.VariableNames = ["Depth", "Oxygen_BC", "Std_BC", "Depth1", "Oxygen_NoBC", "Std_NoBC"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double"];

Oxygen = readtable(fullfile(PATH_DATA, 'Oxygen content.xlsx'), opts, "UseExcel", false);

clear opts

%% Weather station

% Change in load_Foulum_Weather_func before loading
File_FoulumVejr = fullfile(PATH_DATA, 'FoulumVejr_2305_1608.csv');
TT_VejrFoulum = load_Foulum_Weather_func(File_FoulumVejr);

%% Plot temp

% Three shades of red (light → dark)
% reds = [
%     1.00 0.60 0.60  % light red
%     1.00 0.27 0.27  % medium red
%     0.70 0.00 0.00  % dark red
% ];

% Three shades of blue (light → dark)
% blues = [
%     0.60 0.80 1.00  % light blue
%     0.26 0.52 0.96  % medium blue
%     0.00 0.20 0.60  % dark blue
% ];

reds = [
    1.00 0.40 0.40  % light red
    1.00 0.00 0.00  % pure red
    0.60 0.00 0.00  % dark red
];

blues = [
    0.40 0.60 1.00  % light blue
    0.00 0.20 1.00  % pure blue
    0.00 0.00 0.60  % dark blue
];

grayColor = [0.6 0.6 0.6];

fig200 = figure(ii);
hold on;
plot(TT.Time, TT.Temp1, 'Color', blues(1,:), 'LineWidth', 2);
plot(TT.Time, TT.Temp2, 'Color', blues(2,:), 'LineWidth', 2);
plot(TT.Time, TT.Temp3, 'Color', blues(3,:), 'LineWidth', 2);
plot(TT.Time, TT.Temp4, 'Color', reds(1,:), 'LineWidth', 2);
plot(TT.Time, TT.Temp5, 'Color', reds(2,:), 'LineWidth', 2);
plot(TT.Time, TT.Temp6, 'Color', reds(3,:), 'LineWidth', 2);
xlim([datetime(2022,5,23) datetime(2022,8,8,15,0,0)])
grid minor
ylabel('Temperature (^oC)')
xline(datetime(2022,6,24,12,30,0), 'b--','LineWidth', 2.5) % Uncover Biochar pile
xline(datetime(2022,7,4,13,0,0), 'r--','LineWidth', 2.5) % Uncover no biochar pile
xline(datetime(2022,5,25,12,0,0), 'Color', grayColor, 'LineStyle', ':','LineWidth', 2.)
plot(TT_VejrFoulum.Time, TT_VejrFoulum.TempAir,'k-','LineWidth', 1)
xline(datetime(2022,6,14,13,30,0), 'Color', grayColor, 'LineStyle', ':','LineWidth', 2.)
xline(datetime(2022,7,4,13,0,0), 'Color', grayColor, 'LineStyle', ':','LineWidth', 2.)
xline(datetime(2022,7,13,14,30,0), 'Color', grayColor, 'LineStyle', ':','LineWidth', 2.)
legend('Biochar 30 cm', 'Biochar 100 cm', 'Biochar 150 cm', 'No Biochar 30 cm', 'No Biochar 100 cm', 'No Biochar 150 cm', 'Biochar uncover', 'No Biochar uncover', ...
    'Temp. sensor adjusted','Air temp.', 'Location','northoutside','NumColumns', 4)
ii = ii + 1;

    if SAVE_FIG == 1
        FigFileName = 'Fig200 Temperature Pile air temp';
        fullFileName = fullfile(foldout, FigFileName);
        fig200 = gcf;
        fig200.PaperUnits = 'centimeters';
        fig200.PaperPosition = [0 0 19 11];
        print(fullFileName,'-dpng','-r800')
    end

%% Plot oxygen

fig300 = figure(ii);
errorbar(Oxygen.Depth, Oxygen.Oxygen_BC, Oxygen.Std_BC, 'bo'); hold on
errorbar(Oxygen.Depth, Oxygen.Oxygen_NoBC, Oxygen.Std_NoBC, 'ro'); hold on
grid minor
xlabel('Depth (cm)')
ylabel('Oxygen content (%)')
ylim([0, 22])
legend('Biochar', 'No Biochar')

    if SAVE_FIG == 1
        FigFileName = 'Fig300 Oxygen Pile';
        fullFileName = fullfile(foldout, FigFileName);
        fig300 = gcf;
        fig300.PaperUnits = 'centimeters';
        fig300.PaperPosition = [0 0 16 11];
        print(fullFileName,'-dpng','-r800')
    end

toc
