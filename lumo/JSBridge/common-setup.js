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
    
    // Run immediately
    modifySignupLinks();
    
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