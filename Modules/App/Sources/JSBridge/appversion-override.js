(function() {
    'use strict';

    var nativeAppVersion = 'ios-lumo@{{APP_VERSION}}';

    var originalFetch = window.fetch;
    window.fetch = function(input, init) {
        if (init && init.headers && init.headers['x-pm-appversion']) {
            init.headers['x-pm-appversion'] = nativeAppVersion;
        }
        return originalFetch.apply(this, arguments);
    };
})();
