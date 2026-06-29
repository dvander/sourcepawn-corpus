/*	<DR. API SHOW DAMAGE> (c) by <De Battista Clint - (http://doyou.watch)	 */
/*																			 */
/*				   <DR. API SHOW DAMAGE> is licensed under a				 */
/* Creative Commons Attribution-NonCommercial-NoDerivs 4.0 Unported License. */
/*																			 */
/*		You should have received a copy of the license along with this		 */
/*	work.  If not, see <http://creativecommons.org/licenses/by-nc-nd/4.0/>.	 */

/*						"NoDerivatives"?! Are You mad?						 */

//***************************************************************************//
//***************************************************************************//
//****************************DR. API SHOW DAMAGE****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1
#pragma newdecls required

//***********************************//
//*************DEFINE****************//
//***********************************//
static const int CVARS				= FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD;
static const int DEFAULT_FLAGS		= FCVAR_NOTIFY;

static const char TAG_CHAT[]		= "[SHOW DAMAGE] - ";
static const char PLUGIN_NAME[]		= "DR.API SHOW DAMAGE";
static const char PLUGIN_VERSION[]	= "1.2.0_debug";

#define MAX_TYPE_WEAPONS			10
#define MAX_STEAMID					25

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <clientprefs>
#include <autoexec>

//***********************************//
//***********PARAMETERS**************//
//***********************************//
Handle hArrayVictim[MAXPLAYERS + 1],
	hCookie_ShowDamage,
	Timer_ShowDamage[MAXPLAYERS + 1];

bool bDmg,
	bDmgDev,
	bShowDamage[MAXPLAYERS + 1];

float fSniperTime,
	fMGTime,
	fRifleTime,
	fSMGTime,
	fPumpTime,
	fPistolTime,
	fInfernoLifetime;

char sFlag[MAX_TYPE_WEAPONS][64],
	sSteamID[MAX_TYPE_WEAPONS][MAX_STEAMID][64];

int iCountVictim[MAXPLAYERS + 1]	= 1,
	iTotalDmg[MAXPLAYERS + 1],
	iTotalDmgArmor[MAXPLAYERS + 1],
	iMaxSteamID[MAX_STEAMID];

//Informations plugin
public Plugin myinfo =
{
	name			= PLUGIN_NAME,
	author			= "Dr. Api (fixes and optimization by Grey83)",
	description		= "DR.API SHOW DAMAGE by Dr. Api",
	version			= PLUGIN_VERSION,
	url				= "https://forums.alliedmods.net/showthread.php?t=264427"
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_show_damage.phrases");
	AutoExecConfig_SetFile("drapi_show_damage", "sourcemod/drapi");

	AutoExecConfig_CreateConVar("aio_show_damage_version", PLUGIN_VERSION, PLUGIN_NAME, CVARS);

	ConVar CVar;
	(CVar = AutoExecConfig_CreateConVar("drapi_active_show_damage",			"1",	"Enable/Disable Show Damage",	DEFAULT_FLAGS, true, _, true, 1.0)).AddChangeHook(CVarChanged_Dmg);
	bDmg = CVar.BoolValue;

	(CVar = AutoExecConfig_CreateConVar("drapi_active_show_damage_dev",		"0",	"Enable/Disable Show Damage Dev", DEFAULT_FLAGS,	true, _, true, 1.0)).AddChangeHook(CVarChanged_DmgDev);
	bDmgDev = CVar.BoolValue;

	(CVar = AutoExecConfig_CreateConVar("drapi_show_damage_sniper_time",	"0.5",	"SNIPERS Time Between shots",	DEFAULT_FLAGS, true)).AddChangeHook(CVarChanged_SniperTime);
	fSniperTime = CVar.FloatValue;

	(CVar = AutoExecConfig_CreateConVar("drapi_show_damage_mg_time",		"0.5",	"MGuns Time Between shots",		DEFAULT_FLAGS, true)).AddChangeHook(CVarChanged_MGTime);
	fMGTime = CVar.FloatValue;

	(CVar = AutoExecConfig_CreateConVar("drapi_show_damage_rifle_time",		"0.5",	"RIFLES Time Between shots",	DEFAULT_FLAGS, true)).AddChangeHook(CVarChanged_RifleTime);
	fRifleTime = CVar.FloatValue;

	(CVar = AutoExecConfig_CreateConVar("drapi_show_damage_mp_time",		"0.5",	"MPs Time Between shots",		DEFAULT_FLAGS, true)).AddChangeHook(CVarChanged_SMGTime);
	fSMGTime = CVar.FloatValue;

	(CVar = AutoExecConfig_CreateConVar("drapi_show_damage_pump_time",		"0.5",	"PUMPS Time Between shots",		DEFAULT_FLAGS, true)).AddChangeHook(CVarChanged_PumpTime);
	fPumpTime = CVar.FloatValue;

	(CVar = AutoExecConfig_CreateConVar("drapi_show_damage_pistol_time",	"0.5",	"PISTOLS Time Between shots",	DEFAULT_FLAGS, true)).AddChangeHook(CVarChanged_PistolTime);
	fPistolTime = CVar.FloatValue;

	(CVar = FindConVar("inferno_flame_lifetime")).AddChangeHook(CVarChanged_InfernoLifetime);
	fInfernoLifetime = CVar.FloatValue;

	RegAdminCmd("sm_array", Command_Array, ADMFLAG_CHANGEMAP);
	RegConsoleCmd("sm_sd", Command_BuildMenuShowDamage);

	hCookie_ShowDamage = RegClientCookie("hCookie_ShowDamage", "", CookieAccess_Private);
	int info;
	SetCookieMenuItem(ShowDamageCookieHandler, info, "Show Damage");

	AutoExecConfig_ExecuteFile();

	ToggleEventHook(bDmg);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(hArrayVictim[i] == null) hArrayVictim[i] = CreateArray(3);

			if(AreClientCookiesCached(i)) OnClientCookiesCached(i);
		}
	}
}

