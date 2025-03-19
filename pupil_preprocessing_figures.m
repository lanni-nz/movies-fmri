%%PUPIL SIZE PREPROCESSING:
function [output, figures]=pupil_preprocessing_figures(input_data,type_data,smooth,desired_duration, nsubj)
%input_data: text: directory containig a txt file per subject with 1
%column: pupil diameter column, or struct: one columns with subj in raws 
%type_data: 'text' or 'struct'
%smooth=1, smooth data with movmedian, =0 do not smooth
%desired_duration: desired timepoints to downsampling, omision interpolates
%to the average length
%nsubj: if output "figures" is selected, enter the desired number of
%subject to display each figure steps

%Preprocessing:
%removes the first 300 timepoints (luminance effects)
%1-removes artifacts due to device (lost of signal, etc)
%2-removes subjects with more than 40% of missing data
%3-Interpolates using calculated median, with a moving window of 100 timepoints  
%4-Does de-blinking based on changes higher or lower than 1.5 standard deviations
%5-Remove outliers data points
%6-Repeat steps 2 and 3 (with linear interpolation? why?)
%7-Filter data with medfilt (100 timepoints)
%8-Repeat steps 2 and 3
%9-Smooths (optional) with moving median
%10-Downsamples the data with linear interpolation to either the average length or the desired length 

%displaying figures
   figures = {};
        
    % Handle cases based on number of arguments
    if nargout > 1  % When figures are requested
        if nargin == 4  % display_iterations is passed as input4
            display_iterations = desired_duration;  % Take the value of input4 as display_iterations
        elseif nargin == 5  % display_iterations is passed as nsubj
            display_iterations = nsubj{1};  % Take the first sbuj as display_iterations
        end
    end



%calculate average length of data
for subj= 1:numel(input_data) %
    if strcmp(type_data, 'text')
        %data = load([input_data(subj).folder, filesep,input_data(subj).name]);
        data =  dlmread([input_data(subj).folder, filesep,input_data(subj).name]);
        all_lengthT(:,subj)= length(data);
        
    elseif strcmp(type_data, 'struct')
        data= input_data{subj,:};
        all_lengthT(:,subj)= length(data);
    end
end

mean_lengthT= round(mean(all_lengthT)); % average length 

%% PREPROCESSING

