(function() {
    'use strict';
    
    // Prevent scaling and zoom issues
    function preventScaling() {
        // Reset any transforms that may cause scaling effects
        document.documentElement.style.transform = 'none';
        document.body.style.transform = 'none';
        
        // Set zoom exactly to 1.0
        document.documentElement.style.zoom = 1;
        document.body.style.zoom = 1;
    }
    
    // Set proper viewport and layout
    function setupViewport() {
        // Ensure correct layout
        document.documentElement.style.width = '100%';
        document.documentElement.style.height = '100%';
        document.body.style.margin = '0';
        document.body.style.padding = '0';
        
        // Set proper viewport meta tag if not exists
        let viewportMeta = document.querySelector('meta[name="viewport"]');
        if (!viewportMeta) {
            viewportMeta = document.createElement('meta');
            viewportMeta.name = 'viewport';
            document.head.appendChild(viewportMeta);
        }
        
        // Set optimal viewport settings
        viewportMeta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
    }
    
    // Force layout reflow
    function forceReflow() {
        if (window.LumoUtils) {
            window.LumoUtils.forceLayout();
        } else {
            document.body.getBoundingClientRect();
        }
    }
    
    // Execute all setup functions
    preventScaling();
    setupViewport();
    forceReflow();
    
    console.log('✅ Initial page setup completed');
    return null;
})(); 