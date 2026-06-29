#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Advanced Client Redirect",
	author = "Olly/Tobi",
	description = "Redirect client to a new server via a menu.",
	version = "1.0",
	url = "http://www.steamfriends.com"
}

new Handle:redirKv;
new Handle:redirMenu;
public OnPluginStart()
{
	new String:redirLoc[128];
	CreateConVar("sm_adv_redirect_version", "1.0", "Advanced Client Redirect", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	BuildPath(Path_SM,redirLoc,sizeof(redirLoc),"configs/redirect_servers.cfg");
	redirKv = CreateKeyValues("Servers");
	if(!FileToKeyValues(redirKv, redirLoc))
		LogToGame("Error loading server list");
	
	
	RegConsoleCmd("sm_servers", DoMenu, "Show Server Lists");
	RegConsoleCmd("sm_swapme", DoMenu, "Show Server Lists");
	
	
	new stack=0;
	new String:tmpName[128];
	new String:tmpAddr[128];
	redirMenu = CreateMenu(RedirMenuHandler);
	SetMenuTitle(redirMenu, "Choose a server to join...");
	SetMenuExitButton(redirMenu, true);
	
	
	KvRewind(redirKv);
	KvGotoFirstSubKey(redirKv);
	do
	{
		KvGetSectionName(redirKv, tmpName, sizeof(tmpName));
		KvGetString(redirKv, "address", tmpAddr, sizeof(tmpAddr));
		AddMenuItem(redirMenu, tmpAddr, tmpName);
		stack++;
	}while(KvGotoNextKey(redirKv))
	
}

public Action:DoMenu(client,args)
{
	DisplayMenu(redirMenu, client, 20);
	ClientCommand(client, "bind F4 \"askconnect_accept\"");
	return Plugin_Handled;
}

public RedirMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)	
	{
		new Handle:top_values = CreateKeyValues("msg");
		KvSetString(top_values, "title", "You have selected to join a new server");
		KvSetNum(top_values, "level", 1); 
		KvSetString(top_values, "time", "10"); 
		CreateDialog(param1, top_values, DialogType_Msg);
		CloseHandle(top_values);
		
		new String:info[64];
		GetMenuItem(redirMenu, param2, info, sizeof(info))
		
		new Handle:values = CreateKeyValues("msg");
		KvSetString(values, "time", "10"); 
		KvSetString(values, "title", info); 
		CreateDialog(param1, values, DialogType_AskConnect);
		CloseHandle(values);
		
	} 
}