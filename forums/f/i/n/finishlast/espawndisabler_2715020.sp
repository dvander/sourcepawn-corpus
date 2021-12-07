#pragma semicolon 1
#pragma newdecls required 

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "espawndisabler",
	author = "",
	description = "Prevents espawn. ",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?t=182103"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();   
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
   	return APLRes_Success;
}

public void OnPluginStart()
{

}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse)
{
	char output[128];

	if (IsValidClient(client) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		if(buttons & (IN_USE)) 
		{ 
			if (GetEntProp(client, Prop_Send, "m_isGhost") > 0)
			{ 
				if(buttons & (IN_ATTACK)) 
				{ 
					//PrintToChatAll("m_isGhost: %d", GetEntProp(client, Prop_Send, "m_isGhost"));
					ForcePlayerSuicide(client);
					Format(output, sizeof(output), "[SM] %N tried to espawn and was killed for it.", client);
					PrintToChatAll(output);
				}
			}	
		}  

	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients);
}