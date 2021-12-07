#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <autoexecconfig>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

#define RESET_ENABLED
//#define UNKNOWN_ERROR "\x01An unknown error has occured, action was aborted."

#define ADMFLAG_VIP ADMFLAG_CUSTOM2

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "Gun XP Mod",
	author = "Eyal282",
	description = "The sourcemod equivalent of the well-known Gun-XP of Counter Strike 1.6",
	version = PLUGIN_VERSION,
	url = "NULL"
};


new HealthMaxLevel = 5;
new RegenMaxLevel = 5;
new DamageMaxLevel = 5;

new HealthPerLevel = 20;
new RegenPerLevel = 4;
new Float:DamagePerLevel = 0.1;


new bool:SaveLastGuns[MAXPLAYERS+1];

new Handle:hcv_xpKill = INVALID_HANDLE;
new Handle:hcv_xpHS = INVALID_HANDLE;
new Handle:hcv_xpKnife = INVALID_HANDLE;
new Handle:hcv_xpZeus = INVALID_HANDLE;
new Handle:hcv_xpTriple = INVALID_HANDLE;
new Handle:hcv_xpUltra = INVALID_HANDLE;
new Handle:hcv_xpWin = INVALID_HANDLE;
new Handle:hcv_TripleKills = INVALID_HANDLE;
new Handle:hcv_UltraKills = INVALID_HANDLE;
new Handle:hcv_MinPlayers = INVALID_HANDLE;
new Handle:hcv_MinPlayersWin = INVALID_HANDLE;
new Handle:hcv_MaxLevelBypass = INVALID_HANDLE;
new Handle:hcv_xpKillChicken = INVALID_HANDLE;
new Handle:hcv_VIPMultiplier = INVALID_HANDLE;
new Handle:hcv_Zeus = INVALID_HANDLE;

new Handle:hcv_FriendlyFire = INVALID_HANDLE;

new Handle:hRegenTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:hRemoveTimer[4100] = INVALID_HANDLE;

new Handle:hfwTimer = INVALID_HANDLE;
new Handle:hsprayTimer = INVALID_HANDLE;

new KillStreak[MAXPLAYERS+1];

new Level[MAXPLAYERS+1], XP[MAXPLAYERS+1];

new Handle:cpXP, Handle:cpResets, Handle:cpTempResets, Handle:cpHP, Handle:cpRegen, Handle:cpDamage;

new Handle:cpLastPistol, Handle:cpLastRifle;

new bool:TookWeapons[MAXPLAYERS+1];

new const StartOfRifles = 10; // Change to the beginning of rifles in the levels, remember to count [0]

new const HUD_INFO_CHANNEL = 25;
new const HUD_KILL_CHANNEL = 82;
new const HUD_FW_CHANNEL = 42;

new bool:fwStarted, bool:fwMove, String:fwNumbers[42], fwTimer, fwPrize;
new bool:sprayStarted, Float:sprayScore[MAXPLAYERS+1], sprayTimer, sprayPrize;

#define MAX_LEVEL 33


/*
new const String:FORBIDDEN_WEAPONS[][] =
{
	"weapon_sawedoff"
}

*/
new const LEVELS[MAX_LEVEL+1] =
{
	10, // USP-S
	15, // P2000
	50, // P250
	100, // CZ75-Auto
	150, // Five_Seven
	200, // Tec-9
	300, // Dual Berettas
	500, // Desert Eagle
	700, // R8 Revolver
	800, // MAC-10, The first rifle
	900, // MP9
	1000, // PP-Bizon
	1150, // MP7
	1300, // UMP-45
	1500, // P90
	1700, // M249
	1850, // Negev
	2000, // Galil AR
	2225, // FAMAS
	2500, // SSG 08
	3000, // AK-47
	3250, // M4A1
	3300, // M4A1-S
	4000, // SG 553
	4250, // AUG
	5000, // Nova
	5250, // XM1014
	5500, // MAG-7
	6500, // Sawed-Off
	7500, // G3SG1
	8000, // SCAR-20
	10000, // AWP
	12500, // Nothing
	2147483647 // This shall never change, NEVERRRRR
};
new const String:GUNS_CLASSNAMES[MAX_LEVEL+1][] =
{
	"weapon_glock",
	"weapon_hkp2000",
	"weapon_usp_silencer",
	"weapon_p250",
	"weapon_cz75a",
	"weapon_fiveseven",
	"weapon_tec9",
	"weapon_elite",
	"weapon_deagle",
	"weapon_revolver",
	"weapon_mac10",
	"weapon_mp9",
	"weapon_bizon",
	"weapon_mp7",
	"weapon_ump45",
	"weapon_p90",
	"weapon_m249",
	"weapon_negev",
	"weapon_galilar",
	"weapon_famas",
	"weapon_ssg08",
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_m4a1_silencer",
	"weapon_sg556",
	"weapon_aug",
	"weapon_nova",
	"weapon_xm1014",
	"weapon_mag7",
	"weapon_sawedoff",
	"weapon_g3sg1",
	"weapon_scar20",
	"weapon_awp",
	"weapon_null"
};

new const String:GUNS_NAMES[MAX_LEVEL+1][] =
{
	"Glock-18",
	"P2000",
	"USP-S",
	"P250",
	"CZ75-Auto",
	"Five-Seven",
	"Tec-9",
	"Dual Berettas",
	"Desert Eagle",
	"R8 Revolver",
	"MAC-10", // The first rifle
	"MP9",
	"PP-Bizon",
	"MP7",
	"UMP-45",
	"P90",
	"M249",
	"Negev",
	"Galil AR",
	"FAMAS",
	"SSG 08",
	"AK-47",
	"M4A1",
	"M4A1-S",
	"SG 553",
	"AUG",
	"Nova",
	"XM1014",
	"MAG-7",
	"Sawed-Off",
	"G3SG1",
	"SCAR-20",
	"AWP",
	"NULL"
};

