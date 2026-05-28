clear; clc;

% 1. Selezione dinamica del file (nessun errore di percorso!)
[nome_file_scelto, percorso] = uigetfile('*.xlsx', 'Seleziona il file WINSHIFT_SUPER_MASTER.xlsx');
if isequal(nome_file_scelto, 0)
    disp('Operazione annullata.');
    return; 
end
fileName = fullfile(percorso, nome_file_scelto); 

% Carica il file selezionato
T = readtable(fileName, 'VariableNamingRule', 'preserve');

% 2. Estrazione del numero del giorno usando le espressioni regolari (Regex)
day_strings = regexp(T.File_Source, 'day_(\d+)', 'tokens', 'once');
day_numbers = zeros(height(T), 1);

for i = 1:height(T)
    if ~isempty(day_strings{i})
        day_numbers(i) = str2double(day_strings{i}{1});
    else
        day_numbers(i) = 999; % Sistema di sicurezza
    end
end

% 3. Ordinamento gerarchico
T.Day_Num = day_numbers;
% Ordina prima per Giorno, poi per Ratto, poi per Trial (1 e 2)
T = sortrows(T, {'Day_Num', 'Rat_n', 'Trial_n'});
T.Day_Num = []; % Rimuove la colonna temporanea

% 4. Salvataggio nella stessa cartella da cui hai preso il file
nome_salvataggio = fullfile(percorso, 'WINSHIFT_SUPER_MASTER_SORTED.xlsx');
writetable(T, nome_salvataggio);
disp(['Tabella ordinata cronologicamente e salvata con successo come: WINSHIFT_SUPER_MASTER_SORTED.xlsx']);