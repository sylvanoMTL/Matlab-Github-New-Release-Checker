%% Example 5: Custom Configuration
function example5_CustomConfig()
    fprintf('=== Example 5: Custom Configuration ===\n');
    
    updater = GitHubUpdateManager('SoftFever', 'OrcaSlicer', 'v2.1.0', ...
        'FileExtensionFilter', '64-bit.exe', ...       % Specific installer type
        'DownloadDirectory', fullfile(pwd, 'updates'),... % Custom download location
        'InstallMode', 'install', ...                   % Auto-run installer
        'AppName', 'Git for Windows', ...
        'OverwriteFiles', true);
    
    [needsQuit, wasUpdated] = updater.checkForUpdates();
end