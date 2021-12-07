/*  <DR. API SHOW DAMAGE> (c) by <De Battista Clint - (http://doyou.watch)   */
/*                                                                           */
/*                 <DR. API SHOW DAMAGE> is licensed under a                 */
/* Creative Commons Attribution-NonCommercial-NoDerivs 4.0 Unported License. */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*  work.  If not, see <http://creativecommons.org/licenses/by-nc-nd/4.0/>.  */
//***************************************************************************//
//***************************************************************************//
//****************************DR. API SHOW DAMAGE****************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define CVARS 									0|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
#define DEFAULT_FLAGS 							0|FCVAR_NOTIFY
#define TAG_CHAT 								"[SHOW DAMAGE] - "
#define PLUGIN_VERSION							"1.1.2"
#define MAX_TYPE_WEAPONS						10
#define MAX_SHOW_DAMAGE_STEAMID					25

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <clientprefs>
#include <autoexec>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_show_damage;
Handle cvar_active_show_damage_dev;

Handle cvar_show_damage_sniper_time;
Handle cvar_show_damage_mg_time;
Handle cvar_show_damage_rifle_time;
Handle cvar_show_damage_mp_time;
Handle cvar_show_damage_pump_time;
Handle cvar_show_damage_pistol_time;

Handle Array_Victim[MAXPLAYERS + 1];
Handle Cookie_ShowDamage;

Handle Timer_ShowDamage[MAXPLAYERS + 1];

//Bool
bool B_active_show_damage 					= false;
bool B_active_show_damage_dev				= false;

bool B_ShowDamage_SteamID[MAXPLAYERS+1][MAX_TYPE_WEAPONS];

//Floats
float TimerDamage[MAXPLAYERS + 1];

float F_show_damage_sniper_time;
float F_show_damage_mg_time;
float F_show_damage_rifle_time;
float F_show_damage_mp_time;
float F_show_damage_pump_time;
float F_show_damage_pistol_time;

//Strings
char S_new_weapon[MAXPLAYERS + 1][64];
char S_old_weapon[MAXPLAYERS + 1][64];

char S_showdamageflag[MAX_TYPE_WEAPONS][64];
char S_showdamagesteamid[MAX_TYPE_WEAPONS][MAX_SHOW_DAMAGE_STEAMID][64];

//Cutstom
int C_CountVictim[MAXPLAYERS + 1]			= 1;
int C_TotalDamage[MAXPLAYERS + 1];
int C_TotalDamageArmor[MAXPLAYERS + 1];
C_ShowDamage[MAXPLAYERS + 1];

