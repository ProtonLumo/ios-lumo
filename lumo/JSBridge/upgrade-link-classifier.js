(function() {
    'use strict';
    
    // Function to add lumo-upgrade-trigger class to upgrade links
    function classifyUpgradeLinks() {
        // Find all anchor elements with href containing /lumo/upgrade
        const upgradeLinks = document.querySelectorAll('a[href*="/lumo/upgrade"]');
        
        upgradeLinks.forEach(link => {
            // Check if it doesn't already have the lumo-upgrade-trigger class
            if (!link.classList.contains('lumo-upgrade-trigger')) {
                link.classList.add('lumo-upgrade-trigger');
                console.log('✅ Added lumo-upgrade-trigger class to link:', link.href, link);
            }
        });
    }
    
    // Run immediately on page load
    classifyUpgradeLinks();
    
    // Watch for dynamically added links
    const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            mutation.addedNodes.forEach(function(node) {
                if (node.nodeType === Node.ELEMENT_NODE) {
                    // Check if the added node is an upgrade link
                    if (node.tagName === 'A' && 
                        node.href && 
                        node.href.includes('/lumo/upgrade') &&
                        !node.classList.contains('lumo-upgrade-trigger')) {
                        
                        node.classList.add('lumo-upgrade-trigger');
                        console.log('✅ Added lumo-upgrade-trigger class to dynamically added link:', node.href, node);
                    }
                    
                    // Check for upgrade links within the added node
                    const nestedUpgradeLinks = node.querySelectorAll && node.querySelectorAll('a[href*="/lumo/upgrade"]');
                    if (nestedUpgradeLinks) {
                        nestedUpgradeLinks.forEach(link => {
                            if (!link.classList.contains('lumo-upgrade-trigger')) {
                                link.classList.add('lumo-upgrade-trigger');
                                console.log('✅ Added lumo-upgrade-trigger class to nested link:', link.href, link);
                            }
                        });
                    }
                }
            });
        });
    });
    
    // Start observing
    observer.observe(document.body, {
        childList: true,
        subtree: true
    });
    
    // Also watch for attribute changes in case href gets modified
    const attributeObserver = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            if (mutation.type === 'attributes' && 
                mutation.attributeName === 'href' && 
                mutation.target.tagName === 'A') {
                
                const link = mutation.target;
                if (link.href && link.href.includes('/lumo/upgrade')) {
                    if (!link.classList.contains('lumo-upgrade-trigger')) {
                        link.classList.add('lumo-upgrade-trigger');
                        console.log('✅ Added lumo-upgrade-trigger class to modified link:', link.href, link);
                    }
                } else {
                    // Remove the class if href no longer contains upgrade
                    if (link.classList.contains('lumo-upgrade-trigger')) {
                        link.classList.remove('lumo-upgrade-trigger');
                        console.log('🗑️ Removed lumo-upgrade-trigger class from link:', link.href, link);
                    }
                }
            }
        });
    });
    
    // Start observing attribute changes
    attributeObserver.observe(document.body, {
        attributes: true,
        subtree: true,
        attributeFilter: ['href']
    });
    
    console.log('✅ Upgrade link classifier initialized - will add lumo-upgrade-trigger class to /lumo/upgrade links');
    return null;
})(); 