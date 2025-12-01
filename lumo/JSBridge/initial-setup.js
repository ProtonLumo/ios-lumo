(function() {
    'use strict';
    
    function preventScaling() {
        document.documentElement.style.transform = 'none';
        document.body.style.transform = 'none';
        
        document.documentElement.style.zoom = 1;
        document.body.style.zoom = 1;
    }
    
    function setupViewport() {
        document.documentElement.style.width = '100%';
        document.documentElement.style.height = '100%';
        document.body.style.margin = '0';
        document.body.style.padding = '0';
        
        let viewportMeta = document.querySelector('meta[name="viewport"]');
        if (!viewportMeta) {
            viewportMeta = document.createElement('meta');
            viewportMeta.name = 'viewport';
            document.head.appendChild(viewportMeta);
        }
        
        viewportMeta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
    }
    
    function forceReflow() {
        if (document.body) {
            document.body.getBoundingClientRect();
        }
    }
    
    preventScaling();
    setupViewport();
    forceReflow();
    
    console.log('✅ Initial page setup completed');
    return null;
})(); 
