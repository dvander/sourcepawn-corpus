#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <Skills>
#include <sdktools>
#include <sdkhooks>

#pragma tabsize 0

#define ZOMBIECLASS_TANK 8
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define SURVIVOR_MODELS 8
#define TEAMUPGRADES 6

#define	MAX_MELEE			12
#define Melee_GAMEDATA			"l4d2_melee_range"

// Macros for determining client validity
#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

public Plugin myinfo = 
{
	name = "[L4D2] Skills Core",
	author = "BHaType",
	description = "Main Plugin",
	version = "1.0",
	url = "SDKCall"
};

char Temp1[] = " | Assist: ", Temp2[] = ", ", Temp3[] = " (", Temp4[] = " dmg)", Temp5[] = "\x04", Temp6[] = "\x01", Temp7[] = "\x04[+$", Temp8[] = "\x04]";
Handle g_hPerkStateChanged, g_hPerkReset, g_hTimerHealth, g_hTimerPoison, g_hReloadConfig;
Menu g_hMainMenu, g_hPerksPassive, g_hPerksActive, g_hSwitchMenu, g_hAdminMenu, g_hReload;
bool g_bHookChat[MAXPLAYERS + 1], AssistFlag, WitchAssistFlag, EnableAssist, EnableWitch, MeleeRangeUpgrade = false, g_bCvarAllow, EnableFFDetection;
float g_flHealInterval, g_flHealTime, g_flPoisonInterval, g_flPoisonTime, g_iRewardKill[9], TeamMultiplier;
int  g_iPlayerBalance[MAXPLAYERS + 1], g_iTeamBalance, g_iTeamCosts[TEAMUPGRADES], g_iHealCount, g_iPoisonDamage, g_iTarget[MAXPLAYERS + 1], g_iHealTeamCount, g_iMaxHeal, g_iMaxHealCount, 	
	g_iRewardCrown, g_iShop[3], g_iBoxesAmmo[2], Damage[MAXPLAYERS+1][MAXPLAYERS+1], DamageWitch[MAXPLAYERS+1][MAXPLAYERS+1], SpecInfecBonus, WitchKBonus, g_iRange, g_iStockRange,
	g_friendlyfire[MAXPLAYERS+1];
StringMap g_hScripts, g_smbalance, g_smFriendlyFire;
Handle g_hDetour;
ConVar g_hCvarMeleeRange;


public int NA_PerkRegister(Handle hPlugin, int iNumParams)
{
	if (iNumParams > 4 || iNumParams <= 0)
	{
		ThrowError("Invalid params number");
		return false;
	}
	
	char szPerkName[MAXPERKNAME], szTemp[64], szSaveName[MAXPERKNAME];
	GetNativeString(1, szSaveName, MAXPERKNAME);
	
	iPerkType iType = GetNativeCell(2);
	
	int iCost = GetNativeCell(3);
	bool bUpgradeble = view_as<bool>(GetNativeCell(4));
	
	Format(szTemp, sizeof szTemp, "%s - %i (%s)", szSaveName, iCost, bUpgradeble ? "+" : "-");
	Format(szPerkName, sizeof szPerkName, "%s|%i|%s", szSaveName, iCost, bUpgradeble ? "++" : "");
	
	char szBuffer[MAXPERKNAME], szExploded[3][MAXPERKNAME];
	
	if (iType == Passive)
	{
		for (int i; i <= g_hPerksPassive.ItemCount; i++)
		{
			g_hPerksPassive.GetItem(i, szBuffer, sizeof szBuffer);
			ExplodeString(szBuffer, "|", szExploded, sizeof szExploded, sizeof szExploded[]);
			if (strcmp(szSaveName, szExploded[0]) == 0 && szExploded[0][0] != '\0')
			{
				g_hPerksPassive.RemoveItem(i);
				g_hPerksPassive.InsertItem(i, szPerkName, szTemp);
				return true;
			}
		}
	}
	else
	{
		for (int i; i <= g_hPerksActive.ItemCount; i++)
		{
			g_hPerksActive.GetItem(i, szBuffer, sizeof szBuffer);
			ExplodeString(szBuffer, "|", szExploded, sizeof szExploded, sizeof szExploded[]);
			if (strcmp(szSaveName, szExploded[0]) == 0 && szExploded[0][0] != '\0')
			{
				g_hPerksActive.RemoveItem(i);
				g_hPerksActive.InsertItem(i, szPerkName, szTemp);
				return true;
			}
		}
	}
	
	switch (iType)
	{
		case Passive:	g_hPerksPassive.AddItem(szPerkName, szTemp);
		case Activate:	g_hPerksActive.AddItem(szPerkName, szTemp);
	}
	
	return true;
}

public int NA_GetClientBalance(Handle hPlugin, int iNumParams)
{
	if (iNumParams != 1)
	{
		ThrowError("Invalid params number");
		return -1;
	}
	return g_iPlayerBalance[GetNativeCell(1)];
}

public int NA_SetClientBalance(Handle hPlugin, int iNumParams)
{
	if (iNumParams != 2)
	{
		ThrowError("Invalid params number");
		return -1;
	}
	g_iPlayerBalance[GetNativeCell(1)] = GetNativeCell(2);
	return true;
}

public int NA_ShowClientMenu(Handle hPlugin, int iNumParams)
{
	g_hMainMenu.Display(GetNativeCell(1), MENU_TIME_FOREVER);
	return false;
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max) 
{
	CreateNative("RegisterPerk", NA_PerkRegister);
	CreateNative("GetClientBalance", NA_GetClientBalance);
	CreateNative("SetClientBalance", NA_SetClientBalance);
	CreateNative("ClientMenu", NA_ShowClientMenu);
	
	g_hPerkStateChanged = CreateGlobalForward("OnClientPerkStateChanged", ET_Event, Param_Cell, Param_String);
	g_hPerkReset = CreateGlobalForward("OnShouldReset", ET_Ignore);
	g_hReloadConfig = CreateGlobalForward("OnReloadConfig", ET_Event, Param_String);
	
	RegPluginLibrary("l4d2_skills_core");
	return APLRes_Success;
}

