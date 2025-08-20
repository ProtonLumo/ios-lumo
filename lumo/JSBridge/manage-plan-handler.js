// Load utilities first
if (typeof setViewport === 'undefined') {
    console.log('Utilities not loaded, loading now...');
    // Utilities will be loaded by JSBridgeManager
}

(function() {
    function handleManagePlanClick(event) {
        event.preventDefault();
        
        // Check if webkit message handlers are available
        if (typeof window.webkit === 'undefined' || 
            typeof window.webkit.messageHandlers === 'undefined' ||
            typeof window.webkit.messageHandlers.managePlanClicked === 'undefined') {
            return;
        }
        
        try {
            window.webkit.messageHandlers.managePlanClicked.postMessage({
                timestamp: Date.now(),
                buttonElement: event.target.outerHTML
            });
        } catch (error) {
            console.error('🔧 Error sending message:', error);
        }
    }
    
    function setupManagePlanHandlers() {
        const existingButtons = document.querySelectorAll('.manage-plan[data-lumo-listener="true"]');
        existingButtons.forEach(button => {
            button.removeEventListener('click', handleManagePlanClick);
            button.removeAttribute('data-lumo-listener');
        });
        
        const managePlanButtons = document.querySelectorAll('.manage-plan');
        managePlanButtons.forEach((button, index) => {
            button.addEventListener('click', handleManagePlanClick);
            button.setAttribute('data-lumo-listener', 'true');
        });
    }
    
    setupManagePlanHandlers();
    
    const observer = new MutationObserver(function(mutations) {
        let shouldUpdate = false;
        mutations.forEach(function(mutation) {
            if (mutation.type === 'childList') {
                mutation.addedNodes.forEach(function(node) {
                    if (node.nodeType === 1) { 
                        if (node.classList && node.classList.contains('manage-plan')) {
                            shouldUpdate = true;
                        } else if (node.querySelectorAll && node.querySelectorAll('.manage-plan').length > 0) {
                            shouldUpdate = true;
                        }
                    }
                });
            }
        });
        
        if (shouldUpdate) {
            setupManagePlanHandlers();
        }
    });
    
    observer.observe(document.body, {
        childList: true,
        subtree: true
    });
})(); 