/***********************************************************/
/************************ PLUGIN END ***********************/
/***********************************************************/
public void OnPluginEnd()
{
	int i = 1;
	while(i <= MaxClients)
	{
		if(IsClientInGame(i))
		{
			if(hArrayVictim[i] != null)
			{
				CloseHandle(hArrayVictim[i]);
				hArrayVictim[i] = null;
			}
		}
		i++;
	}
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
public void CVarChanged_Dmg(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	ToggleEventHook(bDmg = CVar.BoolValue);
}

void ToggleEventHook(bool enable)
{
	static bool hooked;
	if(enable && !hooked)
	{
		hooked = true;
		HookEvent("player_hurt", Event_PlayerHurt);
		PrintToServer("DS>	Event 'player_hurt' hook enabled.");
	}
	else if(!enable && hooked)
	{
		hooked = false;
		UnhookEvent("player_hurt", Event_PlayerHurt);
		PrintToServer("DS>	Event 'player_hurt' hook disabled.");
	}
}

public void CVarChanged_DmgDev(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bDmgDev = CVar.BoolValue;
}

public void CVarChanged_SniperTime(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fSniperTime = CVar.FloatValue;
}

public void CVarChanged_MGTime(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fMGTime = CVar.FloatValue;
}

public void CVarChanged_RifleTime(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fRifleTime = CVar.FloatValue;
}

public void CVarChanged_SMGTime(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fSMGTime = CVar.FloatValue;
}

public void CVarChanged_PumpTime(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fPumpTime = CVar.FloatValue;
}

public void CVarChanged_PistolTime(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fPistolTime = CVar.FloatValue;
}

public void CVarChanged_InfernoLifetime(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fInfernoLifetime = CVar.FloatValue;
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	hArrayVictim[client] = CreateArray(3);
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	if(hArrayVictim[client] != null)
	{
		CloseHandle(hArrayVictim[client]);
		hArrayVictim[client] = null;
	}
}

/***********************************************************/
/**************** ON CLIENT COOKIE CACHED ******************/
/***********************************************************/
public void OnClientCookiesCached(int client)
{
	char value[16];
	GetClientCookie(client, hCookie_ShowDamage, value, sizeof(value));
	bShowDamage[client] = (!value[0] || StringToInt(value));
}

/***********************************************************/
/****************** CMD MENU SHOW DAMAGE *******************/
/***********************************************************/
public Action Command_BuildMenuShowDamage(int client, int args)
{
	BuildMenuShowDamage(client);
}

/***********************************************************/
/********************** MENU SETTINGS **********************/
/***********************************************************/
public void ShowDamageCookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	BuildMenuShowDamage(client);
}

