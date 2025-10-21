%% GitHubUpdateManager Usage Examples
% This file demonstrates how to use the GitHubUpdateManager class

%% Example 1: Basic Optional Update Check
function example1_BasicUpdate()
    fprintf('=== Example 1: Basic Optional Update ===\n');
    
    % Create update manager for VS Code
    updater = GitHubUpdateManager('SoftFever', 'OrcaSlicer', 'v2.1.0', ...
        'AppName', 'Orca', ...
        'FileExtensionFilter', 'win');  % Only Windows files
    
    % Check for updates (user can skip)
    [needsQuit, wasUpdated] = updater.checkForUpdates();
    
    fprintf('Needs quit: %s, Was updated: %s\n', string(needsQuit), string(wasUpdated));
end

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












% %% Run All Examples
% function runAllExamples()
%     fprintf('=== Running All GitHubUpdateManager Examples ===\n\n');
% 
%     examples = {
%         @example1_BasicUpdate, ...
%         @example2_MandatoryUpdate, ...
%         @example3_PrivateRepo, ...
%         @example4_ExtractOnly, ...
%         @example5_CustomConfig, ...
%         @example6_AppStartup, ...
%         @example7_BatchUpdates, ...
%         @example8_SilentCheck
%     };
% 
%     for i = 1:length(examples)
%         try
%             examples{i}();
%         catch ME
%             fprintf('Example %d failed: %s\n', i, ME.message);
%         end
% 
%         fprintf('\n');
% 
%         if i < length(examples)
%             input('Press Enter to continue to next example...');
%         end
%     end
% 
%     fprintf('All examples completed!\n');
% end