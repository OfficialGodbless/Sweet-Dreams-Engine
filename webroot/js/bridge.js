export function exec(command) {
    return new Promise((resolve, reject) => {
        if (typeof ksu === 'undefined') {
            console.warn('[Bridge] ksu not found. Mock:', command);
            resolve('');
            return;
        }
        const cb = `exec_cb_${Date.now()}_${Math.random().toString(36).substring(2)}`;
        window[cb] = (errno, stdout, stderr) => {
            delete window[cb];
            if (errno !== 0) reject(new Error(stderr || stdout || 'error'));
            else resolve(stdout);
        };
        try {
            ksu.exec(command, `window.${cb}`);
        } catch (e) {
            reject(e);
        }
    });
}