public void OnPluginStart()
{
	// Melee GAMEDATA
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", Melee_GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(Melee_GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", Melee_GAMEDATA);

	g_hDetour = DHookCreateFromConf(hGameData, "CTerrorMeleeWeapon::TestMeleeSwingCollision");
	delete hGameData;

	if( !g_hDetour )
		SetFailState("Failed to find \"CTerrorMeleeWeapon::GetPrimaryAttackActivity\" signature.");

	// SCRIPTS - Must match cvars list and their index numbers. The "_unknown" cvar must be last and not in scripts list.
	// You must also increase MAX_MELEE by 1 for each script you add.
	g_hScripts = CreateTrie();
	g_hScripts.SetValue("baseball_bat",		0);
	g_hScripts.SetValue("cricket_bat",		1);
	g_hScripts.SetValue("crowbar",			2);
	g_hScripts.SetValue("electric_guitar",	3);
	g_hScripts.SetValue("fireaxe",			4);
	g_hScripts.SetValue("frying_pan",		5);
	g_hScripts.SetValue("golfclub",			6);
	g_hScripts.SetValue("katana",			7);
	g_hScripts.SetValue("knife",			8);
	g_hScripts.SetValue("machete",			9);
	g_hScripts.SetValue("tonfa",			10);
	g_hScripts.SetValue("pitchfork",		11);
	g_hScripts.SetValue("shovel",			12);
	// g_hScripts.SetValue("riotshield",		13); // Uncommenting? Increase MAX_MELEE at top of plugin by 1, change unknown cvar below from index [13] to [14] and uncomment [13] cvar.
	g_hCvarMeleeRange = FindConVar("melee_range");
	g_smbalance = new StringMap();
	g_smFriendlyFire = new StringMap();
	//Melee GAMEDATA
	
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), CONFIG_SETTINGS);
	
	if (!FileExists(szPath))
	{
		File hCfg = OpenFile(szPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
		
		SetupConfig(szPath);
		LoadConfig(szPath);
	}
	else
		LoadConfig(szPath);

	g_hMainMenu = new Menu(VMainMenuHandler);
	g_hMainMenu.AddItem("", "Player Balances");
	g_hMainMenu.AddItem("", "Passives");
	g_hMainMenu.AddItem("", "Non-Passives");
	g_hMainMenu.AddItem("", "Transfer Money");
	g_hMainMenu.AddItem("", "Team Improvements");
	g_hMainMenu.AddItem("", "Shop");
	g_hMainMenu.SetTitle("Skills: Main Menu");
	
	g_hPerksActive = new Menu(VPerksHandler);
	g_hPerksActive.SetTitle("Skills: Non - Passive Perks");
	g_hPerksActive.ExitBackButton = true;
	
	g_hPerksPassive = new Menu(VPerksHandler);
	g_hPerksPassive.SetTitle("Skills: Passives Perks");
	g_hPerksPassive.ExitBackButton = true;
	
	RegConsoleCmd("sm_skills", cMainMenu);
	RegAdminCmd("sm_skills_admin", cAdmin, ADMFLAG_ROOT);
	RegAdminCmd("sm_sa", cAdmin, ADMFLAG_ROOT);
	RegAdminCmd("sm_reload_perks", cConfReload, ADMFLAG_ROOT);
	
	AddCommandListener(HookPlayerChat, "say");
	
	HookEvent("player_death", Event_Player_Death);
	//HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("round_end", Event_Round_End);
	HookEvent("round_start", Round_Start);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("witch_harasser_set", Event_WitchHarasserSet);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("finale_win", Event_ReportScreen);
	if(EnableFFDetection)
		HookEvent("friendly_fire", Event_FriendlyFire);
	else
		UnhookEvent("friendly_fire", Event_FriendlyFire);
}

public void OnMapStart()
{
	char szMap[56];
	GetCurrentMap(szMap, sizeof(szMap));
	
	if (StrContains(szMap, "m1") == -1)
		return;

	Call_StartForward(g_hPerkReset);
	Call_Finish();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iPlayerBalance[i] = 0;
		g_bHookChat[i] = false;
		g_iTarget[i] = 0;
		g_friendlyfire[i] = 0;
	}
	g_iTeamBalance = 0;
}

public void Event_FriendlyFire(Event event, const char[] name, bool dontbroadcast)
{
	if(EnableFFDetection)
	{
		int victim = GetClientOfUserId(event.GetInt("victim"));
		int attacker = GetClientOfUserId(event.GetInt("guilty"));
		if (bIsValidClient(attacker) && bIsValidClient(victim) && IsPlayerAlive(attacker))
		{
			g_friendlyfire[attacker] += 1;
			SetStringMapV(attacker, g_friendlyfire[attacker], true);
			PrintToChat(attacker, "\x01Friendly Fire count:\x03 %i", g_friendlyfire[attacker]);
		}
	}
}
public void Event_ReportScreen(Event event, const char[] name, bool dontbroadcast)
{
	char sName[MAX_NAME_LENGTH];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (bIsValidClient(i))
		{
			GetClientName(i, sName, sizeof(sName));
			int FF_count = g_friendlyfire[i];
			PrintToChatAll("\x04%s \x05Friendly Fire: \x03 %i", sName, FF_count);
		}
	}
}

public void Round_Start(Event event, const char[] name, bool dontbroadcast)
{
	if (EnableAssist)
	{
		ClearAllDmg();
	}
}

