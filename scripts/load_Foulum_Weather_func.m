% Load data from Foulum weather station
% Jesper Kamp
% November 2022

function TT_VejrFoulum = load_Foulum_Weather_func(FILENAME)

opts = delimitedTextImportOptions("NumVariables", 18);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["station", "date", "time", "prec", "surfwet", "glorad", "TempAir", "TempGrass", "Temp10cm", "Temp30cm", "RH", "WD10", "WS10", "wd2", "wv2", "pres", "netrad", "heatflux"];
opts.VariableTypes = ["double", "datetime", "datetime", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
opts = setvaropts(opts, 2, "InputFormat", "dd/MM/yyyy");
% opts = setvaropts(opts, 2, "InputFormat", "dd-MM-yyy"); % Old version
opts = setvaropts(opts, 3, "InputFormat", "H");
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
VejrFoulum = readtable(FILENAME, opts);

VejrFoulum.TIME = VejrFoulum.date + timeofday(VejrFoulum.time) + hours(1);
VejrFoulum.TIME.Format = 'dd-MM-yyyy HH:mm:ss.SSS';

TT_VejrFoulum = table2timetable(VejrFoulum,'RowTimes',VejrFoulum.TIME);
TT_VejrFoulum(:,[1:3, 19]) = [];

end

%% Nedbør, mm; Precipitation
    % Overfladefugtighed, minutter; Leaf wetness
    % Globalstråling, W/m2; Global radiation
    % Lufttemperatur - timemiddel, °C;  Air temperature - hour mean
    % Græstemperatur - timemiddel, °C; Grass temperature - hour mean
    % Jordtemperatur i 10 cm - timemiddel, °C;  Soil temperature 10cm - hour mean
    % Jordtemperatur i 30 cm - timemiddel, °C; Soil temperature 30cm - hour mean
    % Relativ luftfugtighed - timemiddel; Relative humidity - hour mean
    % Vindretning i 10 m - timemiddel, grader; Wind direction at 10 m - hour mean
    % Vindhastighed i 10 m - timemiddel, m/s; Wind velocity at 10 m - hour mean
    % Lufttryk, hPa; % Air pressure
    % Nettostråling; Net radiation
    % Jordvarmeflux; Soil heat flux
    
    % http://agro-web01t.uni.au.dk/klimadb/