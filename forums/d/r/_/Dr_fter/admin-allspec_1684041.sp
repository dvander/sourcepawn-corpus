#include <sourcemod>
#include <dhooks>

new Handle:hIsValidTarget;
new Handle:mp_forcecamera;

public Plugin:myinfo = 
{
	name = "Admin all spec",
	author = "Dr!fter",
	description = "Allows admin to spec all players",
	version = "1.0.0",
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	mp_forcecamera = FindConVar("mp_forcecamera");
	if(!mp_forcecamera)
	{
		SetFailState("Failed to locate mp_forcecamera");
	}
	new Handle:temp = LoadGameConfigFile("allow-spec.games");
	if(!temp)
	{
		SetFailState("Why you no has gamedata?");
	}
	new offset = GameConfGetOffset(temp, "IsValidObserverTarget");
	hIsValidTarget = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, IsValidTarget);
	DHookAddParam(hIsValidTarget, HookParamType_CBaseEntity);
	CloseHandle(temp);
}
public OnClientPostAdminCheck(client)
{
	if(IsFakeClient(client))
		return;
	if(CheckCommandAccess(client, "admin_allspec_flag", ADMFLAG_CHEATS))
	{
		SendConVarValue(client, mp_forcecamera, "0");
		DHookEntity(hIsValidTarget, true, client);
	}
}
public MRESReturn:IsValidTarget(this, Handle:hReturn, Handle:hParams)
{
	PrintToChat(this, "Hook fired");
	new target = DHookGetParam(hParams, 1);
	if(target <= 0 || target > MaxClients || !IsClientInGame(this) || !IsClientInGame(target) || !IsPlayerAlive(target) || IsPlayerAlive(this) || GetClientTeam(this) <= 1 || GetClientTeam(target) <= 1)
	{
		return MRES_Ignored;
	}
	else
	{
		if(!DHookGetReturn(hReturn))
		{
			PrintToChat(this, "Change return!");
		}
		DHookSetReturn(hReturn, true);
		return MRES_Override;
	}
}