public Action Event_PlayerHurt(Event event, char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    float damage = event.GetFloat("dmg_health");
    if (!(1 <= attacker <= MaxClients))
		return Plugin_Continue;
	if (!(bIsValidClient(victim) && bIsValidClient(attacker)))
		return Plugin_Continue;
    if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) != 2)
	{
		if ((victim != 0) && (attacker != 0))
		{
			if(GetClientTeam(attacker) != 3 && GetClientTeam(victim) == 3)
			{
				int DamageHealth = RoundToCeil(damage);
				if (victim != attacker && GetClientTeam(victim) != GetClientTeam(attacker) && IS_INFECTED_ALIVE(victim))
				{
					Damage[attacker][victim] += DamageHealth;
					g_iTeamBalance += RoundToCeil(DamageHealth * TeamMultiplier);
					return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	if (!IsValidClient(client, TEAM_SURVIVOR) || IsFakeClient(client)) return;
	if (!SetStringMapV(client, 0, false))
	{
		int balance = GetStringMapV(client);
		if (balance > 0)
		{
			g_iPlayerBalance[client] = balance;
		}
	}
	if (!SetStringMapVFF(client, 0, false))
	{
		int ff = GetStringMapVFF(client);
		if (ff > 0)
		{
			g_friendlyfire[client] = ff;
		}
	}
	return;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!(1 <= attacker <= MaxClients))
		return Plugin_Continue;
	if (!(bIsValidClient(victim) && bIsValidClient(attacker)))
		return Plugin_Continue;
    if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
	{
		if ((victim != 0) && (attacker != 0))
		{
			int DamageHealth = RoundToCeil(damage);
			if (victim != attacker && GetClientTeam(victim) != GetClientTeam(attacker) && IS_INFECTED_ALIVE(victim) && DamageHealth > 1)
			{
				Damage[attacker][victim] += DamageHealth;
				g_iTeamBalance += RoundToCeil(DamageHealth * TeamMultiplier);
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}

public void Event_Player_Death(Event event, const char[] name, bool dontbroadcast)
{	
	float iResult;
	
	if (EnableAssist)
	{
		int victim = GetClientOfUserId(event.GetInt("userid"));
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (!(bIsValidClient(victim) && bIsValidClient(attacker)))
			return;
		int iClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
		int hitgroup = GetEventInt(event, "headshot");
		int type = GetEventInt(event, "type");

		char Message[256];
		char MsgAssist[256];
		
		if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) == 2)
		{
			char sName[MAX_NAME_LENGTH];
			GetClientName(attacker, sName, sizeof(sName));
			char sDamage[10], MoneyEarn[9];	
			int maxHP = GetEntProp(victim, Prop_Send, "m_iMaxHealth");
			int iDamage = Damage[attacker][victim];
			IntToString(iDamage, sDamage, sizeof(sDamage));
			if(iDamage > (maxHP + 150))
			{
				iResult = maxHP * g_iRewardKill[iClass];
			}
			else
			{
				iResult = iDamage * g_iRewardKill[iClass];					
			}
			Damage[attacker][victim] = 0;
			g_iPlayerBalance[attacker] = RoundToCeil(iResult) + g_iPlayerBalance[attacker] + SpecInfecBonus;
			SetStringMapV(attacker, g_iPlayerBalance[attacker], true);
			IntToString((RoundToCeil(iResult) + SpecInfecBonus), MoneyEarn, sizeof(MoneyEarn));
			StrCat(Message, sizeof(Message), sName);
			StrCat(Message, sizeof(Message), Temp6);
			StrCat(Message, sizeof(Message), Temp3);
			StrCat(Message, sizeof(Message), sDamage);
			StrCat(Message, sizeof(Message), Temp4);
			StrCat(Message, sizeof(Message), Temp7);
			StrCat(Message, sizeof(Message), MoneyEarn);
			StrCat(Message, sizeof(Message), Temp8);
			
			for (int i = 0; i <= MAXPLAYERS; i++)
			{
				if (Damage[i][victim] > 0)
				{
					if (i != attacker)
					{
						AssistFlag = true;
						char tName[MAX_NAME_LENGTH];
						GetClientName(i, tName, sizeof(tName));
						char tDamage[10], MoneyEarnA[9];
						if(Damage[i][victim] > maxHP)
						{
							IntToString(maxHP, sDamage, sizeof(sDamage));
							iResult = maxHP * g_iRewardKill[iClass];
						}
						else
						{
							IntToString(Damage[i][victim], tDamage, sizeof(tDamage));
							iResult = Damage[i][victim] * g_iRewardKill[iClass];
						}
						IntToString(RoundToCeil(iResult), MoneyEarnA, sizeof(MoneyEarnA));
						g_iPlayerBalance[i] = RoundToCeil(iResult) + g_iPlayerBalance[i];
						SetStringMapV(i, g_iPlayerBalance[i], true);
						StrCat(MsgAssist, sizeof(MsgAssist), Temp5);
						StrCat(MsgAssist, sizeof(MsgAssist), tName);
						StrCat(MsgAssist, sizeof(MsgAssist), Temp6);
						StrCat(MsgAssist, sizeof(MsgAssist), Temp3);
						StrCat(MsgAssist, sizeof(MsgAssist), tDamage);
						StrCat(MsgAssist, sizeof(MsgAssist), Temp4);
						StrCat(MsgAssist, sizeof(MsgAssist), Temp7);
						StrCat(MsgAssist, sizeof(MsgAssist), MoneyEarnA);
						StrCat(MsgAssist, sizeof(MsgAssist), Temp8);
						StrCat(MsgAssist, sizeof(MsgAssist), Temp2);							
					}
				}
				Damage[i][victim] = 0;
			}

			if (AssistFlag == true) 
			{
				strcopy(MsgAssist,strlen(MsgAssist)-1,MsgAssist);
				StrCat(Message, sizeof(Message), Temp1);
				StrCat(Message, sizeof(Message), MsgAssist);
				AssistFlag = false;
			}
			if (hitgroup == 1 && type != 8) // 8 == death by fire
			{  
				PrintToChatAll("\x04%N\x01 killed by a \x05headshot\x01 from \x04%s.", victim, Message);
			}
			else
			{
				PrintToChatAll("\x04%N\x01 got killed by \x04%s.", victim, Message);
			}
		}
		for (int i = 0; i <= MAXPLAYERS; i++)
		{
			Damage[i][victim] = 0;
		}
	}
	return;
}


public void Event_Round_End(Event event, const char[] name, bool dontbroadcast)
{
	if (EnableAssist)
	{
		ClearAllDmg();
	}
}

public void Event_WitchSpawn(Event event, const char[] name, bool dontbroadcast)
{
	if (EnableAssist && EnableWitch)
	{
		int witch = GetClientOfUserId(event.GetInt("witchid"));
		if (IsValidEntity(witch) && IsValidEdict(witch)) 
		{
			ClearDmgWitch();
		}
	}
}

public void Event_WitchKilled(Event event, const char[] name, bool dontbroadcast)
{
	float iResult;
	if (EnableAssist && EnableWitch)
	{
		int witch = GetClientOfUserId(event.GetInt("witchid"));
		int witchCheck = GetEventInt(event,"witchid");
		int killer = GetClientOfUserId(event.GetInt("userid"));
		int hitgroup = GetEventInt(event, "headshot");
		int type = GetEventInt(event, "type");
		if (IsValidEntity(witch) && IsValidEdict(witch))
		{
			if (GetEventBool(event, "oneshot"))
			{
				char sName[MAX_NAME_LENGTH];
				GetClientName(killer, sName, sizeof(sName));
				PrintToChatAll("\x04Witch\x01 got Crowned by \x04%s and earn \x03%i \x04money", sName, g_iRewardCrown);
				g_iPlayerBalance[killer] += g_iRewardCrown;
				SetStringMapV(killer, g_iPlayerBalance[killer], true);
				ClearDmgWitch();
			}
			else
			{
				char WMessage[256];
				char WMsgAssist[256];
				if (IsWitch(witchCheck))
				{
					char killerName[MAX_NAME_LENGTH];
					GetClientName(killer, killerName, sizeof(killerName));
					char killerDamage[10], wMoneyEarn[9], wMoneyEarnA[9];
					IntToString(DamageWitch[killer][witch], killerDamage, sizeof(killerDamage));
					iResult = DamageWitch[killer][witch] * g_iRewardKill[7];
					g_iPlayerBalance[killer] = RoundToCeil(iResult) + g_iPlayerBalance[killer] + WitchKBonus;
					SetStringMapV(killer, g_iPlayerBalance[killer], true);
					IntToString((RoundToCeil(iResult) + WitchKBonus), wMoneyEarn, sizeof(wMoneyEarn));
					StrCat(WMessage, sizeof(WMessage), killerName);
					StrCat(WMessage, sizeof(WMessage), Temp6);
					StrCat(WMessage, sizeof(WMessage), Temp3);
					StrCat(WMessage, sizeof(WMessage), killerDamage);
					StrCat(WMessage, sizeof(WMessage), Temp4);
					StrCat(WMessage, sizeof(WMessage), Temp7);
					StrCat(WMessage, sizeof(WMessage), wMoneyEarn);
					StrCat(WMessage, sizeof(WMessage), Temp8);
					
					for (int i = 0; i <= MAXPLAYERS; i++)
					{
						if (DamageWitch[i][witch] > 0)
						{
							if (i != killer)
							{
								WitchAssistFlag = true;
								
								char AssistName[MAX_NAME_LENGTH];
								GetClientName(i, AssistName, sizeof(AssistName));
								char AssistDamage[10];
								IntToString(DamageWitch[i][witch], AssistDamage, sizeof(AssistDamage));
								iResult = DamageWitch[i][witch] * g_iRewardKill[7];
								g_iPlayerBalance[i] = RoundToCeil(iResult) + g_iPlayerBalance[i];
								SetStringMapV(i, g_iPlayerBalance[i], true);
								IntToString(RoundToCeil(iResult), wMoneyEarnA, sizeof(wMoneyEarn));
								StrCat(WMsgAssist, sizeof(WMsgAssist), Temp5);
								StrCat(WMsgAssist, sizeof(WMsgAssist), AssistName);
								StrCat(WMsgAssist, sizeof(WMsgAssist), Temp6);
								StrCat(WMsgAssist, sizeof(WMsgAssist), Temp3);
								StrCat(WMsgAssist, sizeof(WMsgAssist), AssistDamage);
								StrCat(WMsgAssist, sizeof(WMsgAssist), Temp4);
								StrCat(WMsgAssist, sizeof(WMsgAssist), Temp7);
								StrCat(WMsgAssist, sizeof(WMsgAssist), wMoneyEarnA);
								StrCat(WMsgAssist, sizeof(WMsgAssist), Temp8);
								StrCat(WMsgAssist, sizeof(WMsgAssist), Temp2);
								
							}
						}
						DamageWitch[i][witch] = 0;
					}
					if (WitchAssistFlag == true) 
					{
						strcopy(WMsgAssist,strlen(WMsgAssist)-1,WMsgAssist);
						StrCat(WMessage, sizeof(WMessage), Temp1);
						StrCat(WMessage, sizeof(WMessage), WMsgAssist);
						WitchAssistFlag = false;
					}
					if (hitgroup == 1 && type != 8) // 8 == death by fire
					{  
						PrintToChatAll("\x04Witch\x01 killed by a \x05headshot\x01 from \x04%s.", WMessage);
					}
					else
					{
						PrintToChatAll("\x04Witch\x01 got killed by \x04%s.", WMessage);
					}
				}	
			}
			
		}
		else
		{
			ClearDmgWitch();
		}
	}
	return;
}

public void Event_InfectedHurt(Event event, const char[] name, bool dontbroadcast)
{
	if (EnableAssist && EnableWitch)
	{		
		int witch = GetEventInt(event, "entityid");		
		char class[64];
		GetEdictClassname(witch, class, sizeof(class));
		if (!StrEqual(class, "witch", false)) return;
		int CWitch = GetClientOfUserId(event.GetInt("entityid"));
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (IsValidClient(attacker, TEAM_SURVIVOR))
		{
			int damage = GetEventInt(event, "amount");
			DamageWitch[attacker][CWitch] += damage;			
		}
	}
}

public void ClearDmgWitch()
{	
	for (int i = 0; i <= MAXPLAYERS; i++)
		{
			for (int a = 1; a <= MAXPLAYERS; a++)
			{
				DamageWitch[i][a] = 0;
			}
		}
}
public void ClearAllDmg()
{
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		for (int a = 1; a <= MaxClients; a++)
		{
			Damage[i][a] = 0;
			DamageWitch[i][a] = 0;

		}
	}
}
public void Event_WitchHarasserSet(Event event, const char[] name, bool dontbroadcast)
{
	if (EnableAssist && EnableWitch)
	{
		int target = GetClientOfUserId(event.GetInt("userid"));
		char alerter[MAX_NAME_LENGTH];
		GetClientName(target, alerter, sizeof(alerter));
		if (IsValidClient(target, TEAM_SURVIVOR))
		{
				PrintToChatAll("\x04%s\x01 Startled the \x03Witch", alerter);
		}
	}
}

public void OnEntityDestroyed(int entity) //escaped or burned
{
	if (EnableAssist && EnableWitch)
	{
		if (IsValidEntity(entity) && IsValidEdict(entity))
		{
			char class[64];
			GetEdictClassname(entity, class, sizeof(class));						
			if (StrEqual(class, "witch"))
			{
				ClearDmgWitch();
			}
		}
	}
}

public bool IsValidClient(int client, int team)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == team;
}

public bool IsClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

public bool IsWitch(int client)
{
	char class[64];
	GetEdictClassname(client, class, sizeof(class));						
    if (StrEqual(class, "witch"))
    {
        return true;
    }
    return false;
}

public Action cAdmin (int client, int args)
{
	if (!client)
		return Plugin_Handled;
	
	g_hAdminMenu = new Menu (VAdminMenuHandler);
	g_hAdminMenu.AddItem("GIVE_MONEY", "Give Money");
	g_hAdminMenu.AddItem("SET_MONEY", "Set Money");
	g_hAdminMenu.AddItem("MONEY_TEAM", "Set Team Money");
	g_hAdminMenu.SetTitle("Skills : Admin Menu");
	g_hAdminMenu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int VAdminMenuHandler (Menu menu, MenuAction action, int client, int index)
{
	if (action == MenuAction_Cancel)
	{
		if (index == MenuCancel_ExitBack)
			g_hAdminMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Select)
	{
		char szItem[36];
		menu.GetItem(index, szItem, sizeof szItem);
		
		if (ReplaceString(szItem, sizeof szItem, "_MONEY", "") > 0)
			AdminMenu(client, index);
		else if (ReplaceString(szItem, sizeof szItem, "SETMONEY_", "") > 0 || ReplaceString(szItem, sizeof szItem, "GIVEMONEY_", "") > 0)
		{
			PrintToChat(client, "%s \x04Print to \x03chat \x04number", CHAT_TAG);
			g_bHookChat[client] = true;
			g_iTarget[client] = StringToInt(szItem);
		}
		else if (ReplaceString(szItem, sizeof szItem, "MONEY_TEAM", "") > 0)
		{
			PrintToChat(client, "%s \x04Print to \x03chat \x04number", CHAT_TAG);
			g_bHookChat[client] = true;
			g_iTarget[client] = 666;
		}
	}
}

void AdminMenu (int client, int index)
{
	g_hAdminMenu = new Menu (VAdminMenuHandler);
	
	char szTemp[64], szBuffer[36];
	
	if (!index || index == 1)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != 2 || IsFakeClient(i))
				continue;
			
			Format(szTemp, sizeof szTemp, "%N", i);
			Format(szBuffer, sizeof szBuffer, "%s_%i", view_as<bool>(index) ? "SETMONEY" : "GIVEMONEY", view_as<bool>(index) ? (GetClientUserId(i) + 999) : (GetClientUserId(i) + 666));
			
			g_hAdminMenu.AddItem(szBuffer, szTemp);
		}
		if (!index) g_hAdminMenu.SetTitle("Skills : Admin Give Money");
		else g_hAdminMenu.SetTitle("Skills : Admin Set Money");
	}
	g_hAdminMenu.Display(client, MENU_TIME_FOREVER);
}

