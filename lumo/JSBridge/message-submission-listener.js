(function() {
    'use strict';
    
    let isListenerSetup = false;
    let clickListener = null;
    let keydownListener = null;
    let submitListener = null;
    
    console.log('🔧 Message submission listener script starting...');
    
    // Check if LumoUtils is available
    if (!window.LumoUtils) {
        console.error('❌ LumoUtils not available - cannot setup message submission listener');
        return;
    }
    
    // Remove existing listeners to prevent duplicates
    function removeExistingListeners() {
        if (clickListener) {
            document.removeEventListener('click', clickListener, true);
            clickListener = null;
        }
        if (keydownListener) {
            document.removeEventListener('keydown', keydownListener, true);
            keydownListener = null;
        }
        if (submitListener) {
            document.removeEventListener('submit', submitListener, true);
            submitListener = null;
        }
    }

    // Setup listeners for message submission using event delegation
    // 
    // NOTE: We use event delegation (listening on document) instead of direct listeners
    // on specific elements because:
    // 1. React frequently re-renders and replaces DOM elements (especially submit buttons)
    // 2. Direct listeners get lost when React replaces elements, causing inconsistent behavior
    // 3. Event delegation works regardless of when elements are created/destroyed
    // 4. Performance impact is negligible - we only check event.target when events occur
    //
    function setupSubmissionListeners() {
        if (isListenerSetup) {
            return;
        }
        
        console.log('🔍 Setting up submission listeners with event delegation...');
        
        // Remove any existing listeners first
        removeExistingListeners();
        
        // Helper function to apply stabilization
        function applyStabilization(triggerEvent) {
            console.log(`🎯 ${triggerEvent} - applying layout stabilization`);
            if (window.LumoUtils.applyLayoutStabilization()) {
                // Restore layout after a delay
                setTimeout(() => {
                    window.LumoUtils.restoreLayout();
                }, 500);
            }
        }
        
        // Create and store click listener function
        clickListener = function(event) {
            // Check if clicked element is a submit button
            const clickedElement = event.target;
            
            // Multiple ways to identify submit buttons
            const isSubmitButton = 
                // Direct submit button checks
                (clickedElement.tagName === 'BUTTON' && (
                    clickedElement.type === 'submit' ||
                    clickedElement.classList.contains('submit-button') ||
                    clickedElement.closest('.composer-submit-button')
                )) ||
                // Check if it's inside a submit button container
                clickedElement.closest('.composer-submit-button button') ||
                clickedElement.closest('button[type="submit"]') ||
                // Check for any button that looks like a submit button near composer
                (clickedElement.tagName === 'BUTTON' && clickedElement.closest('.composer'));
            
            if (isSubmitButton) {
                console.log('🎯 Submit button clicked (via delegation)');
                applyStabilization('Submit button click');
            }
        };
        
        // Create and store keydown listener function
        keydownListener = function(event) {
            if (event.key === 'Enter' && !event.shiftKey) {
                // Check if the event target is a composer input
                const target = event.target;
                
                const isComposerInput = 
                    target.classList.contains('composer') ||
                    target.classList.contains('ProseMirror') ||
                    target.tagName === 'TEXTAREA' ||
                    target.getAttribute('contenteditable') === 'true' ||
                    target.closest('.composer') ||
                    target.closest('.tiptap');
                
                if (isComposerInput) {
                    console.log('🎯 Enter key pressed in composer (via delegation)');
                    applyStabilization('Enter key press');
                }
            }
        };
        
        // Create and store submit listener function
        submitListener = function(event) {
            applyStabilization('Form submission');
        };
        
        // Add the listeners
        document.addEventListener('click', clickListener, true);
        document.addEventListener('keydown', keydownListener, true);
        document.addEventListener('submit', submitListener, true);
        
        isListenerSetup = true;
    }
    
    // Since we're using event delegation, we can setup listeners immediately
    // No need to wait for specific elements
    function initializeListeners() {
        if (!isListenerSetup) {
            setupSubmissionListeners();
        }
    }
    
    // Setup listeners immediately - event delegation works regardless of when elements appear
    initializeListeners();
    
    console.log('🔧 Message submission listener initialized');
})(); 