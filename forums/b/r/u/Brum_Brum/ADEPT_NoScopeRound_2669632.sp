#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <noscope>

#pragma semicolon 1
#pragma newdecls required

int g_iNoScopeRoundType, g_iNoScopeRound, g_iNoScopeRoundNotification;

float g_fNoScopeRoundChance, g_fHUDPostionX, g_fHUDPostionY;

bool g_bAllowAdminForceNoScope, g_iNoScopeRoundNotificationColors, g_bNoScopeHUDRandomPostion, g_bEnableLogs, KnifeDamage, OnlySnipersDMG, 
OnlySnipersPickup;

char MOD_TAG[64], AdminFlags[32], ColorHUD[16], ColorHint[16], LogFileDirectory[256];

KeyValues kv;

Handle g_hBeforeNoScopeRoundStart, g_hAfterNoScopeRoundStart, g_hBeforeNoScopeRoundEnd, g_hAfterNoScopeRoundEnd;
Handle g_hBeforeAdminForceNS, g_hAfterAdminForceNSStart, g_hAfterAdminForceNSSEnd;
Handle g_hBeforeAddWeapon, g_hAfterAddWeapon;

int m_flNextSecondaryAttack;
int g_iRounds;

bool noscope;

public Plugin myinfo = 
{
	name = "ADEPT --> NoScope Round", 
	author = "Brum Brum", 
	description = "Autorski plugin StudioADEPT.net", 
	version = "1.0"
};
/***********************************************************
***********************OnPluginStart/OnMapStart*************
************************************************************/
public void OnPluginStart()
{
	m_flNextSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
	
	/** Forward **/
	g_hBeforeNoScopeRoundStart = CreateGlobalForward("NS_BeforeNoScopeRoundStart", ET_Ignore);
	g_hAfterNoScopeRoundStart = CreateGlobalForward("NS_AfterNoScopeRoundStart", ET_Ignore);
	g_hBeforeNoScopeRoundEnd = CreateGlobalForward("NS_BeforeNoScopeRoundEnd", ET_Ignore);
	g_hAfterNoScopeRoundEnd = CreateGlobalForward("NS_AfterNoScopeRoundEnd", ET_Ignore);
	g_hBeforeAdminForceNS = CreateGlobalForward("NS_BeforeAdminForceNS", ET_Ignore, Param_Cell);
	g_hAfterAdminForceNSStart = CreateGlobalForward("NS_AfterAdminForceNSStart", ET_Ignore, Param_Cell);
	g_hAfterAdminForceNSSEnd = CreateGlobalForward("NS_AfterAdminForceNSSEnd", ET_Ignore, Param_Cell);
	g_hBeforeAddWeapon = CreateGlobalForward("NS_BeforeAddWeapon", ET_Ignore, Param_Cell);
	g_hAfterAddWeapon = CreateGlobalForward("NS_AfterAddWeapon", ET_Ignore, Param_Cell);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	RegConsoleCmd("sm_fns", CMD_ForceNoScope);
	RegAdminCmd("sm_nscreload", CMD_Reload, ADMFLAG_ROOT);
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i))OnClientPutInServer(i);
	}
	LoadTranslations("ADEPT_NoScope.phrases.txt");
}

