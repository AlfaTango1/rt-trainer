// RT Trainer desktop: the same app as the web version, in its own window.
const {app,BrowserWindow,session,shell,Menu}=require('electron');
const path=require('path');
function win(){
  const w=new BrowserWindow({width:1280,height:860,minWidth:380,minHeight:600,backgroundColor:'#F3F5F8',title:'RT Trainer',
    icon:path.join(__dirname,'icon.png'),autoHideMenuBar:true,webPreferences:{contextIsolation:true,sandbox:true}});
  w.loadFile(path.join(__dirname,'app','index.html'));
  w.webContents.setWindowOpenHandler(({url})=>{shell.openExternal(url);return {action:'deny'}});
}
app.whenReady().then(()=>{
  session.defaultSession.setPermissionRequestHandler((wc,perm,cb)=>cb(['media','audioCapture','microphone'].includes(perm)));
  Menu.setApplicationMenu(null);win();
  app.on('activate',()=>{if(BrowserWindow.getAllWindows().length===0)win()});
});
app.on('window-all-closed',()=>{if(process.platform!=='darwin')app.quit()});
