%Dijkstra Path test
num_nodes = 12;
max_capacity = 5;
alpha = 1;
num_iterations = 150;
traffic_A = zeros(11,1);
traffic_node_1 = zeros(num_iterations,1);
traffic_node_2 = zeros(num_iterations,1);
traffic_node_3 = zeros(num_iterations,1);

traffic_rksp_total = zeros(num_iterations,1);
traffic_ebrksp_total = zeros(num_iterations,1);
traffic_AR_total = zeros(num_iterations,1);
beta_AR = 0.5;
k_paths = 5;

eta_1 = 1;
eta_2 = 1;

number_nodes_eta = floor((1-eta_1)*num_nodes);

total_num_vehicles = 150;

%initialization
A = formA(num_nodes,num_nodes);%formSingapore(182,182,Munich); %formA(num_nodes,num_nodes);
[node_incidence_matrix,num_paths] = node_incidence(A,num_nodes);
distance = compute_path_cost(A,num_nodes,num_nodes);
path_capacity_matrix = path_capacity(A,num_nodes,max_capacity);
node_capacity_matrix = node_capacity(num_nodes,max_capacity);
vehicle_positions = zeros(num_nodes,total_num_vehicles);
start_end = zeros(2,total_num_vehicles);
        
step = 5;

Xmatrix = zeros(num_paths,total_num_vehicles);    

%A = formSingapore(num_nodes,num_nodes,ArcCon);
for iterations = 5:step:5
    
    node_pressure_type1 = zeros(num_nodes,1);
    node_pressure_type2 = zeros(num_nodes,1);
    node_pressure_type3 = zeros(num_nodes,1);
    %Dijkstra with node pressure
    
    Xmatrix_1 = zeros(num_paths,total_num_vehicles);
    Xmatrix_2 = zeros(num_paths,total_num_vehicles);
    Xmatrix_3 = zeros(num_paths,total_num_vehicles);
    
    traffic_severity_1 = zeros(num_iterations,1);
    traffic_severity_2 = zeros(num_iterations,1);
    traffic_severity_3 = zeros(num_iterations,1);
        
    node_pressure = zeros(num_nodes,1);
    number_vehicles_eta = floor((1-eta_2)* total_num_vehicles);

    %plain Dijkstra for the vehicles not under control
     for j=1:total_num_vehicles
         [start,ending] = formB(num_nodes, node_incidence_matrix, num_paths);
         start_end(1,j) = start;
         start_end(2,j) = ending;
%         path_planning = Dijkstra_path(A,distance,num_nodes,start,ending, node_pressure);
%         vehicle_positions(:,j) = path_planning;
%         Xmatrix(:,j) = calculate_matrix_i(node_incidence_matrix,path_planning,start, num_paths, num_nodes);
     end

     
     for j=1:number_vehicles_eta
         [start,ending] = formB(num_nodes, node_incidence_matrix, num_paths);
         start_end(1,j) = start;
         start_end(2,j) = ending;
         path_planning = Dijkstra_path(A,distance,num_nodes,start,ending, node_pressure);
         vehicle_positions(:,j) = path_planning;
         Xmatrix(:,j) = calculate_matrix_i(node_incidence_matrix,path_planning,start, num_paths, num_nodes);
     end

     



%     %A+ calculation
    A_plus_matrix = A_plus_calculation(node_incidence_matrix,num_nodes,num_paths);
    X_summation = sum(Xmatrix,2);
%     traffic_severity_A = (A_plus_matrix * X_summation) - node_capacity_matrix;
%     traffic_repulsion = (A_plus_matrix * X_summation);
%       
     
    node_pressure = zeros(num_nodes,1);
    vehicle_positions_pressure = zeros(num_nodes,total_num_vehicles);
    
    X_summation_1 = X_summation;
    X_summation_2 = X_summation;
    X_summation_3 = X_summation;
    
    for j = 1:150
        X_summation_1 = sum(Xmatrix_1,2);
        X_summation_2 = sum(Xmatrix_2,2);
        X_summation_3 = sum(Xmatrix_3,2);