public void OnMapStart()
{
	LoadConfig();
	
	char time[32];
	int TimeStamp = GetTime();
	FormatTime(time, sizeof(time), "%F", TimeStamp);
	BuildPath(Path_SM, LogFileDirectory, sizeof(LogFileDirectory), "logs/ADEPT_NoScopeRound-%s.txt", time);
	g_iRounds = 0;
}
/***********************************************************
**************OnClientPutInServer/OnClientDisconnect********
************************************************************/
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}
/***********************************************************
*********************SDKHOOKS/OnPlayerRunCmd****************
************************************************************/
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidClient(victim) || !IsValidClient(attacker))return Plugin_Continue;
	
	if (noscope)
	{
		if (OnlySnipersDMG)
		{
			if (!HaveSnipers(attacker)) {
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		
		if (!KnifeDamage)
		{
			if (GetClientTeam(attacker) != GetClientTeam(victim) && HaveKnife(attacker))
			{
				damage = 0.0;
				PrintToChat(attacker, "\x01\x0B★ \x07[%s -> NoScope]\x04 %t", MOD_TAG, "Knife Damage Is Disable", COLOR_DARKRED);
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action WeaponCanUse(int client, int weapon)
{
	if (OnlySnipersPickup)
	{
		char sWeapon[32];
		GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
		if (StrContains(sWeapon, "knife", false) != -1 || StrContains(sWeapon, "bayonet", false) != -1)return Plugin_Continue;
		
		if (StrContains(sWeapon, "awp", false) != -1 || StrContains(sWeapon, "ssg08", false) != -1 || StrContains(sWeapon, "scar20", false) != -1 || StrContains(sWeapon, "g3sg1", false) != -1) {
			return Plugin_Continue;
		}
		else return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (noscope) {
		
		int awp = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		if (awp != -1)
		{
			SetEntDataFloat(awp, m_flNextSecondaryAttack, GetGameTime() + 99999.9);
		}
		
	}
}
/***********************************************************
****************************Eventy**************************
************************************************************/
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (IsWarmup())return;
	if (!g_iNoScopeRoundType)return;
	
	g_iRounds++;
	switch (g_iNoScopeRoundType)
	{
		case 1:
		{
			if (g_iRounds == g_iNoScopeRound) {
				g_iRounds = 0;
				forward_BeforeNoScopeRoundStart();
				StartNoScope();
				forward_AfterNoScopeRoundStart();
			}
		}
		case 2:
		{
			if (GetRandomFloat(0.0, 100.0) <= g_fNoScopeRoundChance) {
				forward_BeforeNoScopeRoundStart();
				StartNoScope();
				forward_AfterNoScopeRoundStart();
			}
		}
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (noscope) {
		forward_BeforeNoScopeRoundEnd();
		EndNoScope();
		forward_AfterNoScopeRoundEnd();
	}
}
/***********************************************************
****************************Komendy*************************
************************************************************/
public Action CMD_ForceNoScope(int client, int args)
{
	if (HaveFlag(client, AdminFlags))
	{
		if (!g_bAllowAdminForceNoScope) {
			PrintToChat(client, "\x01\x0B★ \x07[%s -> NoScope]\x04 %t", MOD_TAG, "Admin Cant Force NoScope Round");
			if (g_bEnableLogs) {
				char steamid[64];
				GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
				LogToFile(LogFileDirectory, "Admin: %N (%s) próbował włączyć rundę noscope!", client, steamid);
			}
			return Plugin_Handled;
		}
		forward_BeforeAdminForceNS(client);
		noscope = noscope ? false:true;
		if (noscope) {
			forward_BeforeNoScopeRoundStart();
			StartNoScope();
			forward_AfterNoScopeRoundStart();
			forward_AfterAdminForceNSStart(client);
			PrintToChatAll("\x01\x0B★ \x07[%s -> NoScope]\x04 %t", MOD_TAG, "Admin Enable NoScope Round", COLOR_DARKRED, client, COLOR_DARKGREEN);
		}
		else {
			forward_BeforeNoScopeRoundEnd();
			EndNoScope();
			forward_AfterNoScopeRoundEnd();
			forward_AfterAdminForceNSSEnd(client);
			PrintToChatAll("\x01\x0B★ \x07[%s -> NoScope]\x04 %t", MOD_TAG, "Admin Disable NoScope Round", COLOR_DARKRED, client, COLOR_DARKGREEN);
		}
		if (g_bEnableLogs) {
			char steamid[64];
			GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
			LogToFile(LogFileDirectory, "Admin: %N (%s) %s rundę noscope!", client, steamid, noscope == true ? "WŁĄCZYŁ" : "WYŁĄCZYŁ");
		}
	}
	else PrintToChat(client, "\x01\x0B★ \x07[%s -> NoScope]\x04 %t", MOD_TAG, "You do not have acced to this command");
	
	return Plugin_Handled;
}
public Action CMD_Reload(int client, int args)
{
	LoadConfig();
	PrintToChat(client, "\x01\x0B★ \x07[%s -> NoScope]\x04 %t", MOD_TAG, "Reload config");
}
/***********************************************************
****************************Timer***************************
************************************************************/
public Action ShowText(Handle timer)
{
	if (!noscope)return Plugin_Stop;
	if (!g_iNoScopeRoundNotification)return Plugin_Stop;
	
	
	switch (g_iNoScopeRoundNotification)
	{
		case 1:
		{
			if (g_iNoScopeRoundNotificationColors)
			{
				int r = GetRandomInt(1, 255), g = GetRandomInt(1, 255), b = GetRandomInt(1, 255);
				if (!g_bNoScopeHUDRandomPostion)SetHudTextParams(g_fHUDPostionX, g_fHUDPostionY, 0.9, r, g, b, 255);
				else {
					float x = GetRandomFloat(0.0, 1.0), y = GetRandomFloat(0.0, 1.0);
					SetHudTextParams(x, y, 0.9, r, g, b, 255);
				}
				for (int i = 1; i <= MaxClients; i++) {
					if (IsValidClient(i))ShowHudText(i, -1, "%t", "Only NoScope");
				}
			}
			else
			{
				char exstring[3][16];
				ExplodeString(ColorHUD, ";", exstring, sizeof(exstring), sizeof(exstring[]));
				int r = StringToInt(exstring[0]), g = StringToInt(exstring[1]), b = StringToInt(exstring[2]);
				if (!g_bNoScopeHUDRandomPostion)SetHudTextParams(g_fHUDPostionX, g_fHUDPostionY, 0.9, r, g, b, 255);
				else {
					float x = GetRandomFloat(0.0, 1.0), y = GetRandomFloat(0.0, 1.0);
					SetHudTextParams(x, y, 0.9, r, g, b, 255);
				}
				for (int i = 1; i <= MaxClients; i++) {
					if (IsValidClient(i))ShowHudText(i, -1, "%t", "Only NoScope");
				}
			}
		}
		case 2:
		{
			if (g_iNoScopeRoundNotificationColors) {
				int color = GetRandomInt(0, 16777215);
				PrintHintTextToAll("<font color='#%x'>%t</font>", color, "Only NoScope");
			}
			else PrintHintTextToAll("<font color='%s'>%t</font>", ColorHint, "Only NoScope");
		}
		case 3:
		{
			for (int i = 0; i < 5; i++)PrintToChatAll("\x01\x0B★ \x07[%s -> NoScope]\x02 %t", MOD_TAG, "Only NoScope");
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
/***********************************************************
*****************************VOID***************************
************************************************************/
void StartNoScope()
{
	noscope = true;
	GiveWeapon();
	CreateTimer(1.0, ShowText, _, TIMER_REPEAT);
}

void EndNoScope()
{
	noscope = false;
	
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			int awp = GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY);
			if (awp != -1)
			{
				SetEntDataFloat(awp, m_flNextSecondaryAttack, GetGameTime() + 0.0);
			}
		}
	}
}

void GiveWeapon()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			forward_BeforeAddWeapon(i);
			for (int j = 1; j < 6; j++) {
				int w = GetPlayerWeaponSlot(i, j);
				if (w != -1)AcceptEntityInput(w, "kill");
			}
			char sWeapon[32];
			int w = GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY);
			if (w != -1)
			{
				GetEntityClassname(w, sWeapon, sizeof(sWeapon));
				AcceptEntityInput(w, "kill");
				if (StrContains(sWeapon, "awp", false) != -1 || StrContains(sWeapon, "ssg08", false) != -1 || StrContains(sWeapon, "scar20", false) != -1 || StrContains(sWeapon, "g3sg1", false) != -1) {
					GivePlayerItem(i, sWeapon);
				}
				else GivePlayerItem(i, "weapon_awp");
			}
			else GivePlayerItem(i, "weapon_awp");
			GivePlayerItem(i, "weapon_knife");
			forward_AfterAddWeapon(i);
		}
	}
}
/***********************************************************
****************************KeyValues***********************
************************************************************/
void LoadConfig()
{
	delete kv;
	kv = CreateKeyValues("NoScope");
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/ADEPT_NoScope.txt");
	
	if (!FileExists(sPath))
		SetFailState("Nie znaleziono pliku: %s", sPath);
	
	
	kv.ImportFromFile(sPath);
	
	char info[64];
	kv.GetString("MOD_TAG", info, sizeof(info));
	strcopy(MOD_TAG, sizeof(MOD_TAG), info);
	
	g_iNoScopeRoundType = kv.GetNum("NoScope_Round_Type", 1);
	g_iNoScopeRound = kv.GetNum("NoScope_Round", 5);
	g_fNoScopeRoundChance = kv.GetFloat("NoScope_Round_Chance", 10.0);
	g_iNoScopeRoundNotification = kv.GetNum("NoScope_Round_Notification_enable", 1);
	g_iNoScopeRoundNotificationColors = view_as<bool>(kv.GetNum("NoScope_Round_Notification_color", 1));
	
	kv.GetString("NoScope_Round_Notification_color_hud", info, sizeof(info));
	strcopy(ColorHUD, sizeof(ColorHUD), info);
	g_fHUDPostionX = kv.GetFloat("NoScope_Round_Notification_postion_hud_x", 0.15);
	g_fHUDPostionY = kv.GetFloat("NoScope_Round_Notification_postion_hud_y", 0.7);
	g_bNoScopeHUDRandomPostion = view_as<bool>(kv.GetNum("NoScope_Round_Notification_random_postion", 0));
	kv.GetString("NoScope_Round_Notification_color_hint", info, sizeof(info));
	strcopy(ColorHint, sizeof(ColorHint), info);
	
	g_bAllowAdminForceNoScope = view_as<bool>(kv.GetNum("NoScope_Round_Allow_Admin_Force_NoScope", 1));
	kv.GetString("NoScope_Round_Allow_Admin_Flag", info, sizeof(info));
	strcopy(AdminFlags, sizeof(AdminFlags), info);
	
	g_bEnableLogs = view_as<bool>(kv.GetNum("NoScope_Round_Logs", 1));
	KnifeDamage = view_as<bool>(kv.GetNum("NoScope_Round_Knife_damage", 0));
	OnlySnipersDMG = view_as<bool>(kv.GetNum("NoScope_Round_OnlySnipers_damage", 1));
	OnlySnipersPickup = view_as<bool>(kv.GetNum("NoScope_Round_Can_Pickup_Only_Sniper", 1));
}
/***********************************************************
*************************Nativy/Forwardy********************
************************************************************/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("NS_IsNoScopeRound", Native_IsNoScopeRound);
	RegPluginLibrary("NoScope");
	return APLRes_Success;
}

public int Native_IsNoScopeRound(Handle plugin, int numParams)
{
	return noscope;
}

void forward_BeforeNoScopeRoundStart()
{
	Call_StartForward(g_hBeforeNoScopeRoundStart);
	Call_Finish();
}

void forward_AfterNoScopeRoundStart()
{
	Call_StartForward(g_hAfterNoScopeRoundStart);
	Call_Finish();
}

void forward_BeforeNoScopeRoundEnd()
{
	Call_StartForward(g_hBeforeNoScopeRoundEnd);
	Call_Finish();
}

void forward_AfterNoScopeRoundEnd()
{
	Call_StartForward(g_hAfterNoScopeRoundEnd);
	Call_Finish();
}

void forward_BeforeAdminForceNS(int client)
{
	Call_StartForward(g_hBeforeAdminForceNS);
	Call_PushCell(client);
	Call_Finish();
}

void forward_AfterAdminForceNSStart(int client)
{
	Call_StartForward(g_hAfterAdminForceNSStart);
	Call_PushCell(client);
	Call_Finish();
}
void forward_AfterAdminForceNSSEnd(int client)
{
	Call_StartForward(g_hAfterAdminForceNSSEnd);
	Call_PushCell(client);
	Call_Finish();
}

void forward_BeforeAddWeapon(int client)
{
	Call_StartForward(g_hBeforeAddWeapon);
	Call_PushCell(client);
	Call_Finish();
}

void forward_AfterAddWeapon(int client)
{
	Call_StartForward(g_hAfterAddWeapon);
	Call_PushCell(client);
	Call_Finish();
} 