#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

ConVar g_BarStyle;

enum // VisibilityMode
{
	VisibilityMode_Everyone,
	VisibilityMode_VictimTeam,
	VisibilityMode_OppositeTeam,
	VisibilityMode_AttackerOnly
}
ConVar g_VisibilityMode;

public Plugin myinfo = 
{
	name = "Damage Bar",
	author = "Natanel 'LuqS' & Romeo",
	description = "Displays a 'Health Bar' every time a player is taking damage.",
	version = "1.1.0",
	url = "https://steamcommunity.com/id/luqsgood || Discord: LuqS#6505"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		strcopy(error, err_max, "This plugin is for CS:GO only.");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_BarStyle = CreateConVar(
		"db_style",
		"0",
		"Style of the damage bar. (0 - Green / Red, 1 - Orange / Grey, 2 - Light Green / Green)",
		.hasMin = true,
		.min = 0.0,
		.hasMax = true,
		.max = 3.0
	);
	
	g_VisibilityMode = CreateConVar(
		"db_visibility_mode",
		"0",
		"Who should see the damage bar. (0 - Everyone, 1 - Victim Team, 2 - Opposite Team, 3 - Attacker Only)",
		.hasMin = true,
		.min = 0.0,
		.hasMax = true,
		.max = 3.0
	);
	
	AutoExecConfig();

	HookEvent("player_hurt", Event_PlayerHurt);
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	Protobuf pb;
	switch (g_VisibilityMode.IntValue)
	{
		case VisibilityMode_Everyone:
		{
			pb = view_as<Protobuf>(StartMessageAll("UpdateScreenHealthBar"));
		}
		
		case VisibilityMode_VictimTeam, VisibilityMode_OppositeTeam:
		{
			int visibility_team = GetClientTeam(client);
			
			if (g_VisibilityMode.IntValue == VisibilityMode_OppositeTeam)
			{
				// This is CS:GO - i can assume if the team is 2 it will be 3 and vice versa.
				// 2 ^ 1 = 3
				// 3 ^ 1 = 2
				visibility_team ^= 1;
			}
			
			int[] clients = new int[MaxClients];
			pb = view_as<Protobuf>(StartMessage("UpdateScreenHealthBar", clients, GetTeamClients(visibility_team, clients)));
		}
		
		case VisibilityMode_AttackerOnly:
		{
			int attacker = GetClientOfUserId(event.GetInt("attacker"));
			
			if (!attacker)
			{
				return;
			}
			
			pb = view_as<Protobuf>(StartMessageOne("UpdateScreenHealthBar", attacker));
		}
		
		default:
		{
			// seriously how??
			return;
		}
	}
	
	int health = event.GetInt("health"), damage = event.GetInt("dmg_health");
	int max_health = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	static int old_health[MAXPLAYERS+1];
	
	if(!old_health[client]) old_health[client] = max_health;
	
	pb.SetInt("entidx", client);
	pb.SetFloat("healthratio_old", float(health?(health + damage):old_health[client])/float(max_health));
	pb.SetFloat("healthratio_new", float(health)/float(max_health));
	pb.SetInt("style", g_BarStyle.IntValue);
	
	old_health[client] = health;
	
	EndMessage();
}

int GetTeamClients(int team, int[] clients)
{
	int total_client;
	
	for (int current_client = 1; current_client <= MaxClients; current_client++)
	{
	    if (IsClientInGame(current_client) && GetClientTeam(current_client) == team) 
	    {
	        clients[total_client++] = current_client;
	    }
	}
	
	return total_client;
}