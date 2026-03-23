(function() {
    'use strict';
    
    // Utility functions (duplicated from utilities.js to remove dependency)
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
        return true;
    }
    
    function restoreLayout() {
        if (stabilizationStyleElement) {
            document.head.removeChild(stabilizationStyleElement);
            stabilizationStyleElement = null;
            return true;
        }
        return false;
    }
    
    let isListenerSetup = false;
    let clickListener = null;
    let keydownListener = null;
    let submitListener = null;
    
    console.log('🔧 Message submission listener script starting...');
    
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
        
        removeExistingListeners();
        
        function applyStabilization(triggerEvent) {
            console.log(`🎯 ${triggerEvent} - applying layout stabilization`);
            if (applyLayoutStabilization()) {
                setTimeout(() => {
                    restoreLayout();
                }, 500);
            }
        }
        
        clickListener = function(event) {
            const clickedElement = event.target;
            const isSubmitButton =
                (clickedElement.tagName === 'BUTTON' && (
                    clickedElement.type === 'submit' ||
                    clickedElement.classList.contains('submit-button') ||
                    clickedElement.closest('.composer-submit-button')
                )) ||
        
                clickedElement.closest('.composer-submit-button button') ||
                clickedElement.closest('button[type="submit"]') ||
                (clickedElement.tagName === 'BUTTON' && clickedElement.closest('.composer'));
            
            if (isSubmitButton) {
                window.webkit?.messageHandlers?.submitButtonClicked?.postMessage({});
                applyStabilization('Submit button click');
            }
        };
        
        keydownListener = function(event) {
            if (event.key === 'Enter' && !event.shiftKey) {
                const target = event.target;
                
                const isComposerInput = 
                    target.classList.contains('composer') ||
                    target.classList.contains('ProseMirror') ||
                    target.tagName === 'TEXTAREA' ||
                    target.getAttribute('contenteditable') === 'true' ||
                    target.closest('.composer') ||
                    target.closest('.tiptap');
                
                if (isComposerInput) {
                    applyStabilization('Enter key press');
                }
            }
        };
        
        submitListener = function(event) {
            window.webkit?.messageHandlers?.submitButtonClicked?.postMessage({});
            applyStabilization('Form submission');
        };
        
        document.addEventListener('click', clickListener, true);
        document.addEventListener('keydown', keydownListener, true);
        document.addEventListener('submit', submitListener, true);
        
        isListenerSetup = true;
    }
    
    function initializeListeners() {
        if (!isListenerSetup) {
            setupSubmissionListeners();
        }
    }
    
    initializeListeners();
    console.log('🔧 Message submission listener initialized');
})(); 
