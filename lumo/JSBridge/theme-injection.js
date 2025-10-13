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
    
    function injectTheme() {
        try {
            // Check if localStorage is available
            if (typeof Storage === "undefined" || !window.localStorage) {
                throw new Error("localStorage is not available");
            }
            
            const localId = getLocalId();
            const key = `lumo-settings${localId === null ? '' : `:${localId}`}`;
            
            const themeObj = {
                theme: {{THEME}},  // Int
                mode: {{MODE}}     // Int
            };

            localStorage.setItem(key, JSON.stringify(themeObj));
    
            // Log for debugging
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.themeInjected) {
                window.webkit.messageHandlers.themeInjected.postMessage({
                    success: true,
                    theme: {{THEME}},
                    mode: {{MODE}},
                    key: key
                });
            }
            
            return true;
        } catch (error) {
            // Send error message to native
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.themeInjected) {
                window.webkit.messageHandlers.themeInjected.postMessage({
                    success: false,
                    error: error.message,
                    theme: {{THEME}},
                    mode: {{MODE}}
                });
            }
            
            return false;
        }
    }
    
    // Try to inject theme with retry mechanism
    function attemptThemeInjection(retryCount = 0) {
        const success = injectTheme();
        
        if (!success && retryCount < 3) {
            // Retry after a short delay
            setTimeout(() => attemptThemeInjection(retryCount + 1), 100);
        }
    }
    
    // Start the theme injection process
    attemptThemeInjection();
})();


