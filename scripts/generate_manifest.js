const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const RUNTIME_DIR = path.join(__dirname, '../runtime');
const MANIFEST_PATH = path.join(__dirname, '../manifest/runtime.json');

let manifest = {};
if (fs.existsSync(MANIFEST_PATH)) {
    try {
        manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8'));
    } catch (e) {
        manifest = {};
    }
}

function scanDirectory() {
    if (!fs.existsSync(RUNTIME_DIR)) return;
    
    const runtimes = fs.readdirSync(RUNTIME_DIR).filter(item => fs.statSync(path.join(RUNTIME_DIR, item)).isDirectory());
    for (const runtime of runtimes) {
        if (!manifest[runtime]) {
            manifest[runtime] = { latest: "", versions: {} };
        }
        let latestVersion = manifest[runtime].latest;
        
        const runtimePath = path.join(RUNTIME_DIR, runtime);
        const versions = fs.readdirSync(runtimePath).filter(item => fs.statSync(path.join(runtimePath, item)).isDirectory());
        
        for (const version of versions) {
            latestVersion = version; // Simplified version sorting
            if (!manifest[runtime].versions[version]) {
                manifest[runtime].versions[version] = {};
            }
            
            const versionPath = path.join(runtimePath, version);
            const targets = fs.readdirSync(versionPath).filter(item => fs.statSync(path.join(versionPath, item)).isDirectory());
            
            for (const target of targets) {
                const [os, arch] = target.split('-');
                if (!manifest[runtime].versions[version][os]) {
                    manifest[runtime].versions[version][os] = {};
                }
                
                const targetPath = path.join(versionPath, target);
                const isWindows = target.includes('windows');
                const ext = isWindows ? 'zip' : 'tar.gz';
                
                const archiveFile = `${runtime}-${target}.${ext}`;
                const sha256File = `${runtime}-${target}.sha256`;
                
                let sha256Value = "placeholder-sha256";
                let sizeValue = 1024;
                
                const archivePath = path.join(targetPath, archiveFile);
                const sha256Path = path.join(targetPath, sha256File);
                
                if (fs.existsSync(sha256Path)) {
                    const content = fs.readFileSync(sha256Path, 'utf8').trim();
                    sha256Value = content.split(/\s+/)[0]; 
                }
                
                if (fs.existsSync(archivePath)) {
                    const stats = fs.statSync(archivePath);
                    sizeValue = stats.size;
                }

                manifest[runtime].versions[version][os][arch || 'x64'] = {
                    url: `https://github.com/resitdc/rakoda-runtime/releases/download/${runtime}-v${version}/${runtime}-${target}.${ext}`,
                    sha256: sha256Value,
                    size: sizeValue
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
