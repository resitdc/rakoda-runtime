const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const RUNTIME_DIR = path.join(__dirname, '../runtime');
const MANIFEST_PATH = path.join(__dirname, '../manifest/runtime.json');

const manifest = {};

function scanDirectory() {
    if (!fs.existsSync(RUNTIME_DIR)) return;
    
    const runtimes = fs.readdirSync(RUNTIME_DIR);
    for (const runtime of runtimes) {
        manifest[runtime] = { latest: "", versions: {} };
        let latestVersion = "";
        
        const runtimePath = path.join(RUNTIME_DIR, runtime);
        const versions = fs.readdirSync(runtimePath);
        
        for (const version of versions) {
            latestVersion = version; // Simplified version sorting
            manifest[runtime].versions[version] = {};
            
            const versionPath = path.join(runtimePath, version);
            const targets = fs.readdirSync(versionPath);
            
            for (const target of targets) {
                const [os, arch] = target.split('-');
                if (!manifest[runtime].versions[version][os]) {
                    manifest[runtime].versions[version][os] = {};
                }
                
                const targetPath = path.join(versionPath, target);
                // In real world, we would read the SHA256 file and get the exact artifact URL
                const isWindows = target.includes('windows');
                const ext = isWindows ? 'zip' : 'tar.gz';
                manifest[runtime].versions[version][os][arch || 'x64'] = {
                    url: `https://github.com/resitdc/rakoda-runtime/releases/download/${runtime}-v${version}/${runtime}-${target}.${ext}`,
                    sha256: "placeholder-sha256",
                    size: 1024
                };
            }
        }
        manifest[runtime].latest = latestVersion;
    }
}

scanDirectory();

if (!fs.existsSync(path.dirname(MANIFEST_PATH))) {
    fs.mkdirSync(path.dirname(MANIFEST_PATH), { recursive: true });
}

fs.writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2));
console.log("Manifest generated at manifest/runtime.json");
