const fs = require('fs');

let content = fs.readFileSync('build/node.sh', 'utf-8');

// Insert the generation of hook.js at the end of the script before the exit
const hookJs = `
    cat << 'EOF_HOOK' > "$OUT_DIR/hook.js"
const cp = require('child_process');
const path = require('path');
const nodeDir = process.env.NODE_DIR;
if (!nodeDir) return;

function patchArgs(command, args) {
    if (command === 'sh' || command === '/system/bin/sh') {
        const cIdx = args.indexOf('-c');
        if (cIdx !== -1 && args[cIdx + 1]) {
            let s = args[cIdx + 1];
            s = s.replace(/(^|;|&|\\||\\(|\\s)node(\\s|$)/g, \`$1sh \${nodeDir}/node$2\`);
            s = s.replace(/(^|;|&|\\||\\(|\\s)npm(\\s|$)/g, \`$1sh \${nodeDir}/npm$2\`);
            s = s.replace(/(^|;|&|\\||\\(|\\s)npx(\\s|$)/g, \`$1sh \${nodeDir}/npx$2\`);
            s = s.replace(/(^|;|&|\\||\\(|\\s)pnpm(\\s|$)/g, \`$1sh \${nodeDir}/pnpm$2\`);
            s = s.replace(/(^|;|&|\\||\\(|\\s)pnpx(\\s|$)/g, \`$1sh \${nodeDir}/pnpx$2\`);
            args[cIdx + 1] = s;
        }
    } else if (command === 'node' || command.endsWith('/node.bin') || command.endsWith('/node')) {
        command = 'sh';
        args.unshift(\`\${nodeDir}/node\`);
    } else if (command === 'npm' || command.endsWith('/npm')) {
        command = 'sh';
        args.unshift(\`\${nodeDir}/npm\`);
    } else if (command === 'pnpm' || command.endsWith('/pnpm')) {
        command = 'sh';
        args.unshift(\`\${nodeDir}/pnpm\`);
    }
    return { command, args };
}

const origSpawn = cp.spawn;
cp.spawn = function(command, args, options) {
    if (!Array.isArray(args)) { options = args; args = []; }
    const p = patchArgs(command, args);
    return origSpawn.call(this, p.command, p.args, options);
};

const origSpawnSync = cp.spawnSync;
cp.spawnSync = function(command, args, options) {
    if (!Array.isArray(args)) { options = args; args = []; }
    const p = patchArgs(command, args);
    return origSpawnSync.call(this, p.command, p.args, options);
};
EOF_HOOK
`;

// Insert it right after pnpx wrapper generation or at the end of Android case
// Since we generate node wrappers around line 150-180, we can insert it at the bottom.
content = content.replace('echo "Build complete."', hookJs + '\n\necho "Build complete."');

// Add export NODE_DIR and NODE_OPTIONS to node wrapper
content = content.replace(
    'exec "$DIR/node.bin" "$@"',
    'export NODE_DIR="$DIR"\nexport NODE_OPTIONS="--require $DIR/hook.js $NODE_OPTIONS"\nexec "$DIR/node.bin" "$@"'
);

// Add export NODE_DIR and NODE_OPTIONS to npm, npx, pnpm wrappers
// They have `export npm_config_cache="\$DIR/.npm-cache"`
content = content.replace(
    /export npm_config_cache="\\\$DIR\/\.npm-cache"/g,
    'export npm_config_cache="\\$DIR/.npm-cache"\nexport NODE_DIR="\\$DIR"\nexport NODE_OPTIONS="--require \\$DIR/hook.js \\$NODE_OPTIONS"'
);

fs.writeFileSync('build/node.sh', content);
