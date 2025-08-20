(function() {
    'use strict';
    
    var setInputValue = function(editor, value) {
        try {
            
            editor.textContent = value; 
            
            ['input', 'change'].forEach(eventType => {
                editor.dispatchEvent(new Event(eventType, { bubbles: true }));
            });
            
        } catch (setError) {
            console.error('❌ MAIN: Error setting editor value:', setError);
        }
    }

    try {
        const prompt = '{{SAFE_PROMPT}}';
        const editorType = '{{EDITOR_TYPE}}';
        
        // Use shared layout stabilization functions from LumoUtils
        if (window.LumoUtils && window.LumoUtils.applyLayoutStabilization) {
            window.LumoUtils.applyLayoutStabilization();
        }
        
        let editor = null;
        if (editorType === "tiptap" || editorType === "basic") {
            editor = document.querySelector('.tiptap.ProseMirror.composer') || 
                    document.querySelector('.composer');
        } else if (editorType === "textarea") {
            editor = document.querySelector('textarea.composer-textarea');
        }
        
        if (!editor) {
            return { success: false, reason: 'editor_not_found' };
        }

        setInputValue(editor, prompt);
        
        // Restore layout using shared function
        if (window.LumoUtils && window.LumoUtils.restoreLayout) {
            window.LumoUtils.restoreLayout();
        }
        
        function waitForSubmitButton() {
            return new Promise((resolve, reject) => {
                const maxAttempts = 20;
                let attempts = 0;
                
                function checkForButton() {
                    attempts++;
                    
                    const submitButton = document.querySelector('.composer-submit-button button') ||
                                       document.querySelector('.composer-submit-button > button');
                    
                    if (submitButton) {
                        resolve(submitButton);
                        return;
                    }
                    
                    if (attempts >= maxAttempts) {
                        reject(new Error('submit_button_timeout'));
                        return;
                    }
                    setTimeout(checkForButton, 100);
                }
                
                checkForButton();
            });
        }
        
        // Just insert the text and return success - let user review and submit manually
        return { success: true, action: 'text_inserted' };
        
    } catch(e) {
        console.error('Insert/submit/clear error:', e);
        return { success: false, reason: e.toString() };
    }
})(); 