%         
        traffic_1 = A_plus_matrix * X_summation_1;
        traffic_1 = traffic_1 - node_capacity_matrix;
        
        traffic_2 = A_plus_matrix * X_summation_2;
        traffic_2 = traffic_2 - node_capacity_matrix;
        
        traffic_3 = A_plus_matrix * X_summation_3;
        traffic_3 = traffic_3 - node_capacity_matrix;
%         
        
        for k = number_vehicles_eta+1:num_nodes
            if(traffic_1(k,1)<0)
                 node_pressure_type1(k,1) = node_pressure_type1(k,1) + alpha* traffic_1(k,1);
                node_pressure_type3(k,1) = node_pressure_type3(k,1) + alpha * exp(traffic_3(k,1));
            end
            if(traffic_1(k,1)>=0)
                node_pressure_type3(k,1) = node_pressure_type3(k,1) + alpha * exp(traffic_3(k,1));
                node_pressure_type2(k,1) = node_pressure_type2(k,1) + alpha *traffic_2(k,1);
                node_pressure_type1(k,1) = node_pressure_type1(k,1) + alpha* traffic_1(k,1);
            end
        end

        for k=number_vehicles_eta+1:total_num_vehicles
            start = start_end(1,k);
            ending = start_end(2,k);
            path_planning_1 = Dijkstra_path(A,distance,num_nodes,start,ending, node_pressure_type1);
            path_planning_2 = Dijkstra_path(A,distance,num_nodes,start,ending, node_pressure_type2);
            path_planning_3 = Dijkstra_path(A,distance,num_nodes,start,ending, 2*log(node_pressure_type3));
            vehicle_positions_pressure(:,k) = path_planning_1;
            Xmatrix_1(:,k) = calculate_matrix_i(node_incidence_matrix,path_planning_1,start, num_paths, num_nodes);
            Xmatrix_2(:,k) = calculate_matrix_i(node_incidence_matrix,path_planning_2,start, num_paths, num_nodes);
            Xmatrix_3(:,k) = calculate_matrix_i(node_incidence_matrix,path_planning_3,start, num_paths, num_nodes);
        end
        vehicle_concentration_i = zeros(num_nodes,num_nodes);
% 
        for tmp = 1: num_nodes
            if(traffic_1(tmp,1) > 0)
                traffic_severity_1(j,1) = traffic_severity_1(j,1) + exp(traffic_1(tmp,1));
            end
            if(traffic_2(tmp,1) > 0)
                traffic_severity_2(j,1) = traffic_severity_2(j,1) + exp(traffic_2(tmp,1));
            end
            if(traffic_3(tmp,1) > 0)
                traffic_severity_3(j,1) = traffic_severity_3(j,1) + exp(traffic_3(tmp,1)); 
            end
        end
    
    traffic_node_1(j,1) = traffic_severity_1(j,1);
    traffic_node_2(j,1) = traffic_severity_2(j,1);
    traffic_node_3(j,1) = traffic_severity_3(j,1);
    end
end
%

%Dijkstra affected nodes
Dijkstra_num_affected = zeros(num_nodes,1);
x_matrix = zeros(num_iterations,1);
for i=1:num_iterations
    %Dijkstra_num_affected(i,1) = traffic_initial;
    x_matrix(i,1) = i;
end

performance = zeros(200,1);

x = x_matrix;

y1 = 6 * log(traffic_node_1);
y2 = 6 * log(traffic_node_2);
y3 = 6 * log(traffic_node_3);
%y3 = 4 * log(traffic_node_1);

% y1 = traffic_AR_total;
% y2 = traffic_rksp_total;
% y4 = traffic_ebrksp_total;
% y3 = traffic_node_1;

% y1 = traffic_node_1;
% y2 = traffic_node_2;
% y3 = traffic_node_3;

figure
plot(x,y1,x,y2,x,y3)
% plot(x,log(y1),x,log(y2),x,log(y3))
