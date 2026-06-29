#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
	HookEvent("heal_success", Event_HealSuccess);
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