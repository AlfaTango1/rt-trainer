// Pilot for computer: the Pilot app in its own window.
// The app files (copied from pilot/ when the installer is built) are inside the installed program,
// so it starts and works with no internet at all. The cloud copy and username requests work when there is internet.
// A new installer is built automatically whenever pilot/ changes.
const {app, BrowserWindow, session, shell, Menu} = require('electron');
const path = require('path');

const PAGE = path.join(__dirname, 'app', 'index.html');
let win = null;

function createWindow() {
  win = new BrowserWindow({
    width: 480, height: 900, minWidth: 360, minHeight: 560,
    backgroundColor: '#121212', title: 'Пилот',
    icon: path.join(__dirname, 'icon.png'), autoHideMenuBar: true,
    webPreferences: {contextIsolation: true, sandbox: true}
  });
  // web links open in the normal browser; the app itself never leaves its own files
  win.webContents.setWindowOpenHandler(({url}) => {
    if (/^https?:/i.test(url)) shell.openExternal(url);
    return {action: 'deny'};
  });
  win.webContents.on('will-navigate', (e, url) => {
    if (!url.startsWith('file:')) { e.preventDefault(); if (/^https?:/i.test(url)) shell.openExternal(url); }
  });
  // F5 / Ctrl+R reload (there is no menu bar)
  win.webContents.on('before-input-event', (e, input) => {
    if (input.type === 'keyDown' && (input.key === 'F5' || (input.control && input.key.toLowerCase() === 'r'))) {
      e.preventDefault(); win.webContents.reload();
    }
  });
  win.loadFile(PAGE);
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
