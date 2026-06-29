#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name        = "sm_sb_add",
	author      = "ivailosp",
	description = "add extra bots",
	version     = "1.0",
	url         = "n/a"
};

public Action:SpawnFakeClient(client, args){
	
	if(client > 0 && GetUserAdmin(client) == INVALID_ADMIN_ID)
		return;
	new Bot = CreateFakeClient("SurvivorBot");
	if (Bot == 0)
		return;
	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
	CreateTimer(0.1, KickFakeClient, Bot);
}

public Action:KickFakeClient(Handle:hTimer, any:Client){
	if(IsClientConnected(Client) && IsFakeClient(Client)){
		KickClient(Client, "Kicking Fake Client.");
	}
	return Plugin_Handled;
}
public OnPluginStart()
{
	RegConsoleCmd("sm_sb_add",SpawnFakeClient, "Create one bot to take over");
}