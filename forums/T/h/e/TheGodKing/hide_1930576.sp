#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1

new bool:g_bHidden[MAXPLAYERS+1] = false;

public Plugin:myinfo ={
	name = "Hide",
	author = "TheGodKing",
	description = "Hides clients via SetTransmit",
	version = "1.0",
	url = "http://immersion-networks.com/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_hide", Command_Hide);
	
	for (new client = 1; client <= MaxClients; client++){
		if (IsClientInGame(client))
			SDKHook(client, SDKHook_SetTransmit, SetTransmit);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_SetTransmit, SetTransmit);
}

public Action:Command_Hide(client, args)
{
	if (g_bHidden[client]){
		g_bHidden[client] = false;
		PrintToChat(client, "[SM] Players are now visible.");
	}else{
		g_bHidden[client] = true;
		PrintToChat(client, "[SM] Players are now hidden.");
	}
	
	return Plugin_Handled;
}

public Action:SetTransmit(entity, client)
{
	if (client != entity && (0 < entity <= MaxClients) && g_bHidden[client])
		return Plugin_Handled;
		
	return Plugin_Continue;
}