for sub=  1:numel(input_data) %
     disp(['Processing subject: ', num2str(sub)]);
    if strcmp(type_data, 'text')
        %pupil= load([input_data(sub).folder,'/',input_data(sub).name]);
         pupil =  dlmread([input_data(subj).folder, filesep,input_data(subj).name]);

    elseif strcmp(type_data, 'struct')
        pupil= input_data{sub,:};        
    end
    
    %figure Raw data-------------------
    if any(sub == display_iterations)
        figure, plot(pupil)
        title(['Raw data ', num2str(sub)]);
    end
    %-----------------------------------

    %remove the first 300 time points (for luminance effects)
    pupil(1:300,:)=[];

    %remove big spikes data
    isOut = isoutlier(pupil,'mean');
    
    % Create pupil2 with NaNs where outliers are and NaNs elsewhere
    % pupil2 = nan(length(pupil(~isnan(pupil))));
    % pupil2= pupil(isOut);

    pupil(isOut) = NaN;

    %remove subjects if nan>30%
    TT= length(pupil);
    thresh=TT*.60;
    real_length= length(pupil(~isnan(pupil)));

    if real_length < thresh
        disp(['Subject ', num2str(sub), ' has more than 40% outliers. Skipping...']);
        if sub == numel(input_data)
            disp('Reached the last subject. Stopping...');
            break; % Stop if this is the last iteration
        else
            continue; % Skip to the next time series
        end
    end

   
    % Fill missing values (interpolation)
    Fpupil_size = fillmissing(pupil,'nearest');

     %Figure after first filter-----------------------------------
    if any(sub == display_iterations)
        x = 1:length(pupil);
       
        figure, plot(Fpupil_size, 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 2);
        hold on,
        plot(x, pupil, 'b', 'LineWidth', 1);
        title(['First filter ', num2str(sub)]);
    end
    %-----------------------------------------------------
    
     
    % filter (based on percentile range):
    len = length(Fpupil_size);

    % Calculate 10th percentile of the length
    per10_len = prctile(len, 20);

    % Calculate window width and sliding step
    window_width = per10_len;
    sliding_step = per10_len;

    % Initialize output variable
    Fpupil_size_filtered = Fpupil_size;

    % Slide the window over the signal
    for i = 1:sliding_step:len - window_width + 1
        % Get data within the current window
        window_data = Fpupil_size(i:i + window_width - 1);

        per20 = prctile(window_data, 40);
        per80 = prctile(window_data, 90);
        isout = window_data < per20 | window_data > per80;

        % Replace values outside the conditions with NaN
        window_data(isout) = NaN;

        % Update the filtered signal with window_data
        Fpupil_size_filtered(i:i + window_width - 1) = window_data;
    end


    %remove subjects again
    real_length3= length(Fpupil_size(~isnan(Fpupil_size)));
     if real_length3 < thresh
        disp(['Subject ', num2str(sub), ' has more than 40% outliers. Skipping...']);
        if sub == numel(input_data)
            disp('Reached the last subject. Stopping...');
            break; % Stop if this is the last iteration
        else
            continue; % Skip to the next time series
        end
    end

    % Linearly interpolate missing values
    %Fpupil_size4 = fillmissing(Fpupil_size3,'linear');
    Fpupil_size2 = fillmissing(Fpupil_size_filtered,'nearest');

 %Figure after second filter-----------------------------------
    if any(sub == display_iterations)
              
        figure, plot(Fpupil_size2, 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 2);
        hold on,
        plot(Fpupil_size_filtered, 'b', 'LineWidth', 1);              
    end
    %-----------------------------------------------------


    % De-blinking (calculated thourgh changes)
     chang=diff(Fpupil_size2); %find changes in the signal

    %individual threshold:
    stand_dev1=std(Fpupil_size2); 
    stand_dev= stand_dev1/100;
    
    indiv_pos=(chang>stand_dev & chang>0); 
    indiv_neg=(chang>stand_dev & chang<0);

    Fpupil_size2(indiv_pos)=NaN;
    Fpupil_size2(indiv_neg)=NaN;

    %remove remaining spikes after deblinking  
    isOut2 = isoutlier(Fpupil_size2,'mean');    
    Fpupil_size2(isOut2) = NaN;

    % remove subjects 
    real_length2= length(Fpupil_size2(~isnan(Fpupil_size2)));
    if real_length2 < thresh
        disp(['Subject ', num2str(sub), ' has more than 40% outliers. Skipping...']);
        if sub == numel(input_data)
            disp('Reached the last subject. Stopping...');
            break; % Stop if this is the last iteration
        else
            continue; % Skip to the next time series
        end
    end

  
    %fill
    %Fpupil_size3 = fillmissing(Fpupil_size,'linear');
    Fpupil_size3 = fillmissing(Fpupil_size2,'nearest');


 %Figure after third filter-----------------------------------
    if any(sub == display_iterations)
              
        figure, plot(Fpupil_size3, 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 2);
        hold on,
        plot(Fpupil_size2, 'b', 'LineWidth', 1);              
    end
    %-----------------------------------------------------
   
    %filter data
    Fpupil_size4=medfilt1(Fpupil_size3,100,'omitnan', 'truncate'); % segment length, truncate: handle boundaries



 %Figure after 4th filter-----------------------------------
    if any(sub == display_iterations)
              
        figure, plot(Fpupil_size4, 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 2);
        hold on,
        plot(Fpupil_size3, 'b', 'LineWidth', 1);              
    end
    %-----------------------------------------------------

             
    if smooth==1
        % Smoothing
        pupil_sm = smoothdata(Fpupil_size4,'movmean'); %<--final pupil signal
        
        preprocessed_data= pupil_sm;

    else
        preprocessed_data= Fpupil_size4;
    end

    
  % Interpolation step outside the loop
idx = 1:length(preprocessed_data);
if isnumeric(desired_duration)
    idxq = linspace(min(idx), max(idx), desired_duration);
    output(:,sub)= interp1(idx, preprocessed_data, idxq, 'linear');
elseif strcmp(desired_duration, 'original')

% Ensure output matrix is initialized correctly
output{1,sub} =preprocessed_data;

else
    idxq = linspace(min(idx), max(idx), mean_lengthT);
    output{:,sub}= interp1(idx, preprocessed_data, idxq, 'linear');
end

end
end