/***********************************************************/
/***************** BUILD MENU SHOW DAMAGE ******************/
/***********************************************************/
void BuildMenuShowDamage(int client)
{
	Menu menu = CreateMenu(MenuShowDamageAction);
	menu.SetTitle("%T", "ShowDamage_TITLE", client);

	char show_damage[40], status_show_damage[40];
	Format(status_show_damage, sizeof(status_show_damage), "%T",(bShowDamage[client]) ? "Enabled" : "Disabled", client);
	Format(show_damage, sizeof(show_damage), "%T", "ShowDamage_HUD_MENU_TITLE", client, status_show_damage);
	AddMenuItem(menu, "M_show_damage_hud", show_damage);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/**************** MENU ACTION SHOW DAMAGE ******************/
/***********************************************************/
public int MenuShowDamageAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(menu);
		case MenuAction_Cancel: if(param2 == MenuCancel_ExitBack) ShowCookieMenu(param1);
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));

			if(!strcmp(menu1, "M_show_damage_hud"))
			{
				bShowDamage[param1] = !bShowDamage[param1];
				SetClientCookie(param1, hCookie_ShowDamage,(bShowDamage[param1]) ? "1" : "0");
			}
			BuildMenuShowDamage(param1);
		}
	}
}

/***********************************************************/
/************************ CMD ARRAY ************************/
/***********************************************************/
public Action Command_Array(int client, int args)
{
	SortADTArray(hArrayVictim[client], Sort_Ascending, Sort_Integer);

	PrintToChat(client, "------FULL SIZE------");
	int size = GetArraySize(hArrayVictim[client]);
	for(int i; i < size; i++) PrintToChat(client, "%i", GetArrayCell(hArrayVictim[client], i));
}