public Action cConfReload (int client, int args)
{
	if (!client)
		return Plugin_Handled;
	
	g_hReload = new Menu (VReloadHandler);
	g_hReload.AddItem("ReloadOnePerk", "Reload config for 1 perk");
	g_hReload.AddItem("ReloadAllSettings", "Reload all settings");
	g_hReload.SetTitle("Skills : Reload Menu");
	g_hReload.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int VReloadHandler(Menu menu, MenuAction action, int client, int index)
{
	if (action == MenuAction_Cancel)
	{
		if (index == MenuCancel_ExitBack)
			cConfReload(client, 0);
	}
	else if (action == MenuAction_Select)
	{
		char szMenuItem[MAXPERKNAME], szExploded[3][MAXPERKNAME];
		menu.GetItem(index, szMenuItem, sizeof szMenuItem);
		
		if (ReplaceString(szMenuItem, sizeof szMenuItem, "ReloadAllSettings", "") > 0)
		{
			iReloadReType iResult;
			Call_StartForward(g_hReloadConfig);
			Call_PushString("666");
			Call_Finish(iResult);
			
			PrintToChat(client, "%s \x04Start reloading all \x03settings", CHAT_TAG);
		}
		else if (ReplaceString(szMenuItem, sizeof szMenuItem, "ReloadOnePerk", "") > 0)
		{
			int i;
			g_hReload = new Menu (VReloadHandler);
			g_hReload.AddItem("ReloadAllSettings", "Core");
			
			for (i = 0; i <= g_hPerksActive.ItemCount; i++)
			{
				if (!g_hPerksActive.GetItem(i, szMenuItem, sizeof szMenuItem))
					break;

				ExplodeString(szMenuItem, "|", szExploded, sizeof szExploded, sizeof szExploded[]);
				Format(szMenuItem, sizeof szMenuItem, "RELOADTHIS_%s", szExploded[0]);
				g_hReload.AddItem(szMenuItem, szExploded[0]);		
			}
			
			for (i = 0; i <= g_hPerksPassive.ItemCount; i++)
			{
				if (!g_hPerksPassive.GetItem(i, szMenuItem, sizeof szMenuItem))
					break;
					
				ExplodeString(szMenuItem, "|", szExploded, sizeof szExploded, sizeof szExploded[]);
				Format(szMenuItem, sizeof szMenuItem, "RELOADTHIS_%s", szExploded[0]);
				g_hReload.AddItem(szMenuItem, szExploded[0]);
			}
			
			g_hReload.SetTitle("Skills : Select a perk");
			g_hReload.ExitBackButton = true;
			g_hReload.Display(client, MENU_TIME_FOREVER);
		}
		else if (ReplaceString(szMenuItem, sizeof szMenuItem, "RELOADTHIS_", "") > 0)
		{
			iReloadReType iResult;
			
			Call_StartForward(g_hReloadConfig);
			Call_PushString(szMenuItem);
			Call_Finish(iResult);
			
			ReloadResult(client, iResult, szMenuItem);
		}
	}
}

public Action cMainMenu (int client, int args)
{
	if (!client)
		return Plugin_Handled;
		
	g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	PrintToChat(client, "%s \x01\x04Your money \x01- \x03%i", CHAT_TAG, g_iPlayerBalance[client]);
	return Plugin_Handled;
}

public Action HookPlayerChat(int iClient, const char[] sCommand, int iArgs) 
{ 
	if (strcmp(sCommand, "say") == 0 || strcmp(sCommand, "say_team") == 0)
	{
		if(g_bHookChat[iClient])
		{
			char sArg[56];
			GetCmdArg(1, sArg, sizeof(sArg));
			
			if(strcmp(sArg, "reset") == 0)
				PrintToChat(iClient, "%s \x04Cancled", CHAT_TAG);
			else
			{
				if (g_iTarget[iClient] == 666)
				{
					g_iTeamBalance = StringToInt(sArg);
					g_iTarget[iClient] = 0;
					PrintToChatAll("%s \x04Admin \x05%N \x04set \x02team money \x04to \x03%i", CHAT_TAG, iClient, StringToInt(sArg));
					g_bHookChat[iClient] = false;
					return Plugin_Handled;
				}
				//for (int i = 1; i < sizeof sArg - 1; i++)
				//{
				//	if (!IsCharNumeric(sArg[i]))
				//	{
				//		PrintToChat(iClient, "%s \x04Don't use \x03non numeric \x04symbols", CHAT_TAG);
				//		g_bHookChat[iClient] = false;
				//		return Plugin_Handled;
				//	}
				//}
				
				int iCount = StringToInt(sArg);
				int iTarget = g_iTarget[iClient];
				if (iTarget <= 0 || iTarget > MAXPLAYERS+1)
				{
					if (iTarget < 999)
					{
						int Target_id = g_iTarget[iClient] - 666;
						iTarget = GetClientOfUserId(Target_id);
						if (iTarget <= 0 || iTarget > MaxClients)
						{
							PrintToChat(iClient, "%s \x04Target is \x03invalid", CHAT_TAG);
							g_bHookChat[iClient] = false;
							g_iTarget[iClient] = 0;
							return Plugin_Handled;
						}
						else
						{
							g_iPlayerBalance[iTarget] += iCount;
							PrintToChatAll("%s \x04Admin \x03%N \x04has give money player \x02%N \x03%i", CHAT_TAG, iClient, iTarget, iCount);
							g_bHookChat[iClient] = false;
							g_iTarget[iClient] = 0;
							return Plugin_Handled;
						}
					}
					else
					{
						if (iTarget > 1000)
							iTarget -= 1000;
						g_iPlayerBalance[iTarget] = iCount;
						PrintToChatAll("%s \x04Admin \x03%N \x04has set money player \x05%N \x04to \x03%i", CHAT_TAG, iClient, iTarget, iCount);
						g_bHookChat[iClient] = false;
						g_iTarget[iClient] = 0;
						return Plugin_Handled;
					}
				}
				
				if (iCount <= 0)
				{
					PrintToChat(iClient, "%s \x01\x04What \x03are you doing?", CHAT_TAG);
					g_bHookChat[iClient] = false;
					return Plugin_Handled;
				}
				
				if (g_iPlayerBalance[iClient] < iCount)
				{
					PrintToChat(iClient, "\x01\x04You don't have that much \x03money");
					g_bHookChat[iClient] = false;
					return Plugin_Handled;
				}
				
				g_iPlayerBalance[iClient] -= iCount;
				SetStringMapV(iClient, g_iPlayerBalance[iClient], true);
				g_iPlayerBalance[iTarget] += iCount;
				SetStringMapV(iTarget, g_iPlayerBalance[iTarget], true);
				PrintHintText(iTarget, "%N transfered to you %i money", iClient, iCount);
				PrintHintText(iClient, "You transfered to %N %i money", iTarget, iCount);
			}
			g_iTarget[iClient] = 0;
			g_bHookChat[iClient] = false;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public int VMainMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if (index == 1)
			g_hPerksPassive.Display(client, MENU_TIME_FOREVER);
		else if (index == 2) 
			g_hPerksActive.Display(client, MENU_TIME_FOREVER);
		else
			SwitchMenu(client, index);
	}
}

public int VPerksHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_Select )
	{
		char szItemMenu[MAXPERKNAME], szExploded[3][MAXPERKNAME];
		GetMenuItem(menu, index, szItemMenu, MAXPERKNAME);
		
		ExplodeString(szItemMenu, "|", szExploded, sizeof szExploded, sizeof szExploded[]);
		
		int iCost = StringToInt(szExploded[1]);
		
		if (g_iPlayerBalance[client] < iCost)
		{
			PrintToChat(client, "%s \x01\x04You \x03don't have enough \x02money", CHAT_TAG);
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
			return;
		}
		
		int iResult;
		
		Call_StartForward(g_hPerkStateChanged);
		Call_PushCell(client);
		Call_PushString(szExploded[0]);
		Call_Finish(iResult);
		
		if (iResult == 0)
			return;
		
		g_iPlayerBalance[client] -= iResult;
		SetStringMapV(client, g_iPlayerBalance[client], true);
		g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	}
}

