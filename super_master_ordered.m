% =========================================================
% END-TO-END PIPELINE: BATCH PROCESSING, METRICS & SORTING
% =========================================================
% This script processes multiple raw Excel files from a Win-Shift task,
% extracts robust behavioral metrics (Error Rank, First-4 Accuracy, 
% Clockwise Index), filters out noise, and chronologically sorts the 
% final Master Dataset using regex.

clear; clc;

% --- 1. FOLDER SELECTION ---
cartella = uigetdir('', 'Select the folder containing the daily .xlsx files');
if isequal(cartella, 0)
    disp('Operation cancelled by user.');
    return;
end

file_list = dir(fullfile(cartella, '*.xlsx'));
% Filter out temporary files and any previously generated master datasets
file_list = file_list(~startsWith({file_list.name}, '~$') & ~contains({file_list.name}, 'MASTER'));

Super_Tabella = table();

% --- 2. BATCH PROCESSING & METRIC EXTRACTION ---
for f = 1:length(file_list)
    nome_file = file_list(f).name; 
    percorso_completo = fullfile(cartella, nome_file);
    
    disp(['Processing session: ' nome_file '...']);
    
    % DYNAMIC ARM ASSIGNMENT (Update with correct daily arms)
    switch nome_file
        case 'day_10_winshift_19_april.xlsx'
            right_arms_trial1 = [1, 2, 3, 4]; 
            right_arms_trial2 = [5, 6, 7, 8];
            
        case 'day_11_winshift_20_april.xlsx' 
            right_arms_trial1 = [2, 5, 7, 8]; 
            right_arms_trial2 = [1, 3, 4, 6];
            
        % ADD ALL OTHER CASES HERE...
            
        otherwise
            disp(['WARNING: No target arms defined for ' nome_file]);
            continue; 
    end
    
    % Import configuration to bypass header noise
    opts = detectImportOptions(percorso_completo);
    opts.DataRange = 'A1';
    opts.VariableNamingRule = 'preserve';
    T = readtable(percorso_completo, opts);
    
    % Pre-allocate essential metric columns
    T.Error_Rank = NaN(height(T), 1);
    T.First4_Accuracy = NaN(height(T), 1); 
    T.Clockwise_Index = NaN(height(T), 1); 
    
    for i = 1:height(T)
        if ~isempty(T.("Arms sequence"){i})
            
            % Trial phase routing
            if T.("Trial n")(i) == 1
                arms_to_use = right_arms_trial1;
            elseif T.("Trial n")(i) == 2
                arms_to_use = right_arms_trial2;
            else
                continue; 
            end
            
            % Robust sequence extraction
            sequence_text = string(T.("Arms sequence"){i});
            extracted_numbers = regexp(sequence_text, '\d+', 'match');
            visited_arms = str2double(extracted_numbers); 
            is_correct = ismember(visited_arms, arms_to_use);
            
            % 1. Error Rank (Errors prior to first correct choice)
            first_correct_pos = find(is_correct, 1);
            if ~isempty(first_correct_pos)
                T.Error_Rank(i) = first_correct_pos - 1;
            else
                T.Error_Rank(i) = length(visited_arms);
            end

            % 2. First-4 Accuracy (Short-term working memory capacity)
            num_choices = min(4, length(visited_arms));
            if num_choices > 0
                correct_in_first_4 = sum(is_correct(1:num_choices));
                T.First4_Accuracy(i) = correct_in_first_4 / 4; 
            end
            
            % 3. Clockwise Index (Egocentric motor strategy evaluation)
            total_transitions = length(visited_arms) - 1;
            if total_transitions > 0
                clockwise_count = 0;
                for j = 1:total_transitions
                    current_arm = visited_arms(j);
                    next_arm = visited_arms(j+1);
                    if (next_arm == current_arm + 1) || (current_arm == 8 && next_arm == 1)
                        clockwise_count = clockwise_count + 1;
                    end
                end
                T.Clockwise_Index(i) = clockwise_count / total_transitions;
            else
                T.Clockwise_Index(i) = NaN; 
            end
        end 
    end 
    
    % TARGETED EXTRACTION: Keep only strictly required variables
    T_clean = table();
    T_clean.Rat_n = T.("Rat n");
    T_clean.Trial_n = T.("Trial n");
    T_clean.Arms_sequence = string(T.("Arms sequence"));
    T_clean.Error_Rank = T.Error_Rank;
    T_clean.First4_Accuracy = T.First4_Accuracy;
    T_clean.Clockwise_Index = T.Clockwise_Index;
    T_clean.File_Source = repmat(string(nome_file), height(T), 1);
    
    Super_Tabella = [Super_Tabella; T_clean];
end

% --- 3. CHRONOLOGICAL SORTING VIA REGEX ---
disp('Sorting the Master Dataset chronologically...');
day_strings = regexp(Super_Tabella.File_Source, 'day_(\d+)', 'tokens', 'once');
day_numbers = zeros(height(Super_Tabella), 1);

for i = 1:height(Super_Tabella)
    if ~isempty(day_strings{i})
        day_numbers(i) = str2double(day_strings{i}{1});
    else
        day_numbers(i) = 999; % Failsafe for unformatted names
    end
end

Super_Tabella.Day_Num = day_numbers;
% Sort hierarchically: Day -> Subject ID -> Trial Phase
Super_Tabella = sortrows(Super_Tabella, {'Day_Num', 'Rat_n', 'Trial_n'});
Super_Tabella.Day_Num = []; % Remove temp variable

% --- 4. FINAL EXPORT ---
percorso_salvataggio = fullfile(cartella, 'WINSHIFT_MASTER_PIPELINE.xlsx');
writetable(Super_Tabella, percorso_salvataggio);

disp('=========================================');
disp('Success! End-to-End Pipeline completed.');
disp(['Dataset saved as: WINSHIFT_MASTER_PIPELINE.xlsx']);