/***********************************************************/
/******************** WHEN PLAYER HURTED *******************/
/***********************************************************/
public void Event_PlayerHurt(Event event, char[] name, bool dontBroadcast)
{
	if(!bDmg) return;

	static int attacker;
	if(!bShowDamage[(attacker = GetClientOfUserId(event.GetInt("attacker")))]) return;

	static int victim;
	if(Client_IsIngame(attacker) && Client_IsIngame((victim = GetClientOfUserId(event.GetInt("userid")))))
	{
		static char wpn[64];
		wpn[0] = '\0';
		GetEventString(event, "weapon", wpn, sizeof(wpn));

		static int type;
		type = GetWeaponType(wpn);
		if(!CheckAccessShowDamage(attacker, type)) return;

		static float time, TimerDamage[MAXPLAYERS + 1];
		static char old_wpn[MAXPLAYERS + 1][64], new_wpn[MAXPLAYERS + 1][64];
		strcopy(new_wpn[attacker], 64, wpn);

		//We reset all.
		float now = GetEngineTime();
		if(now >= TimerDamage[attacker] || !!strcmp(new_wpn[attacker], old_wpn[attacker], false))
		{
			switch(type)
			{
				//Inferno need more time. The time will be reset every time but it's fine.
				case 1: time = fInfernoLifetime;
				//HE grenade need at least 1s to catch all victims.
				case 2: time = 1.0;
				//Snipers let's say 0.5s it's enough to make 2 or 3 instant headshots.
				case 3: time = fSniperTime;
				//Machine gun can be fun to set high time.
				case 4: time = fMGTime;
				//Rifles.
				case 5: time = fRifleTime;
				//SMGs.
				case 6: time = fSMGTime;
				//Pumps.
				case 7: time = fPumpTime;
				//Pistols.
				case 8: time = fPistolTime;
				//Others guns we don't care.
				default: time = 0.0;
			}
			TimerDamage[attacker]	= now + time;
			old_wpn[attacker]		= new_wpn[attacker];
			iCountVictim[attacker] = iTotalDmg[attacker] = iTotalDmgArmor[attacker] = 0;
			ClearArray(hArrayVictim[attacker]);
		}

		//Let's get total health and armor.
		iTotalDmg[attacker] += event.GetInt("dmg_health");
		iTotalDmgArmor[attacker] += event.GetInt("dmg_armor");

		//Get better informations like that.
		Handle dataPackHandle;
		ClearTimer(Timer_ShowDamage[attacker]);
		Timer_ShowDamage[attacker] = CreateDataTimer(0.0, TimerData_ShowDamage, dataPackHandle, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		WritePackString(dataPackHandle, wpn);
		WritePackCell(dataPackHandle, GetClientUserId(attacker));
		WritePackCell(dataPackHandle, GetClientUserId(victim));
		WritePackCell(dataPackHandle, event.GetInt("hitgroup"));

		//We check if the vicitm are the same and remove duplicate victim's id.
		if(hArrayVictim[attacker] == null) hArrayVictim[attacker] = CreateArray(3);
		PushArrayCell(hArrayVictim[attacker], victim);
		Array_RemoveDuplicateInt(hArrayVictim[attacker]);
		iCountVictim[attacker] = GetArraySize(hArrayVictim[attacker]);
	}
}

stock int GetWeaponType(char[] weapon)
{
	if(!weapon[0]) return 0;

	if(!strcmp(weapon, "inferno", false))
		return 1;
	else if(!strcmp(weapon, "hegrenade", false))
		return 2;
	else if(!strcmp(weapon, "aug", false)
	|| !strcmp(weapon, "awp", false)
	|| !strcmp(weapon, "g3sg1", false)
	|| !strcmp(weapon, "scar20", false)
	|| !strcmp(weapon, "sg556", false)
	|| !strcmp(weapon, "ssg08", false))
		return 3;
	else if(!strcmp(weapon, "m249", false)
	|| !strcmp(weapon, "negev", false))
		return 4;
	else if(!strcmp(weapon, "ak47", false)
	|| !strcmp(weapon, "famas", false)
	|| !strcmp(weapon, "galilar", false)
	|| !strcmp(weapon, "m4a1", false))
		return 5;
	else if(!strcmp(weapon, "bizon", false)
	|| !strcmp(weapon, "mac10", false)
	|| !strcmp(weapon, "mp7", false)
	|| !strcmp(weapon, "mp9", false)
	|| !strcmp(weapon, "p90", false)
	|| !strcmp(weapon, "ump45", false))
		return 6;
	else if(!strcmp(weapon, "mag7", false)
	|| !strcmp(weapon, "nova", false)
	|| !strcmp(weapon, "sawedoff", false)
	|| !strcmp(weapon, "xm1014", false))
		return 7;
	else if(!strcmp(weapon, "cz75a", false)
	|| !strcmp(weapon, "deagle", false)
	|| !strcmp(weapon, "elite", false)
	|| !strcmp(weapon, "fiveseven", false)
	|| !strcmp(weapon, "glock", false)
	|| !strcmp(weapon, "hkp2000", false)
	|| !strcmp(weapon, "p250", false)
	|| !strcmp(weapon, "tec9", false))
		return 8;

	return 9;
}

/***********************************************************/
/****************** TIMER DATA SHOW DAMAGE *****************/
/***********************************************************/
public Action TimerData_ShowDamage(Handle timer, Handle hndl)
{
	ResetPack(hndl);

	char S_weapon[64];
	ReadPackString(hndl, S_weapon, sizeof(S_weapon));

	static int attacker;
	ShowDamage(S_weapon, (attacker = GetClientOfUserId(ReadPackCell(hndl))), GetClientOfUserId(ReadPackCell(hndl)), ReadPackCell(hndl), iCountVictim[attacker], iTotalDmg[attacker], iTotalDmgArmor[attacker]);

	Timer_ShowDamage[attacker] = null;
}

/***********************************************************/
/************************ SHOW DAMAGE **********************/
/***********************************************************/
void ShowDamage(char[] weapon, int attacker, int victim, int hitgroup, int count, int damage_health, int damage_armor)
{
	if(bDmgDev) PrintToServer("SD>	Weapon: %s\n	Attacker: %i\n	Victim: %i\n	Hitgroup: %i\n	Num hits: %i\n	HP: -%i\n	AP: -%i", weapon, attacker, victim, hitgroup, count, damage_health, damage_armor);

	if(!Client_IsIngame(attacker)) return;

	if(bDmgDev) PrintToServer("	Attacker name: %N", attacker);

	if(count > 1)
		PrintHintText(attacker, "%t", "Show damage multiple", weapon, count, damage_health, damage_armor);
	else if(!strcmp(weapon, "inferno", false))
		PrintHintText(attacker, "%t", "Show damage inferno", count, damage_health, damage_armor);
	else if(!strcmp(weapon, "hegrenade", false))
		PrintHintText(attacker, "%t", "Show damage hegrenade", count, damage_health, damage_armor);
	else
	{
		if(attacker != victim && Client_IsIngame(victim) && GetClientTeam(attacker) != GetClientTeam(victim))
		{
			if(bDmgDev) PrintToServer("	Victim name: %N", victim);

			static char buffer[256];
			switch(hitgroup)
			{
				case 0: buffer[0] = '\0';	// Generic
				case 1: Format(buffer, sizeof(buffer), "%T", "Head", attacker);
				case 2: Format(buffer, sizeof(buffer), "%T", "Chest", attacker);
				case 3: Format(buffer, sizeof(buffer), "%T", "Stomach", attacker);
				case 4: Format(buffer, sizeof(buffer), "%T", "Left arm", attacker);
				case 5: Format(buffer, sizeof(buffer), "%T", "Right arm", attacker);
				case 6: Format(buffer, sizeof(buffer), "%T", "Left leg", attacker);
				case 7: Format(buffer, sizeof(buffer), "%T", "Right leg", attacker);
			}

			if(!buffer[0]) PrintHintText(attacker, "%t", "Show damage hit message", damage_health, damage_armor);
			else PrintHintText(attacker, "%t", "Show damage hit message body", buffer, damage_health, damage_armor);
		}
	}
}

/***********************************************************/
/*************** CHECK ACCESS SHOW DAMAGE*******************/
/***********************************************************/
bool CheckAccessShowDamage(int client, int type)
{
	char S_steamid[64];
	if(!GetClientAuthId(client, AuthId_Steam2, S_steamid, sizeof(S_steamid))) return false;

	static bool bSteamID[MAXPLAYERS+1][MAX_TYPE_WEAPONS];

	for(int steamid = 1; steamid <= iMaxSteamID[type]; ++steamid)
		bSteamID[client][type] = (!strcmp(sSteamID[type][steamid], S_steamid ,false));

		//Steamid only
	return ((bSteamID[client][type] && !strcmp(sFlag[type], "steamid", false))
		//Admin + steamid
		|| (IsAdminEx(client) && !strcmp(sFlag[type], "admin", false) || bSteamID[client][type])
		//Vip + steamid
		|| ((IsVip(client)|| IsAdminEx(client)) && !strcmp(sFlag[type], "vip", false) || bSteamID[client][type])
		//Public;
		|| !strcmp(sFlag[type], "public", false));
}
/***********************************************************/
/********************** LOAD SETTINGS **********************/
/***********************************************************/
public void LoadSettings()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/drapi/show_damage.cfg");

	Handle kv = CreateKeyValues("ShowDamage");
	FileToKeyValues(kv, hc);

	static int max_type_weapons;
	max_type_weapons = 1;

	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			if(KvJumpToKey(kv, "ShowDamageAccess"))
			{
				if(KvGotoFirstSubKey(kv))
				{
					do
					{
						char S_info[3];
						if(KvGetSectionName(kv, S_info, 3))
						{
							KvGetString(kv, "flags", sFlag[max_type_weapons], 64);

							iMaxSteamID[max_type_weapons] = 1;

							if(KvJumpToKey(kv, "SteamIDs"))
							{
								for(int i = 1; i <= MAX_STEAMID; ++i)
								{
									char key[3];
									IntToString(i, key, 3);

									if(KvGetString(kv, key, sSteamID[max_type_weapons][i], 64) && strlen(sSteamID[max_type_weapons][i]))
									{
										if(bDmgDev) PrintToServer("%s [%i] - ID: %i, STEAMID: %s", TAG_CHAT, max_type_weapons, i, sSteamID[max_type_weapons][i]);
										iMaxSteamID[max_type_weapons] = i;
									}
									else break;
								}
								KvGoBack(kv);
							}

							if(bDmgDev) PrintToServer("%s, %s", S_info, sFlag[max_type_weapons]);
							max_type_weapons++;
						}
					}
					while(KvGotoNextKey(kv));
				}
			}
		}
		while(KvGotoNextKey(kv));
	}
	CloseHandle(kv);
}

