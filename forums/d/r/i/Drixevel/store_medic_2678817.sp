#include <sourcemod>
#include <cstrike>
#include <store>

ConVar g_cvACredits;
ConVar g_cvAHealth

public Plugin myinfo = 
{
	name = "Medic",
	author = "Pilo#8253, Drixevel",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	g_cvACredits = CreateConVar("sm_medic_credits", "50", "Amount of credits the medic cost", _, true, 0.0);
	g_cvAHealth = CreateConVar("sm_health_amount", "50", "Amount of health to give the player", _, true, 0.0);
	
	RegConsoleCmd("sm_medic", Command_Medic, "Heal yourself for credits on the store.");
}

public Action Command_Medic(int client, int args)
{
	if (!IsClientInGame(client))
		return Plugin_Handled;
	
	int credits = Store_GetClientCredits(client);
	int price = g_cvACredits.IntValue;
	
	if (credits < price)
	{
		PrintToChat(client, "You don't have enough credits to restore your health.");
		return Plugin_Handled;
	}
	
	int health = GetClientHealth(client);
	int give = g_cvAHealth.IntValue;
	
	if (health >= 100)
	{
		PrintToChat(client, "You're healthy.");
		return Plugin_Handled;
	}
	
	health += give;
	
	if (health > 100)
		health = 100;
	
	Store_SetClientCredits(client, credits - price);
	SetEntityHealth(client, health);
	PrintToChat(client, "You're healthy now!");
	
	return Plugin_Handled;
}