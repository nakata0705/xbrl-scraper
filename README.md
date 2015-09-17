# xbrl-scraper

sudo apt-get install nodejs
sudo apt-get install nodejs-legacy
sudo apt-get install npm

npm install -g casperjs
ln -s /home/ubuntu/.nvm/v0.10.35/lib/node_modules/casperjs/node_modules/phantomjs/lib/phantom/bin/phantomjs /usr/local/bin/phantomjs

git clone https://github.com/Arelle/Arelle.git
apt-get install python3-lxml
apt-get install python3-pip
sudo pip3 install PyMySQL

python3 arelleCmdLine.py --plugins +xbrlDB
python3 arelleCmdLine.py -f ../E02367/2015_1Q_S1005JRG/XBRL/PublicDoc/jpcrp040300-q1r-001_E02367-000_2015-06-30_01_2015-08-07.xbrl --facts=facts.html --factTable=factTable.html --concepts=concepts.html --pre=pre.html --cal=cal.html --dim=dim.html --formulae=formulae.html

forever -w start /home/nakata0705/c9sdk/server.js -w /home/nakata0705/workspace -a nakata0705:MY_PASSWORD
forever -w start /usr/local/lib/node_modules/mongo-express/app.js

# sudo mysql --user nakata0705 c9
# > source ~/workspace/Arelle/arelle/plugin/xbrlDB/xbrlSemanticMySqlDB.ddl

python3 arelleCmdLine.py  --disclosureSystem fsa -f ../E02367/2015_1Q_S1005JRG/XBRL/PublicDoc/jpcrp040300-q1r-001_E02367-000_2015-06-30_01_2015-08-07.xbrl --store-to-XBRL-DB "jsonFile,,xbrl,xbrl,/home/nakata0705/workspace/test2.json,,json"

apt-get install ruby-dev
gem install mongo

apt-get install unzip nkf

apt-get purge nginx nginx-full nginx-common
apt-get install nginx
Refer this for nginx SSH reverse proxy setup. http://blog.akagi.jp/archives/3883.html

{ baseItem: { $regex: /\:OperatingIncome/i }, period: {$regex: /xbrli:period\/duration\/\d{4,4}-04-01\/\d{4,4}-03-31/ }, contextId: {$regex: /^CurrentYear(?!.*Non).*$/i } }
{ baseItem: { $regex: /\:OperatingIncome/i }, period: {$regex: /xbrli:period\/duration\/\d{4,4}-04-01\/\d{4,4}-03-31/ }, $or: [ { contextId: "CurrentYearDuration"}, {contextId: "CurrentYearConsolidatedDuration"} ], entityIdentifier: { $regex: /E02475/} }