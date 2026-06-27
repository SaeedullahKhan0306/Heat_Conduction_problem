%% ========================================================
%% METHOD 1: Explicit Method (FTCS)
%% ========================================================
clear; clc; close all;

%% PARAMETERS
L = 20;              % Length of rod (cm)
dx = 2;              % Spatial step (cm)
Nx = L/dx + 1;       % Number of nodes

% Material properties
k = 0.49;            % Thermal conductivity (cal/s·cm·°C)
rho = 2.7;           % Density (g/cm^3)
C = 0.2174;          % Specific heat (cal/g·°C)

% Thermal diffusivity
alpha = k / (rho * C);

dt = 0.1;            % Time step (s)
lambda = alpha * dt / dx^2;   % Stability factor

% Stability check
if lambda > 0.5
    warning('FTCS method unstable! Reduce dt or increase dx.');
end

%% GRID
x = linspace(0, L, Nx);

%% TIME SETTINGS
t_final = 12;
Nt = round(t_final / dt);

%% INITIAL CONDITION (T = 25°C everywhere)
T = 25 * ones(1, Nx);

%% BOUNDARY CONDITIONS
T_left  = @(t) 80 + 2*t;
T_right = @(t) 40 + 0.5*t;

%% STORAGE
T_all = zeros(Nt+1, Nx);
T_all(1,:) = T;

%% TIME LOOP
for n = 1:Nt
    t = (n-1)*dt;
    T_new = T;

    % Apply boundary conditions
    T_new(1)   = T_left(t);
    T_new(end) = T_right(t);

    % FTCS (interior nodes)
    for i = 2:Nx-1
        T_new(i) = T(i) + lambda * (T(i+1) - 2*T(i) + T(i-1));
    end

    % Update
    T = T_new;
    T_all(n+1,:) = T;
end

%% PLOTTING
times_to_plot = [0.1, 3, 6, 9, 12];
figure;
hold on;
colors = jet(length(times_to_plot));
legend_entries = {};

for j = 1:length(times_to_plot)
    n_plot = round(times_to_plot(j)/dt) + 1;
    plot(x, T_all(n_plot,:), '-o', 'Color', colors(j,:), 'LineWidth', 2);
    legend_entries{end+1} = ['t = ' num2str(times_to_plot(j)) ' s'];
end

xlabel('Position x (cm)');
ylabel('Temperature T (°C)');
title('FTCS Solution (Updated Problem)');
legend(legend_entries, 'Location', 'best');
grid on;
hold off;


%% ========================================================
%% METHOD 2: Implicit Method (BTCS)
%% ========================================================
clear; clc; close all;

%% PARAMETERS
L = 20;
dx = 2;
dt = 0.1;
k = 0.49;
rho = 2.7;
C = 0.2174;
alpha = k / (rho * C);
x = 0:dx:L;
n = length(x);
t_end = 12;
time = 0:dt:t_end;
r = alpha * dt / dx^2;

%% INITIAL CONDITION
T = 25 * ones(n, length(time));

%% BOUNDARY CONDITIONS
for k_t = 1:length(time)
    T(1, k_t)   = 80 + 2*time(k_t);
    T(end, k_t) = 40 + 0.5*time(k_t);
end

%% COEFFICIENT MATRIX
A = (1 + 2*r) * eye(n-2);
for i = 1:n-3
    A(i, i+1) = -r;
    A(i+1, i) = -r;
end

%% TIME LOOP
for k_t = 1:length(time)-1
    b = T(2:end-1, k_t);

    % Boundary effects (implicit uses k+1)
    b(1)   = b(1)   + r * T(1, k_t+1);
    b(end) = b(end) + r * T(end, k_t+1);

    T(2:end-1, k_t+1) = A \ b;
end

%% PLOTTING
times_to_plot = [0.1, 3, 6, 9, 12];
figure;
hold on;
for i = 1:length(times_to_plot)
    idx = round(times_to_plot(i)/dt) + 1;
    plot(x, T(:, idx), '-o', 'LineWidth', 2);
end
xlabel('x (cm)');
ylabel('Temperature (°C)');
title('BTCS Method (Updated Problem)');
legend('0.1s', '3s', '6s', '9s', '12s');
grid on;
hold off;