public int VSwitchHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			g_hMainMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_Select )
	{
		char szMenuItem[64];
		GetMenuItem(menu, index, szMenuItem, sizeof szMenuItem);
		
		if (ReplaceString(szMenuItem, sizeof szMenuItem, "TransferMoney_", "") > 0)
		{
			g_bHookChat[client] = true;
			g_iTarget[client] = StringToInt(szMenuItem);
			PrintToChatAll("Target number is %i", g_iTarget[client]);
			PrintToChat(client, "%s \x01\x04Print to chat number of \x03money", CHAT_TAG);
		}
		else if (ReplaceString(szMenuItem, sizeof szMenuItem, "Teamupgrade_", "") > 0)
		{
			index = StringToInt(szMenuItem) - 1;
			
			if (g_iTeamBalance < g_iTeamCosts[index])
			{
				PrintToChat(client, "%s \x03Not enough team money, \x04%i \x03team money need", CHAT_TAG, g_iTeamCosts[index] - g_iTeamBalance);
				return;
			}
			
			switch (index)
			{
				case 0:
				{
					if (g_hTimerHealth == null)
						g_hTimerHealth = CreateTimer(g_flHealInterval, tHeal, _, TIMER_REPEAT);
					else
					{
						PrintToChat(client, "%s \x01\x04Health \x03already regenerate", CHAT_TAG);
						return;
					}
				}
				case 1:
				{
					for (int i = MaxClients; i <= 2048; i++)
					{
						if (!IsValidEntity(i))
							continue;
						
						char szClass[36];
						GetEntityClassname(i, szClass, sizeof szClass);
						
						if (strcmp(szClass, "infected") == 0)
							ForceDamageEntity(client, 1000, i);
					}
					PrintToChatAll("%s \x04%N \x03killed \x02all commons \x03for teamcash remained \x04%i", CHAT_TAG, client, g_iTeamBalance - g_iTeamCosts[index]);
				}
				case 2:
				{
					if (g_hTimerPoison == null)
						g_hTimerPoison = CreateTimer(g_flPoisonInterval, tPoison, GetClientUserId(client), TIMER_REPEAT);
					else
					{
						PrintToChat(client, "%s \x01\x04Poison \x03already deals damage", CHAT_TAG);
						return;
					}
				}
				case 3:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) != 2)
							continue;
							
						int iHealth = GetClientHealth(i);
						
						if (iHealth + g_iHealTeamCount > g_iMaxHeal)
							SetEntityHealth(i, g_iMaxHeal);
						else
							SetEntityHealth(i, iHealth + g_iHealTeamCount);
					}
				}
				case 4:
				{
					for (int i = 1; i <= MaxClients; i++)
						if (IsClientInGame(i) && GetClientTeam(i) == 2)
							GiveFunction(i, "ammo");

					PrintToChatAll("%s \x01\x04%N \x03bought ammo for all players", CHAT_TAG, client);
				}
				case 5:
				{
					if (!MeleeRangeUpgrade)
					{
						MeleeRangeUpgrade = true;
						if( g_bCvarAllow == false )
						{
							g_bCvarAllow = true;
							g_iStockRange = g_hCvarMeleeRange.IntValue;

							if( !DHookEnableDetour(g_hDetour, false, TestMeleeSwingCollisionPre) )
								SetFailState("Failed to detour pre \"CTerrorMeleeWeapon::TestMeleeSwingCollision\".");

							if( !DHookEnableDetour(g_hDetour, true, TestMeleeSwingCollisionPost) )
								SetFailState("Failed to detour post \"CTerrorMeleeWeapon::TestMeleeSwingCollision\".");
						}
						else
						{
							g_bCvarAllow = false;
							g_hCvarMeleeRange.SetInt(g_iStockRange);

							if( !DHookDisableDetour(g_hDetour, false, TestMeleeSwingCollisionPre) )
								SetFailState("Failed to disable detour pre \"CTerrorMeleeWeapon::TestMeleeSwingCollision\".");

							if( !DHookDisableDetour(g_hDetour, true, TestMeleeSwingCollisionPost) )
								SetFailState("Failed to disable detour post \"CTerrorMeleeWeapon::TestMeleeSwingCollision\".");
						}
						PrintToChatAll("%s \x01\x04%N \x03bought Melee Range Upgrade for all players", CHAT_TAG, client);
					}
					else
					{
						PrintToChat(client, "%s\x03You already own \x01\x04Melee Range", CHAT_TAG);
						return;
					}
				}
			}
			
			g_iTeamBalance -= g_iTeamCosts[index];
		}
		else if (ReplaceString(szMenuItem, sizeof szMenuItem, "Shop_", "") > 0)
		{
			index = StringToInt(szMenuItem);
			
			if (g_iPlayerBalance[client] < g_iShop[index - 1])
			{
				PrintToChat(client, "%s \x03Not enough money, \x04%i \x03money need", CHAT_TAG, g_iShop[index - 1] - g_iPlayerBalance[client]);
				return;
			}
			
			GiveUpgrade(client, index);
			g_iPlayerBalance[client] -= g_iShop[index - 1];
			SetStringMapV(client, g_iPlayerBalance[client], true);
		}
		else if (ReplaceString(szMenuItem, sizeof szMenuItem, "AMMO_BOX_", "") > 0)
		{
			index = StringToInt(szMenuItem) - 1;
			
			if (g_iPlayerBalance[client] < g_iBoxesAmmo[index])
			{
				PrintToChat(client, "%s \x03Not enough money, \x04%i \x03money need", CHAT_TAG, g_iBoxesAmmo[index] - g_iPlayerBalance[client]);
				return;
			}
			
			switch (index)
			{
				case 0: GiveFunction(client, "upgradepack_explosive");
				case 1: GiveFunction(client, "upgradepack_incendiary");
			}
			
			g_iPlayerBalance[client] -= g_iBoxesAmmo[index];
			SetStringMapV(client, g_iPlayerBalance[client], true);
		}
	}
}