public OnPluginStart()
{
	#if defined _autoexecconfig_included
	
	AutoExecConfig_SetFile("GunXPMod");
	
	#endif
	
	RegConsoleCmd("sm_xp", Command_XP);
	RegConsoleCmd("sm_guns", Command_Guns);
	RegAdminCmd("sm_givexp", Command_GiveXP, ADMFLAG_ROOT);
	RegAdminCmd("sm_giveresets", Command_GiveResets, ADMFLAG_ROOT);
	RegAdminCmd("sm_chicken", Command_Chicken, ADMFLAG_VIP);
	RegAdminCmd("sm_chickens", Command_Chicken, ADMFLAG_VIP);
	RegAdminCmd("sm_fw", Command_FW, ADMFLAG_ROOT);
	//RegAdminCmd("sm_spray", Command_Spray, ADMFLAG_ROOT);
	RegAdminCmd("sm_stopfw", Command_StopFW, ADMFLAG_ROOT);
	//RegAdminCmd("sm_stopspray", Command_StopSpray, ADMFLAG_ROOT);
	#if defined RESET_ENABLED
	RegConsoleCmd("sm_reset", Command_Reset);
	RegConsoleCmd("sm_rpg", Command_Shop);
	#endif
	
	AddCommandListener(Listener_Say, "say");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("other_death", Event_OtherDeath, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("weapon_outofammo", Event_WeaponOutOfAmmo, EventHookMode_Pre);
	
	HookUserMessage(GetUserMessageId("TextMsg"), Message_TextMsg, true); 
	
	hcv_FriendlyFire = FindConVar("mp_friendlyfire");
	SetConVarString(UC_CreateConVar("gun_xp_version", PLUGIN_VERSION), PLUGIN_VERSION);
	hcv_xpKill = UC_CreateConVar("gun_xp_kill", "10", "Amount of xp you get per kill");
	hcv_xpHS = UC_CreateConVar("gun_xp_bonus_hs", "3", "Amount of bonus xp you get per headshot kill");
	hcv_xpKnife = UC_CreateConVar("gun_xp_bonus_knife", "5", "Amount of bonus xp you get per knife kill");
	hcv_xpZeus = UC_CreateConVar("gun_xp_bonus_zeus", "3", "Amount of bonus xp you get per zeus kill");
	hcv_xpTriple = UC_CreateConVar("gun_xp_bonus_triple", "5", "Amount of bonus xp you get per triple kill");
	hcv_xpUltra = UC_CreateConVar("gun_xp_bonus_ultra", "10", "Amount of bonus xp you get per ultra kill, overrides triple kill");
	hcv_xpWin = UC_CreateConVar("gun_xp_win", "100", "Amount of xp you get if you win the deathmatch.");
	hcv_TripleKills = UC_CreateConVar("gun_xp_triple_kills", "3", "Amount of kills to get triple kill");
	hcv_UltraKills = UC_CreateConVar("gun_xp_ultra_kills", "6", "Amount of kills to get ultra kill");
	hcv_MinPlayers = UC_CreateConVar("gun_xp_min_players", "4", "XP Gain is only possible if players count is equal or greater than this");
	hcv_MinPlayersWin = UC_CreateConVar("gun_xp_min_players_win", "10", "XP Gain for winning is only possible if players count is equal or greater than this");
	hcv_MaxLevelBypass = UC_CreateConVar("gun_xp_max_players", "0", "Players equal or below this can gain EXP while bypassing hcv_MinPlayers. -1 to disable");
	hcv_xpKillChicken = UC_CreateConVar("gun_xp_kill_chicken", "1", "Amount of xp you get per chicken kill");
	hcv_VIPMultiplier = UC_CreateConVar("gun_xp_vip_multiplier", "2.0", "How much to mulitply rewards for VIP players. 1 to disable.");
	hcv_Zeus = UC_CreateConVar("gun_xp_zeus", "1", "Give zeus on spawn?"); // Note to self: level 10 gives you he, level 20 gives you flash in addition to he, level 30 gives you extra flash in addition to other.
	
	cpXP = RegClientCookie("GunXP_PlayerXP", "Amount of XP a player has.", CookieAccess_Private);
	cpResets = RegClientCookie("GunXP_PlayerResets", "Amount of resets a player has ever achieved.", CookieAccess_Private);
	cpTempResets = RegClientCookie("GunXP_PlayerTempResets", "Amount of resets a player has to spend.", CookieAccess_Private);
	cpHP = RegClientCookie("GunXP_PlayerSkill_HP", "Level of the player's HP skill", CookieAccess_Private);
	cpRegen = RegClientCookie("GunXP_PlayerSkill_Regen", "Level of the player's Regen skill", CookieAccess_Private);
	cpDamage = RegClientCookie("GunXP_PlayerSkill_Damage", "Level of the player's Damage skill", CookieAccess_Private);
	
	cpLastPistol = RegClientCookie("GunXP_LastPistol", "Level of the player's Damage skill", CookieAccess_Private);
	cpLastRifle = RegClientCookie("GunXP_LastRifle", "Level of the player's Damage skill", CookieAccess_Private);
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		OnClientPutInServer(i);
		
		if(AreClientCookiesCached(i))
			CalculateStats(i);
	}
	
	#if defined _autoexecconfig_included
	
	AutoExecConfig_ExecuteFile();

	AutoExecConfig_CleanFile();
	
	#endif
	/*
	new String:ServerIP[50];
	
	GetServerIP(ServerIP, sizeof(ServerIP));
	
	if(!StrEqual(ServerIP, "93.186.198.117:30415"))
		SetFailState("Only Spectre Gaming can use this plugin.");
		
	*/
}

public Action:Message_TextMsg(UserMsg:msg_id, Handle:msg, const players[], playersNum, bool:reliable, bool:init) 
{ 
    decl String:buffer[64]; 
    PbReadString(msg, "params", buffer, sizeof(buffer), 0); 

    if(StrContains(buffer, "Cash_Award") != -1) 
        return Plugin_Handled; 

	else if(StrContains(buffer, "teammate_attack") != -1 && !GetConVarBool(hcv_FriendlyFire))
		return Plugin_Handled;

    return Plugin_Continue; 
} 

/*
public Action:CS_OnCSWeaponDrop(client, entity)
{
	hRemoveTimer[entity] = CreateTimer(5.0, RemoveWeapon, entity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:RemoveWeapon(Handle:hTimer, entity)
{
	AcceptEntityInput(entity, "Kill");
	
	hRemoveTimer[entity] = INVALID_HANDLE;
}
*/
public OnClientConnected(client)
{
	sprayScore[client] = 0.0;
	SaveLastGuns[client] = false;
	CalculateStats(client);
}

public OnMapStart()
{
	CreateTimer(2.5, HudMessageXP, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)
	
	for(new i=0;i < MAXPLAYERS+1;i++)
	{
		hRegenTimer[i] = INVALID_HANDLE;
	}
	
	#if defined DeadMatch
	CreateTimer(2.5, RespawnAll, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	#endif
	
	for(new i=0;i < 4100;i++)
		hRemoveTimer[i] = INVALID_HANDLE;
		
	#if defined RESET_ENABLED
	CreateTimer(150.0, TellAboutShop,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	#endif
	
	hfwTimer = INVALID_HANDLE;
	hsprayTimer = INVALID_HANDLE;

}

public Action:RespawnAll(Handle:hTimer)
{
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		else if(IsPlayerAlive(i))
			continue;
		
		else if(GetClientTeam(i) == CS_TEAM_SPECTATOR)
			continue;
			
		CS_RespawnPlayer(i);
	}
	
	return Plugin_Continue;
}

public Action:HudMessageXP(Handle:hTimer)
{
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		SetHudMessage(0.2, 0.1, 2.5, 232, 61, 22);
		if(LEVELS[Level[i]] != 2147483647)
			ShowHudMessage(i, HUD_INFO_CHANNEL, "[Resets : %i]\n[Level : %i]\n[XP : %i/%i]\n[Weapon : %s]", GetClientResets(i), Level[i], XP[i], LEVELS[Level[i]], GUNS_NAMES[Level[i]]);
			
		else 
			ShowHudMessage(i, HUD_INFO_CHANNEL, "[Resets : %i]\n[Level : %i]\n[XP : %i/∞]\n[Weapon : %s]", GetClientResets(i), Level[i], XP[i], GUNS_NAMES[Level[i]]);
	}
	return Plugin_Continue;
}

#if defined RESET_ENABLED

public Action:TellAboutShop(Handle:hTimer)
{
	PrintToChatAll("\x01Type\x03 !rpg\x01 to buy powers using resets!");
	PrintToChatAll("\x01Gain\x03 resets\x01 by reaching\x04 %i\x05 XP\x01 and reseting it to 0.", LEVELS[MAX_LEVEL-1]);
	
	return Plugin_Continue;
}

#endif

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Event_Hurt);
	SDKHook(client, SDKHook_WeaponEquip, Event_WeaponPickUp);
}

public Action:Event_Hurt(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(victim > MaxClients || victim < 1)
		return Plugin_Continue;
		
	else if(attacker > MaxClients || attacker < 1)
		return Plugin_Continue;
		
	else if(!AreClientCookiesCached(attacker))
		return Plugin_Continue;
		
	else if(damage == 0.0)
		return Plugin_Continue;
	
	damage *= (1.0 + ( DamagePerLevel * GetClientDamageSkill(attacker) ));
	return Plugin_Continue;
}