%% ========================================================
%% METHOD 3: Crank-Nicolson Method
%% ========================================================
clear; clc; close all;

%% PARAMETERS
L = 20;
dx = 2;
dt = 0.1;
k = 0.49;
rho = 2.7;
C = 0.2174;
alpha = k / (rho * C);
x = 0:dx:L;
Nx = length(x);
t_final = 12;
Nt = t_final / dt;
lambda = alpha * dt / dx^2;

%% INITIAL CONDITION
T = 25 * ones(Nx, 1);

%% BC FUNCTIONS
T_left  = @(t) 80 + 2*t;
T_right = @(t) 40 + 0.5*t;

%% MATRICES
a = -lambda/2;
b = 1 + lambda;
c = -lambda/2;

A = diag(b*ones(Nx-2, 1)) + diag(a*ones(Nx-3, 1), -1) + diag(c*ones(Nx-3, 1), 1);
B = diag((1-lambda)*ones(Nx-2, 1)) + diag((lambda/2)*ones(Nx-3, 1), -1) + diag((lambda/2)*ones(Nx-3, 1), 1);

%% STORAGE
times_to_plot = [0.1, 3, 6, 9, 12];
plot_idx = round(times_to_plot / dt);
T_store = zeros(length(plot_idx), Nx);
count = 1;

%% TIME LOOP
for n = 1:Nt
    t_now  = n * dt;
    t_prev = (n-1) * dt;

    T(1)   = T_left(t_now);
    T(end) = T_right(t_now);

    RHS = B * T(2:end-1);
    RHS(1)   = RHS(1)   + (lambda/2) * (T_left(t_now)  + T_left(t_prev));
    RHS(end) = RHS(end) + (lambda/2) * (T_right(t_now) + T_right(t_prev));

    T(2:end-1) = A \ RHS;

    if ismember(n, plot_idx)
        T_store(count, :) = T';
        count = count + 1;
    end
end

%% PLOT
figure;
hold on;
for i = 1:length(times_to_plot)
    plot(x, T_store(i,:), '-o', 'LineWidth', 2);
end
xlabel('x (cm)');
ylabel('Temperature (°C)');
title('Crank-Nicolson Method');
legend('0.1s', '3s', '6s', '9s', '12s');
grid on;
hold off;


%% ========================================================
%% METHOD 4: Richardson Method
%% ========================================================
clear; clc; close all;

%% PARAMETERS
L = 20;
dx = 2;
dt = 0.1;
k = 0.49;
rho = 2.7;
C = 0.2174;
alpha = k / (rho * C);
lambda = alpha * dt / dx^2;
x = 0:dx:L;
nx = length(x);
t_end = 12;
nt = t_end / dt;

%% INITIAL CONDITION
T = 25 * ones(nx, nt+1);
time = (0:nt) * dt;

%% BOUNDARY CONDITIONS
T(1,:)   = 80 + 2*time;
T(end,:) = 40 + 0.5*time;

%% RICHARDSON LOOP
for n = 1:nt
    T_half = zeros(nx, 1);

    % Half-step BC
    T_half(1)   = (T(1,n)   + T(1,n+1))   / 2;
    T_half(end) = (T(end,n) + T(end,n+1)) / 2;

    % Predictor
    for i = 2:nx-1
        T_half(i) = T(i,n) + (lambda/2) * (T(i-1,n) - 2*T(i,n) + T(i+1,n));
    end

    % Corrector
    for i = 2:nx-1
        T(i,n+1) = T(i,n) + lambda * (T_half(i-1) - 2*T_half(i) + T_half(i+1));
    end
end

%% PLOT
times_to_plot = [0.1, 3, 6, 9, 12];
figure;
hold on;
for i = 1:length(times_to_plot)
    idx = round(times_to_plot(i)/dt) + 1;
    plot(x, T(:,idx), '-o', 'LineWidth', 2);
end
xlabel('x (cm)');
ylabel('Temperature (°C)');
title('Richardson Method');
legend('0.1s', '3s', '6s', '9s', '12s');
grid on;
hold off;
