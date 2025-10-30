(function() {
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
    
    // Run immediately
    modifySignupLinks();
    removeDropdownButton();
    
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
        }
    });
    
    // Start observing changes to the DOM
    observer.observe(document.body, { 
        childList: true, 
        subtree: true 
    });
    
    // Report back navigation state accurately using utility if available
    if (window.LumoUtils) {
        window.LumoUtils.sendWebKitMessage('navigationState', {
            canGoBack: window.history.length > 1,
            url: window.location.href
        });
    } else {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.navigationState) {
            window.webkit.messageHandlers.navigationState.postMessage({
                canGoBack: window.history.length > 1,
                url: window.location.href
            });
        }
    }
    
    return null;
})(); 
