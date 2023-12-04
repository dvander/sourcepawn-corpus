#pragma semicolon 1
#pragma newdecls required

#define MAX_PLAYERS 8	// maximum number of players on the NMRiH server

static const char
	PL_NAME[]	= "[NMRiH] Health & Armor Vampirism",
	PL_VER[]	= "1.0.4_20.11.2021",

// HUD settings
	STATE[][]	= {"♡", "☣", "☺", "☠"};	// healthy, infected, extracted, dead
static const int
	CLR[][]		= {{0, 255, 0}, {255, 127, 0}, {255, 255, 255}, {255, 0, 0}};	// R, G, B, A

Handle
	hHUD,
	hTimer;
bool
	bLate,
	bEnable,
	bHint,
	bStamina,
	bHasUpgrades[2][MAX_PLAYERS+1],
	bExtracted[MAX_PLAYERS+1];
int
	iMaxHP,
	iMaxAP,
	iStartAP,
	iKill,
	iHS,
	iFire;
float
	fPosX,
	fPosY,
	fCD,
	fMaxStamina;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Leech health and armor from killed zombies",
	author		= "Grey83 (improving the idea of the Undeadsewer)",
	url			= "https://forums.alliedmods.net/showthread.php?t=300674"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	hHUD = CreateHudSynchronizer();

	CreateConVar("nmrih_hav_version", PL_VER, PL_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar cvar;
	cvar = CreateConVar("sm_hav_enable",	"1",	"Enables/disables leech health from killed zombies", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Enable);
	CVarChanged_Enable(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_hav_hint",		"1",	"The display current player's health in the: 1 = hint, 0 = HUD", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Hint);
	CVarChanged_Hint(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_hav_stamina",	"0",	"Show current stamina level", FCVAR_NOTIFY, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Stamina);
	bStamina = cvar.BoolValue;

	cvar = CreateConVar("sm_hav_max_hp",	"100",	"The maximum amount of health, which can get a player for killing zombies", FCVAR_NOTIFY, true, 100.0);
	cvar.AddChangeHook(CVarChanged_MaxHP);
	iMaxHP = cvar.IntValue;

	cvar = CreateConVar("sm_hav_max_ap",	"100",	"The maximum amount of armor, which can get a player for killing zombies (0 - disable armor)", FCVAR_NOTIFY, true);
	cvar.AddChangeHook(CVarChanged_MaxAP);
	iMaxAP = cvar.IntValue;

	cvar = CreateConVar("sm_hav_start_ap",	"100",	"Amount of armor, which can get a player after spawn", FCVAR_NOTIFY, true, 0.0);
	cvar.AddChangeHook(CVarChanged_StartAP);
	iStartAP = cvar.IntValue;

	cvar = CreateConVar("sm_hav_kill",		"5",	"Health gained from kill", _, true);
	cvar.AddChangeHook(CVarChanged_Kill);
	iKill = cvar.IntValue;

	cvar = CreateConVar("sm_hav_headshot",	"10",	"Health bonus from headshot", _, true);
	cvar.AddChangeHook(CVarChanged_HS);
	iHS = cvar.IntValue;

	cvar = CreateConVar("sm_hav_fire",		"5",	"Health gained from burned zombie", _, true);
	cvar.AddChangeHook(CVarChanged_Fire);
	iFire = cvar.IntValue;

	cvar = CreateConVar("sm_hav_update", "1.0", "Update info every x seconds (0.0 - show only changes)", _, true, _, true, 5.0);
	cvar.AddChangeHook(CVarChanged_CD);
	CVarChanged_CD(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_hav_hud_x", "0.01", "HUD info position X (0.0 - 1.0 left to right or -1 for center)", _, true, -2.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_PosX);
	fPosX = cvar.FloatValue;

	cvar = CreateConVar("sm_hav_hud_y", "1.00", "HUD info position Y (0.0 - 1.0 top to bottom or -1 for center)", _, true, -2.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_PosY);
	fPosY = cvar.FloatValue;

	cvar = FindConVar("sv_max_stamina");
	cvar.AddChangeHook(CVarChanged_MaxStamina);
	fMaxStamina = cvar.FloatValue;

	AutoExecConfig(true, "nmrih_hav");

	HookEvent("player_death", Event_PD);
	HookEvent("player_spawn", Event_PS);
	HookEvent("player_extracted", Event_PE);
	HookEvent("state_change", Event_SC);

	if(bLate)
	{
		for(int i = 1; i <= MaxClients; i++) if(IsClientAuthorized(i)) OnClientPostAdminCheck(i);
		bLate = false;
	}
}

public void CVarChanged_Enable(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bEnable = CVar.BoolValue;
	static bool hooked;
	if(!bEnable == !hooked) return;

	hooked = !hooked;
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
	UpdateTimer();
}

public void CVarChanged_Hint(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bHint = cvar.BoolValue;
	static bool hooked;
	if(!bHint == !hooked) return;

	hooked = !hooked;
	if(bHint) HookEvent("player_hurt", Event_Hurt);
	else UnhookEvent("player_hurt", Event_Hurt);
}

public void CVarChanged_Stamina(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bStamina = cvar.BoolValue;
}

public void CVarChanged_MaxHP(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iMaxHP = cvar.IntValue;
}

public void CVarChanged_MaxAP(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iMaxAP = cvar.IntValue;
}

public void CVarChanged_StartAP(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iStartAP = cvar.IntValue;
}

public void CVarChanged_Kill(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iKill = cvar.IntValue;
}

public void CVarChanged_HS(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iHS = cvar.IntValue;
}

public void CVarChanged_Fire(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iFire = cvar.IntValue;
}

public void CVarChanged_PosX(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fPosX = cvar.FloatValue;
}

public void CVarChanged_PosY(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fPosY = cvar.FloatValue;
}

public void CVarChanged_CD(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fCD = cvar.FloatValue;
	UpdateTimer();
}

public void CVarChanged_MaxStamina(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fMaxStamina = cvar.FloatValue;
}

public void OnMapStart()
{
	if(bEnable) hTimer = CreateTimer(fCD, Timer_UpdateInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPostAdminCheck(int client)
{
	bExtracted[client] = bHasUpgrades[0][client] = bHasUpgrades[1][client] = false;
}

public Action Timer_UpdateInfo(Handle timer)
{
	if(bHint)
	{
		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) UpdateHint(i);
	}
	else for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) UpdateHUD(i);

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
	static int client;
	if((client = GetClientOfUserId(GetEventInt(event, "userid"))) && IsClientInGame(client))
		SendInfoToClient(client, GetEventInt(event, "health"));
}

public void Event_PD(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	bExtracted[client] = bHasUpgrades[0][client] = bHasUpgrades[1][client] = false;
}

public void Event_PS(Event event, const char[] name, bool dontBroadcast)
{
	if(bEnable) RequestFrame(RequestFrame_Callback, event.GetInt("userid"));
}

public void RequestFrame_Callback(int client)
{
	if(!(client = GetClientOfUserId(client)) || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;

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

public void Event_SC(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("state") == 3) for(int i = 1; i <= MaxClients; i++) if(IsClientAuthorized(i))
		OnClientPostAdminCheck(i);
}

public void Event_PE(Event event, const char[] name, bool dontBroadcast)
{
	bExtracted[event.GetInt("player_id")] = true;
}

stock void Heal(int client, int heal)
{
	if(!bEnable || !heal || client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	static int hp, ap, healHP, healAP;
	hp = GetClientHealth(client);
	ap = GetEntProp(client, Prop_Data, "m_ArmorValue");
	if(heal <= iMaxHP - hp)
	{
		hp += heal;
		SetEntityHealth(client, hp);
	}
	else
	{
		healHP = healAP = 0;
		if(iMaxHP > hp) healHP = iMaxHP - hp;

		healAP = heal - healHP;
		if(iMaxAP - ap < healAP) healAP = iMaxAP - ap;
		if(healHP)
		{
			hp += healHP;
			SetEntityHealth(client, hp);
		}
		if(healAP && iMaxAP > ap)
		{
			ap += healAP;
			SetEntProp(client, Prop_Data, "m_ArmorValue", ap);
		}
	}

	SendInfoToClient(client, hp, ap);
}

static void SendInfoToClient(const int client, const int hp = -1, const int ap = -1)
{
	if(bHint) UpdateHint(client, hp, ap);
	else UpdateHUD(client, hp, ap);
}

stock void UpdateHint(const int client, int hp = -1, int armor = -1)
{
	static char txt[32];
	if(hp == -1) hp = GetClientHealth(client);
	FormatEx(txt, sizeof(txt), "%s%iHP%s", IsPlayerInfected(client) ? "☣" : "", hp, hp < iMaxHP ? "" : " (max)");
	if(iMaxAP)
	{
		if(armor == -1) armor = GetEntProp(client, Prop_Data, "m_ArmorValue");
		Format(txt, sizeof(txt), "%s %iAP%s", txt, armor, armor < iMaxAP ? "" : " (max)");
	}
	if(bStamina) Format(txt, sizeof(txt), "%s %iSP", txt, GetStaminaLvl(client));
	PrintHintText(client, txt);
}

static void UpdateHUD(const int client, int hp = -1, int armor = -1)
{
	static int state;
	static char txt[32];
	state = IsPlayerAlive(client) ? (IsPlayerInfected(client) ? 1 : 0) : (bExtracted[client] ? 2 : 3);
	SetHudTextParams(fPosX, fPosY, fCD + 0.1, CLR[state][0], CLR[state][1], CLR[state][2], 127, 0, 0.0, 0.1, 0.1);

	if(state > 1)
		FormatEx(txt, sizeof(txt), STATE[state]);
	else
	{
		if(hp == -1) hp = GetClientHealth(client);
		FormatEx(txt, sizeof(txt), "%s%i", STATE[state], hp);
		if(iMaxAP)
		{
			if(armor == -1) armor = GetEntProp(client, Prop_Data, "m_ArmorValue");
			Format(txt, sizeof(txt), "%s\n♦%i", txt, armor);
		}
		if(bStamina)	Format(txt, sizeof(txt), "%s\n↔%i", txt, GetStaminaLvl(client));
	}

	ShowSyncHudText(client, hHUD, txt);
}

stock int GetStaminaLvl(int client)
{
	static float sp;
	sp = GetEntPropFloat(client, Prop_Send, "m_flStamina");
	if(sp < 1)
		return 0;

	if(FloatCompare(fMaxStamina, sp) < 1)
		return 100;

	return RoundToNearest(100 * sp / fMaxStamina);
}

stock bool IsPlayerInfected(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flInfectionTime") > 0 && GetEntPropFloat(client, Prop_Send, "m_flInfectionDeathTime") > 0;
}

stock void UpdateTimer()
{
	if(hTimer) delete hTimer;
	if(fCD > 0) hTimer = CreateTimer(fCD, Timer_UpdateInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}