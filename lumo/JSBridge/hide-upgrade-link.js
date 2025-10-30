(function() {
    'use strict';
    
    function removeIfExists(selector, description) {
        const elements = document.querySelectorAll(selector);
        if (elements.length > 0) {
            elements.forEach(el => el.remove());
            console.log(`Lumo: Removed ${elements.length} ${description}`);
            return true;
        }
        return false;
    }
    
    function removeSidebarUpgradeItem() {
        // Match any link with "upgrade" in the href
        const upgradeLinks = document.querySelectorAll('a.navigation-link[href*="upgrade"]');
        let removed = false;
        upgradeLinks.forEach(link => {
            const li = link.closest('li.navigation-item');
            if (li) {
                li.remove();
                removed = true;
                console.log('Lumo: Removed sidebar upgrade list item');
            }
        });
        return removed;
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
    
    function modifyAccountPage() {
        // Remove "Your plan" section
        removeIfExists('#your-plan', '#your-plan section');
        
        // Remove Black Friday promo button
        removeIfExists('.button-promotion--bf-2025-free', 'Black Friday promo button');
        
        // Upgrade option on account header
        removeIfExists('.button-promotion.button-promotion--icon-gradient', 'Default upgrade button');
        
        // Remove sidebar "Upgrade" entry
        removeSidebarUpgradeItem();
        removeUpgradeLinks();
        
        // Remove any standalone upgrade links (not in sidebar)
        const allUpgradeLinks = document.querySelectorAll('a[href*="upgrade"]');
        let linkCount = 0;
        allUpgradeLinks.forEach(link => {
            // Only remove if not already removed as part of sidebar item
            if (link.isConnected && !link.closest('li.navigation-item')) {
                link.remove();
                linkCount++;
            }
        });
        if (linkCount > 0) {
            console.log(`Lumo: Removed ${linkCount} standalone upgrade link(s)`);
        }
    }
    
    // Run immediately in case elements already exist
    console.log('Lumo: Initializing account page modifier');
    modifyAccountPage();
    
    // Observe DOM changes (handles sidebar open + async content)
    const observer = new MutationObserver((mutationsList) => {
        for (const mutation of mutationsList) {
            if (mutation.addedNodes.length > 0 || mutation.removedNodes.length > 0) {
                modifyAccountPage();
                break; // one pass per batch is enough
            }
        }
    });
    
    observer.observe(document.body, { childList: true, subtree: true });
    console.log('Lumo: Account page modifier observer registered');
})();

