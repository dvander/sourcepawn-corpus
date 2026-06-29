#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_NAME		"[CURE] Vampirism"
#define PLUGIN_VERSION	"1.1.0"

ConVar	hEnable, hMsg, hHint;
bool	bEnable, bMsg, bHint;
ConVar	hHealMax, hArmorMax, hFistHeal, hPrimaryHeal, hSecondaryHeal, hFragHeal, hFireHeal, hSentryHeal, hSoldierMult, hAdmMult;
int		iHealMax, iArmorMax, iFistHeal, iPrimaryHeal, iSecondaryHeal, iFragHeal, iFireHeal, iSentryHeal, iSoldierMult, iAdmMult;

bool bIsAdmin[MAXPLAYERS+1];
bool bLate;

int Killed[MAXPLAYERS+1][2];
int KilledTotal[MAXPLAYERS+1][2];

static char ClassName[][] = {
"zombie",
"strong zombie"
};
static char Weapon[][] = {
	"player",
	"glock",
	"p228",
	"fiveseven",
	"elite",
	"Buckshot",
	"m4super",
	"mp5",
	"galil",
	"g3sg1",
	"grenade_projectile",
	"entityflame",
	"npc_sentry"
};

static char WeaponName[][] = {	
	"own fists",
	"HK USP Match",
	"CZ 75",
	"FN Five-seveN",
	"dual Beretta 92",
	"Mossberg 590",
	"Benelli M4 Super 90",
	"HK MP5K",
	"Galil AR",
	"HK PSG1",
	"frag grenade",
	"incendiary grenade",
	"sentry gun"
};

public Plugin myinfo =
{
	name 		= PLUGIN_NAME,
	author 		= "Grey83",
	description 	= "Leech health and armor from killed zombies in Codename CURE",
	version 		= PLUGIN_VERSION,
	url 			= "https://forums.alliedmods.net/showthread.php?p=2417923"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success; 
}

