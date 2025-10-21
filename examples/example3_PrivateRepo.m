%% Example 3: Private Repository with Token
function example3_PrivateRepo()
    fprintf('=== Example 3: Private Repository ===\n');
    
    % You would get this token from secure storage or environment variable
    token = 'ghp_your_token_here';  % Don't hardcode in real applications!
    
    updater = GitHubUpdateManager('SoftFever', 'OrcaSlicer', 'v2.1.0', ...
        'Token', token, ...
        'AppName', 'Private App', ...
        'DownloadDirectory', 'C:\Updates');
    
    [needsQuit, wasUpdated] = updater.checkForUpdates();
end
