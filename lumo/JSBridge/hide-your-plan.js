(function() {
    'use strict';
    
    const hideYourPlanElement = () => {
        const element = document.querySelector('section#your-plan');
        if (element && element.style.display !== 'none') {
            element.style.display = 'none';
        }
    };
    
    hideYourPlanElement();
    
    const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
            if (mutation.type === 'childList') {
                mutation.addedNodes.forEach((node) => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        if (node.tagName === 'SECTION' && node.id === 'your-plan') {
                            hideYourPlanElement();
                        }
                        else if (node.querySelector && node.querySelector('section#your-plan')) {
                            hideYourPlanElement();
                        }
                    }
                });
            }
        });
    });
    
    observer.observe(document.body, {
        childList: true,
        subtree: true
    });
})(); 