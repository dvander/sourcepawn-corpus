#pragma semicolon 1
#include <sourcemod>
#include <autoupdate>
#include <socket>
#define PL_VERSION "1.5"
new Handle:g_hPlugins = INVALID_HANDLE;
new Handle:g_hUrls = INVALID_HANDLE;
new Handle:g_hFiles = INVALID_HANDLE;
new Handle:g_hVersions = INVALID_HANDLE;
new Handle:g_hBlocked = INVALID_HANDLE;
new Handle:g_hCheckQueue = INVALID_HANDLE;
new Handle:g_hDownloadsQueue = INVALID_HANDLE;
new bool:g_bDownloading = false;
new Handle:g_hBinary = INVALID_HANDLE;
new bool:g_bBinary = true;
new Handle:g_hSource = INVALID_HANDLE;
new bool:g_bSource = true;
new Handle:g_hGamedata = INVALID_HANDLE;
new bool:g_bGamedata = true;
new Handle:g_hOther = INVALID_HANDLE;
new bool:g_bOther = true;
new Handle:g_hBackup = INVALID_HANDLE;
new bool:g_bBackup = true;
public Plugin:myinfo = 
{
	name = "Plugin Autoupdater",
	author = "MikeJS",
	description = "Automatically checks for and downloads plugin updates.",
	version = PL_VERSION,
	url = "http://www.mikejsavage.com/"
}
public OnPluginStart() {
	g_hPlugins = CreateArray();
	g_hUrls = CreateArray(64);
	g_hFiles = CreateArray(16);
	g_hVersions = CreateArray(4);
	g_hBlocked = CreateArray(32);
	g_hCheckQueue = CreateArray();
	g_hDownloadsQueue = CreateArray();
	CreateConVar("sm_autoupdate_version", PL_VERSION, "Plugin Autoupdater version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hBinary = CreateConVar("sm_autoupdate_binary", "1", "Download binaries?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hSource = CreateConVar("sm_autoupdate_source", "1", "Download sources?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hGamedata = CreateConVar("sm_autoupdate_gamedata", "1", "Download gamedata files?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hOther = CreateConVar("sm_autoupdate_other", "1", "Download other files?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hBackup = CreateConVar("sm_autoupdate_backup", "1", "Save backups of old versions?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_autoupdate_check", Command_check, ADMFLAG_ROOT, "Checks for updates but doesn't download them. sm_autoupdate_check [filename/idx]");
	RegAdminCmd("sm_autoupdate_download", Command_download, ADMFLAG_ROOT, "Checks for updates and downloads them. sm_autoupdate_download [filename/idx]");
	RegAdminCmd("sm_autoupdate_list", Command_list, ADMFLAG_ROOT, "Lists plugins being autoupdated.");
	RegAdminCmd("sm_autoupdate_rem", Command_rem, ADMFLAG_ROOT, "Stops a plugin being autoupdated. sm_autoupdate_rem <filename/idx>");
	RegAdminCmd("sm_autoupdate_block_add", Command_addblock, ADMFLAG_ROOT, "Stops a plugin from being updated by filename. sm_autoupdate_block_add <filename>");
	RegAdminCmd("sm_autoupdate_block_rem", Command_remblock, ADMFLAG_ROOT, "Removes a plugin from the block list. sm_autoupdate_block_rem <filename/idx>");
	RegAdminCmd("sm_autoupdate_block_list", Command_listblock, ADMFLAG_ROOT, "Lists blocked plugins.");
	HookConVarChange(g_hBinary, Cvar_binary);
	HookConVarChange(g_hSource, Cvar_source);
	HookConVarChange(g_hGamedata, Cvar_gamedata);
	HookConVarChange(g_hOther, Cvar_other);
	HookConVarChange(g_hBackup, Cvar_backup);
}
public OnConfigsExecuted() {
	g_bBinary = GetConVarBool(g_hBinary);
	g_bSource = GetConVarBool(g_hSource);
	g_bGamedata = GetConVarBool(g_hGamedata);
	g_bOther = GetConVarBool(g_hOther);
	g_bBackup = GetConVarBool(g_hBackup);
}
public Cvar_binary(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bBinary = GetConVarBool(g_hBinary);
}
public Cvar_source(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bSource = GetConVarBool(g_hSource);
}
public Cvar_gamedata(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bGamedata = GetConVarBool(g_hGamedata);
}
public Cvar_other(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bOther = GetConVarBool(g_hOther);
}
public Cvar_backup(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bBackup = GetConVarBool(g_hBackup);
}
public Action:Command_check(client, args) {
	new size = GetArraySize(g_hPlugins);
	if(args==0) {
		for(new i=0;i<size;i++)
			CheckUpdates(i);
	} else {
		decl String:argstr[32];
		GetCmdArgString(argstr, sizeof(argstr));
		StripQuotes(argstr);
		TrimString(argstr);
		new idx = FindPlugin(argstr);
		if(idx==-1)
			idx = StringToInt(argstr);
		if(idx>=size || idx<0) {
			ReplyToCommand(client, "Invalid index.");
		} else {
			CheckUpdates(idx);
		}
	}
	return Plugin_Handled;
}
public Action:Command_download(client, args) {
	new size = GetArraySize(g_hPlugins);
	if(args==0) {
		for(new i=0;i<size;i++)
			CheckUpdates(i, 1);
	} else {
		decl String:argstr[32];
		GetCmdArgString(argstr, sizeof(argstr));
		StripQuotes(argstr);
		TrimString(argstr);
		new idx = FindPlugin(argstr);
		if(idx==-1)
			idx = StringToInt(argstr);
		if(idx>=size || idx<0) {
			ReplyToCommand(client, "Invalid index.");
		} else {
			CheckUpdates(idx, 1);
		}
	}
	return Plugin_Handled;
}
public Action:Command_list(client, args) {
	new size = GetArraySize(g_hPlugins);
	decl String:pluginname[32], String:version[16];
	for(new i=0;i<size;i++) {
		GetPluginFilename(GetArrayCell(g_hPlugins, i), pluginname, sizeof(pluginname));
		GetArrayString(g_hVersions, i, version, sizeof(version));
		ReplyToCommand(client, "[%i] %s %s", i, pluginname, version);
	}
	ReplyToCommand(client, "Autoupdating %i plugin%s.", size, size==1?"":"s");
	return Plugin_Handled;
}
public Action:Command_rem(client, args) {
	if(args==1) {
		decl String:argstr[32];
		GetCmdArgString(argstr, sizeof(argstr));
		StripQuotes(argstr);
		TrimString(argstr);
		new idx = FindPlugin(argstr);
		if(idx==-1)
			idx = StringToInt(argstr);
		if(idx<GetArraySize(g_hPlugins))
			AutoUpdate_RemovePlugin(GetArrayCell(g_hPlugins, idx));
	} else {
		ReplyToCommand(client, "Usage: sm_autoupdate_rem <filename/idx>");
	}
	return Plugin_Handled;
}
public Action:Command_addblock(client, args) {
	if(args==1) {
		decl String:argstr[32];
		GetCmdArgString(argstr, sizeof(argstr));
		StripQuotes(argstr);
		TrimString(argstr);
		PushArrayString(g_hBlocked, argstr);
	} else {
		ReplyToCommand(client, "Usage: sm_autoupdate_block_add <filename>");
	}
	return Plugin_Handled;
}
public Action:Command_remblock(client, args) {
	if(args==1) {
		decl String:argstr[32];
		GetCmdArgString(argstr, sizeof(argstr));
		StripQuotes(argstr);
		TrimString(argstr);
		new idx = FindStringInArray(g_hBlocked, argstr);
		if(idx==-1)
			idx = StringToInt(argstr);
		if(idx<GetArraySize(g_hBlocked) && idx>=0)
			RemoveFromArray(g_hBlocked, idx);
	} else {
		ReplyToCommand(client, "Usage: sm_autoupdate_block_rem <filename/idx>");
	}
	return Plugin_Handled;
}
public Action:Command_listblock(client, args) {
	decl String:pluginname[32];
	new size = GetArraySize(g_hBlocked);
	for(new i=0;i<size;i++) {
		GetArrayString(g_hBlocked, i, pluginname, sizeof(pluginname));
		ReplyToCommand(client, "[%i] %s", i, pluginname);
	}
	ReplyToCommand(client, "Blocked %i plugin%s.", size, size==1?"":"s");
	return Plugin_Handled;
}
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max) {
	RegPluginLibrary("pluginautoupdate");
	CreateNative("AutoUpdate_AddPlugin", Native_AddPlugin);
	CreateNative("AutoUpdate_RemovePlugin", Native_RemovePlugin);
	return true;
}
public Native_AddPlugin(Handle:plugin, numParams) {
	decl String:pluginname[32];
	GetPluginFilename(plugin, pluginname, sizeof(pluginname));
	if(FindStringInArray(g_hBlocked, pluginname)==-1) {
		decl String:url[256], String:file[64], String:version[16];
		GetNativeString(1, url, sizeof(url));
		GetNativeString(2, file, sizeof(file));
		GetNativeString(3, version, sizeof(version));
		PushArrayCell(g_hPlugins, plugin);
		PushArrayString(g_hUrls, url);
		PushArrayString(g_hFiles, file);
		PushArrayString(g_hVersions, version);
	}
}
public Native_RemovePlugin(Handle:plugin, numParams) {
	new Handle:rplugin = GetNativeCell(1);
	if(rplugin==INVALID_HANDLE)
		rplugin = plugin;
	new idx = FindValueInArray(g_hPlugins, rplugin);
	if(idx!=-1) {
		RemoveFromArray(g_hPlugins, idx);
		RemoveFromArray(g_hUrls, idx);
		RemoveFromArray(g_hFiles, idx);
		RemoveFromArray(g_hVersions, idx);
	}
}
AULog(const String:format[], any:...) {
	decl String:path[256], String:buffer[192];
	BuildPath(Path_SM, path, sizeof(path), "logs/autoupdate.log");
	VFormat(buffer, sizeof(buffer), format, 2);
	LogToFileEx(path, "%s", buffer);
}
CreateDirectories(const String:path[], mode=511) {
	decl String:dirs[16][32];
	new count = ExplodeString(path, "\\", dirs, sizeof(dirs), sizeof(dirs[])), String:curpath[256];
	for(new i=0;i<count;i++) {
		StrCat(curpath, sizeof(curpath), "\\");
		StrCat(curpath, sizeof(curpath), dirs[i]);
		if(!DirExists(curpath))
			CreateDirectory(curpath, mode);
	}
}
CheckUpdates(idx, dl=0) {
	new Handle:pack = INVALID_HANDLE, Handle:data = INVALID_HANDLE;
	decl String:url[256], String:file[64], String:version[16];
	GetArrayString(g_hUrls, idx, url, sizeof(url));
	GetArrayString(g_hVersions, idx, version, sizeof(version));
	GetArrayString(g_hFiles, idx, file, sizeof(file));
	pack = CreateDataPack();
	data = CreateDataPack();
	WritePackCell(pack, _:data);
	WritePackString(pack, url);
	WritePackString(pack, file);
	WritePackCell(pack, dl);
	WritePackString(pack, version);
	WritePackCell(pack, _:GetArrayCell(g_hPlugins, idx));
	PushArrayCell(g_hCheckQueue, pack);
	ProcessDownloadsQueue();
}
FindPlugin(const String:plugin[]) {
	decl String:buffer[32];
	new size = GetArraySize(g_hPlugins);
	for(new i=0;i<size;i++) {
		GetPluginFilename(GetArrayCell(g_hPlugins, i), buffer, sizeof(buffer));
		if(StrEqual(plugin, buffer))
			return i;
	}
	return -1;
}
ProcessDownloadsQueue() {
	if(!g_bDownloading) {
		new size = GetArraySize(g_hCheckQueue);
		if(size>0) {
			new Handle:pack = GetArrayCell(g_hCheckQueue, 0);
			RemoveFromArray(g_hCheckQueue, 0);
			SetPackPosition(pack, 8);
			decl String:url[256];
			ReadPackString(pack, url, sizeof(url));
			new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
			SocketSetArg(socket, pack);
			SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, url, 80);
			g_bDownloading = true;
		} else {
			size = GetArraySize(g_hDownloadsQueue);
			if(size>0) {
				new Handle:pack = GetArrayCell(g_hDownloadsQueue, 0);
				RemoveFromArray(g_hDownloadsQueue, 0);
				ResetPack(pack);
				decl String:url[256];
				ReadPackString(pack, url, sizeof(url));
				SetPackPosition(pack, GetPackPosition(pack)+8);
				ReadPackString(pack, url, sizeof(url));
				new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
				SocketSetArg(socket, pack);
				SocketConnect(socket, OnSocketConnectedDl, OnSocketReceiveDl, OnSocketDisconnectedDl, url, 80);
				g_bDownloading = true;
			}
		}
	}
}
public OnSocketConnected(Handle:socket, any:pack) {
	decl String:url[256], String:file[64], String:buffer[512];
	SetPackPosition(pack, 8);
	ReadPackString(pack, url, sizeof(url));
	ReadPackString(pack, file, sizeof(file));
	Format(buffer, sizeof(buffer), "GET %s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", file, url);
	SocketSend(socket, buffer);
}
public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:pack) {
	ResetPack(pack);
	new Handle:data = Handle:ReadPackCell(pack);
	WritePackString(data, receiveData);
}
public OnSocketDisconnected(Handle:socket, any:pack) {
	g_bDownloading = false;
	ProcessDownloadsQueue();
	decl String:datastr[2048], String:buffer[2048], String:url[256], String:file[64], String:version[16];
	ResetPack(pack);
	new Handle:data = Handle:ReadPackCell(pack);
	ReadPackString(pack, url, sizeof(url));
	ReadPackString(pack, file, sizeof(file));
	new dl = ReadPackCell(pack);
	ResetPack(data);
	Format(datastr, sizeof(datastr), "");
	while(IsPackReadable(data, 1)) {
		ReadPackString(data, buffer, sizeof(buffer));
		StrCat(datastr, sizeof(datastr), buffer);
	}
	ReadPackString(pack, version, sizeof(version));
	new Handle:plugin = Handle:ReadPackCell(pack);
	decl String:pluginname[64];
	GetPluginFilename(plugin, pluginname, sizeof(pluginname));
	CloseHandle(data);
	CloseHandle(pack);
	new pos = StrContains(datastr, "<plugin>");
	if(pos==-1) {
		AULog("<FAILED> %s: %s%s (couldn't find anything)", pluginname, url, file);
	} else {
		decl String:newversion[16];
		pos = StrContains(datastr, "<version>")+9;
		if(pos==8) {
			AULog("<FAILED> %s: %s%s (couldn't find version)", pluginname, url, file);
		} else {
			strcopy(newversion, IMin(sizeof(newversion), (StrContains(datastr, "</version>")-pos)+1), datastr[pos]);
			if(!StrEqual(version, newversion)) {
				decl String:changes[256];
				pos = StrContains(datastr, "<changes>")+9;
				if(pos==8) {
					Format(changes, sizeof(changes), "");
				} else {
					strcopy(changes, IMin(sizeof(changes), (StrContains(datastr, "</changes>")-pos)+1), datastr[pos]);
				}
				if(dl==1) {
					decl String:filelist[1024], String:newfiles[16][64], String:path[512], String:exfile[16][32], filecount, splitcount;
					AULog("<UPDATING> %s to version %s - Changes: %s", pluginname, newversion, changes);
					if(g_bBinary) {
						pos = StrContains(datastr, "<binary>")+8;
						if(pos!=7) {
							strcopy(filelist, IMin(sizeof(filelist), (StrContains(datastr, "</binary>")-pos)+1), datastr[pos]);
							filecount = ExplodeString(filelist, ",", newfiles, sizeof(newfiles), sizeof(newfiles[]));
							for(new i=0;i<filecount;i++) {
								TrimString(newfiles[i]);
								splitcount = ExplodeString(newfiles[i], "/", exfile, sizeof(exfile), sizeof(exfile[]));
								BuildPath(Path_SM, path, sizeof(path), "plugins/%s", exfile[splitcount-1]);
								if(g_bBackup) {
									decl String:backuppath[512];
									BuildPath(Path_SM, backuppath, sizeof(backuppath), "plugins/disabled/backups/%s/%s/addons/sourcemod/plugins", pluginname, version);
									CreateDirectories(backuppath);
									BuildPath(Path_SM, backuppath, sizeof(backuppath), "plugins/disabled/backups/%s/%s/addons/sourcemod/plugins/%s", pluginname, version, exfile[splitcount-1]);
									RenameFile(backuppath, path);
								}
								Download(url, newfiles[i], path);
							}
						}
					}
					if(g_bSource) {
						pos = StrContains(datastr, "<source>")+8;
						if(pos!=7) {
							strcopy(filelist, IMin(sizeof(filelist), (StrContains(datastr, "</source>")-pos)+1), datastr[pos]);
							filecount = ExplodeString(filelist, ",", newfiles, sizeof(newfiles), sizeof(newfiles[]));
							for(new i=0;i<filecount;i++) {
								TrimString(newfiles[i]);
								splitcount = ExplodeString(newfiles[i], "/", exfile, sizeof(exfile), sizeof(exfile[]));
								BuildPath(Path_SM, path, sizeof(path), "scripting/%s", exfile[splitcount-1]);
								if(g_bBackup) {
									decl String:backuppath[512];
									BuildPath(Path_SM, backuppath, sizeof(backuppath), "plugins/disabled/backups/%s/%s/addons/sourcemod/scripting", pluginname, version);
									CreateDirectories(backuppath);
									BuildPath(Path_SM, backuppath, sizeof(backuppath), "plugins/disabled/backups/%s/%s/addons/sourcemod/scripting/%s", pluginname, version, exfile[splitcount-1]);
									RenameFile(backuppath, path);
								}
								Download(url, newfiles[i], path);
							}
						}
					}
					if(g_bGamedata) {
						pos = StrContains(datastr, "<gamedata>")+10;
						if(pos!=9) {
							strcopy(filelist, IMin(sizeof(filelist), (StrContains(datastr, "</gamedata>")-pos)+1), datastr[pos]);
							filecount = ExplodeString(filelist, ",", newfiles, sizeof(newfiles), sizeof(newfiles[]));
							for(new i=0;i<filecount;i++) {
								TrimString(newfiles[i]);
								splitcount = ExplodeString(newfiles[i], "/", exfile, sizeof(exfile), sizeof(exfile[]));
								BuildPath(Path_SM, path, sizeof(path), "gamedata/%s", exfile[splitcount-1]);
								if(g_bBackup) {
									decl String:backuppath[512];
									BuildPath(Path_SM, backuppath, sizeof(backuppath), "plugins/disabled/backups/%s/%s/addons/sourcemod/gamedata", pluginname, version);
									CreateDirectories(backuppath);
									BuildPath(Path_SM, backuppath, sizeof(backuppath), "plugins/disabled/backups/%s/%s/addons/sourcemod/gamedata/%s", pluginname, version, exfile[splitcount-1]);
									RenameFile(backuppath, path);
								}
								Download(url, newfiles[i], path);
							}
						}
					}
					if(g_bOther) {
						decl String:path2[512];
						pos = StrContains(datastr, "<other dir=\"")+12;
						while(pos!=11) {
							strcopy(path, IMin(sizeof(path), StrContains(datastr[pos], "\">")+1), datastr[pos]);
							CreateDirectories(path);
							pos = StrContains(datastr[pos], "\">")+2+pos;
							strcopy(filelist, IMin(sizeof(filelist), StrContains(datastr[pos], "</other>")+1), datastr[pos]);
							filecount = ExplodeString(filelist, ",", newfiles, sizeof(newfiles), sizeof(newfiles[]));
							for(new i=0;i<filecount;i++) {
								TrimString(newfiles[i]);
								splitcount = ExplodeString(newfiles[i], "/", exfile, sizeof(exfile), sizeof(exfile[]));
								Format(path2, sizeof(path2), "%s/%s", path, exfile[splitcount-1]);
								if(g_bBackup) {
									decl String:backuppath[512];
									BuildPath(Path_SM, backuppath, sizeof(backuppath), "plugins/disabled/backups/%s/%s/%s", pluginname, version, path);
									CreateDirectories(backuppath);
									BuildPath(Path_SM, backuppath, sizeof(backuppath), "plugins/disabled/backups/%s/%s/%s/%s", pluginname, version, path, exfile[splitcount-1]);
									RenameFile(backuppath, path2);
								}
								Download(url, newfiles[i], path2);
							}
							if(StrContains(datastr[pos], "<other dir=\"")==-1) {
								pos = 11;
							} else {
								pos = StrContains(datastr[pos], "<other dir=\"")+12+pos;
							}
						}
					}						
					AutoUpdate_RemovePlugin(plugin);
				} else {
					AULog("<NOT UPDATED> %s to version %s - Changes: %s", pluginname, newversion, changes);
				}
			}
		}
	}
}
IMin(x, y) {
	return x<y?x:y;
}
Download(const String:url[], const String:file[], const String:path[]) {
	DeleteFile(path);
	new Handle:pack = CreateDataPack();
	WritePackString(pack, path);
	WritePackCell(pack, 1);
	WritePackString(pack, url);
	WritePackString(pack, file);
	PushArrayCell(g_hDownloadsQueue, pack);
	ProcessDownloadsQueue();
}
public OnSocketConnectedDl(Handle:socket, any:pack) {
	decl String:url[256], String:file[64], String:buffer[512];
	ResetPack(pack);
	ReadPackString(pack, file, sizeof(file));
	SetPackPosition(pack, GetPackPosition(pack)+8);
	ReadPackString(pack, url, sizeof(url));
	ReadPackString(pack, file, sizeof(file));
	Format(buffer, sizeof(buffer), "GET %s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", file, url);
	SocketSend(socket, buffer);
}
public OnSocketReceiveDl(Handle:socket, String:receiveData[], const dataSize, any:pack) {
	decl String:path[256];
	ResetPack(pack);
	ReadPackString(pack, path, sizeof(path));
	new pos = 0;
	if(ReadPackCell(pack)==1) {
		pos = StrContains(receiveData, "\r\n\r\n")+4;
		SetPackPosition(pack, GetPackPosition(pack)-8);
		WritePackCell(pack, 0);
	}
	new Handle:file = OpenFile(path, "ab");
	for(new i=pos;i<dataSize;i++)
		WriteFile(file, _:receiveData[i], 1, 1);
	CloseHandle(file);
}
public OnSocketDisconnectedDl(Handle:socket, any:pack) {
	g_bDownloading = false;
	ProcessDownloadsQueue();
	decl String:path[256];
	ResetPack(pack);
	ReadPackString(pack, path, sizeof(path));
	AULog("Downloaded %s", path);
	CloseHandle(pack);
}
public OnSocketError(Handle:socket, const errorType, const errorNum, any:ary) {
	LogError("Socket error: %d (#%d)", errorType, errorNum);
	CloseHandle(socket);
}