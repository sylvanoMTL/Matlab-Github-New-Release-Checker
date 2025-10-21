%% Example 7: Batch Update Multiple Components
function example7_BatchUpdates()
    fprintf('=== Example 7: Batch Updates ===\n');
    
    % Define components to update
    components = {
        {'microsoft', 'vscode', 'v1.80.0', 'VS Code'}, ...
        {'git-for-windows', 'git', 'v2.40.0', 'Git'}, ...
        {'nodejs', 'node', 'v18.0.0', 'Node.js'}
    };
    
    for i = 1:length(components)
        comp = components{i};
        fprintf('\n--- Checking %s ---\n', comp{4});
        
        try
            updater = GitHubUpdateManager(comp{1}, comp{2}, comp{3}, ...
                'AppName', comp{4}, ...
                'Interactive', false, ...  % Batch mode - no prompts
                'FileExtensionFilter', 'win');
            
            [~, wasUpdated] = updater.checkForUpdates();
            
            if wasUpdated
                fprintf('✅ %s updated successfully\n', comp{4});
            else
                fprintf('ℹ️  %s is up to date\n', comp{4});
            end
            
        catch ME
            fprintf('❌ Failed to update %s: %s\n', comp{4}, ME.message);
        end
    end
    
    fprintf('\nBatch update completed!\n');
end