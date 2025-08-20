// Common utility functions for JSBridge scripts
window.LumoUtils = (function() {
    
    // Set viewport meta tag with standard Lumo settings
    function setViewport() {
        var viewport = document.querySelector('meta[name="viewport"]');
        if (!viewport) {
            viewport = document.createElement('meta');
            viewport.name = 'viewport';
            document.head.appendChild(viewport);
        }
        viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        return viewport;
    }
    
    // Safe webkit message handler call
    function sendWebKitMessage(handlerName, data) {
        try {
            if (window.webkit && window.webkit.messageHandlers && 
                window.webkit.messageHandlers[handlerName]) {
                window.webkit.messageHandlers[handlerName].postMessage(data || {});
                return true;
            } else {
                console.warn('WebKit message handler not found: ' + handlerName);
                return false;
            }
        } catch (e) {
            console.error('Error sending WebKit message to ' + handlerName + ':', e);
            return false;
        }
    }
    
    // Force layout recalculation
    function forceLayout() {
        if (document.body) {
            document.body.getBoundingClientRect();
        }
    }
    
    // Debounce function utility
    function debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = function() {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
    
    function isElementVisible(element) {
        return element && element.offsetParent !== null;
    }
    
    // Layout stabilization functions (shared between scripts)
    let stabilizationStyleElement = null;
    
    function applyLayoutStabilization() {
        /**
         * This is a hack to prevent layout shifts by targeting 
         * the specific problematic CSS selector.
         * These shifts were specifically caused after message submissions.
         */
        if (stabilizationStyleElement) {
            // Remove existing stabilization first
            restoreLayout();
        }
        
        stabilizationStyleElement = document.createElement('style');
        stabilizationStyleElement.id = 'lumo-layout-stabilization';
        stabilizationStyleElement.textContent = `
            html:not(.feature-scrollbars-off) * {
                bottom: 0 !important;
            }
        `;
        document.head.appendChild(stabilizationStyleElement);
        console.log('✅ Layout stabilization applied');
        return true;
    }
    
    function restoreLayout() {
        if (stabilizationStyleElement) {
            document.head.removeChild(stabilizationStyleElement);
            stabilizationStyleElement = null;
            console.log('✅ Layout stabilization restored');
            return true;
        }
        return false;
    }
    
    return {
        setViewport: setViewport,
        sendWebKitMessage: sendWebKitMessage,
        forceLayout: forceLayout,
        debounce: debounce,
        isElementVisible: isElementVisible,
        applyLayoutStabilization: applyLayoutStabilization,
        restoreLayout: restoreLayout
    };
})(); 
