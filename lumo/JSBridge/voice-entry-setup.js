(function() {
    'use strict';
    
    let voiceEntrySetup = false;
    let clickHandlerActive = false;
    let currentUrl = location.href;
    
    function setupVoiceEntry() {
        const voiceEntryDiv = document.getElementById('voice-entry-mobile');
        const voiceButton = document.getElementById('voice-entry-mobile-button');
        
        if (!voiceEntryDiv || !voiceButton || voiceEntrySetup) return;
        
        // Show the voice entry div if hidden
        if (voiceEntryDiv.classList.contains('hidden')) {
            voiceEntryDiv.classList.remove('hidden');
        }
        
        function handleVoiceButtonClick(e) {
            if (clickHandlerActive) return;
            clickHandlerActive = true;
            
            try {
                if (window.LumoUtils) {
                    window.LumoUtils.sendWebKitMessage('startVoiceEntry', {});
                } else if (window.webkit?.messageHandlers?.startVoiceEntry) {
                    window.webkit.messageHandlers.startVoiceEntry.postMessage({});
                }
                console.log('🎤 Voice entry triggered');
            } catch(err) {
                console.error('Voice entry error:', err);
            }
            
            setTimeout(() => { clickHandlerActive = false; }, 100);
        }
        
        voiceButton.addEventListener('click', handleVoiceButtonClick);
        
        // Mark this button as having been set up
        voiceButton.setAttribute('data-lumo-voice-setup', 'true');
        
        voiceEntrySetup = true;
        console.log('✅ Voice entry setup completed');
    }
    
    function checkForVoiceElements() {
        const voiceButton = document.getElementById('voice-entry-mobile-button');
        
        if (voiceButton) {
            // Check if this button already has our click handler
            const hasHandler = voiceButton.hasAttribute('data-lumo-voice-setup');
            
            if (!hasHandler) {
                console.log('🔍 Found new voice button, setting up...');
                setupVoiceEntry();
            }
        } else {
            // If button is not found, reset setup flag for next time
            if (voiceEntrySetup) {
                console.log('🔄 Voice button removed, resetting setup flag');
                voiceEntrySetup = false;
            }
        }
    }
    
    function handleUrlChange() {
        if (location.href !== currentUrl) {
            currentUrl = location.href;
            voiceEntrySetup = false;
            console.log('🔄 URL changed, resetting voice entry setup');
            checkForVoiceElements();
        }
    }
    
    // Setup immediately if elements already exist
    checkForVoiceElements();
    
    // Efficient observer for voice entry elements
    const observer = new MutationObserver((mutations) => {
        let shouldCheck = false;
        
        mutations.forEach((mutation) => {
            if (mutation.type === 'childList') {
                // Check for added nodes
                mutation.addedNodes.forEach((node) => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        // Check if voice button was added directly
                        if (node.id === 'voice-entry-mobile-button') {
                            console.log('🔍 Voice button directly added to DOM');
                            shouldCheck = true;
                        }
                        // Check if container with voice button was added
                        else if (node.querySelector && node.querySelector('#voice-entry-mobile-button')) {
                            console.log('🔍 Container with voice button added to DOM');
                            shouldCheck = true;
                        }
                    }
                });
                
                // Check for removed nodes
                mutation.removedNodes.forEach((node) => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        // Check if voice button was removed directly
                        if (node.id === 'voice-entry-mobile-button') {
                            console.log('🔄 Voice button directly removed from DOM');
                            voiceEntrySetup = false;
                            shouldCheck = true;
                        }
                        // Check if container with voice button was removed
                        else if (node.querySelector && node.querySelector('#voice-entry-mobile-button')) {
                            console.log('🔄 Container with voice button removed from DOM');
                            voiceEntrySetup = false;
                            shouldCheck = true;
                        }
                    }
                });
            }
        });
        
        if (shouldCheck) {
            // Add a small delay to let React finish rendering
            setTimeout(checkForVoiceElements, 50);
        }
        
        // Check for URL changes (covers both real URL changes and React route changes)
        handleUrlChange();
    });
    
    // Start observing
    observer.observe(document.body, {
        childList: true,
        subtree: true
    });
    
    console.log('🔧 Voice entry observer initialized');
})(); 
