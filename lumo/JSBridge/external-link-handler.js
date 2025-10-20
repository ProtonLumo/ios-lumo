// Intercept external links and window.open calls to open them in Safari
(function() {
    'use strict';
    
    // Function to check if URL should open externally
    function shouldOpenExternally(url) {
        if (!url) return false;
        
        const urlString = url.toString();
        
        // Support, docs, legal pages
        if (urlString.includes('proton.me/support') ||
            urlString.includes('proton.me/docs') ||
            urlString.includes('proton.me/legal') ||
            urlString.includes('proton.me/terms') ||
            urlString.includes('proton.me/privacy')) {
            return true;
        }
        
        // External domains (not proton.me)
        try {
            const urlObj = new URL(urlString);
            if (!urlObj.hostname.includes('proton.me')) {
                return true;
            }
        } catch (e) {
            // Invalid URL
        }
        
        return false;
    }
    
    // Function to open URL in Safari via native bridge
    function openInSafari(url) {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.openExternalURL) {
            window.webkit.messageHandlers.openExternalURL.postMessage({ url: url });
            return true;
        }
        return false;
    }
    
    // 1. INTERCEPT window.open()
    const originalWindowOpen = window.open;
    window.open = function(url, target, features) {
        if (shouldOpenExternally(url)) {
            openInSafari(url);
            // Return a fake window object to prevent errors
            return {
                closed: false,
                close: function() {},
                focus: function() {}
            };
        }
        
        // Call original for internal URLs
        return originalWindowOpen.apply(this, arguments);
    };
    
    // 2. INTERCEPT window.location changes
    let isSettingLocation = false;
    Object.defineProperty(window, 'location', {
        get: function() {
            return document.location;
        },
        set: function(url) {
            if (!isSettingLocation && shouldOpenExternally(url)) {
                isSettingLocation = true;
                openInSafari(url);
                isSettingLocation = false;
                return;
            }
            
            // Allow internal navigation
            document.location = url;
        }
    });
    
    // 3. INTERCEPT link clicks (for regular <a> tags)
    document.addEventListener('click', function(e) {
        let target = e.target;
        
        // Find the closest <a> tag
        while (target && target.tagName !== 'A') {
            target = target.parentElement;
        }
        
        if (!target || target.tagName !== 'A') {
            return;
        }
        
        const href = target.href;
        
        if (shouldOpenExternally(href)) {
            // Prevent default navigation
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
            
            openInSafari(href);
        }
    }, true); // Use capture phase to intercept before other handlers
})();

