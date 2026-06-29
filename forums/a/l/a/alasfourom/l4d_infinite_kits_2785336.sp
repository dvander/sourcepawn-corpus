#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("defibrillator_used", EVENT_PlayerDefib);
	HookEvent("heal_success", Event_HealSuccess);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId (event.GetInt("userid"));
	{
		if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2) return;
		int CmdFlags = GetCommandFlags("give");
		SetCommandFlags("give", CmdFlags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give first_aid_kit");
		SetCommandFlags("give", CmdFlags);
	}
}

// Thanks To Silvers, Way To Bypass Admin Flag
public void EVENT_PlayerDefib(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId (event.GetInt("subject"));
	{
		if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2) return;
		int CmdFlags = GetCommandFlags("give");
		SetCommandFlags("give", CmdFlags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give first_aid_kit");
		SetCommandFlags("give", CmdFlags);
	}
}

// Thanks To Eyal282, I understand the concept of checking slots
public Action Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId (event.GetInt("userid"));

	if (!client || !IsClientInGame(client)) return;

	int KitSlot = GetPlayerWeaponSlot(client, 3);
	bool GotFirstAidKit = true;

	if (!IsValidEdict(KitSlot)) GotFirstAidKit = false;
	
	if (GotFirstAidKit)
	{
		char Classname[50];
		GetEntityClassname(KitSlot, Classname, sizeof(Classname));

		if (!StrEqual(Classname, "weapon_first_aid_kit")) GotFirstAidKit = false;
	}
	if (!GotFirstAidKit && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		int CmdFlags = GetCommandFlags("give");
		SetCommandFlags("give", CmdFlags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give first_aid_kit");
		SetCommandFlags("give", CmdFlags);
	}
}