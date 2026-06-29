#pragma semicolon 1
#pragma newdecls required

static const char PLUGIN_VERSION[]	= "1.0.0";
static const char PLUGIN_NAME[]		= "[NMRiH] Health & Armor Vampirism";

static const int	iColor[][]		= {{0, 255, 0}, {255, 127, 0}, {255, 255, 255}, {255, 0, 0}};
static const char	cState[][]		= {"♡", "☣", "☺", "☠"};	// healthy, infected, extracted, dead
static const float	fPosX			= 0.01,						// position	(from left to right)
					fPosY			= 1.0,						// 			(from top to bottom)
					UPDATE_INTERVAL	= 1.0;						// HUD info update period in seconds

bool bEnable,
	bHint;
int iMaxHP,
	iMaxAP,
	iStartAP,
	iKill,
	iHS,
	iFire;

Handle HudHintTimers[MAXPLAYERS+1];
bool bLate,
	bHasUpgrades[2][MAXPLAYERS+1],
	bExtracted[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Grey83 (improving the idea of the Undeadsewer)",
	description	= "Leech health and armor from killed zombies",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=300674"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("nmrih_hav_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar CVar;
	(CVar = CreateConVar("sm_hav_enable",	"1",	"Enables/disables leech health from killed zombies", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, _, true, 1.0)).AddChangeHook(CVarChanged_Enable);
	bEnable = CVar.BoolValue;
	(CVar = CreateConVar("sm_hav_hint",		"1",	"The display current player's health in the: 1 = hint, 0 = HUD", FCVAR_NOTIFY, true, _, true, 1.0)).AddChangeHook(CVarChanged_Hint);
	bHint = CVar.BoolValue;
	(CVar = CreateConVar("sm_hav_max_hp",	"100",	"The maximum amount of health, which can get a player for killing zombies", FCVAR_NOTIFY, true, 100.0)).AddChangeHook(CVarChanged_MaxHP);
	iMaxHP = CVar.IntValue;
	(CVar = CreateConVar("sm_hav_max_ap",	"100",	"The maximum amount of armor, which can get a player for killing zombies", FCVAR_NOTIFY, true, 0.0)).AddChangeHook(CVarChanged_MaxAP);
	iMaxAP = CVar.IntValue;
	(CVar = CreateConVar("sm_hav_start_ap",	"100",	"Amount of armor, which can get a player after spawn", FCVAR_NOTIFY, true, 0.0)).AddChangeHook(CVarChanged_StartAP);
	iStartAP = CVar.IntValue;
	(CVar = CreateConVar("sm_hav_kill",		"5",	"Health gained from kill", _, true)).AddChangeHook(CVarChanged_Kill);
	iKill = CVar.IntValue;
	(CVar = CreateConVar("sm_hav_headshot",	"10",	"Health gained from headshot", _, true)).AddChangeHook(CVarChanged_HS);
	iHS = CVar.IntValue;
	(CVar = CreateConVar("sm_hav_fire",		"5",	"Health gained from burning zombie", _, true)).AddChangeHook(CVarChanged_Fire);
	iFire = CVar.IntValue;

	AutoExecConfig(true, "nmrih_hav");

	if(bHint) HookEvent("player_hurt", Event_Hurt);
	if(bEnable)
	{
		HookEvent("npc_killed", Event_Killed);
		HookEvent("zombie_head_split", Event_Headshot);
		HookEvent("zombie_killed_by_fire", Event_Fire);
	}
	HookEvent("player_spawn", Event_PS);
	HookEvent("player_extracted", Event_PE);

	PrintToServer("%s v.%s has been successfully loaded!", PLUGIN_NAME, PLUGIN_VERSION);

	if(bLate)
	{
		for(int i = 1; i <= MaxClients; i++) if(IsClientAuthorized(i)) OnClientPostAdminCheck(i);
		bLate = false;
	}
}

public void CVarChanged_Enable(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bEnable = CVar.BoolValue;

	if(bEnable)
	{
		HookEvent("npc_killed", Event_Killed);
		HookEvent("zombie_head_split", Event_Headshot);
		HookEvent("zombie_killed_by_fire", Event_Fire);
	}
	else
	{
		UnhookEvent("npc_killed", Event_Killed);
		UnhookEvent("zombie_head_split", Event_Headshot);
		UnhookEvent("zombie_killed_by_fire", Event_Fire);
	}
}

public void CVarChanged_Hint(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bHint = CVar.BoolValue;

	if(bHint) HookEvent("player_hurt", Event_Hurt);
	else UnhookEvent("player_hurt", Event_Hurt);
}

public void CVarChanged_MaxHP(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iMaxHP = CVar.IntValue;
}

public void CVarChanged_MaxAP(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iMaxAP = CVar.IntValue;
}

public void CVarChanged_StartAP(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iStartAP = CVar.IntValue;
}

public void CVarChanged_Kill(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iKill = CVar.IntValue;
}

public void CVarChanged_HS(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iHS = CVar.IntValue;
}

public void CVarChanged_Fire(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iFire = CVar.IntValue;
}

