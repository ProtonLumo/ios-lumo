(function() {
    'use strict';
    
    function shouldOpenExternally(url) {
        if (!url) return false;
        
        const urlString = url.toString();
        
        // Support, docs, legal pages
        if (urlString.includes('proton.me/support') ||
            urlString.includes('proton.me/docs') ||
            urlString.includes('proton.me/legal') ||
            urlString.includes('proton.me/business') ||
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
    
    function openInSafari(url) {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.openExternalURL) {
            window.webkit.messageHandlers.openExternalURL.postMessage({ url: url });
            return true;
        }
        return false;
    }
    
    // INTERCEPT window.open()
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
    
    // INTERCEPT window.location changes
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
    
    // INTERCEPT link clicks (for regular <a> tags)
    document.addEventListener('click', function(e) {
        let target = e.target;
        
        while (target && target.tagName !== 'A') {
            target = target.parentElement;
        }
        
        if (!target || target.tagName !== 'A') {
            return;
        }
        
        const href = target.href;
        
        if (shouldOpenExternally(href)) {
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
            
            openInSafari(href);
        }
    }, true);
})();

