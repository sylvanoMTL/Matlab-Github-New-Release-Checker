%% Example 2: Mandatory Update (Force New Release)
function example2_MandatoryUpdate()
    fprintf('=== Example 2: Mandatory Update ===\n');
    
    % Create update manager with forced updates
    updater = GitHubUpdateManager('SoftFever', 'OrcaSlicer', 'v2.1.0', ...
        'ForceNewRelease', true, ...
        'AppName', 'My Application', ...
        'FileExtensionFilter', '.exe');
    
    [needsQuit, wasUpdated] = updater.checkForUpdates();
    
    if needsQuit
        fprintf('User chose to quit - application should exit\n');
        return;  % or exit() in real application
    end
    
    if wasUpdated
        fprintf('Update completed - restart may be needed\n');
    end
end