/***********************************************************/
/********************* IS VALID CLIENT *********************/
/***********************************************************/
stock bool Client_IsValid(int client, bool checkConnected=true)
{
	if(client > 4096) client = EntRefToEntIndex(client);

	return (0 < client <= MaxClients && !(checkConnected && !IsClientConnected(client)));
}

/***********************************************************/
/******************** IS CLIENT IN GAME ********************/
/***********************************************************/
stock bool Client_IsIngame(int client)
{
	return Client_IsValid(client, false) && IsClientInGame(client);
}

/***********************************************************/
/*************** REMOVE DUPLICATE FROM ARRAY ***************/
/***********************************************************/
stock void Array_RemoveDuplicateInt(Handle array, bool sorted = false)
{
	// Sort array if not sorted.
	// Sort the array so duplicate entries will be next to eachother.
	if(!sorted) SortADTArray(array, Sort_Ascending, Sort_Integer);

	int len = GetArraySize(array);
	// Arrays with one or zero elements can't have duplicates.
	if(len < 2) return;

	int currentVal;
	int lastVal = GetArrayCell(array, len - 1);

	// Iterate backwards through elements and remove duplicates. Elements are
	// removed at the end first so that minimal amount of elements must be
	// shifted.
	for(int i = len - 2; i > -1; i--)
	{
		currentVal = GetArrayCell(array, i);
		// Remove last duplicate(the one after this).
		if(lastVal == currentVal) RemoveFromArray(array, i + 1);
		lastVal = currentVal;
	}
}