public Action tPoison (Handle timer, any client)
{
	static float flTime;
	
	if (flTime == 0.0)
		flTime = GetGameTime();
	
	if (GetGameTime() - flTime >= g_flPoisonTime)
	{
		flTime = 0.0;
		PrintToChatAll("%s \x01\x04Poison \x03stops deals damage", CHAT_TAG);
		g_hTimerPoison = null;
		return Plugin_Stop;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 3)
			continue;
			
		ForceDamageEntity(GetClientOfUserId(client), g_iPoisonDamage, i);
	}
	return Plugin_Continue;
}

public Action tHeal (Handle timer)
{
	static float flTime;
	
	if (flTime == 0.0)
		flTime = GetGameTime();
	
	if (GetGameTime() - flTime >= g_flHealTime)
	{
		flTime = 0.0;
		PrintToChatAll("%s \x01\x04Health \x03stops regenerate", CHAT_TAG);
		g_hTimerHealth = null;
		return Plugin_Stop;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
		
		int iHealth = GetClientHealth(i);
		
		if (iHealth + g_iHealCount > g_iMaxHealCount)
			SetEntityHealth(i, g_iMaxHealCount);
		else
			SetEntityHealth(i, GetClientHealth(i) + g_iHealCount);
	}
	return Plugin_Continue;
}

