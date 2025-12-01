(function() {
    'use strict';
    
    // Global error handling
    window.addEventListener('error', function(event) {
        console.error('Unhandled JavaScript error:', event.error);
    });
    
    // Utility functions
    window.LumoPageUtils = {
        // Check for lumo input container
        hasLumoContainer: function() {
            return !!document.querySelector('.lumo-input-container');
        },
        
        // Element found checker (returns object for better compatibility)
        checkElement: function() {
            return {
                elementFound: !!document.querySelector('.lumo-input-container')
            };
        },
        
        // Force layout reflow
        forceLayout: function() {
            if (document.body) {
                document.body.getBoundingClientRect();
            }
        }
    };
    
    console.log('🔧 Page utilities initialized');
    return null;
})(); 