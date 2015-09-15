// Required external tools
// nkf (to convert SJIS cvs to UTF-8)
// unzip (to unzip edinetcode.zip)

// Initiaize CasperJS
var casper = require('casper').create();

var g_loadingurl = '';
var g_reporturl = '';

if (casper.cli.has(0) == false || casper.cli.has(1) == false) {
    this.exit(-1);
}
var g_targetcode = casper.cli.get(0);
var g_edinetreportzip = g_targetcode + '.zip';
var workdir_name = casper.cli.get(1);

casper.userAgent('Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)');

casper.on('page.resource.requested', function(request) {
    this.echo('page.resource.requested: ' + request.url);
    //require('utils').dump(request);
    if (request.url.match(/download/) && g_reporturl.length == 0) {
        g_reporturl = request.url;
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

casper.setFilter("page.confirm", function(msg) {
    return true;
});

casper.start('http://disclosure.edinet-fsa.go.jp/');

casper.then(function() {
    this.echo('Click ' + '書類検索');
    this.click('img[alt="書類検索"]');
});

casper.then(function() {
    this.fill('form#control_object_class1', {
        mul: g_targetcode,
        fls: true,
        lpr: false,
        oth: false,
        pfs: 5
    }, false);
    this.echo('Click input[onclick*="SendSearchAction"]');
    this.click('input[onclick*="SendSearchAction"]');
});

casper.then(function() {
    this.echo('Click input#xbrlbutton');
    this.click('input#xbrlbutton');
});

casper.waitFor(function() { return g_reporturl; }, function() {
    this.echo('requesting ' + g_reporturl);
    this.download(g_reporturl, workdir_name + '/' + g_edinetreportzip);
}, function() {
    this.echo('timeout').exit();
}, 60000);

casper.run();