void SwitchMenu(int client, int index)
{
	char szTemp[64];
	g_hSwitchMenu = new Menu(VSwitchHandler);
	
	switch (index)
	{
		case 0: 
		{
			Format(szTemp, sizeof szTemp, "Your money - %i", g_iPlayerBalance[client]);
			g_hSwitchMenu.AddItem("", szTemp, ITEMDRAW_DISABLED);
			Format(szTemp, sizeof szTemp, "Team money - %i", g_iTeamBalance);
			g_hSwitchMenu.AddItem("", szTemp, ITEMDRAW_DISABLED);
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || GetClientTeam(i) != 2 || IsFakeClient(i) || client == i)
					continue;
					
				Format(szTemp, sizeof szTemp, "%N - %i", i, g_iPlayerBalance[i]);
				g_hSwitchMenu.AddItem("", szTemp, ITEMDRAW_DISABLED);
			}
			g_hSwitchMenu.SetTitle("Skills: Check Players Money");
		}
		case 3:
		{
			bool bAlone = true;
			char szIndex[16];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || GetClientTeam(i) != 2 || IsFakeClient(i) || i == client)
					continue;
				
				Format(szIndex, sizeof szIndex, "TransferMoney_%i", GetClientUserId(i));
				Format(szTemp, sizeof szTemp, "%N", i);
				
				g_hSwitchMenu.AddItem(szIndex, szTemp);
				bAlone = false;
			}
			
			if (bAlone)
			{
				PrintToChat(client, "%s \x04On the server there are no \x03players \x04for the \x03survivors \x04except \x02you", CHAT_TAG);
				return;
			}
			
			g_hSwitchMenu.SetTitle("Skills: Transfer Money");
		}
		case 4:
		{
			g_hSwitchMenu.AddItem("Teamupgrade_1", "Renegerate Health");
			g_hSwitchMenu.AddItem("Teamupgrade_2", "Kill Commons");
			g_hSwitchMenu.AddItem("Teamupgrade_3", "Poison Specials");
			g_hSwitchMenu.AddItem("Teamupgrade_4", "Heal Survivors");
			g_hSwitchMenu.AddItem("Teamupgrade_5", "Buy Ammo");
			g_hSwitchMenu.AddItem("Teamupgrade_6", "Melee Range++");
			//g_hSwitchMenu.AddItem("Teamupgrade_7", "Gravity Reduce");
			g_hSwitchMenu.SetTitle("Skills: Team Improvements");
		}
		case 5:
		{
			g_hSwitchMenu.AddItem("Shop_3", "Laser Sight");
			g_hSwitchMenu.AddItem("Shop_1", "Explosive Ammo");
			g_hSwitchMenu.AddItem("Shop_2", "Incediary Ammo");
			g_hSwitchMenu.AddItem("AMMO_BOX_1", "Explosive Ammo Box");
			g_hSwitchMenu.AddItem("AMMO_BOX_2", "Incediary Ammo Box");
			g_hSwitchMenu.SetTitle("Skills: Shop");
		}
	}
	
	g_hSwitchMenu.ExitBackButton = true;
	g_hSwitchMenu.Display(client, MENU_TIME_FOREVER);
}

