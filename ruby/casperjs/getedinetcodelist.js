// Required external tools
// nkf (to convert SJIS cvs to UTF-8)
// unzip (to unzip edinetcode.zip)

// Worker variables
var g_loadingurl = '';
var g_codelisturl = '';
var g_log = false;

function log(message) {
    if (g_log) {
        this.echo(message);
    }
}

// Initiaize CasperJS
var casper = require('casper').create();

if (casper.cli.has(0) == false) {
    exit(-1);
}
var g_edinetcodezip = casper.cli.get(0);

casper.userAgent('Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)');

casper.on('page.resource.requested', function(request) {
    log('page.resource.requested: ' + request.url);
    //require('utils').dump(request);
    if (request.url.match(/EdinetCodeDownload/) && g_codelisturl.length == 0) {
        g_codelisturl = request.url;
        log('aborting request');
        request.abort();
    }
});

casper.on('page.resource.received', function(response) {
    log('page.resource.received ' + response.url);
});

casper.on('resource.error', function(error) {
    this.echo('resource.error ' + error);
});

casper.start('http://disclosure.edinet-fsa.go.jp/');

casper.then(function() {
    log('Click ' + 'EDINETタクソノミ及びコードリスト');
    this.clickLabel('EDINETタクソノミ及びコードリスト');
});

casper.then(function() {
    log('Click a[href*="EdinetCodeListDownloadAction"]');
    this.click('a[href*="EdinetCodeListDownloadAction"]');
});

casper.waitFor(function() { return g_codelisturl; }, function() {
    log('requesting ' + g_codelisturl);
    this.download(g_codelisturl, g_edinetcodezip);
}, function() {
    this.echo('timeout').exit(-1);
}, 60000);

casper.run(function() {
    this.exit(0);
});
