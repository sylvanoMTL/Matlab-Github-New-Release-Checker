%% Example 6: Integration in Application Startup
function example6_AppStartup()
    fprintf('=== Example 6: Application Startup Integration ===\n');
    
    % This shows how you might integrate the updater into your app's startup
    
    try
        % Create updater with your app's information
        updater = GitHubUpdateManager('SoftFever', 'OrcaSlicer', getCurrentAppVersion(), ...
            'ForceNewRelease', false, ...           % Optional updates
            'AppName', 'My Application', ...
            'FileExtensionFilter', getPlatformFilter(), ...
            'DownloadDirectory', getAppUpdateDir());
        
        % Check for updates
        [needsQuit, wasUpdated] = updater.checkForUpdates();
        
        if needsQuit
            % User chose to quit instead of updating
            fprintf('Application exiting due to user choice\n');
            return;
        end
        
        if wasUpdated
            % Show restart notification
            choice = questdlg('Update completed. Restart application now?', ...
                'Update Complete', 'Restart Now', 'Restart Later', 'Restart Now');
            
            if strcmp(choice, 'Restart Now')
                restartApplication();
            end
        end
        
        % Continue with normal application startup
        startMainApplication();
        
    catch ME
        fprintf('Update check failed: %s\n', ME.message);
        % Continue with normal startup even if update check fails
        startMainApplication();
    end
end

%% Helper functions for Example 6
function version = getCurrentAppVersion()
    % In real app, this might read from a config file or version.txt
    version = 'v1.2.3';
end

function filter = getPlatformFilter()
    % Platform-specific file filtering
    if ispc
        filter = 'windows';
    elseif ismac
        filter = 'mac';
    else
        filter = 'linux';
    end
end

function dir = getAppUpdateDir()
    % Application-specific update directory
    if ispc
        dir = fullfile(getenv('APPDATA'), 'MyApp', 'Updates');
    else
        dir = fullfile(getenv('HOME'), '.myapp', 'updates');
    end
end

function startMainApplication()
    fprintf('Starting main application...\n');
    % Your main application code here
end

function restartApplication()
    fprintf('Restarting application...\n');
    % In real app, you might:
    % 1. Save current state
    % 2. Launch new version
    % 3. Exit current process
end