public Action:Event_WeaponPickUp(client, weapon) 
{
	new String:Classname[64]; 
	GetEdictClassname(weapon, Classname, sizeof(Classname)); 
	
	if(strncmp(Classname, "weapon_knife", 12) == 0)
		return Plugin_Continue;
	/*
	for(new i=0;i < sizeof(FORBIDDEN_WEAPONS);i++)
	{
		if(StrEqual(FORBIDDEN_WEAPONS[i], WeaponName))
			return Plugin_Handled;
	}
	*/
	new i, bool:Found = false;
	for(i=0;i < MAX_LEVEL;i++)
	{
		if(StrEqual(GUNS_CLASSNAMES[i], Classname))
		{
			Found = true;
			break;
		}
	}
    
	if(Level[client] < i && Found)
	{
		AcceptEntityInput(weapon, "Kill");
		return Plugin_Handled;
	}
	
	/*
	if(hRemoveTimer[weapon] != INVALID_HANDLE)
	{
		CloseHandle(hRemoveTimer[weapon]);
		hRemoveTimer[weapon] = INVALID_HANDLE;
	}
	*/
	return Plugin_Continue; 
}  
public Action:Command_Guns(client, args)
{
	ShowChoiceMenu(client);
	
	if(SaveLastGuns[client])
	{
		SaveLastGuns[client] = false;
		PrintToChat(client, "\x05Last guns save\x01 is now disabled.");
		
		if(TookWeapons[client])
			return Plugin_Handled;
	}
	if(TookWeapons[client])
		PrintToChat(client, "\01You have already taken weapons this round.");
		
	return Plugin_Handled;
}

#if defined RESET_ENABLED
public Action:Command_Reset(client, args)
{
	CalculateStats(client);
	
	if(Level[client] < MAX_LEVEL)
	{
		ReplyToCommand(client, "\x03Error:\x01 You must reach level %i to reset your progress", MAX_LEVEL);
		return Plugin_Handled;
	}
	
	new Handle:hMenu = CreateMenu(Reset_MenuHandler);

	AddMenuItem(hMenu, "", "Yes");
	
	AddMenuItem(hMenu, "", "No");
	
	SetMenuTitle(hMenu, "Do you want to set your XP to 0 in exchange for 1 reset?");
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Reset_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{
		if(item == 0)
		{
			if(Level[client] >= MAX_LEVEL)
			{
				AddClientResets(client, 1);
				
				SetClientXP(client, 0);
				SetClientLastPistol(client, 0);
				SetClientLastRifle(client, 0);
				
				PrintToChat(client, "\x04SUCCESS!\x01 Type\x05 !rpg\x01 to spend your reset!");
			}
		}
	}	
	
	hMenu = INVALID_HANDLE;
}

