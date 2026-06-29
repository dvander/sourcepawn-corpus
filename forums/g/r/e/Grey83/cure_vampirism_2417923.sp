#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_NAME		"[CURE] Vampirism"
#define PLUGIN_VERSION	"1.0.0"

ConVar hEnable = null;
bool bEnable;
ConVar hMsg = null;
bool bMsg;
ConVar hHint = null;
bool bHint;
ConVar hHealMax = null;
int iHealMax;
ConVar hFistHeal = null;
int iFistHeal;
ConVar hPrimaryHeal = null;
int iPrimaryHeal;
ConVar hSecondaryHeal = null;
int iSecondaryHeal;
ConVar hFragHeal = null;
int iFragHeal;
ConVar hFireHeal = null;
int iFireHeal;
ConVar hSentryHeal = null;
int iSentryHeal;
ConVar hSoldierMult = null;
int iSoldierMult;
ConVar hAdmMult = null;
int iAdmMult ;

bool bIsAdmin[MAXPLAYERS+1];
bool bLate;
static char ClassName[2][14] = {
"zombie",
"strong zombie",
};

public Plugin myinfo =
{
	name 		= PLUGIN_NAME,
	author 		= "Grey83",
	description 	= "Leech health from killed zombies in Codename CURE",
	version 		= PLUGIN_VERSION,
	url 			= "https://forums.alliedmods.net/showthread.php?t=282542"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success; 
}

public void OnPluginStart()
{
	CreateConVar("cure_vampirism_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hEnable			= CreateConVar("sm_vampirism_enable", "0", "Enables/Disables the plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	hMsg			= CreateConVar("sm_vampirism_message", "1", "Enables/Disables the plugin message when zombie was killed", FCVAR_NONE, true, 0.0, true, 1.0);
	hHint			= CreateConVar("sm_vampirism_hint", "1", "Enables/disables the display current player's health in the hint", FCVAR_NONE, true, 0.0, true, 1.0);
	hHealMax		= CreateConVar("sm_vampirism_max", "100", "The maximum amount of health, which can get a player for killing zombies", FCVAR_NOTIFY, true, 10.0);
	hFistHeal		= CreateConVar("sm_vampirism_fist", "6", "Health gained from kill with a fists", FCVAR_NONE, true, 0.0);
	hPrimaryHeal	= CreateConVar("sm_vampirism_primary", "2", "Health gained from kill with a primary weapon", FCVAR_NONE, true, 0.0);
	hSecondaryHeal	= CreateConVar("sm_vampirism_secondary", "4", "Health gained from kill with a secondary weapon", FCVAR_NONE, true, 0.0);
	hFragHeal		= CreateConVar("sm_vampirism_frag", "2", "Health gained from kill with a frag grenade", FCVAR_NONE, true, 0.0);
	hFireHeal		= CreateConVar("sm_vampirism_fire", "2", "Health gained from burning zombie", FCVAR_NONE, true, 0.0);
	hSentryHeal		= CreateConVar("sm_vampirism_sentry", "2", "Health gained from kill with a sentry gun", FCVAR_NONE, true, 0.0);
	hSoldierMult		= CreateConVar("sm_vampirism_soldier", "3", "Multiplier of the heal from killed the soldier zombie", FCVAR_NONE, true, 1.0);
	hAdmMult		= CreateConVar("sm_vampirism_admin", "1", "Multiplier of the heal for the admins", FCVAR_NONE, true, 1.0);

	bEnable			= GetConVarBool(hEnable);
	bMsg			= GetConVarBool(hMsg);
	bHint			= GetConVarBool(hHint);
	iHealMax		= GetConVarInt(hHealMax);
	iFistHeal		= GetConVarInt(hFistHeal);
	iPrimaryHeal	= GetConVarInt(hPrimaryHeal);
	iSecondaryHeal 	= GetConVarInt(hSecondaryHeal);
	iFragHeal 		= GetConVarInt(hFragHeal);
	iFireHeal		= GetConVarInt(hFireHeal);
	iSentryHeal		= GetConVarInt(hSentryHeal);
	iSoldierMult		= GetConVarInt(hSoldierMult);
	iAdmMult		= GetConVarInt(hAdmMult);

	HookConVarChange(hEnable, OnConVarChanged);
	HookConVarChange(hMsg, OnConVarChanged);
	HookConVarChange(hHint, OnConVarChanged);
	HookConVarChange(hHealMax, OnConVarChanged);
	HookConVarChange(hFistHeal, OnConVarChanged);
	HookConVarChange(hPrimaryHeal, OnConVarChanged);
	HookConVarChange(hSecondaryHeal, OnConVarChanged);
	HookConVarChange(hFragHeal, OnConVarChanged);
	HookConVarChange(hFireHeal, OnConVarChanged);
	HookConVarChange(hSentryHeal, OnConVarChanged);
	HookConVarChange(hSoldierMult, OnConVarChanged);
	HookConVarChange(hAdmMult, OnConVarChanged);

	HookEvent("zombie_killed", Event_ZK);

	AutoExecConfig(true, "cure_vampirism");

	if (bLate)
	{
		LookupClients();
		bLate = false;
	}

	CreateTimer(1.5, RefreshHealthText, _, TIMER_REPEAT);
}

public void OnConVarChanged(Handle hCVar, const char[] oldValue, const char[] newValue)
{
	if (hCVar == hEnable)				bEnable = (StringToInt(newValue)) ? true : false;
	else if (hCVar == hMsg)			bMsg = (StringToInt(newValue)) ? true : false;
	else if (hCVar == hHint)			bHint = (StringToInt(newValue)) ? true : false;
	else if (hCVar == hHealMax)		iHealMax = StringToInt(newValue);
	else if (hCVar == hFistHeal)		iFistHeal = StringToInt(newValue);
	else if (hCVar == hPrimaryHeal)	iPrimaryHeal = StringToInt(newValue);
	else if (hCVar == hSecondaryHeal)	iSecondaryHeal = StringToInt(newValue);
	else if (hCVar == hFragHeal)		iFragHeal = StringToInt(newValue);
	else if (hCVar == hFireHeal)		iFireHeal = StringToInt(newValue);
	else if (hCVar == hSentryHeal)		iSentryHeal = StringToInt(newValue);
	else if (hCVar == hSoldierMult)		iSoldierMult = StringToInt(newValue);
	else if (hCVar == hAdmMult)		iAdmMult = StringToInt(newValue);
}

void LookupClients()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) OnClientPostAdminCheck(i);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if  (1 <= client <= MaxClients && !IsFakeClient(client))
		bIsAdmin[client] = CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC);
}

