const esbuild = require('esbuild');

esbuild.build({
  entryPoints: ['app/javascript/application.js'],
  bundle: true,
  outdir: 'app/assets/builds',
  sourcemap: true,
  format: 'esm',
  target: 'es2020',
  external: ['/encrypt.js', '/decrypt.js']
}).catch(() => process.exit(1));