public Action:Command_GiveXP(client, args)
{	
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_givexp <#userid|name> [number of xp]");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[10];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		new String:Path[256], String:LogFormat[100];
		BuildPath(Path_SM, Path, sizeof(Path), "logs/gunxp.txt");
		
		Format(LogFormat, sizeof(LogFormat), "Admin %N has given %i EXP to %s.", client, StringToInt(arg2), arg);
		LogToFile(Path, LogFormat);
		
		AddClientXP(target_list[0], StringToInt(arg2));
		
		PrintToChatAll("\x01Admin\x03 %N\x01 has given\x04 %i\x01 XP to \x05%N", client, StringToInt(arg2), target_list[0]);
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_GiveResets(client, args)
{
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_giveresets <#userid|name> [number of resets]");
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[10];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		new String:Path[256], String:LogFormat[100];
		BuildPath(Path_SM, Path, sizeof(Path), "logs/gunxp.txt");
		
		Format(LogFormat, sizeof(LogFormat), "Admin %N has given %i Resets to %s.", client, StringToInt(arg2), arg);
		LogToFile(Path, LogFormat);
		
		ResetPowers(target_list[0]);
		AddClientResets(target_list[0], StringToInt(arg2));
		
		PrintToChatAll("\x01Admin\x03 %N\x01 has given\x04 %i\x01 Resets to \x05%N", client, StringToInt(arg2), target_list[0]);
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}


public Action:Command_Chicken(client, args)
{
	new Count;
	
	new entCount = GetEntityCount();
	
	for(new i=MaxClients;i < entCount;i++)
	{
		if(!IsValidEntity(i) || !IsValidEdict(i))
			continue;
			
		new String:Classname[50];
		
		GetEdictClassname(i, Classname, sizeof(Classname));
		
		if(!StrEqual(Classname, "Chicken", false))
			continue;
			
		new leader = GetEntPropEnt(i, Prop_Send, "m_leader");
		
		if(leader == -1)
		{
			SetEntPropEnt(i, Prop_Send, "m_leader", client);
			Count++;
		}
	}
	
	if(Count == 0)
		ReplyToCommand(client, "[SM] No chickens were found!");
	
	else
		ReplyToCommand(client, "[SM] %i chickens are now following you!", Count);
		
	return Plugin_Handled;
}

public Action:Command_FW(client, args)
{
	if(args < 2 || args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fw <prize> <numbers>");
		return Plugin_Handled;
	}
	
	else if(sprayStarted)
	{
		ReplyToCommand(client, "[SM] Error: Use !stopspray to stop the running first writes game.");
		return Plugin_Handled;
	}	
	else if(fwStarted)
	{
		ReplyToCommand(client, "[SM] Error: Use !stopfw to stop the running first writes game.");
		return Plugin_Handled;
	}
	
	new String:Arg1[50], String:Arg2[50];
	
	GetCmdArg(1, Arg1, sizeof(Arg1));
	GetCmdArg(2, Arg2, sizeof(Arg2));
	
	if(!IsStringNumber(Arg1) || !IsStringNumber(Arg2))
	{
		ReplyToCommand(client, "[SM] Usage: sm_fw <prize> <numbers>");
		return Plugin_Handled;
	}
	new Numbers = StringToInt(Arg2);
	if(Numbers > sizeof(fwNumbers))
	{
		ReplyToCommand(client, "[SM] Error: Max numbers is %i", sizeof(fwNumbers));
		return Plugin_Handled;
	}
	
	else if(Numbers <= 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fw <prize> <numbers>");
		return Plugin_Handled;
	}
	
	fwPrize = StringToInt(Arg1);
	fwNumbers[0] = EOS;

	for(new i=0;i < Numbers;i++)
	{
		Format(fwNumbers, sizeof(fwNumbers), "%s%i", fwNumbers, GetRandomInt(0, 9));
	}
	
	fwStarted = true;
	fwMove = false;
	
	fwTimer = 5;
	
	hfwTimer = CreateTimer(1.0, fwCountdown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	PrintToChatAll("\x01Admin\x03 %N\x01 has started\x05 First Writes\x01 game for\x04 %i\x05 EXP\x01!", client);
	
	return Plugin_Handled;
}

public Action:fwCountdown(Handle:hTimer)
{
	if(fwTimer == 0)
	{
		SetHudMessage(_, _, 25.0);
		ShowHudMessage(0, HUD_FW_CHANNEL, "The first player to write these numbers will win the game!\n%s", fwNumbers);
		
		fwMove = true;
		
		hfwTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	SetHudMessage(_, _, 0.9);
	ShowHudMessage(0, HUD_FW_CHANNEL, "First writes game will start in %i seconds with %i numbers!\nWinner will receive %i EXP!", fwTimer, strlen(fwNumbers), fwPrize);
	
	fwTimer--;
	
	return Plugin_Continue;
}

public Action:Command_StopFW(client, args)
{
	if(!fwStarted)
	{
		ReplyToCommand(client, "[SM] Error: There isn't any running FW game.");
		return Plugin_Handled;
	}
	
	StopFirstWrites();
	
	PrintToChatAll("\x01Admin\x03 %N\x01 has stopped\x05 First Writes\x01 game!", client);
	
	return Plugin_Handled;
}


public Action:Command_Spray(client, args)
{
	if(args < 1 || args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spray <prize>");
		return Plugin_Handled;
	}
	
	else if(fwStarted)
	{
		ReplyToCommand(client, "[SM] Error: Use !stopfw to stop the running first writes game.");
		return Plugin_Handled;
	}
	else if(sprayStarted)
	{
		ReplyToCommand(client, "[SM] Error: Use !stopspray to stop the running spray game.");
		return Plugin_Handled;
	}
	
	new String:Arg1[50];
	
	GetCmdArg(1, Arg1, sizeof(Arg1));
	
	if(!IsStringNumber(Arg1))
	{
		ReplyToCommand(client, "[SM] Usage: sm_spray <prize>");
		return Plugin_Handled;
	}
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		SetEntPropFloat(i, Prop_Send, "m_flNextDecalTime", 0.0);
		sprayScore[i] = 0.0;
	}
	sprayPrize = StringToInt(Arg1);
	
	sprayStarted = true;
	
	sprayTimer = 30;
	
	hsprayTimer = CreateTimer(1.0, sprayCountdown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	PrintToChatAll("\x01Admin\x03 %N\x01 has started\x05 Spray\x01 game for\x04 %i\x05 EXP\x01!", client, sprayPrize);
	PrintToChatAll("\x01Press E to spray, aim for the highest spray possible!");
	
	return Plugin_Handled;
}

public Action:sprayCountdown(Handle:hTimer)
{
	if(sprayTimer == 0)
	{
		new Winner = 0;
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsValidPlayer(i))
				continue;
				
			if(Winner == 0)
				Winner = i;
				
			else if(sprayScore[i] > sprayScore[Winner])
				Winner = i;
			
			else if(sprayScore[i] == sprayScore[Winner] && GetRandomInt(0, 1) == 1)
				Winner = i;
		}
		SetHudMessage(_, _, 25.0);
		PrintToChatAll("\x03%N\x01 has won the\x05 Spray\x01 game and won\x04 %i\x01 EXP!", Winner, sprayPrize);
		PrintToChatAll("\x01He reached a spray score of\x05 %.2f\x01 units!", sprayScore[Winner]);
		AddClientXP(Winner, sprayPrize);
		
		fwMove = true;
		
		hfwTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	SetHudMessage(_, _, 2.5);
	ShowHudMessage(0, HUD_FW_CHANNEL, "Spray game will end in %i seconds!\nWinner will receive %i EXP!\nFind a wall and press E as high as you can to win!", sprayTimer, sprayPrize);
	
	sprayTimer--;
	
	return Plugin_Continue;
}

public Action:Command_StopSpray(client, args)
{
	if(!sprayStarted)
	{
		ReplyToCommand(client, "[SM] Error: There isn't any running Spray game.");
		return Plugin_Handled;
	}
	
	StopSpray();
	
	PrintToChatAll("\x01Admin\x03 %N\x01 has stopped\x05 Spray\x01 game!", client);
	
	return Plugin_Handled;
}
public Action:OnCustomSpray_Post(client, Float:HeightFromGround, Cheater)
{
	if(sprayStarted)
		sprayScore[client] = HeightFromGround;
}

public Action:Listener_Say(client, const String:command[], args)
{
	if(!fwStarted)
		return Plugin_Continue;
		
	else if(!fwMove)
		return Plugin_Continue;
		
	new String:Message[44];
	
	GetCmdArg(1, Message, sizeof(Message));
	
	if(!IsStringNumber(Message))
	{
		SetHudMessage(_, _, 25.0);
		ShowHudMessage(0, HUD_FW_CHANNEL, "The first player to write these numbers will win the game!\n%s", fwNumbers);
		
		return Plugin_Continue;
	}
	
	else if(StrEqual(Message, fwNumbers))
	{
		PrintToChatAll("\x03%N\x01 has won the\x05 First Writes\x01 game and won\x04 %i\x01 EXP!", client, fwPrize);
		
		AddClientXP(client, fwPrize);
		
		StopFirstWrites();
		
		return Plugin_Continue;
	}
	
	SetHudMessage(_, _, 25.0);
	ShowHudMessage(0, HUD_FW_CHANNEL, "The first player to write these numbers will win the game!\n%s", fwNumbers);
	
	return Plugin_Continue;
}

StopFirstWrites()
{
	fwNumbers[0] = EOS;
	
	fwStarted = false;
	fwMove = false;
	
	fwTimer = 0;
	
	if(hfwTimer != INVALID_HANDLE)
	{
		CloseHandle(hfwTimer);
		hfwTimer = INVALID_HANDLE;
	}
}

StopSpray()
{
	sprayStarted = false;
	
	sprayTimer = 0;
	
	if(hsprayTimer != INVALID_HANDLE)
	{
		CloseHandle(hsprayTimer);
		hsprayTimer = INVALID_HANDLE;
	}
}	
public Action:Command_Shop(client, args)
{
	new String:TempFormat[200];
	new Handle:hMenu = CreateMenu(Shop_MenuHandler);
	
	new HPSkill = GetClientHPSkill(client);
	new RegenSkill = GetClientRegenSkill(client);
	new DamageSkill = GetClientDamageSkill(client);
	Format(TempFormat, sizeof(TempFormat), "Health: [%i/%i] [%i HP] [%i RESETS]", HPSkill, HealthMaxLevel, HPSkill * HealthPerLevel, (1 + ((HPSkill) * 2)));
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "HP Regen: [%i/%i] [%i/5sec] [%i RESETS]", RegenSkill, RegenMaxLevel, RegenSkill * RegenPerLevel, (1 + ((RegenSkill) * 2)));
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "Damage: [%i/%i] [%.2fx] [%i RESETS]", DamageSkill, DamageMaxLevel, 1.0 + (DamageSkill * DamagePerLevel), (1 + ((DamageSkill) * 2)));
	AddMenuItem(hMenu, "", TempFormat);
	
	AddMenuItem(hMenu, "", "Reset powers [FREE]");
	
	Format(TempFormat, sizeof(TempFormat), "Choose your power:\nYou have %i resets and %i available resets.", GetClientResets(client), GetClientTempResets(client));
	SetMenuTitle(hMenu, TempFormat);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Shop_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{
		switch(item)
		{
			case 0:
			{
				new HPSkill = GetClientHPSkill(client);
				new cost = (1 + ((HPSkill) * 2));
				new resets = GetClientTempResets(client);
				
				if(HPSkill == HealthMaxLevel)
				{
					PrintToChat(client, "\x04Error:\x01 You reached the\x04 max level\x01 for this skill!");
				}
				else if(resets < cost)
				{
					PrintToChat(client, "\x04Error:\x01 You need\x03 %i\x01 more resets to buy this skill!", cost - resets);
				}
				else
				{
					AddClientTempResets(client, (-1 * cost));
					
					AddClientHPSkill(client, 1);
					
					PrintToChat(client, "\x01You have successfully purchased\x03 Health Skill\x01.");
				}
			}
			case 1:
			{
				new RegenSkill = GetClientRegenSkill(client);
				new cost = (1 + ((RegenSkill) * 2));
				new resets = GetClientTempResets(client);
				
				if(RegenSkill == RegenMaxLevel)
				{
					PrintToChat(client, "\x04Error:\x01 You reached the\x03 max level\x01 for this skill!");
				}
				else if(resets < cost)
				{
					PrintToChat(client, "\x04Error:\x01 You need\x03 %i\x01 more resets to buy this skill!", cost - resets);
				}
				else
				{
					AddClientTempResets(client, (-1 * cost));
					
					AddClientRegenSkill(client, 1);
					
					PrintToChat(client, "\x01You have successfully purchased\x03 HP Regen Skill\x01.");
				}
			}
			case 2:
			{
				new DamageSkill = GetClientDamageSkill(client);
				new cost = (1 + ((DamageSkill) * 2));
				new resets = GetClientTempResets(client);
				
				if(DamageSkill == DamageMaxLevel)
				{
					PrintToChat(client, "\x04Error:\x01 You reached the\x03 max level\x01 for this skill!");
				}
				else if(resets < cost)
				{
					PrintToChat(client, "\x04Error:\x01 You need\x03 %i\x01 more resets to buy this skill!", cost - resets);
				}
				else
				{
					AddClientTempResets(client, (-1 * cost));
					
					AddClientDamageSkill(client, 1);
					
					PrintToChat(client, "\x01You have successfully purchased\x03 Damage Skill\x01.");
				}
			}
			
			case 3:
			{
				ResetPowers(client);
				PrintToChat(client, "\x01You have successfully reset all your\x03 Skills\x01.");
			}
		}
	}	
	
	hMenu = INVALID_HANDLE;
}

