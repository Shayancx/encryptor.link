const esbuild = require('esbuild');
const { typescript } = require('esbuild-plugin-tsc');

const isWatchMode = process.argv.includes('--watch');

const config = {
  entryPoints: [
    'app/javascript/application.ts',
    'app/javascript/lib/decrypt.js'
  ],
  bundle: true,
  outdir: 'app/assets/builds',
  entryNames: '[name]',
  sourcemap: true,
  format: 'esm',
  target: 'es2020',
  plugins: [
    typescript({
      tsconfigPath: './tsconfig.json'
    })
  ]
};

if (isWatchMode) {
  esbuild.context(config).then(context => {
    context.watch();
    console.log('Watching for changes...');
  }).catch(() => process.exit(1));
} else {
  esbuild.build(config).catch(() => process.exit(1));
}
