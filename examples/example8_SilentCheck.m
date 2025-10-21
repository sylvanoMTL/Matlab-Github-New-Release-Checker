%% Example 8: Silent Update Check (No UI)
function example8_SilentCheck()
    fprintf('=== Example 8: Silent Update Check ===\n');
    
    updater = GitHubUpdateManager('Soft', 'vscode', 'v1.80.0', ...
        'Interactive', false);  % No UI dialogs
    
    % Manually check without user interaction
    try
        releaseInfo = updater.getLatestRelease();
        hasNew = updater.compareVersions(updater.CurrentVersion, releaseInfo.tag_name);
        
        if hasNew
            fprintf('New version available: %s -> %s\n', ...
                updater.CurrentVersion, releaseInfo.tag_name);
            
            % Log to file or send notification
            logUpdateAvailable(releaseInfo);
        else
            fprintf('Application is up to date\n');
        end
        
    catch ME
        fprintf('Silent update check failed: %s\n', ME.message);
    end
end

function logUpdateAvailable(releaseInfo)
    % Example logging function
    logFile = 'update_log.txt';
    fid = fopen(logFile, 'a');
    if fid > 0
        fprintf(fid, '[%s] New version available: %s\n', ...
            datestr(now), releaseInfo.tag_name);
        fclose(fid);
    end
end