ResetPowers(client)
{
	SetClientTempResets(client, GetClientResets(client));
	SetClientHPSkill(client, 0);
	SetClientRegenSkill(client, 0);
	SetClientDamageSkill(client, 0);
}

#endif // #if defined RESET_ENABLED
public Action:ShowChoiceMenu(client)
{	
	CalculateStats(client);
	
	new Handle:hMenu = CreateMenu(Choice_MenuHandler);
	
	//MessageMenu[client] = hMenu;
	AddMenuItem(hMenu, "", "Choose Guns");
	AddMenuItem(hMenu, "", "Last Guns");
	AddMenuItem(hMenu, "", "Last Guns + Save");
	
	new String:TempFormat[100];
	
	if(Level[client] >= StartOfRifles)
		Format(TempFormat, sizeof(TempFormat), "Choose your guns:\n \nLast Pistol: %s\nLast Rifle: %s \n ", GUNS_NAMES[GetClientLastPistol(client)], GUNS_NAMES[GetClientLastRifle(client)]);
		
	else
		Format(TempFormat, sizeof(TempFormat), "Choose your guns:\n \nLast Pistol: %s\nLast Rifle: NULL \n ", GUNS_NAMES[GetClientLastPistol(client)]);
		
	SetMenuTitle(hMenu, TempFormat);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Choice_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
	{
		/*
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsValidPlayer(i))
				continue;
				
			if(MessageMenu[i] == hMenu)
			{
				PrintToChat(i, "Type\x05 !guns\x01 to re-open this menu.");
				MessageMenu[i] = INVALID_HANDLE;
				break;
			}
		}
		*/
		CloseHandle(hMenu);
	}
	
	else if(action == MenuAction_Select)
	{
		if(!IsValidPlayer(client)) // Don't ask, I got an error :/
			return;
			
		switch(item)
		{
			case 0:	ChoosePistolsMenu(client);
			case 1:
			{
				GiveGuns(client);
			}
			case 2:
			{
				GiveGuns(client);
				SaveLastGuns[client] = true;
				PrintToChat(client, "Last Guns save is now enabled. Type \x05!guns\x01 to disable it.");
			}
		}
	}	
	else if(action == MenuAction_Cancel)
	{
		if(IsValidPlayer(client))
			PrintToChat(client, "Type\x05 !guns\x01 to re-open this menu.");
	}
	hMenu = INVALID_HANDLE;
}