public void OnPluginStart()
{
//	LoadTranslations("cure_vampirism.phrases");

	CreateConVar("cure_vampirism_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hEnable			= CreateConVar("sm_vampirism_enable", "0", "Enables/Disables the plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	hMsg			= CreateConVar("sm_vampirism_message", "1", "Enables/Disables the plugin message when zombie was killed", FCVAR_NONE, true, 0.0, true, 1.0);
	hHint			= CreateConVar("sm_vampirism_hint", "1", "Enables/disables the display current player's health in the hint", FCVAR_NONE, true, 0.0, true, 1.0);
	hHealMax		= CreateConVar("sm_vampirism_max", "100", "The maximum amount of health, which can get a player for killing zombies", FCVAR_NOTIFY, true, 10.0);
	hArmorMax		= CreateConVar("sm_vampirism_armor", "100", "The maximum amount of armor, which can get a player for killing zombies", FCVAR_NOTIFY, true, 0.0);
	hFistHeal		= CreateConVar("sm_vampirism_fist", "6", "Health gained from kill with a fists", FCVAR_NONE, true, 0.0);
	hPrimaryHeal	= CreateConVar("sm_vampirism_primary", "2", "Health gained from kill with a primary weapon", FCVAR_NONE, true, 0.0);
	hSecondaryHeal	= CreateConVar("sm_vampirism_secondary", "4", "Health gained from kill with a secondary weapon", FCVAR_NONE, true, 0.0);
	hFragHeal		= CreateConVar("sm_vampirism_frag", "2", "Health gained from kill with a frag grenade", FCVAR_NONE, true, 0.0);
	hFireHeal		= CreateConVar("sm_vampirism_fire", "2", "Health gained from burning zombie", FCVAR_NONE, true, 0.0);
	hSentryHeal		= CreateConVar("sm_vampirism_sentry", "2", "Health gained from kill with a sentry gun", FCVAR_NONE, true, 0.0);
	hSoldierMult		= CreateConVar("sm_vampirism_soldier", "5", "Multiplier of the heal from killed the soldier zombie", FCVAR_NONE, true, 1.0);
	hAdmMult		= CreateConVar("sm_vampirism_admin", "1", "Multiplier of the heal for the admins", FCVAR_NONE, true, 1.0);

	bEnable			= GetConVarBool(hEnable);
	bMsg			= GetConVarBool(hMsg);
	bHint			= GetConVarBool(hHint);
	iHealMax		= GetConVarInt(hHealMax);
	iArmorMax		= GetConVarInt(hArmorMax);
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
	HookConVarChange(hArmorMax, OnConVarChanged);
	HookConVarChange(hFistHeal, OnConVarChanged);
	HookConVarChange(hPrimaryHeal, OnConVarChanged);
	HookConVarChange(hSecondaryHeal, OnConVarChanged);
	HookConVarChange(hFragHeal, OnConVarChanged);
	HookConVarChange(hFireHeal, OnConVarChanged);
	HookConVarChange(hSentryHeal, OnConVarChanged);
	HookConVarChange(hSoldierMult, OnConVarChanged);
	HookConVarChange(hAdmMult, OnConVarChanged);

	HookEvent("zombie_killed", Event_ZK);
	HookEvent("player_spawn", Event_PS);
	HookEvent("player_death", Event_PD);

	RegConsoleCmd("sm_frags", Cmd_Frags);

	AutoExecConfig(true, "cure_vampirism");

	if(bLate)
	{
		LookupClients();
		bLate = false;
	}

	CreateTimer(1.5, RefreshHintText, _, TIMER_REPEAT);
}

public void OnConVarChanged(Handle hCVar, const char[] oldValue, const char[] newValue)
{
	if(hCVar == hEnable)				bEnable = view_as<bool>(StringToInt(newValue));
	else if(hCVar == hMsg)			bMsg = view_as<bool>(StringToInt(newValue));
	else if(hCVar == hHint)			bHint = view_as<bool>(StringToInt(newValue));
	else if(hCVar == hHealMax)		iHealMax = StringToInt(newValue);
	else if(hCVar == hArmorMax)		iArmorMax = StringToInt(newValue);
	else if(hCVar == hFistHeal)		iFistHeal = StringToInt(newValue);
	else if(hCVar == hPrimaryHeal)	iPrimaryHeal = StringToInt(newValue);
	else if(hCVar == hSecondaryHeal)	iSecondaryHeal = StringToInt(newValue);
	else if(hCVar == hFragHeal)		iFragHeal = StringToInt(newValue);
	else if(hCVar == hFireHeal)		iFireHeal = StringToInt(newValue);
	else if(hCVar == hSentryHeal)		iSentryHeal = StringToInt(newValue);
	else if(hCVar == hSoldierMult)		iSoldierMult = StringToInt(newValue);
	else if(hCVar == hAdmMult)		iAdmMult = StringToInt(newValue);
}

void LookupClients()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i)) OnClientPostAdminCheck(i);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(0 < client <= MaxClients && !IsFakeClient(client))
	{
		bIsAdmin[client] = CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC);
		KilledTotal[client][0] = KilledTotal[client][1] = 0;
	}
}

public Action RefreshHintText(Handle timer)
{
	if(bHint)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client) && !IsClientObserver(client))
				PrintHintText(client, "✙%d/♦%d ☠%i(%i/%i)", GetEntProp(client, Prop_Data, "m_iHealth"), GetEntProp(client, Prop_Data, "m_ArmorValue"), Killed[client][0]+Killed[client][1], Killed[client][0], Killed[client][1]);
		}
	}
}

public void Event_ZK(Event event, const char[] name, bool dontBroadcast)
{
	if(bEnable)
	{
		static int attaker = 0;
		attaker = event.GetInt("entindex_attacker");
		if(0 < attaker <= MaxClients && IsClientInGame(attaker))
		{
			static char weapon[64];
			weapon[0] = '\0';
			event.GetString((attaker == event.GetInt("entindex_inflictor")) ? "ammoName" : "inflictorClassname", weapon, sizeof(weapon));
			static int weaponID = -1;
			weaponID = GetWeaponID(weapon);
			if(weaponID == -1) return;

			static int zombie = -1;
			zombie = event.GetInt("zombieType");
			if(zombie == -1) return;

			Killed[attaker][zombie]++;
			KilledTotal[attaker][zombie]++;

			if(IsPlayerAlive(attaker)) PlayerHeal(attaker, weaponID, zombie);
		}
	}
}

