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
                
                // For system theme, always use current system preference, not stored mode
                // The stored mode might be stale if device appearance changed since last save
                let actualMode = settings.mode;
                // Check if theme is "system" (stored as theme 14 with mode 0, or possibly theme 16)
                const isSystemTheme = (settings.theme === 14 && settings.mode === 0) || settings.theme === 16;
                if (isSystemTheme) {
                    actualMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 1 : 2; // 1=dark, 2=light
                }
                
                // Send the stored theme to native
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.themeRead) {
                    window.webkit.messageHandlers.themeRead.postMessage({
                        success: true,
                        theme: settings.theme,
                        mode: actualMode,
                        storedMode: settings.mode,
                        key: key,
                        rawSettings: storedSettings,
                        isSystemTheme: isSystemTheme
                    });
                }
                
                return {
                    theme: settings.theme,
                    mode: actualMode
                };
            } else {
                // No stored theme found, default to system theme
                const systemMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 1 : 2; // 1=dark, 2=light
                
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.themeRead) {
                    window.webkit.messageHandlers.themeRead.postMessage({
                        success: true,
                        theme: 16, // system theme (assuming 16, or could use 14 with mode 0)
                        mode: systemMode,
                        key: key,
                        reason: "No stored theme found, defaulting to system",
                        isDefault: true
                    });
                }
                
                return {
                    theme: 16, // system (or 14)
                    mode: systemMode
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