public ChoosePistolsMenu(client)
{
	new String:TempFormat[200];
	CalculateStats(client);
	new Handle:hMenu = CreateMenu(Pistols_MenuHandler);

	for(new i=0;i < StartOfRifles;i++)
	{
		Format(TempFormat, sizeof(TempFormat), "%s (Level: %i)", GUNS_NAMES[i], i);
		AddMenuItem(hMenu, "", TempFormat, Level[client] >= i ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	//MessageMenu[client] = hMenu;
	SetMenuTitle(hMenu, "Choose your pistol:");
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public Pistols_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
	{
		/*
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsValidPlayer(i))
				continue;
				
			if(MessageMenu[i] == hMenu)
			{
				PrintToChat(i, "Type\x05 !guns\x01 to re-open this menu.");
				MessageMenu[i] = INVALID_HANDLE;
				break;
			}
		}
		*/
		CloseHandle(hMenu);
	}
	else if(action == MenuAction_Select)
	{
		if(!IsValidPlayer(client)) // Don't ask, I got an error :/
			return;
			
		SetClientLastPistol(client, item);
		
		if(Level[client] >= StartOfRifles)
			ChooseRiflesMenu(client);
			
		else
			GiveGuns(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(IsValidPlayer(client))
			PrintToChat(client, "Type\x05 !guns\x01 to re-open this menu.");
	}
	
	hMenu = INVALID_HANDLE;
}

ChooseRiflesMenu(client)
{
	new String:TempFormat[200];
	CalculateStats(client);
	new Handle:hMenu = CreateMenu(Rifles_MenuHandler);

	for(new i=StartOfRifles;i < MAX_LEVEL;i++)
	{
		Format(TempFormat, sizeof(TempFormat), "%s (Level: %i)", GUNS_NAMES[i], i);
		AddMenuItem(hMenu, "", TempFormat, Level[client] >= i ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	//MessageMenu[client] = hMenu;
	SetMenuTitle(hMenu, "Choose your rifle:");
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public Rifles_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
	{
		/*
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsValidPlayer(i))
				continue;
				
			if(MessageMenu[i] == hMenu)
			{
				PrintToChat(i, "Type\x05 !guns\x01 to re-open this menu.");
				MessageMenu[i] = INVALID_HANDLE;
				break;
			}
		}
		*/
		CloseHandle(hMenu);
	}
	else if(action == MenuAction_Select)
	{
		if(!IsValidPlayer(client)) // Don't ask, I got an error :/
			return;
			
		SetClientLastRifle(client, StartOfRifles + item);
		
		GiveGuns(client);
	}	
	else if(action == MenuAction_Cancel)
	{
		if(IsValidPlayer(client))
			PrintToChat(client, "Type\x05 !guns\x01 to re-open this menu.");
	}
	hMenu = INVALID_HANDLE;
}

public GiveGuns(client)
{
	if(TookWeapons[client])
		return;
		
	new LastPistol, LastRifle;
	LastPistol = GetClientLastPistol(client);
	LastRifle = GetClientLastRifle(client);
	
	if(LastRifle > Level[client] || LastRifle < StartOfRifles)
		LastRifle = StartOfRifles;
		
	if(LastPistol > Level[client] || LastPistol >= StartOfRifles)
		LastPistol = 0;
		
	StripWeaponFromPlayer(client, GUNS_CLASSNAMES[LastPistol]);
	GivePlayerItem(client, GUNS_CLASSNAMES[LastPistol]);
	
	if(Level[client] >= StartOfRifles)
	{
		StripWeaponFromPlayer(client, GUNS_CLASSNAMES[LastRifle]);
		GivePlayerItem(client, GUNS_CLASSNAMES[LastRifle]);
	}
		
	TookWeapons[client] = true;
}

public Action:Event_PlayerDeath(Handle:hEvent, String:Name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsValidPlayer(victim))
		return;

	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if(attacker == victim || !IsValidPlayer(attacker))
		return;
		
	else if(!AreClientCookiesCached(attacker))
		return;
	
	new players = 0;
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
		
		else if(GetClientTeam(i) == CS_TEAM_SPECTATOR)
			continue;
		
		players++;
	}
	
	new MinPlayers = GetConVarInt(hcv_MinPlayers);
	new BypassLevel = GetConVarInt(hcv_MaxLevelBypass);
	
	if(players < MinPlayers && BypassLevel < Level[attacker])
	{
		PrintToChat(attacker, "\x01There aren't enough players to gain XP, minimum\x03 %i\x01.", MinPlayers);
		return;
	}	

	new bool:headshot = GetEventBool(hEvent, "headshot");
	new String:Weapon[50];
	
	GetEventString(hEvent, "weapon", Weapon, sizeof(Weapon));
	new bool:knife = (StrContains(Weapon, "knife") != -1) ? true : false;
	new bool:tazed = (StrContains(Weapon, "taser") != -1) ? true : false;
	
	new String:HudFormat[100];
	new xpToAdd = GetConVarInt(hcv_xpKill);
	new hsXP = GetConVarInt(hcv_xpHS);
	new knifeXP = GetConVarInt(hcv_xpKnife);
	new zeusXP = GetConVarInt(hcv_xpZeus);
	new ultraXP = GetConVarInt(hcv_xpUltra);
	new tripleXP = GetConVarInt(hcv_xpTriple);
	new Colors[3];
	
	KillStreak[victim] = 0;	
	KillStreak[attacker]++;
	
	if(KillStreak[attacker] >= GetConVarInt(hcv_UltraKills) && ultraXP > 0)
	{
		Colors = {234, 102, 20};
		xpToAdd += ultraXP;
		Format(HudFormat, sizeof(HudFormat), "+ %i XP ( Ultra Kill )\n", xpToAdd);
	}
	else if(KillStreak[attacker] >= GetConVarInt(hcv_TripleKills) && tripleXP > 0)
	{
		Colors = {255, 0, 0};
		xpToAdd += tripleXP;
		Format(HudFormat, sizeof(HudFormat), "+ %i XP ( Triple Kill )\n", xpToAdd);
	}
	else
	{
		Colors = {0, 255, 0}
		// xpToAdd already equal to getconvarint(hcv_xpHs);
		Format(HudFormat, sizeof(HudFormat), "+ %i XP ( Kill )\n", xpToAdd);
	}	
	if(headshot && hsXP > 0)
	{
		xpToAdd += hsXP;
		Format(HudFormat, sizeof(HudFormat), "%s+ %i XP ( Headshot )\n", HudFormat, hsXP);
	}
	if(knife && knifeXP > 0)
	{
		xpToAdd += knifeXP;
		Format(HudFormat, sizeof(HudFormat), "%s+ %i XP ( Knife )\n", HudFormat, knifeXP);
	}
	if(tazed && zeusXP > 0)
	{
		xpToAdd += zeusXP;
		Format(HudFormat, sizeof(HudFormat), "%s+ %i XP ( Zeus )\n", HudFormat, zeusXP);
	}
	
	new Float:PremiumMultiplier = GetConVarFloat(hcv_VIPMultiplier);
	if(CheckCommandAccess(attacker, "sm_checkcommandaccess_custom4", ADMFLAG_VIP) && PremiumMultiplier != 1.0)
	{
		new Float:xp = float(xpToAdd);
		
		xp *= PremiumMultiplier;
		
		xpToAdd = RoundFloat(xp);
		
		Format(HudFormat, sizeof(HudFormat), "%sx %.1f XP ( VIP )\n", HudFormat, PremiumMultiplier);
	}
	if(HudFormat[0] != EOS)
	{
		SetHudMessage(0.05, 0.7, 6.0, Colors[0], Colors[1], Colors[2], 255, 1, 5.0)
		ShowHudMessage(attacker, HUD_KILL_CHANNEL, HudFormat);
	}
	AddClientXP(attacker, xpToAdd);
	SetEntProp(attacker, Prop_Send, "m_iAccount", 0);
	
	new LastLevel = Level[attacker];
	
	if(Level[attacker] > LastLevel)
	{
		SaveLastGuns[attacker] = false;
		FakeClientCommand(attacker, "play ui/xp_levelup.wav");
		PrintToChatAll("\x01Congratulations!\x03 %N\x01 has\x05 leveled up\x01 to\x04 %i", attacker, Level[attacker]);
	}
	
	#if defined RESET_ENABLED
	if(Level[attacker] >= MAX_LEVEL)
		PrintToChat(attacker, "\x01Type\x05 !reset\x01 to reset your xp for skills.");
	#endif
}

public Action:Event_OtherDeath(Handle:hEvent, String:Name[], bool:dontBroadcast)
{
	new victim = GetEventInt(hEvent, "otherid");
	
	if(!IsValidEntity(victim))
		return;
		
	new String:Classname[50];
	GetEdictClassname(victim, Classname, sizeof(Classname));

	if(!StrEqual(Classname, "Chicken", false))
		return;
		
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	
	if(!IsValidPlayer(attacker))
		return;
	
	else if(!AreClientCookiesCached(attacker))
		return;
		
	new xpToAdd = GetConVarInt(hcv_xpKillChicken);
	
	if(xpToAdd == 0)
		return;
		
	new players;
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
		
		else if(GetClientTeam(i) == CS_TEAM_SPECTATOR)
			continue;
		
		players++;
	}
	
	new MinPlayers = GetConVarInt(hcv_MinPlayers);
	new BypassLevel = GetConVarInt(hcv_MaxLevelBypass);
	
	if(players < MinPlayers && BypassLevel < Level[attacker])
	{
		PrintToChat(attacker, "\x01There aren't enough players to gain XP, minimum\x03 %i\x01.", MinPlayers);
		return;
	}	
	
	new Colors[3];
	Colors = {0, 0, 255};
	
	new String:HudFormat[200];
	
	Format(HudFormat, sizeof(HudFormat), "+ %i XP ( Chicken Kill )\n", xpToAdd);
		
	new Float:PremiumMultiplier = GetConVarFloat(hcv_VIPMultiplier);
	if(CheckCommandAccess(attacker, "sm_checkcommandaccess_custom4", ADMFLAG_VIP) && PremiumMultiplier != 1.0)
	{
		new Float:xp = float(xpToAdd);
		
		xp *= PremiumMultiplier;
		
		xpToAdd = RoundFloat(xp);
		
		Format(HudFormat, sizeof(HudFormat), "%sx %.1f XP ( VIP )\n", HudFormat, PremiumMultiplier);
	}
	if(HudFormat[0] != EOS)
	{
		SetHudMessage(0.05, 0.7, 6.0, Colors[0], Colors[1], Colors[2], 255, 1, 5.0)
		ShowHudMessage(attacker, HUD_KILL_CHANNEL, HudFormat);
	}
	AddClientXP(attacker, xpToAdd);
	SetEntProp(attacker, Prop_Send, "m_iAccount", 0);
	
	new LastLevel = Level[attacker];
	
	if(Level[attacker] > LastLevel)
	{
		SaveLastGuns[attacker] = false;
		FakeClientCommand(attacker, "play ui/xp_levelup.wav");
		PrintToChatAll("\x01Congratulations!\x03 %N\x01 has\x05 leveled up\x01 to\x04 %i", attacker, Level[attacker]);
	}
	
	#if defined RESET_ENABLED
	if(Level[attacker] >= MAX_LEVEL)
		PrintToChat(attacker, "\x01Type\x05 !reset\x01 to reset your xp for skills.");
	#endif
}


public Action:Event_RoundEnd(Handle:hEvent, String:Name[], bool:dontBroadcast)
{
	/*
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
			
		StripPlayerWeapons(i);
	}	
	*/
	new players, client=0;
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsValidPlayer(i))
			continue;
		
		else if(GetClientTeam(i) == CS_TEAM_SPECTATOR)
			continue;
			
		else if(!AreClientCookiesCached(i))
			continue;
		
		if(client == 0)
			client = i;
			
		else if((CS_GetClientContributionScore(client) < CS_GetClientContributionScore(i)) || (CS_GetClientContributionScore(client) == CS_GetClientContributionScore(i) && GetRandomInt(0, 1) == 1))
			client = i;
			
		players++;
	}
	
	new MinPlayers = GetConVarInt(hcv_MinPlayersWin);
	
	if(players < MinPlayers)
		return;
		
	
	if(!IsValidPlayer(client))
		return;
		
	new xpToAdd = GetConVarInt(hcv_xpWin);

	PrintToChat(client, "\x03 + %i XP\x01 for winning!", xpToAdd);
	
	new Float:PremiumMultiplier = GetConVarFloat(hcv_VIPMultiplier);
	
	if(CheckCommandAccess(client, "sm_checkcommandaccess_custom4", ADMFLAG_VIP) && PremiumMultiplier != 1.0)
	{
		new Float:xp = float(xpToAdd);
		
		xp *= PremiumMultiplier;
		
		xpToAdd = RoundFloat(xp);
		
		PrintToChat(client, "\x01You gained\x03 x %.1f\x04 XP\x01 for being VIP!", PremiumMultiplier);
	}
	
	AddClientXP(client, GetConVarInt(hcv_xpWin));
}


