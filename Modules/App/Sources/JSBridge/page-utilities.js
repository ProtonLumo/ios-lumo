(function() {
    'use strict';
    
    window.addEventListener('error', function(event) {
        console.error('Unhandled JavaScript error:', event.error);
    });
    
    // Utility functions
    window.LumoPageUtils = {
        hasLumoContainer: function() {
            return !!document.querySelector('.lumo-input-container');
        },
        
        checkElement: function() {
            return {
                elementFound: !!document.querySelector('.lumo-input-container')
            };
        },
        
        forceLayout: function() {
            if (document.body) {
                document.body.getBoundingClientRect();
            }
        }
    };
    
    console.log('🔧 Page utilities initialized');
    return null;
})(); 
