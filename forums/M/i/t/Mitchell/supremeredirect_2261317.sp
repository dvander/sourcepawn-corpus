#pragma semicolon 1
#include <sdktools>

#define MAXSERVERS         25
new String:szSever[MAXSERVERS][32];
new String:szSvrIP[MAXSERVERS][32];
new iMaxServers;
new iCurrentServer = -1;
new String:szCurrentIP[32];
new Handle:hServerMenu = INVALID_HANDLE;
new Handle:cvShowAddress = INVALID_HANDLE;

#define PLUGIN_VERSION              "1.1.2"
public Plugin:myinfo = {
	name = "Supreme Redirect System",
	author = "Mitchell",
	description = "Uses the new 'redirect' command to make a player join a different server.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2261322"
}
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
------Plugin Functions
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
public OnPluginStart() {
	cvShowAddress = CreateConVar( "sm_supremeredirect_showaddress", "0", "Set to 1 to show the address of the server as a disabled item, 2 to let the player connect to the current server." );
	AutoExecConfig();
	CreateConVar("sm_supremeredirect_version", PLUGIN_VERSION, "Redirect Version",  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_servers", Cmd_Redirect, 0);
	RegAdminCmd("sm_redirect", Cmd_Redirect, 0);
	RegAdminCmd("sm_direct", Cmd_Redirect, 0);
}

public OnMapStart() {
	LoadConfig();
	SetupMenu();
}

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
------Cmd_Redirect		(type: Public Function)
	Sends the redirect menu.
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
public Action:Cmd_Redirect(client, args) {
	if(client && IsClientInGame(client)) {
		if(IsRedirectMenuReady()) {
			DisplayMenu(hServerMenu, client, MENU_TIME_FOREVER);
		}
	}
	return Plugin_Handled;
}
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
------SetupMenu		(type: Public Function)
	Setups a menu...wat
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
public SetupMenu() {
	if(hServerMenu != INVALID_HANDLE) {
		CloseHandle(hServerMenu);
		hServerMenu = INVALID_HANDLE;
	}
	hServerMenu = CreateMenu(Menu_Redirect, MENU_ACTIONS_DEFAULT);
	SetMenuTitle(hServerMenu, "Server Redirect:");
	new iAction = GetConVarInt(cvShowAddress);
	if(iAction == 1 && iCurrentServer != -1) {
		AddMenuItem(hServerMenu, "", szSever[iCurrentServer], ITEMDRAW_DISABLED);
	}
	for(new i = 0; i < iMaxServers; i++) {
		if(iAction <= 1 && iCurrentServer == i) {
			continue;
		}
		AddMenuItem(hServerMenu, szSvrIP[i], szSever[i]);
	}
	SetMenuExitButton(hServerMenu, true);
}
public Menu_Redirect(Handle:main, MenuAction:action, client, param2) {
	switch (action) {
		case MenuAction_Select: {
			new String:info[32];
			GetMenuItem(main, param2, info, sizeof(info));
			ClientCommand(client, "redirect %s", info);
			DisplayAskConnectBox(client, 45.0, info);
		}
	}
	return;
}
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
------LoadConfig		(type: Public Function)
	Loads the config from 
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
public LoadConfig() {
	iCurrentServer = -1;
	//Could probably use steam tools or something and use this as a fall back method.
	decl String:sHostIP[32];
	decl String:sHostPort[8];
	GetConVarString(FindConVar("ip"), sHostIP, 32);
	GetConVarString(FindConVar("hostport"), sHostPort, 8);
	Format(szCurrentIP, sizeof(szCurrentIP), "%s:%s", sHostIP, sHostPort);
	PrintToServer(szCurrentIP);
	new Handle:SMC = SMC_CreateParser(); 
	SMC_SetReaders(SMC, NewSection, KeyValue, EndSection); 
	decl String:sPaths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPaths, sizeof(sPaths),"configs/redirect.cfg");
	SMC_ParseFile(SMC, sPaths);
	CloseHandle(SMC);
}
public SMCResult:NewSection(Handle:smc, const String:name[], bool:opt_quotes) {}
public SMCResult:EndSection(Handle:smc) {}  
public SMCResult:KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes) {
	strcopy(szSever[iMaxServers], 32, key);
	strcopy(szSvrIP[iMaxServers], 32, value);
	if(StrEqual(value, szCurrentIP)) {
		iCurrentServer = iMaxServers;
	}
	iMaxServers++;
}
public bool:IsRedirectMenuReady () {
	return hServerMenu != INVALID_HANDLE;
}