void PlayerHeal(int client, const int weaponID, const int zombie)
{
	static int heal = 0;
	heal = GetHealAmt(weaponID);
	if(heal < 1) return;
	if(zombie > 0) heal *= iSoldierMult;
	if(bIsAdmin[client]) heal *= iAdmMult;

	static int health;
	static int armor;
	health = GetEntProp(client, Prop_Data, "m_iHealth");
	armor = GetEntProp(client, Prop_Data, "m_ArmorValue");
	static int healH;
	static int healA;
	static char buffer[32];
	buffer[0] = '\0';
	if(heal <= iHealMax - health)
	{
		health += heal;
		SetEntProp(client, Prop_Send, "m_iHealth", health);
		Format(buffer, sizeof(buffer), " \x03(\x04+%dHP\x03)", heal);
	}
	else
	{
 		healH = healA = 0;
		if(iHealMax > health) healH = iHealMax - health;

		healA = heal - healH;
		if(iArmorMax - armor < healA) healA = iArmorMax - armor;
		if(healH > 0)
		{
			health += healH;
			SetEntProp(client, Prop_Send, "m_iHealth", health);
			Format(buffer, sizeof(buffer), "+%dHP", healH);
		}
		if(iArmorMax > armor)
		{
			armor += healA;
			SetEntProp(client, Prop_Data, "m_ArmorValue", armor);
			if(healA > 0) Format(buffer, sizeof(buffer), "%s%s+%dAP", buffer, healH > 0 ? "\x03|\x04" : "", healA);
		}
		if(healH > 0 || healA > 0) Format(buffer, sizeof(buffer), " \x03(\x04%s\x03)", buffer);
	}
	if(bMsg) PrintToChat(client, "\x03You killed a \x04%s \x03with a \x04%s%s", ClassName[zombie], WeaponName[weaponID], buffer);
	if(bHint) PrintHintText(client, "✙%d/♦%d ☠%i(%i/%i)", health, armor, Killed[client][0]+Killed[client][1], Killed[client][0], Killed[client][1]);
}

public void Event_PS(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(iHealMax > 100) SetEntProp(client, Prop_Data, "m_iMaxHealth", iHealMax);
	Killed[client][0] = Killed[client][1] = 0;
}

public void Event_PD(Event event, const char[] name, bool dontBroadcast)
{
	ShowFragCount(GetClientOfUserId(event.GetInt("userid")));
}

stock void ShowFragCount(int client, bool total = false)
{
	if(0 < client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		char buffer[64];
		int num, kills;
		for(int i; i < 2; i++)
		{
			kills = total ? KilledTotal[client][i] : Killed[client][i];
			if(kills > 0)
			{
				Format(buffer, sizeof(buffer), "%s%s \x04%i \x03%s%s", buffer, num > 0 ? " and" : "", kills, ClassName[i], kills > 1 ? "s" : "");
				num++;
			}
		}
		if(num > 0) PrintToChat(client, "\x03During %s You killed%s", total ? "round" : "life", buffer);
		else PrintToChat(client, "\x03During %s You did not kill any zombies", total ? "round" : "life");
	}
}

public Action Cmd_Frags(int client, int args)
{
	ShowFragCount(client);
	ShowFragCount(client, true);
}

stock int GetWeaponID(const char[] weapon)
{
	for(int i; i < 13; i++)
	{
		if(StrContains(weapon, Weapon[i]) == 0) return i;
	}
	return -1;
}

stock int GetHealAmt(const int weaponID)
{
	static int amt = 0;
	switch(weaponID)
	{
		case 0:			amt = iFistHeal;
		case 1, 2, 3, 4:	amt = iSecondaryHeal;
		case 5, 6, 7, 8, 9:	amt = iPrimaryHeal;
		case 10:			amt = iFragHeal;
		case 11:			amt = iFireHeal;
		case 12:			amt = iSentryHeal;
	}
	return amt;
}