public Action RefreshHealthText(Handle timer)
{
	if(bHint)
	{
		int curHealth;
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client) && !IsClientObserver(client))
			{
				curHealth = GetEntProp(client, Prop_Data, "m_iHealth");
				PrintHintText(client, (curHealth < iHealMax) ? "%dHP" : "%dHP (max)", curHealth);
			}
		}
	}
}

public void Event_ZK(Event event, const char[] name, bool dontBroadcast)
{
	if(bEnable)
	{
		int attaker = event.GetInt("entindex_attacker");
		if(0 < attaker <= MaxClients)
		{
			int inflictor = event.GetInt("entindex_inflictor");
	
			char weapon[64];
			event.GetString((attaker == inflictor) ? "ammoName" : "inflictorClassname", weapon, sizeof(weapon));
			int iHeal = GetHealAmt(weapon);
			int zombie = event.GetInt("zombieType");
			if(zombie) iHeal = iHeal * iSoldierMult;
	
			if (IsClientInGame(attaker) && IsPlayerAlive(attaker))
			{
				int health = GetEntProp(attaker, Prop_Data, "m_iHealth");
				if (bIsAdmin[attaker]) iHeal = iHeal * iAdmMult;

				if(bMsg)
				{
					ReplaceString(weapon, sizeof(weapon), "player", "own fists");
					ReplaceString(weapon, sizeof(weapon), "glock", "HK USP Match");
					ReplaceString(weapon, sizeof(weapon), "p228", "CZ 75");
					ReplaceString(weapon, sizeof(weapon), "fiveseven", "FN Five-seveN");
					ReplaceString(weapon, sizeof(weapon), "elite", "dual Beretta 92");
					ReplaceString(weapon, sizeof(weapon), "Buckshot", "Mossberg 590");
					ReplaceString(weapon, sizeof(weapon), "m4super", "Benelli M4 Super 90");
					ReplaceString(weapon, sizeof(weapon), "mp5", "HK MP5K");
					ReplaceString(weapon, sizeof(weapon), "galil", "Galil AR");
					ReplaceString(weapon, sizeof(weapon), "g3sg1", "HK PSG1");
					ReplaceString(weapon, sizeof(weapon), "grenade_projectile", "frag grenade");
					ReplaceString(weapon, sizeof(weapon), "entityflame", "incendiary grenade");
					ReplaceString(weapon, sizeof(weapon), "npc_sentry", "sentry gun");
				}
				if(health < (iHealMax - iHeal))
				{
					SetEntProp(attaker, Prop_Send, "m_iHealth", health + iHeal);
					if(bMsg) PrintToChat(attaker, "\x03You killed a \x04%s \x03with a \x04%s \x03(\x04+%dHP\x03)", ClassName[zombie], weapon, iHeal);
					if(bHint) PrintHintText(attaker, "%dHP", health + iHeal);
				}
				else
				{
					if(bMsg) PrintToChat(attaker, "\x03You killed a \x04%s \x03with a \x04%s \x03(\x04+%dHP\x03)", ClassName[zombie], weapon, (health <= iHealMax) ? iHealMax - health : 0);
					SetEntProp(attaker, Prop_Send, "m_iHealth", (health > iHealMax) ? health : iHealMax);
				}
			}
		}
	}
}

stock int GetHealAmt(char[] weapon)
{
	if (StrContains(weapon, "player") == 0)
		return iFistHeal;
	else if (StrContains(weapon, "glock") == 0 || StrContains(weapon, "p228") == 0 || StrContains(weapon, "fiveseven") == 0 || StrContains(weapon, "elite") == 0)
		return iSecondaryHeal;
	else if (StrContains(weapon, "Buckshot") == 0 || StrContains(weapon, "m4super") == 0 || StrContains(weapon, "mp5") == 0 || StrContains(weapon, "galil") == 0 || StrContains(weapon, "g3sg1") == 0)
		return iPrimaryHeal;
	else if (StrContains(weapon, "grenade_projectile") == 0)
		return iFragHeal;
	else if (StrContains(weapon, "entityflame") == 0)
		return iFireHeal;
	else if (StrContains(weapon, "npc_sentry") == 0)
		return iSentryHeal;
	else return 0;
}