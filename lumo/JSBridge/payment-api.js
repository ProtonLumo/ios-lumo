(function() {
    'use strict';
    
    const operation = '{{OPERATION}}';
    const data = '{{DATA}}' || null;
    
    try {
        if (typeof window.paymentApiInstance === 'undefined') {
            console.error('paymentApiInstance not found');
            return JSON.stringify({error: 'paymentApiInstance not found'});
        }
        
        const api = window.paymentApiInstance;
        
        switch (operation) {
            case 'getPlans':
                if (typeof api.getPlans === 'function') {
                    const result = api.getPlans('ios');
                    return JSON.stringify(result);
                } else {
                    console.error('getPlans function not found');
                    return JSON.stringify({error: 'getPlans function not found'});
                }
                
            case 'getSubscriptions':
                return (async function() {
                    try {
                        if (typeof api.getSubscriptions === 'function') {
                            console.log('Calling getSubscriptions...');
                            const result = await api.getSubscriptions('ios');
                            console.log('getSubscriptions result:', result);
                            
                            // Send result back to native
                            if (window.webkit?.messageHandlers?.getSubscriptionsResponseReceived) {
                                window.webkit.messageHandlers.getSubscriptionsResponseReceived.postMessage({
                                    response: result
                                });
                                console.log('Sent getSubscriptions result to native');
                            }
                            
                            return JSON.stringify(result);
                        } else {
                            console.error('getSubscriptions function not found');
                            return JSON.stringify({error: 'getSubscriptions function not found'});
                        }
                    } catch(error) {
                        console.error('Error in getSubscriptions:', error);
                        return JSON.stringify({error: error.message});
                    }
                })();
                
            case 'createSubscription':
                if (typeof api.createSubscription === 'function' && data) {
                    const subscriptionData = JSON.parse(data);
                    api.createSubscription(subscriptionData);
                    return JSON.stringify({success: true});
                } else {
                    console.error('createSubscription function not found or no data provided');
                    return JSON.stringify({error: 'createSubscription function not found or no data'});
                }
                
            case 'createToken':
                if (typeof api.createToken === 'function' && data) {
                    const tokenData = JSON.parse(data);
                    api.createToken(tokenData);
                    return JSON.stringify({success: true});
                } else {
                    console.error('createToken function not found or no data provided');
                    return JSON.stringify({error: 'createToken function not found or no data'});
                }
                
            default:
                console.error('Unknown payment operation:', operation);
                return JSON.stringify({error: 'Unknown operation: ' + operation});
        }
        
    } catch(error) {
        console.error('Error in payment API operation:', error);
        return JSON.stringify({error: error.message});
    }
})(); 