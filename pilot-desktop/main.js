// Pilot for computer: the Pilot web app in its own window.
// It opens the live site, so it updates itself like the website; the site's service worker
// keeps it working without internet after the first start. Data stays in this app's own storage.
const {app, BrowserWindow, session, shell, Menu} = require('electron');
const path = require('path');

const APP_URL = 'https://alfatango1.github.io/rt-trainer/pilot/';
const inApp = (u) => typeof u === 'string' && u.startsWith(APP_URL);
let win = null;

function createWindow() {
  win = new BrowserWindow({
    width: 480, height: 900, minWidth: 360, minHeight: 560,
    backgroundColor: '#121212', title: 'Пилот',
    icon: path.join(__dirname, 'icon.png'), autoHideMenuBar: true,
    webPreferences: {contextIsolation: true, sandbox: true}
  });
  // links to other sites open in the normal browser
  win.webContents.setWindowOpenHandler(({url}) => {
    if (!inApp(url)) shell.openExternal(url);
    return {action: 'deny'};
  });
  win.webContents.on('will-navigate', (e, url) => {
    if (!inApp(url) && !url.startsWith('file:')) { e.preventDefault(); shell.openExternal(url); }
  });
  // first start without internet (nothing cached yet): show a page that retries
  win.webContents.on('did-fail-load', (e, code, desc, url, isMain) => {
    if (isMain && code !== -3 && inApp(url)) win.loadFile(path.join(__dirname, 'offline.html'));
  });
  // F5 / Ctrl+R reload (there is no menu bar)
  win.webContents.on('before-input-event', (e, input) => {
    if (input.type === 'keyDown' && (input.key === 'F5' || (input.control && input.key.toLowerCase() === 'r'))) {
      e.preventDefault(); win.loadURL(APP_URL);
    }
  });
  win.loadURL(APP_URL);
}

if (!app.requestSingleInstanceLock()) {
  app.quit();
} else {
  app.on('second-instance', () => {
    if (win) { if (win.isMinimized()) win.restore(); win.focus(); }
  });
  app.setAppUserModelId('io.github.alfatango1.pilot.desktop'); // needed for Windows notifications
  app.whenReady().then(() => {
    session.defaultSession.setPermissionRequestHandler((wc, perm, cb) =>
      cb(['notifications', 'clipboard-sanitized-write'].includes(perm)));
    Menu.setApplicationMenu(null);
    createWindow();
    app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
  });
  app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
}
