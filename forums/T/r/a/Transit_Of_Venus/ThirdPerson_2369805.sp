#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.1.0"

new bool:g_bThirdPersonEnabled[MAXPLAYERS+1] = false;

public Plugin:myinfo =
{
	name = "[TF2] Thirdperson",
	author = "DarthNinja",
	description = "Allows players to use thirdperson without having to enable client sv_cheats",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("thirdperson_version", PLUGIN_VERSION, "Plugin Version",  FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_thirdperson", EnableThirdperson, 0, "Usage: sm_thirdperson");
	RegAdminCmd("tp", EnableThirdperson, 0, "Usage: sm_thirdperson");
	RegAdminCmd("sm_firstperson", DisableThirdperson, 0, "Usage: sm_firstperson");
	RegAdminCmd("fp", DisableThirdperson, 0, "Usage: sm_firstperson");
	HookEvent("player_spawn", OnPlayerSpawned);
	HookEvent("player_class", OnPlayerSpawned);
}

public Action:OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	if (g_bThirdPersonEnabled[GetClientOfUserId(userid)])
		CreateTimer(0.2, SetViewOnSpawn, userid);
}

public Action:SetViewOnSpawn(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client != 0)	//Checked g_bThirdPersonEnabled in hook callback, dont need to do it here~
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
}

public Action:EnableThirdperson(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "[SM] Thirdperson view will be enabled when you spawn.");
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
	g_bThirdPersonEnabled[client] = true;
	return Plugin_Handled;
}

public Action:DisableThirdperson(client, args)
{
	if(!IsPlayerAlive(client))
		PrintToChat(client, "[SM] Thirdperson view disabled!");
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");
	g_bThirdPersonEnabled[client] = false;
	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	g_bThirdPersonEnabled[client] = false;
}