int max_type_weapons;
int max_show_damage_steamid[MAX_SHOW_DAMAGE_STEAMID];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API SHOW DAMAGE",
	author = "Dr. Api",
	description = "DR.API SHOW DAMAGE by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_show_damage.phrases");
	AutoExecConfig_SetFile("drapi_show_damage", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("aio_show_damage_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_show_damage 					= AutoExecConfig_CreateConVar("drapi_active_show_damage",  				"1", 					"Enable/Disable Show Damage", 		DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	cvar_active_show_damage_dev					= AutoExecConfig_CreateConVar("drapi_active_show_damage_dev", 			"0", 					"Enable/Disable Show Damage Dev", 	DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_show_damage_sniper_time				= AutoExecConfig_CreateConVar("drapi_show_damage_sniper_time", 			"0.5", 					"SNIPERS Time Between shots", 		DEFAULT_FLAGS);
	cvar_show_damage_mg_time					= AutoExecConfig_CreateConVar("drapi_show_damage_mg_time", 				"0.5", 					"MGuns Time Between shots", 		DEFAULT_FLAGS);
	cvar_show_damage_rifle_time					= AutoExecConfig_CreateConVar("drapi_show_damage_rifle_time", 			"0.5", 					"RIFLES Time Between shots", 		DEFAULT_FLAGS);
	cvar_show_damage_mp_time					= AutoExecConfig_CreateConVar("drapi_show_damage_mp_time", 				"0.5", 					"MPs Time Between shots", 			DEFAULT_FLAGS);
	cvar_show_damage_pump_time					= AutoExecConfig_CreateConVar("drapi_show_damage_pump_time", 			"0.5", 					"PUMPS Time Between shots", 		DEFAULT_FLAGS);
	cvar_show_damage_pistol_time				= AutoExecConfig_CreateConVar("drapi_show_damage_pistol_time", 			"0.5", 					"PISTOLS Time Between shots", 		DEFAULT_FLAGS);
	
	HookEvents();
	
	HookEvent("player_hurt", Event_PlayerHurt);
	
	RegAdminCmd("sm_array", Command_Array, ADMFLAG_CHANGEMAP, "");
	RegConsoleCmd("sm_sd", Command_BuildMenuShowDamage, "");
	
	Cookie_ShowDamage 					= RegClientCookie("Cookie_ShowDamage", "", CookieAccess_Private);
	int info;
	SetCookieMenuItem(ShowDamageCookieHandler, info, "Show Damage");
		
	AutoExecConfig_ExecuteFile();
	
	int i = 1;
	while (i <= MaxClients)
	{
		if(IsClientInGame(i))
		{
			if(Array_Victim[i] == INVALID_HANDLE)
			{
				Array_Victim[i] = CreateArray(3);
			}
			
			if(AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
		i++;
	}
}

/***********************************************************/
/************************ PLUGIN END ***********************/
/***********************************************************/
public void OnPluginEnd()
{
	int i = 1;
	while (i <= MaxClients)
	{
		if(IsClientInGame(i))
		{
			if(Array_Victim[i] != INVALID_HANDLE)
			{
				CloseHandle(Array_Victim[i]);
				Array_Victim[i] = INVALID_HANDLE;
			}
		}
		i++;
	}
}
/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_show_damage, 				Event_CvarChange);
	HookConVarChange(cvar_active_show_damage_dev, 			Event_CvarChange);
	
	HookConVarChange(cvar_show_damage_sniper_time, 			Event_CvarChange);
	HookConVarChange(cvar_show_damage_mg_time, 				Event_CvarChange);
	HookConVarChange(cvar_show_damage_rifle_time, 			Event_CvarChange);
	HookConVarChange(cvar_show_damage_mp_time, 				Event_CvarChange);
	HookConVarChange(cvar_show_damage_pump_time, 			Event_CvarChange);
	HookConVarChange(cvar_show_damage_pistol_time, 			Event_CvarChange);
}

/***********************************************************/
/******************** WHEN CVARS CHANGE ********************/
/***********************************************************/
public void Event_CvarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	UpdateState();
}

/***********************************************************/
/*********************** UPDATE STATE **********************/
/***********************************************************/
void UpdateState()
{
	B_active_show_damage 			= GetConVarBool(cvar_active_show_damage);
	B_active_show_damage_dev 		= GetConVarBool(cvar_active_show_damage_dev);
	
	F_show_damage_sniper_time 		= GetConVarFloat(cvar_show_damage_sniper_time);
	F_show_damage_mg_time 			= GetConVarFloat(cvar_show_damage_mg_time);
	F_show_damage_rifle_time 		= GetConVarFloat(cvar_show_damage_rifle_time);
	F_show_damage_mp_time 			= GetConVarFloat(cvar_show_damage_mp_time);
	F_show_damage_pump_time 		= GetConVarFloat(cvar_show_damage_pump_time);
	F_show_damage_pistol_time 		= GetConVarFloat(cvar_show_damage_pistol_time);
}

/***********************************************************/
/**************** WHEN CLIENT PUT IN SERVER ****************/
/***********************************************************/
public void OnClientPutInServer(int client)
{
	Array_Victim[client] = CreateArray(3);
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	if(Array_Victim[client] != INVALID_HANDLE)
	{
		CloseHandle(Array_Victim[client]);
		Array_Victim[client] = INVALID_HANDLE;
	}
}

