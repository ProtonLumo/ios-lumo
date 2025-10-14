(function() {
    let observedButtons = new WeakSet();

    function extractThemeFromAriaLabel(ariaLabel) {
        // "Use Light theme" -> "Light"
        // "Use Dark theme" -> "Dark"
        // "Use System theme" -> "System"
        const match = ariaLabel?.match(/Use (\w+) theme/i);
        return match ? match[1] : null;
    }

    function attachClickObserver(button) {
        if (!button || observedButtons.has(button)) return;

        observedButtons.add(button);
        const ariaLabel = button.getAttribute("aria-label");
        const theme = extractThemeFromAriaLabel(ariaLabel);

        button.addEventListener('click', function() {
            const clickedTheme = extractThemeFromAriaLabel(this.getAttribute("aria-label"));
            
            // Send theme change to iOS
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.themeChanged) {
                window.webkit.messageHandlers.themeChanged.postMessage({
                    theme: clickedTheme,
                    timestamp: Date.now()
                });
            }
        });
    }

    function findAndObserveThemeButtons() {
        // Find all theme card buttons
        const buttons = document.querySelectorAll('button.lumo-theme-card-button');

        if (buttons.length > 0) {
            buttons.forEach(attachClickObserver);
        }
    }

    // Body observer to detect when theme buttons appear
    const bodyObserver = new MutationObserver(mutations => {
        for (const mutation of mutations) {
            for (const node of mutation.addedNodes) {
                if (!(node instanceof HTMLElement)) continue;

                // Case 1: the node itself is a theme button
                if (node.matches("button.lumo-theme-card-button")) {
                    attachClickObserver(node);
                }

                // Case 2: theme buttons are inside the added node
                const buttons = node.querySelectorAll("button.lumo-theme-card-button");
                buttons.forEach(attachClickObserver);
            }
        }
    });

    // Initial scan for existing buttons
    findAndObserveThemeButtons();

    bodyObserver.observe(document.body, {
        childList: true,
        subtree: true
    });
})();


