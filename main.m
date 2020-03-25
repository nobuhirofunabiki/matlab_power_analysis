%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Power balance analysis simulation
% Author: Nobuiro Funabki
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO
% - Use a charge curve model instead of the discharge model

clc
clear
close all;

restoredefaultpath
addpath(genpath('../power_analysis'));
addpath(genpath('../common_utilities'));
addpath(genpath('../YAMLMatlab_0.4.3'));

% Read files
general_params = ReadYaml('config/general_parameters.yaml');
battery_params = ReadYaml('config/battery_parameters.yaml');
power_consumption_raw = csvread(['data/', general_params.file_name.power.consumption]);
power_generation_raw = csvread(['data/', general_params.file_name.power.generation]);
last_time = power_consumption_raw(length(power_consumption_raw),1);

% General parameters
delta_time = general_params.time.delta;
total_counts = round(last_time/delta_time);
eff.sap_to_bus = general_params.efficiency.sap_to_bus;

% Power consumption list
time_counter = 1;
for iCounts = 1:total_counts
    time = iCounts*delta_time;
    if time > power_consumption_raw(time_counter+1, 1)
        time_counter = time_counter + 1;
    end
    power_consumption(iCounts,1) = time;
    power_consumption(iCounts,2) = power_consumption_raw(time_counter,2);
end

% Power generation list
time_counter = 1;
for iCounts = 1:total_counts
    time = iCounts*delta_time;
    if time > power_generation_raw(time_counter+1, 1)
        time_counter = time_counter + 1;
    end
    power_generation(iCounts,1) = time;
    power_generation(iCounts,2) = power_generation_raw(time_counter,2);
end

battery_ = Battery(battery_params);
battery_voltage = zeros(total_counts,2);
dod = zeros(total_counts,2);
battery_info.current = zeros(total_counts, 2);

for iCounts = 1:total_counts
    delta_power = power_consumption(iCounts,2)/eff.sap_to_bus - power_generation(iCounts,2);
    bus_voltage = battery_.getBatteryVoltage();
    current = delta_power/bus_voltage;
    % if current > 0, the battery is being discharged
    battery_.updateBatteryStatus(current, delta_time/3600.0);
    battery_voltage(iCounts,1) = iCounts*delta_time;
    battery_voltage(iCounts,2) = battery_.getBatteryVoltage();
    dod(iCounts,1) = iCounts*delta_time;
    dod(iCounts,2) = battery_.getDepthOfDischarge();
    battery_info.current(iCounts,1) = iCounts*delta_time;
    battery_info.current(iCounts,2) = battery_.getBatteryCurrent();
end

% Visualization

cg_ = ColorGenerator();

figure
hold on

ylim_max = 60;

num_nights = 5;
time_night = 2240.0;
orbit_period = 5600.0;
min_power = [0 0];
max_power = [ylim_max ylim_max];
in_between = [min_power, fliplr(max_power)];
for iNights = 1:num_nights
    time_list = [orbit_period*(iNights-1) time_night+orbit_period*(iNights-1)];
    time_list_agg = [time_list, fliplr(time_list)];
    plot_night = fill(time_list_agg, in_between, ...
        cg_.getNormalizedRGB('kurobeni'), ...
        'FaceAlpha', 0.2, ...
        'EdgeColor', 'none');
end

plot_consumption = plot(power_consumption(:,1), power_consumption(:,2),...
    'Color', cg_.getNormalizedRGB('benihi'),...
    'LineStyle', '-', ...
    'LineWidth', 1.5);
plot_generation = plot(power_generation(:,1), power_generation(:,2),...
    'Color', cg_.getNormalizedRGB('ruri'),...
    'LineStyle', '-', ...
    'LineWidth', 1);
set(gca,'FontSize',10);
ax = gca;
xlabel('Time [sec]')
ylabel('Power Consumption/Generation [W]')
xlim([0.0 last_time]);
ylim([0.0 ylim_max]);
legend([plot_consumption plot_generation plot_night],...
    {'Power Consumption', 'Power Generation', 'Eclipse Period'}, ...
    'Location', 'northeast', 'FontSize', 12);
grid on
hold off


fig = figure;
% hold on

set(fig, 'defaultAxesColorOrder',[cg_.getNormalizedRGB('midori'); cg_.getNormalizedRGB('kurobeni')]);

yyaxis left
hold on
plot_voltage = plot(battery_voltage(:,1), battery_voltage(:,2),...
    'Color', cg_.getNormalizedRGB('midori'),...
    'LineStyle', '-', ...
    'LineWidth', 1.5);

num_nights = 5;
time_night = 2240.0;
orbit_period = 5600.0;
min_power = [10 10];
max_power = [15 15];
in_between = [min_power, fliplr(max_power)];
for iNights = 1:num_nights
    time_list = [orbit_period*(iNights-1) time_night+orbit_period*(iNights-1)];
    time_list_agg = [time_list, fliplr(time_list)];
    plot_night = fill(time_list_agg, in_between, ...
        cg_.getNormalizedRGB('kurobeni'), ...
        'FaceAlpha', 0.2, ...
        'EdgeColor', 'none');
end

ylabel('Battery Voltage [V]')
ylim([10.0 14.0]);

yyaxis right
plot_dod = plot(dod(:,1), dod(:,2),...
    'Color', cg_.getNormalizedRGB('kurobeni'),...
    'LineStyle', '-', ...
    'LineWidth', 1.5);
ylabel('DOD (Depth of discharge) [%]')
ylim([0.0 30.0]);

xlabel('Time [sec]');
xlim([0.0 last_time]);
legend([plot_voltage plot_dod plot_night],...
    {'Battery Voltage', 'DOD', 'Eclipse Period'}, ...
    'Location', 'northeast', 'FontSize', 12);
grid on
hold off


figure
hold on
plot_current = plot(battery_info.current(:,1), battery_info.current(:,2),...
    'Color', cg_.getNormalizedRGB('tsutsuji'),...
    'LineStyle', '-', ...
    'LineWidth', 2);
set(gca,'FontSize',10);
ax = gca;
xlabel('Time [sec]')
ylabel('Buttery Current [A]')
xlim([0.0 last_time]);
ylim([-5.0 5.0]);
grid on
hold off
