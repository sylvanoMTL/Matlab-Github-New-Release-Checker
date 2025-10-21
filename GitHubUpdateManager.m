classdef GitHubUpdateManager < handle
    % GITHUBUPDATEMANAGER Comprehensive GitHub release update manager
    %
    % This class provides a complete solution for checking, downloading,
    % and installing updates from GitHub releases with user interaction.
    %
    % Example Usage:
    %   updater = GitHubUpdateManager('microsoft', 'vscode', 'v1.80.0');
    %   [needsQuit, wasUpdated] = updater.checkForUpdates();
    
    properties
        % Repository information
        Owner string = ""
        Repository string = ""
        CurrentVersion string = ""
        Token string = ""
        
        % Update behavior
        ForceNewRelease logical = false  % If true, user must update or quit
        FileExtensionFilter string = ""  % Filter for assets (e.g., 'windows', '.exe')
        
        % Download settings  
        DownloadDirectory string = "./downloads"
        InstallMode string = "auto"      % 'download', 'extract', 'install', 'auto'
        Interactive logical = true
        OverwriteFiles logical = true
        
        % UI settings
        AppName string = "Application"   % Name shown in dialogs
        progressFig %uifigure %uifigure for progress bar
    end
    
    properties (Access = private)
        LatestRelease = []
        SelectedAssets = []
        DownloadedFiles = {}
    end
    
    methods
        function obj = GitHubUpdateManager(owner, repo, currentVersion, varargin)
            % Constructor for GitHubUpdateManager
            if nargin > 0
                obj.Owner = string(owner);
                obj.Repository = string(repo);
                obj.CurrentVersion = string(currentVersion);
                
                % Parse optional parameters
                p = inputParser;
                addParameter(p, 'Token', '', @ischar);
                addParameter(p, 'FileExtensionFilter', '', @ischar);
                addParameter(p, 'ForceNewRelease', false, @islogical);
                addParameter(p, 'DownloadDirectory', './downloads', @ischar);
                addParameter(p, 'InstallMode', 'auto', @ischar);
                addParameter(p, 'Interactive', true, @islogical);
                addParameter(p, 'AppName', 'Application', @ischar);
                
                parse(p, varargin{:});
                
                obj.Token = string(p.Results.Token);
                obj.FileExtensionFilter = string(p.Results.FileExtensionFilter);
                obj.ForceNewRelease = p.Results.ForceNewRelease;
                obj.DownloadDirectory = string(p.Results.DownloadDirectory);
                obj.InstallMode = string(p.Results.InstallMode);
                obj.Interactive = p.Results.Interactive;
                obj.AppName = string(p.Results.AppName);
            end
        end
        
        function [needsQuit, wasUpdated] = checkForUpdates(obj)
            % Main method to check for updates and handle user interaction
            needsQuit = false;
            wasUpdated = false;
            
            try
                fprintf('Checking for updates for %s/%s...\n', obj.Owner, obj.Repository);
                
                % Get latest release information
                obj.LatestRelease = obj.getLatestRelease();
                
                % Check if new version is available
                hasNewRelease = obj.compareVersions(obj.CurrentVersion, obj.LatestRelease.tag_name);
                
                if ~hasNewRelease
                    fprintf('✅ You have the latest version: %s\n', obj.CurrentVersion);
                    return;
                end
                
                % New release available - show appropriate dialog
                fprintf('🎉 New release available: %s -> %s\n', obj.CurrentVersion, obj.LatestRelease.tag_name);
                
                if obj.ForceNewRelease
                    userChoice = obj.showForceUpdateDialog();
                else
                    userChoice = obj.showOptionalUpdateDialog();
                end
                
                % Handle user choice
                switch userChoice
                    case 'download'
                        wasUpdated = obj.performUpdate();
                    case 'skip'
                        fprintf('Update skipped by user\n');
                    case 'quit'
                        fprintf('User chose to quit\n');
                        needsQuit = true;
                    case 'cancel'
                        fprintf('Update cancelled by user\n');
                end
                
            catch ME
                obj.showErrorDialog('Update Check Failed', ME.message);
                fprintf('❌ Error checking for updates: %s\n', ME.message);
            end
        end
        
        function success = performUpdate(obj)
            % Download and install the update
            success = false;
            
            try
                % Set up cleanup to always run
                cleanup = onCleanup(@() obj.cleanupProgress());

                % Filter and select assets
                obj.SelectedAssets = obj.selectAssets(obj.LatestRelease.assets);
                
                if isempty(obj.SelectedAssets)
                    obj.showErrorDialog('No Assets', 'No suitable installation files found.');
                    return;
                end
                
                % Create download directory
                if ~exist(obj.DownloadDirectory, 'dir')
                    mkdir(obj.DownloadDirectory);
                end
                
                % Show download progress
                progressDlg = obj.showProgressDialog('Downloading update...');
                
                % Check if user cancelled before starting download
                if obj.isProgressCancelled(progressDlg)
                    fprintf('Download cancelled by user\n');
                    return;
                end
                
                % Download assets
                obj.DownloadedFiles = obj.downloadAssets(obj.SelectedAssets, progressDlg);
                
                % Check if user cancelled during download
                if obj.isProgressCancelled(progressDlg)
                    fprintf('Download cancelled by user\n');
                    return;
                end
                
                % Process downloaded files
                if ~isempty(obj.DownloadedFiles)
                    success = obj.processDownloadedFiles(obj.DownloadedFiles);
                end
                
                if success
                    obj.showSuccessDialog();
                    fprintf('✅ Update completed successfully!\n');
                else
                    obj.showErrorDialog('Installation Failed', 'Could not complete installation.');
                end
                
            catch ME
                obj.showErrorDialog('Update Failed', ME.message);
                fprintf('❌ Update failed: %s\n', ME.message);
            end
        end

        function cleanupProgress(obj)
            % Properly cleanup the progress figure if it exists
            if isprop(obj, 'progressFig') && ~isempty(obj.progressFig) && isvalid(obj.progressFig)
                try
                    close(obj.progressFig);
                    delete(obj.progressFig);
                    obj.progressFig = [];  % Clear the reference
                catch
                    % Silent fail if already deleted
                end
            end
        end
    end
    
    methods (Access = private)
        function releaseInfo = getLatestRelease(obj)
            % Get latest release information from GitHub API
            apiUrl = sprintf('https://api.github.com/repos/%s/%s/releases/latest', obj.Owner, obj.Repository);
            
            options = weboptions('UserAgent', 'MATLAB-UpdateManager/1.0', ...
                               'ContentType', 'json', ...
                               'Timeout', 30);
            
            if obj.Token ~= ""
                options.HeaderFields = {'Authorization', ['Bearer ' char(obj.Token)]};
            end
            
            releaseInfo = webread(apiUrl, options);
        end
        
        function hasNewRelease = compareVersions(obj, currentVersion, latestVersion)
            % Compare version strings to determine if update is available
            % Remove 'v' prefix and clean whitespace
            current = strtrim(regexprep(currentVersion, '^v', ''));
            latest = strtrim(regexprep(latestVersion, '^v', ''));
            
            % Split into numeric parts
            currentParts = str2double(split(current, '.'));
            latestParts = str2double(split(latest, '.'));
            
            % Handle non-numeric parts
            if any(isnan(currentParts)) || any(isnan(latestParts))
                hasNewRelease = ~strcmp(current, latest);
                return;
            end
            
            % Pad with zeros to make same length
            maxLen = max(length(currentParts), length(latestParts));
            currentParts(end+1:maxLen) = 0;
            latestParts(end+1:maxLen) = 0;
            
            % Compare each part
            for i = 1:maxLen
                if latestParts(i) > currentParts(i)
                    hasNewRelease = true;
                    return;
                elseif latestParts(i) < currentParts(i)
                    hasNewRelease = false;
                    return;
                end
            end
            
            hasNewRelease = false; % Versions are equal
        end
        
        function selectedAssets = selectAssets(obj, assets)
            % Filter and select assets based on criteria
            selectedAssets = [];
            
            if isempty(assets)
                return;
            end
            
            % Apply filter if specified
            if obj.FileExtensionFilter ~= ""
                filteredAssets = [];
                for i = 1:length(assets)
                    assetName = assets(i).name;
                    if contains(lower(assetName), lower(obj.FileExtensionFilter))
                        filteredAssets = [filteredAssets, assets(i)];
                    end
                end
                assets = filteredAssets;
            end
            
            if isempty(assets)
                return;
            end
            
            % For non-interactive mode or single asset, select all
            if ~obj.Interactive || length(assets) == 1
                selectedAssets = assets;
            else
                % Show asset selection dialog
                selectedAssets = obj.showAssetSelectionDialog(assets);
            end
        end
        
        function downloadedFiles = downloadAssets(obj, assets, progressDlg)
            % Download selected assets
            downloadedFiles = {};
            
            for i = 1:length(assets)
                % Check if user cancelled during download
                if nargin > 2 && obj.isProgressCancelled(progressDlg)
                    fprintf('Download cancelled by user during asset %d\n', i);
                    break;
                end
                
                asset = assets(i);
                filename = fullfile(obj.DownloadDirectory, asset.name);
                
                % Skip if file exists and overwrite is disabled
                if exist(filename, 'file') && ~obj.OverwriteFiles
                    downloadedFiles{end+1} = filename;
                    continue;
                end
                
                fprintf('Downloading %s...\n', asset.name);
                
                % Update progress message if dialog is provided
                if nargin > 2 && isvalid(progressDlg)
                    obj.updateProgressMessage(progressDlg, sprintf('Downloading %s (%d/%d)...', asset.name, i, length(assets)));
                end
                
                try
                    options = weboptions('Timeout', 300);
                    if obj.Token ~= ""
                        options.HeaderFields = {'Authorization', ['Bearer ' char(obj.Token)]; ...
                                              'Accept', 'application/octet-stream'};
                    end
                    
                    websave(filename, asset.browser_download_url, options);
                    downloadedFiles{end+1} = filename;
                    
                catch ME
                    fprintf('Failed to download %s: %s\n', asset.name, ME.message);
                end
            end
        end
        
        function success = processDownloadedFiles(obj, downloadedFiles)
            % Process downloaded files based on installation mode
            success = true;
            
            for i = 1:length(downloadedFiles)
                filepath = downloadedFiles{i};
                [~, ~, ext] = fileparts(filepath);
                
                switch lower(obj.InstallMode)
                    case 'download'
                        % Just download, no processing
                        continue;
                    case 'extract'
                        if ismember(lower(ext), {'.zip', '.tar', '.gz'})
                            success = success && obj.extractArchive(filepath);
                        end
                    case 'install'
                        if ismember(lower(ext), {'.exe', '.msi', '.pkg', '.dmg'})
                            success = success && obj.runInstaller(filepath);
                        end
                    case 'auto'
                        if ismember(lower(ext), {'.zip', '.tar', '.gz'})
                            success = success && obj.extractArchive(filepath);
                        elseif ismember(lower(ext), {'.exe', '.msi', '.pkg', '.dmg'})
                            success = success && obj.runInstaller(filepath);
                        end
                end
            end
        end
        
        function success = extractArchive(obj, filepath)
            % Extract archive files
            success = false;
            [pathstr, name, ext] = fileparts(filepath);
            extractDir = fullfile(pathstr, name);
            
            try
                switch lower(ext)
                    case '.zip'
                        unzip(filepath, extractDir);
                        success = true;
                    case {'.tar', '.gz'}
                        untar(filepath, extractDir);
                        success = true;
                end
            catch ME
                fprintf('Extraction failed: %s\n', ME.message);
            end
        end
        
        function success = runInstaller(obj, filepath)
            % Run installer with proper platform handling
            success = false;
            [~, ~, ext] = fileparts(filepath);
            
            try
                if ispc && ismember(lower(ext), {'.exe', '.msi'})
                    winopen(filepath);
                    success = true;
                elseif ismac && ismember(lower(ext), {'.pkg', '.dmg'})
                    system(sprintf('open "%s"', filepath));
                    success = true;
                else
                    fprintf('Installer format not supported on this platform\n');
                end
            catch ME
                fprintf('Failed to run installer: %s\n', ME.message);
            end
        end
        
        function choice = showOptionalUpdateDialog(obj)
            % Show dialog for optional updates
            if ~obj.Interactive
                choice = 'download';
                return;
            end
            
            try
                % Center figure on screen
                screenSize = get(0, 'ScreenSize');
                figW = 450;
                figH = 250;
                figX = (screenSize(3) - figW) / 2;
                figY = (screenSize(4) - figH) / 2;

                fig = uifigure('Name', sprintf('%s Update Available', obj.AppName), ...
                              'Position', [figX, figY, figW, figH], ...
                              'WindowStyle', 'modal');
                
                % Use absolute positioning instead of grid layout
                % Message
                msg = sprintf('A new version of %s is available!\n\nCurrent: %s\nLatest: %s\n\nWould you like to download it now?', ...
                    obj.AppName, obj.CurrentVersion, obj.LatestRelease.tag_name);
                uilabel(fig, 'Position', [20 80 410 120], ...
                       'Text', msg, ...
                       'WordWrap', 'on', ...
                       'HorizontalAlignment', 'center', ...
                       'VerticalAlignment', 'center');
                
                % Default choice
                choice = 'cancel';
                
                % Buttons with absolute positioning
                uibutton(fig, 'Position', [70 20 140 40], ...
                        'Text', 'Download', ...
                        'ButtonPushedFcn', @(~,~) setChoice('download'));
                
                uibutton(fig, 'Position', [240 20 140 40], ...
                        'Text', 'Skip This Version', ...
                        'ButtonPushedFcn', @(~,~) setChoice('skip'));
                
                % Wait for user choice
                uiwait(fig);
                
            catch
                % Fallback to command line input
                fprintf('\nNew version available: %s -> %s\n', obj.CurrentVersion, obj.LatestRelease.tag_name);
                answer = input('Download update? (y/n/s for skip): ', 's');
                switch lower(answer(1))
                    case 'y'
                        choice = 'download';
                    case 's'
                        choice = 'skip';
                    otherwise
                        choice = 'cancel';
                end
            end
            
            function setChoice(newChoice)
                choice = newChoice;
                if exist('fig', 'var') && isvalid(fig)
                    close(fig);
                end
            end
        end
        
        function choice = showForceUpdateDialog(obj)
            % Show dialog for mandatory updates
            if ~obj.Interactive
                choice = 'download';
                return;
            end
            
            try
                % Center figure on screen
                screenSize = get(0, 'ScreenSize');
                figW = 450;
                figH = 280;
                figX = (screenSize(3) - figW) / 2;
                figY = (screenSize(4) - figH) / 2;
                
              
                fig = uifigure('Name', sprintf('%s Update Required', obj.AppName), ... 
                              'Position', [figX, figY, figW, figH], ...
                              'WindowStyle', 'modal');
                
                % Message with absolute positioning
                msg = sprintf('A mandatory update is required!\n\nCurrent: %s\nRequired: %s\n\nYou must download the update to continue using %s.', ...
                    obj.CurrentVersion, obj.LatestRelease.tag_name, obj.AppName);
                uilabel(fig, 'Position', [20 100 410 140], ...
                       'Text', msg, ...
                       'WordWrap', 'on', ...
                       'HorizontalAlignment', 'center', ...
                       'VerticalAlignment', 'center');
                
                choice = 'quit';
                
                % Buttons with absolute positioning
                uibutton(fig, 'Position', [70 30 140 40], ...
                        'Text', 'Download Update', ...
                        'ButtonPushedFcn', @(~,~) setChoice('download'));
                
                uibutton(fig, 'Position', [240 30 140 40], ...
                        'Text', 'Quit Application', ...
                        'ButtonPushedFcn', @(~,~) setChoice('quit'));
                
                uiwait(fig);
                
            catch
                % Fallback to command line
                fprintf('\nMandatory update required: %s -> %s\n', obj.CurrentVersion, obj.LatestRelease.tag_name);
                answer = input('Download update? (y/n for quit): ', 's');
                if lower(answer(1)) == 'y'
                    choice = 'download';
                else
                    choice = 'quit';
                end
            end
            
            function setChoice(newChoice)
                choice = newChoice;
                if exist('fig', 'var') && isvalid(fig)
                    close(fig);
                end
            end
        end
        
        function selectedAssets = showAssetSelectionDialog(obj, assets)
            % Show dialog to select which assets to download
            selectedAssets = assets; % Default fallback
            
            try
                % Center figure on screen
                screenSize = get(0, 'ScreenSize');
                figW = 500;
                figH = 400;
                figX = (screenSize(3) - figW) / 2;
                figY = (screenSize(4) - figH) / 2;
                
                fig = uifigure('Name', 'Select Files to Download', ...
                    'Position', [figX, figY, figW, figH], ...
                    'WindowStyle', 'modal');
                
                uilabel(fig, 'Position', [20 350 460 30], ...
                    'Text', 'Select files to download:', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'left');
                
                assetNames = {assets.name};
                listbox = uilistbox(fig, 'Position', [20 60 460 270], ...
                    'Items', assetNames, ...
                    'Multiselect', 'on', ...
                    'Value', assetNames);
                
                uibutton(fig, 'Position', [175 15 150 35], ...
                    'Text', 'Download Selected', ...
                    'ButtonPushedFcn', @(~,~) selectAndClose());
                
                uiwait(fig);
                
            catch
                % Fallback: select all assets
                selectedAssets = assets;
            end
            
            function selectAndClose()
                selected = listbox.Value;
                selectedIndices = ismember(assetNames, selected);
                selectedAssets = assets(selectedIndices);
                close(fig);
            end
        end
        
        function dlg = showProgressDialog(obj, message)
            % Show progress dialog during download
            try
                screenSize = get(0, 'ScreenSize');
                figW = 500;
                figH = 400;
                figX = (screenSize(3) - figW) / 2;
                figY = (screenSize(4) - figH) / 2;
                obj.progressFig = uifigure('Name', 'Download progress','Visible','on',...
                                            'Position', [figX, figY, figW, figH], ...
                                            'WindowStyle', 'modal');
                dlg = uiprogressdlg(obj.progressFig, 'Title', obj.AppName, ...
                                   'Message', message, ...
                                   'Indeterminate', 'on', ...
                                   'Cancelable', 'on', ...
                                   'CancelText', 'Cancel Download');
            catch
                % Fallback: create simple figure with close callback
                dlg = uifigure('Name', obj.AppName, 'Position', [100 100 350 120]);
                
                % Add close request callback
                dlg.CloseRequestFcn = @(src, ~) handleClose(src);
                
                % Message label
                uilabel(dlg, 'Text', message, 'Position', [20 60 310 30], ...
                       'HorizontalAlignment', 'center');
                
                % Cancel button
                uibutton(dlg, 'Position', [125 20 100 30], ...
                         'Text', 'Cancel', ...
                         'ButtonPushedFcn', @(~,~) close(dlg));
                
                drawnow;
            end
            
            function handleClose(src)
                % Handle close request
                delete(src);
            end
        end
        
        function showSuccessDialog(obj)
            % Show success message
            try
                screenSize = get(0, 'ScreenSize');
                figW = 500;
                figH = 400;
                figX = (screenSize(3) - figW) / 2;
                figY = (screenSize(4) - figH) / 2;
                % Create named figure for the alert
                alertFig = uifigure('Name', sprintf('%s Success', obj.AppName),...
                                    'Position', [figX, figY, figW, figH], ...
                                    'WindowStyle', 'modal');
                uialert(alertFig, 'Update completed successfully!', obj.AppName, 'Icon', 'success',...
                    'CloseFcn', @(src,event) delete(alertFig));
            catch
                fprintf('✅ Update completed successfully!\n');
            end
        end
        
        function showErrorDialog(obj, title, message)
            % Show error dialog
            try
                screenSize = get(0, 'ScreenSize');
                figW = 500;
                figH = 400;
                figX = (screenSize(3) - figW) / 2;
                figY = (screenSize(4) - figH) / 2;
                % Create named figure for the alert
                alertFig = uifigure('Name', sprintf('%s Error', obj.AppName),...
                                    'Position', [figX, figY, figW, figH], ...
                                    'WindowStyle', 'modal');
                uialert(alertFig, message, title, 'Icon', 'error', ...
                    'CloseFcn', @(src,event) delete(alertFig));
                uiwait(alertFig);
            catch
                fprintf('❌ %s: %s\n', title, message);
            end
        end
        
        function cancelled = isProgressCancelled(obj, progressDlg)
            % Check if progress dialog was cancelled by user
            cancelled = false;
            
            if ~isvalid(progressDlg)
                cancelled = true;
                return;
            end
            
            try
                % For uiprogressdlg, check CanceledByUser property
                if isprop(progressDlg, 'CanceledByUser')
                    cancelled = progressDlg.CanceledByUser;
                end
            catch
                % If we can't check, assume not cancelled
                cancelled = false;
            end
        end
        
        function updateProgressMessage(obj, progressDlg, message)
            % Update progress dialog message
            try
                if isvalid(progressDlg) && isprop(progressDlg, 'Message')
                    progressDlg.Message = message;
                end
            catch
                % Ignore errors when updating message
            end
        end
    end
end