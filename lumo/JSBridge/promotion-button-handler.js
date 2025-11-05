(function() {
    let isProcessingClick = false;
    
    document.addEventListener('click', function(event) {
        if (isProcessingClick) return;
        
        const promotionButton = event.target.closest('.lumo-upgrade-trigger, .lumo-bf2025-promotion, .button-promotion');
        if (!promotionButton) return;
        
        event.preventDefault();
        event.stopPropagation();
        
        isProcessingClick = true;
        
        const buttonData = { 
            buttonText: promotionButton.innerText || '',
            buttonClass: promotionButton.className || '' 
        };
        
        if (promotionButton.dataset) {
            for (const key in promotionButton.dataset) {
                buttonData[key] = promotionButton.dataset[key];
            }
        }
        
        if (window.LumoUtils) {
            window.LumoUtils.sendWebKitMessage('promotionButtonClicked', buttonData);
        } else {
            // Fallback
            try {
                if (window.webkit && window.webkit.messageHandlers && 
                    window.webkit.messageHandlers.promotionButtonClicked) {
                    window.webkit.messageHandlers.promotionButtonClicked.postMessage(buttonData);
                }
            } catch (e) {
                console.error('Error posting promotion click:', e);
            }
        }
        
        setTimeout(function() {
            isProcessingClick = false;
        }, 300);
        
        return false;
    }, { 
        capture: true,
        passive: false
    });
    
    return null;
})(); 