void LoadConfig(const char[] szPath)
{
	KeyValues hFile = new KeyValues("Data");
	
	if(!hFile.ImportFromFile(szPath))
	{
		LogError("Invalid import %s", szPath);
		return;
	}
	char szTemp[4];
	if (hFile.JumpToKey("Reward For Kill"))
	{
		g_iRewardCrown = hFile.GetNum("Reward for oneshot witch");
		for (int i = 1; i <= 8; i++)
		{
			IntToString(i, szTemp, sizeof szTemp);
			g_iRewardKill[i] = hFile.GetFloat(szTemp);
		}
		hFile.GoBack();
	}
	else
		LogError("Warning! No key \"Reward For Kill\", plugin cant setup costs");
		
	if (hFile.JumpToKey("Team Improvements"))
	{
		g_iHealCount = hFile.GetNum("Heal Count");
		g_iMaxHealCount = hFile.GetNum("Max Heal Count Regenerate");
		g_flHealInterval = hFile.GetFloat("Heal Interval");
		g_flHealTime = hFile.GetFloat("Heal Time");
		
		g_flPoisonInterval = hFile.GetFloat("Poison Damage");
		g_flPoisonTime = hFile.GetFloat("Poison Interval");
		g_iPoisonDamage = hFile.GetNum("Poison Time");
		
		g_iHealTeamCount = hFile.GetNum("Heal Survivors Count");
		
		g_iMaxHeal = hFile.GetNum("Max Heal Survivors");
		
		g_iRange = hFile.GetNum("Melee Range");
		
		for (int i; i < TEAMUPGRADES; i++)
		{
			IntToString(i, szTemp, sizeof szTemp);
			g_iTeamCosts[i] = hFile.GetNum(szTemp);
		}
		hFile.GoBack();
	}
	else
		LogError("Warning! No key \"Team Improvements\", plugin can't setup costs");
	
	if (hFile.JumpToKey("Shop"))
	{
		g_iShop[0] = hFile.GetNum("Explosive Ammo");
		g_iShop[1] = hFile.GetNum("Incediary Ammo");
		g_iShop[2] = hFile.GetNum("Laser Sight");
		g_iBoxesAmmo[0] = hFile.GetNum("Explosive Ammo Box");
		g_iBoxesAmmo[1] = hFile.GetNum("Incediary Ammo Box");
		hFile.GoBack();
	}
	else
		LogError("Warning! No key \"Shop\", plugin can't setup costs");
	
	if (hFile.JumpToKey("Assist"))
	{
		EnableAssist = view_as<bool>(hFile.GetNum("EnableAssist"));
		EnableWitch = view_as<bool>(hFile.GetNum("EnableWitch"));
		EnableFFDetection = view_as<bool>(hFile.GetNum("EnableFFDetection", 1));
		SpecInfecBonus = hFile.GetNum("Killing Special Infected Bonus");
		WitchKBonus = hFile.GetNum("Killing Witch Bonus");
		TeamMultiplier = hFile.GetFloat("Team Multiplier");
	}
	else
		LogError("Warning! No key \"Assist\", plugin can't setup Assist System");
		
	hFile.Rewind();
	delete hFile;
}

void SetupConfig(const char[] szPath)
{
	KeyValues hFile = new KeyValues("Data");
	hFile.ImportFromFile(szPath);
	
	char szTemp[4];
	
	hFile.JumpToKey("Reward For Kill", true);
	hFile.SetNum("Reward for oneshot witch", 1000);
	for (int i = 1; i <= 8; i++)
	{
		IntToString(i, szTemp, sizeof szTemp);
		hFile.SetNum(szTemp, 2);
	}
	hFile.GoBack();
	
	hFile.JumpToKey("Team Improvements", true);
	
	hFile.SetNum("Heal Count", 5);
	hFile.SetNum("Max Heal Count Regenerate", 100);
	hFile.SetFloat("Heal Interval", 0.5);
	hFile.SetFloat("Heal Time", 10.0);
	
	hFile.SetNum("Poison Damage", 5);
	hFile.SetFloat("Poison Interval", 0.1);
	hFile.SetFloat("Poison Time", 10.0);
	
	hFile.SetNum("Heal Survivors Count", 75);
	hFile.SetNum("Max Heal Survivors", 100);

	hFile.SetNum("Melee Range", 120);
	
	for (int i; i < TEAMUPGRADES; i++)
	{
		IntToString(i, szTemp, sizeof szTemp);
		hFile.SetNum(szTemp, 2);
	}
	
	hFile.GoBack();
	hFile.JumpToKey("Shop", true);
	
	hFile.SetNum("Laser Sight", 500);
	hFile.SetNum("Explosive Ammo", 1000);
	hFile.SetNum("Incediary Ammo", 1000);
	hFile.SetNum("Explosive Ammo Box", 1000);
	hFile.SetNum("Incediary Ammo Box", 1000);
	hFile.GoBack();
	
	hFile.JumpToKey("Assist", true);
	hFile.SetNum("EnableAssist", 1);
	hFile.SetNum("EnableWitch", 1);
	hFile.SetNum("EnableFFDetection", 1);
	hFile.SetNum("Killing Special Infected Bonus", 50);
	hFile.SetNum("Killing Witch Bonus", 80);
	hFile.SetFloat("Team Multiplier", 0.33);

	
	hFile.Rewind();
	hFile.ExportToFile(szPath);
	delete hFile;
}

public bool SetStringMapV(int client, any Value, bool overwrite)
{
	if (!IsValidClient(client, TEAM_SURVIVOR) || IsFakeClient(client)) return false;
	int SteamID = GetSteamAccountID(client, true);
	char[] s_SteamID = new char[16];
	if (SteamID != 0)
	{
		IntToString(SteamID, s_SteamID, 16);
		g_smbalance.SetValue(s_SteamID, Value, overwrite);
		return true;
	}
	else
		return false;

}

public any GetStringMapV(int client)
{
	if (!IsValidClient(client, TEAM_SURVIVOR) || IsFakeClient(client)) return false;
	int SteamID = GetSteamAccountID(client, true);
	char[] s_SteamID = new char[16];
	if (SteamID != 0)
	{
		IntToString(SteamID, s_SteamID, 16);
		any value;
		g_smbalance.GetValue(s_SteamID, value);
		return value;
	}
	return false;
}

public bool SetStringMapVFF(int client, any Value, bool overwrite)
{
	if (!IsValidClient(client, TEAM_SURVIVOR) || IsFakeClient(client)) return false;
	int SteamID = GetSteamAccountID(client, true);
	char[] s_SteamID = new char[16];
	if (SteamID != 0)
	{
		IntToString(SteamID, s_SteamID, 16);
		g_smFriendlyFire.SetValue(s_SteamID, Value, overwrite);
		return true;
	}
	else
		return false;

}

public any GetStringMapVFF(int client)
{
	if (!IsValidClient(client, TEAM_SURVIVOR) || IsFakeClient(client)) return false;
	int SteamID = GetSteamAccountID(client, true);
	char[] s_SteamID = new char[16];
	if (SteamID != 0)
	{
		IntToString(SteamID, s_SteamID, 16);
		any value;
		g_smFriendlyFire.GetValue(s_SteamID, value);
		return value;
	}
	return false;
}
static bool bIsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientInKickQueue(client);
}

// ====================================================================================================
//					Melee Range
// ====================================================================================================
public MRESReturn TestMeleeSwingCollisionPre(int pThis, Handle hReturn)
{
	if( IsValidEntity(pThis) && MeleeRangeUpgrade)
	{
		static char sTemp[16];
		GetEntPropString(pThis, Prop_Data, "m_strMapSetScriptName", sTemp, sizeof(sTemp));

		int index;
		if( g_hScripts.GetValue(sTemp, index) )
		{
			g_hCvarMeleeRange.SetInt(g_iRange);
		}
		else
		{
			g_hCvarMeleeRange.SetInt(g_iRange);
		}
	}
}

public MRESReturn TestMeleeSwingCollisionPost(int pThis, Handle hReturn)
{
	g_hCvarMeleeRange.SetInt(g_iStockRange);
}