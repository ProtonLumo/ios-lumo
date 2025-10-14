(function() {
    function getLocalId() {
        try {
            const url = window.location.href;
            const pathName = new URL(url).pathname;
            const match = pathName.match(/\/u\/(\d+)\//);
            return match ? match[1] : null;
        } catch {
            return null;
        }
    }
    
    function readStoredTheme() {
        try {
            // Check if localStorage is available
            if (typeof Storage === "undefined" || !window.localStorage) {
                throw new Error("localStorage is not available");
            }
            
            const localId = getLocalId();
            const key = `lumo-settings${localId === null ? '' : `:${localId}`}`;
            
            const storedSettings = localStorage.getItem(key);
            
            if (storedSettings) {
                const settings = JSON.parse(storedSettings);
                
                // Just send the mode value as-is (0=system, 1=dark, 2=light)
                // Native code will handle determining the actual appearance for system theme
                const mode = settings.mode;
                
                // Send the stored theme to native
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.themeRead) {
                    window.webkit.messageHandlers.themeRead.postMessage({
                        success: true,
                        mode: mode,
                        key: key
                    });
                }
                
                return {
                    mode: mode
                };
            } else {
                // No stored theme found, default to system theme (mode 0)
                
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.themeRead) {
                    window.webkit.messageHandlers.themeRead.postMessage({
                        success: true,
                        mode: 0, // 0 = system theme
                        key: key,
                        reason: "No stored theme found, defaulting to system"
                    });
                }
                
                return {
                    mode: 0
                };
            }
        } catch (error) {
            // Error reading theme
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.themeRead) {
                window.webkit.messageHandlers.themeRead.postMessage({
                    success: false,
                    reason: "Error reading theme: " + error.message,
                    error: error.toString()
                });
            }
            
            return null;
        }
    }
    
    // Try to read the theme with a small delay to ensure DOM is ready
    function attemptThemeRead(retryCount = 0) {
        try {
            return readStoredTheme();
        } catch (error) {
            if (retryCount < 3) {
                // Retry after a short delay
                setTimeout(() => attemptThemeRead(retryCount + 1), 100);
                return null;
            } else {
                // Final attempt failed, send error
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.themeRead) {
                    window.webkit.messageHandlers.themeRead.postMessage({
                        success: false,
                        reason: "Failed after retries: " + error.message,
                        error: error.toString()
                    });
                }
                return null;
            }
        }
    }
    
    // Start the theme reading process
    return attemptThemeRead();
})();