/***********************************************************/
/**************** ON CLIENT COOKIE CACHED ******************/
/***********************************************************/
public void OnClientCookiesCached(int client)
{
	char value[16];
	
	GetClientCookie(client, Cookie_ShowDamage, value, sizeof(value));
	if(strlen(value) > 0) 
	{
		C_ShowDamage[client] = StringToInt(value);
	}
	else 
	{
		C_ShowDamage[client] = 1;
	}
}
/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public void OnConfigsExecuted()
{
	LoadSettings();
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	UpdateState();
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
public void ShowDamageCookieHandler(int client, CookieMenuAction action, any info, char [] buffer, int maxlen)
{
	BuildMenuShowDamage(client);
} 

/***********************************************************/
/***************** BUILD MENU SHOW DAMAGE ******************/
/***********************************************************/
void BuildMenuShowDamage(int client)
{
	char title[40], show_damage[40], status_show_damage[40];
	
	Menu menu = CreateMenu(MenuShowDamageAction);
	
	Format(status_show_damage, sizeof(status_show_damage), "%T", (C_ShowDamage[client]) ? "Enabled" : "Disabled", client);
	Format(show_damage, sizeof(show_damage), "%T", "ShowDamage_HUD_MENU_TITLE", client, status_show_damage);
	AddMenuItem(menu, "M_show_damage_hud", show_damage);
	
	Format(title, sizeof(title), "%T", "ShowDamage_TITLE", client);
	menu.SetTitle(title);
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}

/***********************************************************/
/**************** MENU ACTION SHOW DAMAGE ******************/
/***********************************************************/
public int MenuShowDamageAction(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);	
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{	
				FakeClientCommand(param1, "sm_settings");
			}
		}
		case MenuAction_Select:
		{
			char menu1[56];
			menu.GetItem(param2, menu1, sizeof(menu1));
			
			if(StrEqual(menu1, "M_show_damage_hud"))
			{
				C_ShowDamage[param1] = !C_ShowDamage[param1];
				SetClientCookie(param1, Cookie_ShowDamage, (C_ShowDamage[param1]) ? "1" : "0");
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
	/*
	Handle Array_Test = CreateArray(3);
	PushArrayCell(Array_Test, 10);
	PushArrayCell(Array_Test, 10);
	PushArrayCell(Array_Test, 22);
	PushArrayCell(Array_Test, 33);
	PushArrayCell(Array_Test, 33);
	
	PrintToChat(client, "------FULL SIZE------");
	for(int i = 0; i <= GetArraySize(Array_Test) - 1; i++)
	{
		PrintToChat(client, "%i", GetArrayCell(Array_Test, i));
	}
	
	PrintToChat(client, "------REMOVE SIZE------");
	Array_RemoveDuplicateInt(Array_Test);
	
	for(int i = 0; i <= GetArraySize(Array_Test) - 1; i++)
	{
		PrintToChat(client, "%i", GetArrayCell(Array_Test, i));
	}
	*/
	
	/*
	PrintToChat(client, "------FULL SIZE------");
	for(int i = 0; i <= GetArraySize(Array_Victim[client]) - 1; i++)
	{
		PrintToChat(client, "%i", GetArrayCell(Array_Victim[client], i));
	}
	*/
	
	SortADTArray(Array_Victim[client], Sort_Ascending, Sort_Integer);
	
	PrintToChat(client, "------FULL SIZE------");
	for(int i = 0; i <= GetArraySize(Array_Victim[client]) - 1; i++)
	{
		PrintToChat(client, "%i", GetArrayCell(Array_Victim[client], i));
	}
}

/***********************************************************/
/******************** WHEN PLAYER HURTED *******************/
/***********************************************************/
public Action Event_PlayerHurt(Handle event, char[] name, bool dontBroadcast)
{
	if(B_active_show_damage)
	{
		char S_weapon[64];
	
		int victim 			= GetClientOfUserId(GetEventInt(event, "userid"));
		int attacker 		= GetClientOfUserId(GetEventInt(event, "attacker"));
		int damage_health 	= GetEventInt(event, "dmg_health");	
		int damage_armor 	= GetEventInt(event, "dmg_armor");
		int hitgroup		= GetEventInt(event, "hitgroup");
		GetEventString(event, "weapon", S_weapon, sizeof(S_weapon));
		
		if(!C_ShowDamage[attacker]) return;
		
		if(Client_IsIngame(attacker) && Client_IsIngame(victim))
		{
			strcopy(S_new_weapon[attacker], 64, S_weapon);
			
			float time;
			int type;
			//Inferno need more time. The time will be reset every time but it's fine.
			if(StrEqual(S_weapon, "inferno", false))
			{
				time = GetConVarFloat(FindConVar("inferno_flame_lifetime"));
				type = 1;
			}
			
			//Grenade need at least 1s to catch all victims.
			else if(StrEqual(S_weapon, "hegrenade", false))
			{
				time = 1.0;
				type = 2;
			}
			
			//Snipers let's say 0.5s it's enough to make 2 or 3 instant headshots.
			else if(StrEqual(S_weapon, "awp", false) 
			|| StrEqual(S_weapon, "ssg08", false)
			|| StrEqual(S_weapon, "sg556", false)
			|| StrEqual(S_weapon, "aug", false)
			|| StrEqual(S_weapon, "scar20", false)
			|| StrEqual(S_weapon, "g3sg1", false)
			)
			{
				time = F_show_damage_sniper_time;	
				type = 3;
			}
			//Machine gun can be fun to set high time.
			else if(StrEqual(S_weapon, "negev", false) 
			|| StrEqual(S_weapon, "m249", false)
			) 
			{
				time = F_show_damage_mg_time;	
				type = 4;
			}
			//Rifles.
			else if(StrEqual(S_weapon, "m4a1", false) 
			|| StrEqual(S_weapon, "ak47", false)
			|| StrEqual(S_weapon, "famas", false)
			|| StrEqual(S_weapon, "galilar", false)
			) 
			{
				time = F_show_damage_rifle_time;		
				type = 5;
			}
			//MP's.
			else if(StrEqual(S_weapon, "p90", false) 
			|| StrEqual(S_weapon, "ump45", false)
			|| StrEqual(S_weapon, "mac10", false)
			|| StrEqual(S_weapon, "mp7", false)
			|| StrEqual(S_weapon, "mp9", false)
			|| StrEqual(S_weapon, "bizon", false)
			) 
			{
				time = F_show_damage_mp_time;	
				type = 6;
			}
			//Pumps.
			else if(StrEqual(S_weapon, "nova", false) 
			|| StrEqual(S_weapon, "sawedoff", false)
			|| StrEqual(S_weapon, "xm1014", false)
			|| StrEqual(S_weapon, "mag7", false)
			) 
			{
				time = F_show_damage_pump_time;	
				type = 7;
			}
			//Pistols.
			else if(StrEqual(S_weapon, "hkp2000", false) 
			|| StrEqual(S_weapon, "cz75a", false)
			|| StrEqual(S_weapon, "p250", false)
			|| StrEqual(S_weapon, "fiveseven", false)
			|| StrEqual(S_weapon, "deagle", false)
			|| StrEqual(S_weapon, "glock", false)
			|| StrEqual(S_weapon, "tec9", false)
			|| StrEqual(S_weapon, "elite", false)
			) 
			{
				time = F_show_damage_pistol_time;
				type = 8;
			}
			//Others guns we don't care.
			else
			{
				time = 0.0;
				type = 9;
			}
				
			if(!CheckAccessShowDamage(attacker, type)) return;
			
			//We reset all.
			float now = GetEngineTime();
			if(now >= TimerDamage[attacker] || !StrEqual(S_new_weapon[attacker], S_old_weapon[attacker], false))
			{
				C_CountVictim[attacker]			= 0;
				TimerDamage[attacker] 			= now + time;
				C_TotalDamage[attacker] 		= 0;
				C_TotalDamageArmor[attacker] 	= 0;
				S_old_weapon[attacker] 			= S_new_weapon[attacker];
				ClearArray(Array_Victim[attacker]);
			}
			
			//Let's get total health and armor.
			C_TotalDamage[attacker] 		+= damage_health;
			C_TotalDamageArmor[attacker] 	+= damage_armor;
			
			
			//Get better informations like that.
			Handle dataPackHandle;
			ClearTimer(Timer_ShowDamage[attacker]);
			Timer_ShowDamage[attacker] = CreateDataTimer(0.0, TimerData_ShowDamage, dataPackHandle);
			WritePackString(dataPackHandle, S_weapon);
			WritePackCell(dataPackHandle, GetClientUserId(attacker));
			WritePackCell(dataPackHandle, GetClientUserId(victim));
			WritePackCell(dataPackHandle, hitgroup);
			
			//We check if the vicitm are the same and remove duplicate victim's id.
			if(Array_Victim[attacker] == INVALID_HANDLE)
			{
				Array_Victim[attacker] = CreateArray(3);
			}
			PushArrayCell(Array_Victim[attacker], victim);
			Array_RemoveDuplicateInt(Array_Victim[attacker]);
			C_CountVictim[attacker] = GetArraySize(Array_Victim[attacker]);
		}
	}
}

/***********************************************************/
/****************** TIMER DATA SHOW DAMAGE *****************/
/***********************************************************/
public Action TimerData_ShowDamage(Handle timer, Handle dataPackHandle)
{	
	ResetPack(dataPackHandle);
	
	char S_weapon[64];
	ReadPackString(dataPackHandle, S_weapon, sizeof(S_weapon));
	int attacker 		= GetClientOfUserId(ReadPackCell(dataPackHandle));
	int victim 			= GetClientOfUserId(ReadPackCell(dataPackHandle));
	int hitgroup 		= ReadPackCell(dataPackHandle);
	
	Timer_ShowDamage[attacker] = INVALID_HANDLE;
	
	ShowDamage(S_weapon, attacker, victim, hitgroup, C_CountVictim[attacker], C_TotalDamage[attacker], C_TotalDamageArmor[attacker]);
	
	//PrintToChat(attacker, "%s", S_weapon);
	//PrintToChat(attacker, "%i, %N", C_CountVictim[attacker], victim);
	//PrintToChat(attacker, "new:%s, old:%s | %i", S_new_weapon[attacker], S_old_weapon[attacker], C_CountVictim[attacker]);
} 

/***********************************************************/
/************************ SHOW DAMAGE **********************/
/***********************************************************/
void ShowDamage(char[] weapon, int attacker, int victim, int hitgroup, int count, int damage_health, int damage_armor)
{
	//PrintToChat(attacker, "cookie:%i", C_show_damage[attacker]);
	/* hitgroup 0 = generic */
	/* hitgroup 1 = head */
	/* hitgroup 2 = chest */
	/* hitgroup 3 = stomach */
	/* hitgroup 4 = left arm */
	/* hitgroup 5 = right arm */
	/* hitgroup 6 = left leg */
	/* hitgroup 7 = right leg */
	
	if(count > 1 || StrEqual(weapon, "inferno", false) || StrEqual(weapon, "hegrenade", false))
	{
		if(StrEqual(weapon, "inferno", false))
		{
			PrintHintText(attacker, "%t", "Show damage inferno", count, damage_health, damage_armor);
		}
		else if(StrEqual(weapon, "hegrenade", false))
		{
			PrintHintText(attacker, "%t", "Show damage hegrenade", count, damage_health, damage_armor);
		}
		else
		{
			PrintHintText(attacker, "%t", "Show damage multiple", weapon, count, damage_health, damage_armor);
		}
	}
	else
	{
		char S_hitgroup_message[256];
		switch(hitgroup)
		{
			case 0:
			{
				S_hitgroup_message = "";
			}
			case 1:
			{
				//S_hitgroup_message = "Head";
				Format(S_hitgroup_message, sizeof(S_hitgroup_message), "%T", "Head", attacker);
			}
			case 2:
			{
				//S_hitgroup_message = "Chest";
				Format(S_hitgroup_message, sizeof(S_hitgroup_message), "%T", "Chest", attacker);
			}
			case 3:
			{
				//S_hitgroup_message = "Stomach";
				Format(S_hitgroup_message, sizeof(S_hitgroup_message), "%T", "Stomach", attacker);
			}
			case 4:
			{
				//S_hitgroup_message = "Left arm";
				Format(S_hitgroup_message, sizeof(S_hitgroup_message), "%T", "Left arm", attacker);
			}
			case 5:
			{
				//S_hitgroup_message = "Right arm";
				Format(S_hitgroup_message, sizeof(S_hitgroup_message), "%T", "Right arm", attacker);
			}
			case 6:
			{
				//S_hitgroup_message = "Left leg";
				Format(S_hitgroup_message, sizeof(S_hitgroup_message), "%T", "Left leg", attacker);
			}
			case 7:
			{
				//S_hitgroup_message = "Right leg";
				Format(S_hitgroup_message, sizeof(S_hitgroup_message), "%T", "Right leg", attacker);
			}
		}
		
		if(Client_IsIngame(attacker) && Client_IsIngame(victim) && attacker != victim && GetClientTeam(attacker) != GetClientTeam(victim))
		{
			if(strlen(S_hitgroup_message))
			{
				PrintHintText(attacker, "%t", "Show damage hit message body", S_hitgroup_message, damage_health, damage_armor);
			}
			else
			{
				PrintHintText(attacker, "%t", "Show damage hit message", damage_health, damage_armor);
			}
		}
	}
	Timer_ShowDamage[attacker] = INVALID_HANDLE;	
}

/***********************************************************/
/*************** CHECK ACCESS SHOW DAMAGE*******************/
/***********************************************************/
bool CheckAccessShowDamage(int client, int type)
{
	char S_steamid[64];
	GetClientAuthId(client, AuthId_Steam2, S_steamid, sizeof(S_steamid));
	
	for(int steamid = 1; steamid <= max_show_damage_steamid[type]; ++steamid)
	{
		
		if(StrEqual(S_showdamagesteamid[type][steamid], S_steamid ,false))
		{
			B_ShowDamage_SteamID[client][type] = true;
		}
	}
	
	if( (B_ShowDamage_SteamID[client][type] == true && StrEqual(S_showdamageflag[type], "steamid", false)) 													//Steamid only
		|| (IsAdminEx(client) && StrEqual(S_showdamageflag[type], "admin", false) || B_ShowDamage_SteamID[client][type] == true)							//Admin + steamid 
		|| ( (IsVip(client)|| IsAdminEx(client)) && StrEqual(S_showdamageflag[type], "vip", false) || B_ShowDamage_SteamID[client][type] == true) 			//Vip + steamid
		|| StrEqual(S_showdamageflag[type], "public", false) )																								//Public
		{
			return true;
		}
		else
		{
			return false;
		}
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
							KvGetString(kv, "flags", S_showdamageflag[max_type_weapons], 64);
							
							max_show_damage_steamid[max_type_weapons] = 1;
							
							if(KvJumpToKey(kv, "SteamIDs"))
							{
								for(int i = 1; i <= MAX_SHOW_DAMAGE_STEAMID; ++i)
								{
									char key[3];
									IntToString(i, key, 3);
									
									if(KvGetString(kv, key, S_showdamagesteamid[max_type_weapons][i], 64) && strlen(S_showdamagesteamid[max_type_weapons][i]))
									{
										if(B_active_show_damage_dev)
										{
											LogMessage("%s [%i] - ID: %i, STEAMID: %s", TAG_CHAT, max_type_weapons, i, S_showdamagesteamid[max_type_weapons][i]);
										}
										max_show_damage_steamid[max_type_weapons] = i;
									}
									else
									{
										break;
									}
									
								}
								KvGoBack(kv);
							}
							
							if(B_active_show_damage_dev)
							{
								LogMessage("%s, %s", S_info, S_showdamageflag[max_type_weapons]);
							}
							max_type_weapons++;
						}
					}
					while (KvGotoNextKey(kv));
				}
			}
			
		}
		while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
	
}

