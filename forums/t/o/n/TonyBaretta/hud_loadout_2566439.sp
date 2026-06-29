#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION   "1.0"
int weaponslot1;
int weaponslot2;
int weaponslot4;
int weaponslot5;
Handle TimerSpam = INVALID_HANDLE;
ConVar plugin_enable;
public Plugin myinfo =
{
	name = "5vs5 HUD Loadout",
	author = "TonyBaretta",
	description = "Show team loadout on hud",
	version = PLUGIN_VERSION,
	url = "http://www.wantedgov.it"
};
public void OnPluginStart()
{
	CreateConVar("5vs5_loadout_version", PLUGIN_VERSION, "5vs5 HUD Loadout",FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	plugin_enable = CreateConVar("loadout_enable", "1", "Enables/Disables HUD Loadout.");
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
}
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
	if(plugin_enable.BoolValue)
	TimerSpam = CreateTimer(0.5, Timer, _, TIMER_REPEAT);
}
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
	ClearTimer(TimerSpam);
}
int PlayersChecks()
{
	int[] clients = new int[MaxClients+1];

	for (int i; i <=MaxClients; i++)
	{
		clients[i] = i;
	}
	char cName[256];
	char entName[50];
	char entName2[50];
	char entName4[50];
	char entName5[50];
	char LinesT[5][256];
	char LinesCT[5][256];
	char STeamCT[512];
	char STeamT[512];
	int countT = -0;
	int countCT = -0;
	for (int i=MaxClients; i>-0; i--)
	{
		if (IsValidClient(clients[i]) && !IsClientObserver(clients[i]) && GetClientTeam(i) == 2)
		{
			if (countT >= 5)
			{
				break;
			}
			GetClientName(clients[i], cName, sizeof(cName));
			int Health_status = GetEntProp(clients[i], Prop_Send, "m_iHealth");
			if ((weaponslot1 = GetPlayerWeaponSlot(clients[i], 0)) != -1){
				GetEdictClassname(weaponslot1, entName, sizeof(entName));
			}
			else Format(entName, sizeof(entName), "-");
			if ((weaponslot2 = GetPlayerWeaponSlot(clients[i], 1)) != -1){
				GetEdictClassname(weaponslot2, entName2, sizeof(entName2));
			}
			else Format(entName2, sizeof(entName2), "-");
			if ((weaponslot4 = GetPlayerWeaponSlot(clients[i], 3)) != -1){
				GetEdictClassname(weaponslot4, entName4, sizeof(entName4));
			}
			else Format(entName4, sizeof(entName4), "-");
			if ((weaponslot5 = GetPlayerWeaponSlot(clients[i], 4)) != -1){
				GetEdictClassname(weaponslot5, entName5, sizeof(entName5));
			}
			else Format(entName5, sizeof(entName5), "-");
			ReplaceString(entName, sizeof(entName), "weapon_", "", false);
			ReplaceString(entName2, sizeof(entName2), "weapon_", "", false);
			ReplaceString(entName4, sizeof(entName4), "weapon_hegrenade", "HE", false);
			ReplaceString(entName4, sizeof(entName4), "weapon_smokegrenade", "smoke", false);
			ReplaceString(entName4, sizeof(entName4), "weapon_flashbang", "flash", false);
			ReplaceString(entName4, sizeof(entName4), "weapon_decoy", "decoy", false);
			ReplaceString(entName4, sizeof(entName4), "weapon_molotov", "molotov", false);
			ReplaceString(entName5, sizeof(entName5), "weapon_", "", false);
			Format(LinesT[countT], 256, "%s - HP %d\n --> %s %s %s %s", cName, Health_status, entName, entName2, entName4, entName5);
			countT++;
		}
		if (IsValidClient(clients[i]) && !IsClientObserver(clients[i]) && GetClientTeam(i) == 3)
		{
			if (countCT >= 5)
			{
				break;
			}
			GetClientName(clients[i], cName, sizeof(cName));
			int Health_status = GetEntProp(clients[i], Prop_Send, "m_iHealth");
			if ((weaponslot1 = GetPlayerWeaponSlot(clients[i], 0)) != -1){
				GetEdictClassname(weaponslot1, entName, sizeof(entName));
			}
			else Format(entName, sizeof(entName), "-");
			if ((weaponslot2 = GetPlayerWeaponSlot(clients[i], 1)) != -1){
				GetEdictClassname(weaponslot2, entName2, sizeof(entName2));
			}
			else Format(entName2, sizeof(entName2), "-");
			if ((weaponslot4 = GetPlayerWeaponSlot(clients[i], 3)) != -1){
				GetEdictClassname(weaponslot4, entName4, sizeof(entName4));
			}
			else Format(entName4, sizeof(entName4), "-");
			if(GetEntProp(clients[i], Prop_Send, "m_bHasDefuser") == 1)
			Format(entName5, sizeof(entName5), "kit");
			else Format(entName5, sizeof(entName5), "-");

			ReplaceString(entName, sizeof(entName), "weapon_", "", false);
			ReplaceString(entName2, sizeof(entName2), "weapon_usp_silencer", "usp-s", false);
			ReplaceString(entName2, sizeof(entName2), "weapon_", "", false);
			ReplaceString(entName2, sizeof(entName2), "hkp2000", "p2000", false);
			ReplaceString(entName4, sizeof(entName4), "weapon_hegrenade", "HE", false);
			ReplaceString(entName4, sizeof(entName4), "weapon_smokegrenade", "smoke", false);
			ReplaceString(entName4, sizeof(entName4), "weapon_flashbang", "flash", false);
			ReplaceString(entName4, sizeof(entName4), "weapon_decoy", "decoy", false);
			ReplaceString(entName4, sizeof(entName4), "weapon_incgrenade", "incnade", false);
			Format(LinesCT[countCT], 256, "%s - HP %d\n --> %s %s %s %s", cName, Health_status, entName, entName2, entName4, entName5);
			countCT++;
		}
	}
	for (int i; i <=MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 2)
		{	
			ImplodeStrings(LinesT, 5, "\n", STeamT, 512);
			SetHudTextParams(0.01, 0.40, 0.5, 255, 255, 255, 255);
			ShowHudText(i, -1, STeamT);
		}
		if (IsValidClient(i) && GetClientTeam(i) == 3)
		{	
			ImplodeStrings(LinesCT, 5, "\n", STeamCT, 512);
			SetHudTextParams(0.01, 0.40, 0.5, 255, 255, 255, 255);
			ShowHudText(i, -1, STeamCT);
		}
	}
}
public Action Timer(Handle timer)
{
	PlayersChecks();
}
stock bool IsValidClient(int iClient) {
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	if (!IsClientConnected(iClient)) return false;
	return IsClientInGame(iClient);
}
stock int ClearTimer(Handle &timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}