/***********************************************************/
/******************** CHECK IF IS A VIP ********************/
/***********************************************************/
stock bool IsVip(int client)
{
	return (GetUserFlagBits(client) & ADMFLAG_CUSTOM1
		|| GetUserFlagBits(client) & ADMFLAG_CUSTOM2
		|| GetUserFlagBits(client) & ADMFLAG_CUSTOM3
		|| GetUserFlagBits(client) & ADMFLAG_CUSTOM4
		|| GetUserFlagBits(client) & ADMFLAG_CUSTOM5
		|| GetUserFlagBits(client) & ADMFLAG_CUSTOM6);
}

/***********************************************************/
/****************** CHECK IF IS AN ADMIN *******************/
/***********************************************************/
stock bool IsAdminEx(int client)
{
	return (GetUserFlagBits(client) & ADMFLAG_GENERIC
	/*|| GetUserFlagBits(client) & ADMFLAG_RESERVATION*/
	|| GetUserFlagBits(client) & ADMFLAG_KICK
	|| GetUserFlagBits(client) & ADMFLAG_BAN
	|| GetUserFlagBits(client) & ADMFLAG_UNBAN
	|| GetUserFlagBits(client) & ADMFLAG_SLAY
	|| GetUserFlagBits(client) & ADMFLAG_CHANGEMAP
	|| GetUserFlagBits(client) & ADMFLAG_CONVARS
	|| GetUserFlagBits(client) & ADMFLAG_CONFIG
	|| GetUserFlagBits(client) & ADMFLAG_CHAT
	|| GetUserFlagBits(client) & ADMFLAG_VOTE
	|| GetUserFlagBits(client) & ADMFLAG_PASSWORD
	|| GetUserFlagBits(client) & ADMFLAG_RCON
	|| GetUserFlagBits(client) & ADMFLAG_CHEATS
	|| GetUserFlagBits(client) & ADMFLAG_ROOT);
}

/***********************************************************/
/********************** CLEAR TIMER ************************/
/***********************************************************/
stock void ClearTimer(Handle &timer)
{
	if(timer != null)
	{
		KillTimer(timer);
		timer = null;
	}
}