/***********************************************************/
/********************* IS VALID CLIENT *********************/
/***********************************************************/
stock bool Client_IsValid(int client, bool checkConnected=true)
{
	if (client > 4096) 
	{
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) 
	{
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) 
	{
		return false;
	}
	
	return true;
}

/***********************************************************/
/******************** IS CLIENT IN GAME ********************/
/***********************************************************/
stock bool Client_IsIngame(int client)
{
	if (!Client_IsValid(client, false)) 
	{
		return false;
	}

	return IsClientInGame(client);
}

/***********************************************************/
/*************** REMOVE DUPLICATE FROM ARRAY ***************/
/***********************************************************/
stock void Array_RemoveDuplicateInt(Handle array, bool sorted = false)
{
    // Sort array if not sorted.
    if (!sorted)
    {
        // Sort the array so duplicate entries will be next to eachother.
        SortADTArray(array, Sort_Ascending, Sort_Integer);
    }
    
    int len = GetArraySize(array);
    if (len < 2)
    {
        // Arrays with one or zero elements can't have duplicates.
        return;
    }
    
    int currentVal;
    int lastVal = GetArrayCell(array, len - 1);
    
    // Iterate backwards through elements and remove duplicates. Elements are
    // removed at the end first so that minimal amount of elements must be
    // shifted.
    for (int i = len - 2; i >= 0; i--)
    {
        currentVal = GetArrayCell(array, i);
        if (lastVal == currentVal)
        {
            // Remove last duplicate (the one after this).
            RemoveFromArray(array, i + 1);
        }
        lastVal = currentVal;
    }
}

/***********************************************************/
/******************** CHECK IF IS A VIP ********************/
/***********************************************************/
stock bool IsVip(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM2 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM3 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM4 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM5 
	|| GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
	{
		return true;
	}
	return false;
}

/***********************************************************/
/****************** CHECK IF IS AN ADMIN *******************/
/***********************************************************/
stock bool IsAdminEx(int client)
{
	if(
	/*|| GetUserFlagBits(client) & ADMFLAG_RESERVATION*/
	GetUserFlagBits(client) & ADMFLAG_GENERIC
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
	|| GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	return false;
}

/***********************************************************/
/********************** CLEAR TIMER ************************/
/***********************************************************/
stock void ClearTimer(Handle &timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }     
}