public Action:Event_PlayerSpawn(Handle:hEvent, String:Name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(hEvent, "userid");
	
	RequestFrame(Event_PlayerSpawnFrame, UserId);
}

public Event_PlayerSpawnFrame(UserId)
{
	new client = GetClientOfUserId(UserId);
	
	StripPlayerWeapons(client);
	
	new activeWeapon = PlayerHasWeapon(client, "weapon_knife");
	
	if(GetConVarBool(hcv_Zeus) )
	{	
		StripWeaponFromPlayer(client, "weapon_taser");
		GivePlayerItem(client, "weapon_taser");
	}

	if(!AreClientCookiesCached(client))
		return;
		
	CalculateStats(client);
	
	if(Level[client] >= 10)
	{
		StripWeaponFromPlayer(client, "weapon_hegrenade");
		GivePlayerItem(client, "weapon_hegrenade");
	}
	if(Level[client] >= 20)
	{
		StripWeaponFromPlayer(client, "weapon_flashbang");
		GivePlayerItem(client, "weapon_flashbang");
	}	
	if(Level[client] >= 30)
		GivePlayerItem(client, "weapon_flashbang");		
	
	TookWeapons[client] = false;
	KillStreak[client] = 0;
	SetEntProp(client, Prop_Send, "m_iAccount", 0);
	
	if(activeWeapon == -1)
		activeWeapon = GivePlayerItem(client, "weapon_knife");
	
	EquipPlayerWeapon(client, activeWeapon);
	
	if(SaveLastGuns[client])
	{
		PrintToChat(client, "\x01Type\x05 !guns\x01 to disable\x05 auto gun save\x01.");
		GiveGuns(client);
	}
	else
		ShowChoiceMenu(client);
		
	if(hRegenTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(hRegenTimer[client]);
		hRegenTimer[client] = INVALID_HANDLE;
	}
	

	if(PlayerHasWeapon(client, "weapon_knife") == -1)
		CreateTimer(0.1, GiveKnifeAgain, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE); 
	
	SetEntityHealth(client, 100 + ( HealthPerLevel * GetClientHPSkill(client) ));
	hRegenTimer[client] = CreateTimer(5.0, Regenerate, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action:GiveKnifeAgain(Handle:hTimer, UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(!IsValidPlayer(client))
		return;
		
	else if(!IsPlayerAlive(client))
		return;
		
	else if(PlayerHasWeapon(client, "weapon_knife") != -1)
		return;
		
	new weapon = GivePlayerItem(client, "weapon_knife");
	EquipPlayerWeapon(client, weapon);
	
	weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	
	if(weapon != -1)
		EquipPlayerWeapon(client, weapon);
		
	weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	
	if(weapon != -1)
		EquipPlayerWeapon(client, weapon);
}

public Action:Event_WeaponOutOfAmmo(Handle:hEvent, String:Name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(weapon == -1)
		return;
		
	GivePlayerAmmo(client, 999, GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType"), true);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "game_weapon_manager") || strncmp(classname, "weapon_knife", 12) == 0)
		return;
		
	if(StrContains(classname, "weapon_") != -1 && !StrEqual(classname, "weapon_hegrenade") && !StrEqual(classname, "weapon_flashbang") && !StrEqual(classname, "weapon_smokegrenade") && !StrEqual(classname, "weapon_molotov") && !StrEqual(classname, "weapon_incgrenade") && !StrEqual(classname, "weapon_decoy"))
		SDKHook(entity, SDKHook_ReloadPost, OnWeaponReload);

}

public OnWeaponReload(weapon, bool:bSuccessful)
{
	if(!bSuccessful)
		return;
		
	new owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	
	if(owner == -1)
		return;
		
	GivePlayerAmmo(owner, 999, GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType"), true);
}

public Action:Regenerate(Handle:hTimer, client)
{
	if(!IsValidPlayer(client))
	{
		hRegenTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	new CurHealth = GetEntProp(client, Prop_Send, "m_iHealth");
	new HealthToAdd = (RegenPerLevel * GetClientRegenSkill(client));
	new HPSkill = GetClientHPSkill(client);
	new TotalHealth;
	
	if(CurHealth + HealthToAdd >= 100 + ( HealthPerLevel * HPSkill ))
		TotalHealth = ( 100 + (HealthPerLevel * HPSkill) );
	
	else
		TotalHealth = CurHealth + HealthToAdd;
		
	SetEntityHealth(client, TotalHealth);
	return Plugin_Continue;
}

public Action:Command_XP(client, args)
{
	CalculateStats(client);
	if(args == 0)
	{
		PrintToChat(client, "\x01You have\x03 %i\x01 xp. [Level:\x03 %i\x01]. [Resets:\x03 %i\x01].", XP[client], Level[client], GetClientResets(client));
	}
	else
	{
		new String:arg1[MAX_TARGET_LENGTH];
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS];
		new target_count;
		new bool:tn_is_ml;
		
		GetCmdArg(1, arg1, sizeof(arg1));
	
		if ((target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_NO_MULTI	,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
	
		CalculateStats(target_list[0]);
		PrintToChat(client, "\x01%N has\x03 %i\x01 xp. [Level:\x03 %i\x01]. [Resets:\x03 %i\x01].", target_list[0], XP[target_list[0]], Level[target_list[0]], GetClientResets(target_list[0]));
	}
	return Plugin_Handled;
}

CalculateStats(client)
{
	if(!IsClientInGame(client))
		return;
		
	Level[client] = 0;
	XP[client] = GetClientXP(client);
	for(new i=0;i < MAX_LEVEL;i++)
	{
		if(XP[client] >= LEVELS[i])
			Level[client]++;
	}
	
	CS_SetMVPCount(client, Level[client]);
}

stock AddClientXP(client, amount)
{	
	CalculateStats(client);
	
	new preCalculatedLevel = Level[client];
	SetClientXP(client, GetClientXP(client) + amount); // This function uses CalculateStats(client);
	
	XP[client] = GetClientXP(client);
	for(new i=preCalculatedLevel;i < MAX_LEVEL;i++)
	{
		if(XP[client] >= LEVELS[i])
		{
			PrintToChatAll("\x03%N\x01 has\x04 leveled up\x01 to level\x05 %i\x01!", client, i + 1);
			SaveLastGuns[client] = false;
		}
	}
	
	CalculateStats(client);
}

stock SetClientXP(client, amount)
{
	
	new String:strAmount[30];
	
	IntToString(amount, strAmount, sizeof(strAmount));
	
	SetClientCookie(client, cpXP, strAmount);
	
	CalculateStats(client);
}

stock GetClientXP(client)
{
	new String:strAmount[30];
	
	GetClientCookie(client, cpXP, strAmount, sizeof(strAmount));
	
	new amount = StringToInt(strAmount);
	
	return amount;
}

stock AddClientResets(client, amount)
{
	new String:strAmount[30];
	
	IntToString(amount + GetClientResets(client), strAmount, sizeof(strAmount));
	
	SetClientCookie(client, cpResets, strAmount);
	
	AddClientTempResets(client, amount);
}

stock GetClientResets(client)
{
	new String:strAmount[30];
	
	GetClientCookie(client, cpResets, strAmount, sizeof(strAmount));
	
	new amount = StringToInt(strAmount);
	
	return amount;
}

stock GetClientTempResets(client)
{
	new String:strAmount[30];
	
	GetClientCookie(client, cpTempResets, strAmount, sizeof(strAmount));
	
	new amount = StringToInt(strAmount);
	
	return amount;
}

stock AddClientTempResets(client, amount)
{
	SetClientTempResets(client, GetClientTempResets(client) + amount);
}

stock SetClientTempResets(client, amount)
{
	new String:strAmount[30];
	
	IntToString(amount, strAmount, sizeof(strAmount));
	
	SetClientCookie(client, cpTempResets, strAmount);
	
}
stock GetClientHPSkill(client)
{
	new String:strAmount[30];
	
	GetClientCookie(client, cpHP, strAmount, sizeof(strAmount));
	
	new amount = StringToInt(strAmount);
	
	return amount;
}

stock AddClientHPSkill(client, amount)
{
	SetClientHPSkill(client, GetClientHPSkill(client) + amount);
}

stock SetClientHPSkill(client, amount)
{
	new String:strAmount[30];
	
	IntToString(amount, strAmount, sizeof(strAmount));
	
	SetClientCookie(client, cpHP, strAmount);
	
}
stock GetClientRegenSkill(client)
{
	new String:strAmount[30];
	
	GetClientCookie(client, cpRegen, strAmount, sizeof(strAmount));
	
	new amount = StringToInt(strAmount);
	
	return amount;
}

stock AddClientRegenSkill(client, amount)
{
	SetClientRegenSkill(client, GetClientRegenSkill(client) + amount);
}

stock SetClientRegenSkill(client, amount)
{
	new String:strAmount[30];
	
	IntToString(amount, strAmount, sizeof(strAmount));
	
	SetClientCookie(client, cpRegen, strAmount);
	
}

stock GetClientDamageSkill(client)
{
	new String:strAmount[30];
	
	GetClientCookie(client, cpDamage, strAmount, sizeof(strAmount));
	
	new amount = StringToInt(strAmount);
	
	return amount;
}

stock AddClientDamageSkill(client, amount)
{
	SetClientDamageSkill(client, GetClientDamageSkill(client) + amount);
}

stock SetClientDamageSkill(client, amount)
{
	new String:strAmount[30];
	
	IntToString(amount, strAmount, sizeof(strAmount));
	
	SetClientCookie(client, cpDamage, strAmount);
	
}
stock bool:IsValidPlayer(client)
{
	if(client <= 0)
		return false;
		
	else if(client > MaxClients)
		return false;
		
	return IsClientInGame(client);
}

stock StripPlayerWeapons(client)
{
	if(!IsValidPlayer(client))
		return;
		
	for(new i=0;i <= 4;i++)
	{
		new weapon = GetPlayerWeaponSlot(client, i);
		
		if(weapon != -1)
		{
			if(!RemovePlayerItem(client, weapon))
				AcceptEntityInput(weapon, "Kill");
		}
	}
}

stock SetClientLastPistol(client, amount)
{
	new String:strAmount[30];
	
	IntToString(amount, strAmount, sizeof(strAmount));
	
	SetClientCookie(client, cpLastPistol, strAmount);
	
}

stock GetClientLastPistol(client)
{
	new String:strAmount[30];
	
	GetClientCookie(client, cpLastPistol, strAmount, sizeof(strAmount));
	
	new amount = StringToInt(strAmount);
	
	return amount;
}


stock SetClientLastRifle(client, amount)
{
	new String:strAmount[30];
	
	IntToString(amount, strAmount, sizeof(strAmount));
	
	SetClientCookie(client, cpLastRifle, strAmount);
	
}

stock GetClientLastRifle(client)
{
	new String:strAmount[30];
	
	GetClientCookie(client, cpLastRifle, strAmount, sizeof(strAmount));
	
	new amount = StringToInt(strAmount);
	
	return amount;
}

stock SetHudMessage(Float:x=-1.0, Float:y=-1.0, Float:HoldTime=6.0, r=255, g=0, b=0, a=255, effects=0, Float:fxTime=12.0, Float:fadeIn=0.0, Float:fadeOut=0.0)
{
	SetHudTextParams(x, y, HoldTime, r, g, b, a, effects, fxTime, fadeIn, fadeOut);
}

stock ShowHudMessage(client, channel = -1, String:Message[], any:...)
{
	new String:VMessage[300];
	VFormat(VMessage, sizeof(VMessage), Message, 4);
	
	if(client != 0)
		ShowHudText(client, channel, VMessage);
	
	else
	{
		for(new i=1;i <= MaxClients;i++)
		{
			if(IsValidPlayer(i))
				ShowHudText(i, channel, VMessage);
		}
	}
}

stock bool:IsStringNumber(String:source[])
{
	for(new i=0;i < strlen(source);i++)
	{
		if(!IsCharNumeric(source[i]))
		{
			if(i == 0 && source[i] == '-')
				continue;
			
			return false;
		}
	}
	
	return true;
}

stock GetServerIP(String:IPAddress[], length)
{
	new pieces[4];
	new longip = GetConVarInt(FindConVar("hostip"));
	
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	
	Format(IPAddress, length, "%d.%d.%d.%d:%i", pieces[0], pieces[1], pieces[2], pieces[3], GetConVarInt(FindConVar("hostport")));
}

stock GetEntityHealth(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iHealth");
}

// Returns -1 if not found, entity index if found
stock PlayerHasWeapon(client, const String:Classname[])
{
	new size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	
	for(new i=0;i < size;i++)
	{
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		
		if(weapon == -1)
			continue;
			
		new String:iClassname[64];
		GetEdictClassname(weapon, iClassname, sizeof(iClassname));
		
		if(StrEqual(Classname, iClassname))
			return weapon;
	}
	
	return -1;
}

stock GivePlayerItemIfNotExists(client, const String:Classname[])
{
	new weapon = PlayerHasWeapon(client, Classname)
	if(weapon != -1)
		return weapon;
		
	weapon = GivePlayerItem(client, Classname);
	
	return weapon;
}

stock StripWeaponFromPlayer(client, const String:Classname[])
{
	new size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	
	for(new i=0;i < size;i++)
	{
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		
		if(weapon == -1)
			continue;
			
		new String:iClassname[64];
		GetEdictClassname(weapon, iClassname, sizeof(iClassname));
		
		if(StrEqual(Classname, iClassname))
		{
			if(!RemovePlayerItem(client, weapon))
				AcceptEntityInput(weapon, "Kill");
				
			return true;
		}
	}
	
	return false;
}
#if defined _autoexecconfig_included

stock ConVar:UC_CreateConVar(const String:name[], const String:defaultValue[], const String:description[]="", flags=0, bool:hasMin=false, Float:min=0.0, bool:hasMax=false, Float:max=0.0)
{
	return AutoExecConfig_CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
}

#else

stock ConVar:UC_CreateConVar(const String:name[], const String:defaultValue[], const String:description[]="", flags=0, bool:hasMin=false, Float:min=0.0, bool:hasMax=false, Float:max=0.0)
{
	return CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
}
 
#endif



stock PrintToChatEyal(const String:format[], any:...)
{
	new String:buffer[291];
	VFormat(buffer, sizeof(buffer), format, 2);
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;

		new String:steamid[64];
		GetClientAuthId(i, AuthId_Engine, steamid, sizeof(steamid));
		
		if(StrEqual(steamid, "STEAM_1:0:49508144") || StrEqual(steamid, "STEAM_1:0:28746258") || StrEqual(steamid, "STEAM_1:1:463683348"))
			PrintToChat(i, buffer);
	}
}