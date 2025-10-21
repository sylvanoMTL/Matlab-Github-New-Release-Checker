%% Example 4: Extract Only Mode (No Installation)
function example4_ExtractOnly()
    fprintf('=== Example 4: Extract Only ===\n');
    
    updater = GitHubUpdateManager('SoftFever', 'OrcaSlicer', 'v2.1.0', ...
        'InstallMode', 'extract', ...
        'FileExtensionFilter', '.zip', ...
        'Interactive', false);  % No user prompts during download
    
    [needsQuit, wasUpdated] = updater.checkForUpdates();
end