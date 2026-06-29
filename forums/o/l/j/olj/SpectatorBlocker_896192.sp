#pragma semicolon 1;
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.3"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_CHEAT
new Handle:SpecCVAR;

public Plugin:myinfo = 
{
	name = "Blocker",
	author = "Olj",
	description = "Blocks spec allow roaming",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart()
{
	SpecCVAR = CreateConVar("spec_allowroaming", "0.0", "Allows free look, when spectating", CVAR_FLAGS, true, 0.0, true, 1.0);
	//HookConVarChange(SpecCVAR, SpecBlock);
	HookEvent("player_team", ChangingTeams, EventHookMode_Post);
}

public OnClientPostAdminCheck(client)
{
	if ((!IsValidClient(client))||(!IsValidPlayer(client))) return;
	if ((GetClientTeam(client)==2)||(GetClientTeam(client)==1))
		{
			UnCheatAndChangeConVar(client, 0);
		}
	else 
		{
			UnCheatAndChangeConVar(client, 1);
		}
}

public Action:ChangingTeams(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(Handle:event, "userid"));
	if ((!IsValidClient(client))||(!IsValidPlayer(client))) return;
	new t = GetEventInt(Handle:event, "team");
	new o = GetEventInt(Handle:event, "oldteam");
	new bool:b = GetEventBool(Handle:event, "isbot");
	new bool:d = GetEventBool(Handle:event, "disconnect");
	if (b==true) return;
	if (t!=3)
		{
			UnCheatAndChangeConVar(client, 0);
		}
	else
		{
			UnCheatAndChangeConVar(client, 1);
		}
}
public IsValidClient (client)
{
	if ((client >= 1) && (client <=MaxClients))
		return true;
	else
	return false;
}

public IsValidPlayer (client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	return true;
}

UnCheatAndChangeConVar(client, value)
	{
		//new value;
		new String:var[256];
		GetConVarName(SpecCVAR, var, 256);
		new flags = GetCommandFlags(var);
		SetCommandFlags(var, flags & ~FCVAR_CHEAT);
		ClientCommand(client, "spec_allowroaming %i", value);
		SetCommandFlags(var, flags);
	}