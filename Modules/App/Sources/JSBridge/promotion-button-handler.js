(function() {
    // Utility function (duplicated from utilities.js to remove dependency)
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
        
        sendWebKitMessage('promotionButtonClicked', buttonData);
        
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
