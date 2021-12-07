#include <sourcemod>
#include <cstrike>
#include <store>

ConVar g_cvACredits;
ConVar g_cvAHealth

public Plugin myinfo = 
{
	name = "Medic",
	author = "Pilo#8253",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	g_cvACredits = CreateConVar("sm_medic_credits", "50", "Amount of credits the medic cost");
	g_cvAHealth = CreateConVar("sm_health_amount", "50", "Amount of health to give the player");
	
	RegConsoleCmd("sm_medic", Command_Medic);
}

public Action Command_Medic(int client, int args)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetClientHealth(client) == 100)
		{
			PrintToChat(client, "You're healthy.");
			return Plugin_Handled;
		}
		Store_SetClientCredits(client, Store_GetClientCredits(client) - GetConVarInt(g_cvACredits));
		SetEntityHealth(client, GetClientHealth(client) + GetConVarInt(g_cvAHealth));
		PrintToChat(client, "You're healthy now !");
	}
	return Plugin_Handled;
}
