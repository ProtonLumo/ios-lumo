(function() {
    // Utility functions (duplicated from utilities.js to remove dependency)
    function removeIfExists(selector, description) {
        const elements = document.querySelectorAll(selector);
        if (elements.length > 0) {
            elements.forEach(el => el.remove());
            console.log(`Lumo: Removed ${elements.length} ${description}`);
            return true;
        }
        return false;
    }
    
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
    
    // Function to modify signup links
    function modifySignupLinks() {
        const links = document.querySelectorAll('a[href^="https://account.proton.me/lumo/signup"]');
        links.forEach(link => {
            const url = new URL(link.href);
            if (!url.searchParams.has('plan')) {
                url.searchParams.set('plan', 'free');
                link.href = url.toString();
                console.log('Modified link to: ' + link.href);
            }
        });
    }
    
    function removeUpgradeLinks() {
        const links = document.querySelectorAll('a');
        let removedCount = 0;

        links.forEach(link => {
            const href = link.getAttribute('href')?.toLowerCase() || '';
            const text = link.textContent?.toLowerCase() || '';
            if (href.includes('upgrade') || text.includes('upgrade')) {
                link.remove();
                removedCount++;
            }
        });

        if (removedCount > 0) {
            console.log(`Removed ${'$'}{removedCount} upgrade link(s)`);
        }

        return removedCount > 0;
    }
    
    function removeDropdownButton() {
        const dropdownButton = document.querySelector('[data-testid="dropdown-button"]');
        if (dropdownButton) {
            dropdownButton.style.display = 'none';
            console.log('Removed dropdown button from view');
            return true;
        }
        return false;
    }
    
    
    function removeUnwantedLinks() {
        const links = document.querySelectorAll('a');
        let removedCount = 0;
        
        links.forEach(link => {
            const href = link.getAttribute('href') || '';
            
            // Check for business signup or proton.me/mail links
            if (href.includes('lumo/signup/business') || href.includes('proton.me/mail')) {
                link.remove();
                removedCount++;
            }
        });
        
        if (removedCount > 0) {
            console.log(`Removed ${removedCount} unwanted link(s) (business signup, proton.me/mail)`);
        }
        
        return removedCount > 0;
    }
    
    // Run immediately
    modifySignupLinks();
    removeDropdownButton();
    removeUnwantedLinks();
    
    // Set up mutation observer to handle dynamically added links
    const observer = new MutationObserver(mutations => {
        let shouldModifyLinks = false;
        
        mutations.forEach(mutation => {
            if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
                shouldModifyLinks = true;
            }
        });
        
        if (shouldModifyLinks) {
            modifySignupLinks();
            removeUpgradeLinks();
            removeDropdownButton();
            removeUnwantedLinks();
            
            removeIfExists('.button-for-icon.lumo-bf2025-promotion.button-promotion--icon-gradient.bf-2025-free', '');
        }
    });
    
    // Start observing changes to the DOM
    observer.observe(document.body, { 
        childList: true, 
        subtree: true 
    });
    
    // Report back navigation state accurately
    sendWebKitMessage('navigationState', {
        canGoBack: window.history.length > 1,
        url: window.location.href
    });
    
    return null;
})(); 
