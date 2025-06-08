const esbuild = require('esbuild');

esbuild.build({
  entryPoints: [
    'app/javascript/application.js',
    'app/javascript/lib/encrypt.js',
    'app/javascript/lib/decrypt.js'
  ],
  bundle: true,
  outdir: 'app/assets/builds',
  entryNames: '[name]',
  sourcemap: true,
  format: 'esm',
  target: 'es2020'
}).catch(() => process.exit(1));
