// Required external tools
// nkf (to convert SJIS cvs to UTF-8)
// unzip (to unzip edinetcode.zip)

// Worker variables
var g_loadingurl = '';
var g_codelisturl = '';

// Initiaize CasperJS
var casper = require('casper').create();

if (casper.cli.has(0) == false) {
    exit(-1);
}
var g_edinetcodezip = casper.cli.get(0);

casper.userAgent('Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)');

casper.on('page.resource.requested', function(request) {
    this.echo('page.resource.requested: ' + request.url);
    //require('utils').dump(request);
    if (request.url.match(/EdinetCodeDownload/) && g_codelisturl.length == 0) {
        g_codelisturl = request.url;
        this.echo('aborting request');
        request.abort();
    }
});

casper.on('page.resource.received', function(response) {
    this.echo('page.resource.received ' + response.url);
    //require('utils').dump(response);
});

casper.on('resource.error', function(error) {
    this.echo('resource.error ' + error);
    //require('utils').dump(error);
});

casper.start('http://disclosure.edinet-fsa.go.jp/');

casper.then(function() {
    this.echo('Click ' + 'EDINETタクソノミ及びコードリスト');
    this.clickLabel('EDINETタクソノミ及びコードリスト');
});

casper.then(function() {
    this.echo('Click a[href*="EdinetCodeListDownloadAction"]');
    this.click('a[href*="EdinetCodeListDownloadAction"]');
});

casper.waitFor(function() { return g_codelisturl; }, function() {
    this.echo('requesting ' + g_codelisturl);
    this.download(g_codelisturl, g_edinetcodezip);
}, function() {
    this.echo('timeout').exit(-1);
}, 60000);

casper.run(function() {
    this.exit(0);
});
