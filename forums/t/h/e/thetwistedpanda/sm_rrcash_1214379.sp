#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:p_Enabled = INVALID_HANDLE;
new Handle:p_Amount = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Rally Racing Cash",
	author = "Twisted|Panda",
	description = "Gives players a set amount of cash every time they race.",
	version = PLUGIN_VERSION,
	url = "http://alliedmods.net/"
};

public OnPluginStart() 
{ 
	CreateConVar("sm_rrcash_version", PLUGIN_VERSION, "Rally Racing Cash Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	p_Enabled = CreateConVar("sm_rrcash", "1", "Enables or disables any feature of this plugin.");
	p_Amount = CreateConVar("sm_rrcash_amount", "180", "The amount of cash players will receive per each race.");
	AutoExecConfig(true, "sm_rrcash");

	HookEvent("player_team", OnPlayerTeam, EventHookMode_Post);
}

public OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(p_Enabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return;

		new newTeam = GetEventInt(event, "team");
		if(newTeam == 3)
		{
			new original = GetEntProp(client, Prop_Send, "m_iAccount");
			SetEntProp(client, Prop_Send, "m_iAccount", (GetConVarInt(p_Amount) + original));
		}
	}
}