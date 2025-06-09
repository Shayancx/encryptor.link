import * as esbuild from 'esbuild';
import esbuildPluginTsc from 'esbuild-plugin-tsc';

const isWatchMode = process.argv.includes('--watch');

const config: esbuild.BuildOptions = {
  entryPoints: [
    'app/javascript/application.ts',
    'app/javascript/lib/decrypt.ts'
  ],
  bundle: true,
  outdir: 'app/assets/builds',
  entryNames: '[name]',
  sourcemap: true,
  format: 'esm',
  target: 'es2020',
  plugins: [
    esbuildPluginTsc({ tsconfigPath: './tsconfig.json' })
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
