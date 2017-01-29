var assert = require('assert');

describe('login page', function() {
    it('should allow a user to login', function () {
        browser.url('/#login');
        browser.setValue('[name="username"]', 'admin');
        browser.setValue('[name="password"]', 'admin');
        browser.submitForm('.login-form');
        browser.waitForVisible('.menu h4');
        var title = browser.getText('.menu h4');
        assert.equal(title[1], 'admin');

        // Logout session.
        browser.click('.menu > a:nth-child(4)');
        browser.waitForVisible('[name="username"]');
    });
});
