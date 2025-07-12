// Import path for resolving file paths
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default {
  // Specify the entry point for our app.
  entry: [
    path.join(__dirname, 'src/main.js')
  ],
  // Specify the output file containing our bundled code
  output: {
    path: __dirname,
    filename: 'dist/bundle/main.cjs',
    library: {
        type: 'commonjs2'
    }
  },
  // Let webpack know to generate a Node.js bundle
  target: "node",
  externals: [
    // NodeJS modules
    'node:https',
    // AWS SDK
    '@aws-sdk/client-ses'
  ],
  //externalsType: 'commonjs'
//   module: {
//     /**
//       * Tell webpack how to load 'json' files. 
//       * When webpack encounters a 'require()' statement
//       * where a 'json' file is being imported, it will use
//       * the json-loader.  
//       */
//     loaders: [
//       {
//         test: /\.json$/, 
//         loaders: ['json']
//       }
//     ]
//   },
//   experiments: {
//     outputModule: true
//   }
}