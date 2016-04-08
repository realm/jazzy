var lunr = require('./lunr.min.js'),
    fs = require('fs')

if (process.argv.length < 4) {
  console.log('Usage: node ' + process.argv[1] + ' input.json output.json');
  process.exit(1);
}

fs.readFile(process.argv[2], 'utf8', function(err, data) {
  if (err) throw err;

  var declarations = JSON.parse(data);

  var index = lunr(function () {
    this.ref('key');
    this.field('name');
    this.pipeline.reset();
  });

  declarations.forEach(function(d) {
    index.add({name: d.name, key: [d.url, d.parent_name]});
  });

  fs.writeFile(process.argv[3], JSON.stringify(index), function(err) {
    if (err) throw err;
  });
});