public void OnClientPostAdminCheck(int client)
{
	if(bEnable && 0 < client <= MaxClients) CreateHudHintTimer(client);
	bExtracted[client] = false;
}

public void OnClientDisconnect(int client)
{
	KillHudHintTimer(client);
}

stock void CreateHudHintTimer(int client)
{
	if(IsClientInGame(client)) HudHintTimers[client] = CreateTimer(UPDATE_INTERVAL, Timer_UpdateHudHint, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

stock void KillHudHintTimer(int client)
{
	if(HudHintTimers[client] != null)
	{
		KillTimer(HudHintTimers[client]);
		HudHintTimers[client] = null;
	}
}

public Action Timer_UpdateHudHint(Handle timer, any client)
{
	if(bHint)
	{
		UpdateHint(client, GetClientHealth(client), GetEntProp(client, Prop_Data, "m_ArmorValue"));
		return Plugin_Continue;
	}

	static int state;
	state = IsPlayerAlive(client) ? (IsPlayerInfected(client) ? 1 : 0) : (bExtracted[client] ? 2 : 3);

	SetHudTextParams(fPosX, fPosY, UPDATE_INTERVAL + 0.1, iColor[state][0], iColor[state][1], iColor[state][2], 127, 0, 0.0, 0.1, 0.1);
	if(state > 1) ShowHudText(client, -1, cState[state]);
	else ShowHudText(client, -1, "%s%i\n♦%d", cState[state], GetClientHealth(client), GetEntProp(client, Prop_Data, "m_ArmorValue"));

	return Plugin_Continue;
}

public void Event_Killed(Event event, const char[] name, bool dontBroadcast)
{
	Heal(event.GetInt("killeridx"), iKill);
}

public void Event_Headshot(Event event, const char[] name, bool dontBroadcast)
{
	Heal(event.GetInt("player_id"), iHS);
}

public void Event_Fire(Event event, const char[] name, bool dontBroadcast)
{
	Heal(event.GetInt("igniter_id"), iFire);
}

public void Event_Hurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!bHint) return;

	static int client;
	if(!(0 < (client = GetClientOfUserId(GetEventInt(event, "userid"))) <= MaxClients) || IsClientInGame(client) || !IsFakeClient(client)) return;

	UpdateHint(client, GetEventInt(event, "health"), iMaxAP ? GetEntProp(client, Prop_Data, "m_ArmorValue") : 0);
}

public void Event_PS(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	bExtracted[client] = bHasUpgrades[0][client] = bHasUpgrades[1][client] = false;
	CreateTimer(1.0, GiveUpgradesToPlayer, userid);
}

public Action GiveUpgradesToPlayer(Handle timer, any userid)
{
	if(bEnable)
	{
		int client = GetClientOfUserId(userid);
		if(!client || !IsClientInGame(client)) return;

		if(iMaxHP > 100 && !bHasUpgrades[0][client])
		{
			SetEntProp(client, Prop_Data, "m_iMaxHealth", iMaxHP);
			bHasUpgrades[0][client] = (GetEntProp(client, Prop_Data, "m_iMaxHealth") == iMaxHP);
		}
		if(iStartAP && !bHasUpgrades[1][client])
		{
			SetEntProp(client, Prop_Data, "m_ArmorValue", iStartAP);
			bHasUpgrades[1][client] = (GetEntProp(client, Prop_Data, "m_ArmorValue") == iStartAP);
		}
	}
}

public void Event_PE(Event event, const char[] name, bool dontBroadcast)
{
	bExtracted[event.GetInt("player_id")] = true;
}

stock void Heal(int client, int heal)
{
	if(!bEnable || !heal) return;

	if(!(0 < client <= MaxClients) || !IsClientInGame(client) || !IsPlayerAlive(client)) return;


	static int health, armor, healHP, healAP;
	health = GetClientHealth(client);
	armor = GetEntProp(client, Prop_Data, "m_ArmorValue");
	if(heal <= iMaxHP - health)
	{
		health += heal;
		SetEntityHealth(client, health);
	}
	else
	{
		healHP = healAP = 0;
		if(iMaxHP > health) healHP = iMaxHP - health;

		healAP = heal - healHP;
		if(iMaxAP - armor < healAP) healAP = iMaxAP - armor;
		if(healHP)
		{
			health += healHP;
			SetEntityHealth(client, health);
		}
		if(healAP && iMaxAP > armor)
		{
			armor += healAP;
			SetEntProp(client, Prop_Data, "m_ArmorValue", armor);
		}
	}
	if(bHint) UpdateHint(client, health, armor);
}

stock void UpdateHint(const int client, int health, int armor)
{
	if(iMaxAP) PrintHintText(client, "%s%dHP%s %dAP%s", IsPlayerInfected(client) ? "☣" : "", health, health < iMaxHP ? "" : " (max)", armor, armor < iMaxAP ? "" : " (max)");
	else PrintHintText(client, "%s%dHP%s", IsPlayerInfected(client) ? "☣" : "", health, health < iMaxHP ? "" : " (max)");
}

stock bool IsPlayerInfected(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flInfectionTime") > 0 && GetEntPropFloat(client, Prop_Send, "m_flInfectionDeathTime") > 0;
}