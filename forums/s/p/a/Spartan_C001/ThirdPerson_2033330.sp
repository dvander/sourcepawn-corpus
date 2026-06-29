#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.1.1"

new bool:thirdPersonEnabled[MAXPLAYERS+1] = false

public Plugin:myinfo =
{
	name = "[TF2] Thirdperson",
	author = "DarthNinja",
	description = "Allows players to use Third Person View.",
	version = PLUGIN_VERSION,
	url = "http://www.darthninja.com/"
}

public OnPluginStart()
{
	CreateConVar("thirdperson_version",PLUGIN_VERSION,"Plugin Version",FCVAR_PLUGIN|FCVAR_NOTIFY)
	RegConsoleCmd("sm_thirdperson",EnableThirdperson,"Enable Third Person View")
	RegConsoleCmd("sm_tp",EnableThirdperson,"Enable Third Person View")
	RegConsoleCmd("sm_firstperson",DisableThirdperson,"Disable Third Person View")
	RegConsoleCmd("sm_fp",DisableThirdperson,"Disable Third Person View")
	HookEvent("player_spawn",OnPlayerSpawned)
	HookEvent("player_class",OnPlayerSpawned)
}

public Action:OnPlayerSpawned(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid = GetEventInt(event,"userid")
	if (thirdPersonEnabled[GetClientOfUserId(userid)])
	{
		CreateTimer(0.2,SetViewOnSpawn,userid)
	}
}

public Action:SetViewOnSpawn(Handle:timer,any:userid)
{
	new client = GetClientOfUserId(userid)
	if(client > 0)
	{
		SetVariantInt(1)
		AcceptEntityInput(client,"SetForcedTauntCam")
	}
}

public Action:EnableThirdperson(client,args)
{
	if(client == 0)
	{
		ReplyToCommand(client,"[SM] This command cannot be executed by server!")
		return Plugin_Handled
	}
	ReplyToCommand(client,"[SM] Thirdperson view enabled!")
	SetVariantInt(1)
	AcceptEntityInput(client,"SetForcedTauntCam")
	thirdPersonEnabled[client] = true
	return Plugin_Handled
}

public Action:DisableThirdperson(client,args)
{
	if(client == 0)
	{
		ReplyToCommand(client,"[SM] This command cannot be executed by server!")
		return Plugin_Handled
	}
	ReplyToCommand(client,"[SM] Thirdperson view disabled!")
	SetVariantInt(0)
	AcceptEntityInput(client,"SetForcedTauntCam")
	thirdPersonEnabled[client] = false
	return Plugin_Handled
}

public OnClientDisconnect(client)
{
	thirdPersonEnabled[client] = false
}