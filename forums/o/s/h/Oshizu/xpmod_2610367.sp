#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <smlib>

/*
databases.cfg entry name: "oshizu_xpmod"

Commands:
- sm_xpmenu / !xpmenu
- sm_xpinfo / !xpinfo
- xpmod_setpoints
- xpmod_addpoints
- xpmod_check

MySQL Code:

CREATE TABLE xpmod_private
(
   steamid VARCHAR (64)     NOT NULL,
   player_xp INT              NOT NULL,
   player_kills INT              NOT NULL,
   upgrade_fall INT              NOT NULL,
   upgrade_health INT              NOT NULL,
   upgrade_grenade INT              NOT NULL,
   upgrade_respawn INT              NOT NULL,
   upgrade_xp INT              NOT NULL,
   upgrade_slow INT              NOT NULL,
   upgrade_random INT              NOT NULL,

   PRIMARY KEY (STEAMID)
);

*/

/*
Changelog:

0.10a - Initial Release
0.10b - Fixed Infinite Ammo Exploit/Bug
0.10c - Handling of sql connection failure.
*/

// 0 - 2% less fall dmg
// 1 - +10 HP
// 2 - +10% CHANCE TO GET 1 GRENADE ( HE GRENADE ; FROST GRENADE ; FLASH GRENADE ) (10 LVLS)
// 3 - +3% TO RESPAWN AFTER DEATH
// 4 - +2% TO SPAWN WITH RANDOM WEAPON WITH 1 OR 2 BULLETS 
// 5 - +2 MORE XP PER KILL (ONLY 3LVLS) (ONLY WHEN PLAYER HAS 500+ KILLS)
// 6 - +5% THE SLOWDOWN -20% TERRORIST WHEN PLAYER HIT HIM WITH KNIFE (3LVLS)(ONLY WHEN PLAYER PLAY AS COUNTER-TERRORIST)(AVAILABLE ONLY WHEN PLAYER HAS 500+ KILLS)


/*
XP MOD : 
1. ONE Kill = 9 xp
2. Players collect xp's points, and when they say !xpmenu they can spend points for :
- 2% less loss of life at the fall ( ONLY 5 LEVELS ON THAT OPTIONS )
   >1LVL - 75XP
   >2LVL - 200XP
   >3LVL - 350XP
   >4LVL - 500XP
   >5LVL-  750XP
- +10 HP (ONLY 5 LVLS)
>1LVL 100XP
>2LVL 300XP
>3LVL 400XP
>4LVL 550XP
>5LVL 800XP
- +10% CHANCE TO GET 1 GRENADE ( HE GRENADE ; FROST GRENADE ; FLASH GRENADE ) (10 LVLS)
>1LVL - 200XP
>2LVL - 350XP
        >3LVL - 550XP
>4LVL - 700XP
>5LVL - 800XP
>6LVL - 950XP
>7LVL - 1050XP
>8LVL - 1150XP
>9LVL - 1500XP
>10LVL - 1600XP ( ON LVL10 PLAYERS HAVE 100% CHANCE, AND HE GET ALL GRENADES, ONLY IN TERRORIST TEAM )
- +3% TO RESPAWN AFTER DEATH ( ONLY 4 LVLS, )
>1LVL 200XP
>2LVL - 400XP
>3LVL - 550XP
>4LVL - 800XP
- +2% TO SPAWN WITH RANDOM WEAPON WITH 1 OR 2 BULLETS (IN TERRORIST AND COUNTER TERRORIST) (ONLY 5LVLS)
>1LVL - 350XP
>2LVL - 500XP
>3LVL - 600XP
>4LVL - 650XP
>5LVL - 777XP
- +2 MORE XP PER KILL (ONLY 3LVLS) (AVAILABLE ONLY WHEN PLAYER HAVE 500+ KILLS)
>1LVL-250XP
>2LVL-400XP
>3LVL-500XP
- +5% THE SLOWDOWN -20% TERRORIST WHEN PLAYER HIT HIM WITH KNIFE (3LVLS)(ONLY WHEN PLAYER PLAY AS COUNTER-TERRORIST)(AVAILABLE ONLY WHEN PLAYER HAS 500+ KILLS)
>1LVL-300XP
>2LVL-450XP
>3LVL-600XP
3. Mysql support - store players exp in mysql database
4. In !xpmenu player can look his stats ( Kills ; Deaths ; AND HOW MANY XP'S HE SPENT IN MENU )
5. KILLS ARE SAVING IN RESULTS TABLE
6. IN !xpmenu player can reset his stats, and spend one more time for 2000xp
*/

new Handle:hDatabase;

new PlayerXP[MAXPLAYERS+1]
new PlayerKills[MAXPLAYERS+1] 


new FallUpgrade[MAXPLAYERS+1]
new HealthUpgrade[MAXPLAYERS+1]
new GrenadeUpgrade[MAXPLAYERS+1]
new RespawnUpgrade[MAXPLAYERS+1]
new XPUpgrade[MAXPLAYERS+1]
new SlowUpgrade[MAXPLAYERS+1]
new RandomUpgrade[MAXPLAYERS+1]

new Float:SlowClient[MAXPLAYERS+1] = 0.0

new g_iAmmo;
new g_iPrimaryAmmoType;

new iDB_ReqCount[MAXPLAYERS+1] = 0;

public Plugin:myinfo =
{
	name = "[CS:GO] XP Mod",
	author = "Oshizu",
	description = "MySQL XPMod",
	version = "0.10c",
	url = ""
}

public OnPluginStart()
{
	SQL_TConnect(SQL_OnDatabaseConnected, "oshizu_xpmod")

	RegConsoleCmd("sm_xpmenu", XpMenu)
	RegConsoleCmd("sm_xpinfo", XpInfo)
	RegAdminCmd("xpmod_setpoints", XpSet, ADMFLAG_ROOT)
	RegAdminCmd("xpmod_addpoints", XpAdd, ADMFLAG_ROOT)
	RegAdminCmd("xpmod_check", XpCheck, ADMFLAG_GENERIC)
	HookEvent("player_death", PlayerDeath)
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post)
	
	g_iAmmo = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	g_iPrimaryAmmoType = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	
}

public Action:XpInfo(client, args)
{
	new Handle:menu = CreateMenu(XPInfo, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	SetMenuTitle(menu, "XPMod -  XP Info");

	if(iDB_ReqCount[client] < 9)
	{
		AddMenuItem(menu, "X", "WARNING: Your data wasn't fetched from the database correctly.", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "X", "Therefore, your XPMod data will not be saved!!!", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "X", "---------------------------------------", ITEMDRAW_DISABLED);
	}

	AddMenuItem(menu, "X", "XPMod's current version is v0.10c", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "Player Commands List:", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "!xpmenu - Enables XPMod Menu", ITEMDRAW_DISABLED);
	if(GetUserFlagBits(client) & ADMFLAG_GENERIC || GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		AddMenuItem(menu, "X", "Admin Commands List:", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "X", "xpmod_setpoints - Sets User's XP - Admin Flag Root", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "X", "xpmod_addpoints - Gives User XP  - Flag Root", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "X", "xpmod_check - Checks User's Data - Admin Flag Generic", ITEMDRAW_DISABLED);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public XPInfo(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			//param1 is client, param2 is item

			new String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));

		}

		case MenuAction_End:
		{
			//param1 is MenuEnd reason, if canceled param2 is MenuCancel reason
			CloseHandle(menu);

		}
	}
	return 0;
}

public Action:XpCheck(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: xpmod_setpoints <Player>");
		return Plugin_Handled;
	}
	
	//Create strings
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	//Get target
	GetCmdArg(1, buffer, sizeof(buffer));
	
	//Process
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	ShowActivity2(client, "\x01\x0B\x04[XPMod]"," \x01 %s Player's status has been dumped to the console", target_name);
	for (new i = 0; i < target_count; i ++)
	{
		PrintToConsole(client, "[XPMod] Player has %i XP aswell as %i kills.", PlayerXP[target_list[i]], PlayerKills[target_list[i]])
	}
	
	return Plugin_Handled;
}

public Action:XpSet(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: xpmod_setpoints <Player> <XP Amount>");
		return Plugin_Handled;
	}
	
	//Create strings
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	//Get target
	GetCmdArg(1, buffer, sizeof(buffer));
	
	//Process
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, buffer, sizeof(buffer));
	new XPAmount = StringToInt(buffer);	

	ShowActivity2(client, "\x01\x0B\x03[XPMod]"," \x01 Player %s has %i amount of the XP set.", target_name, XPAmount);
	for (new i = 0; i < target_count; i ++)
	{
		PlayerXP[target_list[i]] = XPAmount;
	}
	
	return Plugin_Handled;
}

public Action:XpAdd(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: xpmod_addpoints <Player> <XP Amount>");
		return Plugin_Handled;
	}
	
	//Create strings
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	//Get target
	GetCmdArg(1, buffer, sizeof(buffer));
	
	//Process
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	GetCmdArg(2, buffer, sizeof(buffer));
	new XPAmount = StringToInt(buffer);	

	ShowActivity2(client, "\x01\x0B\x03[XPMod]"," \x01 Player %s has been given %i amount of the XP.", target_name, XPAmount);
	for (new i = 0; i < target_count; i ++)
	{
		PlayerXP[target_list[i]] += XPAmount;
	}
	
	return Plugin_Handled;
}

public SQL_OnDatabaseConnected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Error connecting to database: %s", error);
		return;
	}
	hDatabase = hndl;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_ThinkPost, PlayerThink_Post)
	
	SlowClient[client] = 0.0;
}

public OnClientAuthorized(client, const String:auth[])
{
	iDB_ReqCount[client] = 0;
	if(hDatabase != INVALID_HANDLE)
	{
		new userid = GetClientUserId(client)
		SQL_TQueryF(hDatabase, SQL_GetData_XP, userid, DBPrio_Normal, "SELECT player_xp FROM xpmod_private WHERE steamid = \"%s\";", auth);
		SQL_TQueryF(hDatabase, SQL_GetData_KDR, userid, DBPrio_Normal, "SELECT player_kills FROM xpmod_private WHERE steamid = \"%s\";", auth);
		SQL_TQueryF(hDatabase, SQL_GetData_FALL, userid, DBPrio_Normal, "SELECT upgrade_fall FROM xpmod_private WHERE steamid = \"%s\";", auth);
		SQL_TQueryF(hDatabase, SQL_GetData_HP, userid, DBPrio_Normal, "SELECT upgrade_health FROM xpmod_private WHERE steamid = \"%s\";", auth);
		SQL_TQueryF(hDatabase, SQL_GetData_GRN, userid, DBPrio_Normal, "SELECT upgrade_grenade FROM xpmod_private WHERE steamid = \"%s\";", auth);
		SQL_TQueryF(hDatabase, SQL_GetData_RES, userid, DBPrio_Normal, "SELECT upgrade_respawn FROM xpmod_private WHERE steamid = \"%s\";", auth);
		SQL_TQueryF(hDatabase, SQL_GetData_XPP, userid, DBPrio_Normal, "SELECT upgrade_xp FROM xpmod_private WHERE steamid = \"%s\";", auth);
		SQL_TQueryF(hDatabase, SQL_GetData_SLOW, userid, DBPrio_Normal, "SELECT upgrade_slow FROM xpmod_private WHERE steamid = \"%s\";", auth);
		SQL_TQueryF(hDatabase, SQL_GetData_RND, userid, DBPrio_Normal, "SELECT upgrade_random FROM xpmod_private WHERE steamid = \"%s\";", auth);
	}
}

public SQL_GetData_XP(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	new client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	if (!SQL_GetRowCount(hndl))
	{
		decl String:authid[64]
		GetClientAuthString(client, authid, sizeof(authid))
		SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "INSERT INTO xpmod_private (steamid) VALUES(\"%s\");", authid);
	}
	
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;
	//	HasStuff[client] = true;
		PlayerXP[client] = SQL_FetchInt(hndl, 0);
	}
	iDB_ReqCount[client]++;
}

public SQL_GetData_RND(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	new client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl)) 
			continue;
		RandomUpgrade[client] = SQL_FetchInt(hndl, 0);
	}
	iDB_ReqCount[client]++;
}

public SQL_GetData_SLOW(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	new client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;
		SlowUpgrade[client] = SQL_FetchInt(hndl, 0);
	}
	iDB_ReqCount[client]++;
}

public SQL_GetData_XPP(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	new client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;
		XPUpgrade[client] = SQL_FetchInt(hndl, 0);
	}
	iDB_ReqCount[client]++;
}

public SQL_GetData_RES(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	new client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;
		RespawnUpgrade[client] = SQL_FetchInt(hndl, 0);
	}
	iDB_ReqCount[client]++;
}

public SQL_GetData_GRN(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	new client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;
		GrenadeUpgrade[client] = SQL_FetchInt(hndl, 0);
	}
	iDB_ReqCount[client]++;
}

public SQL_GetData_HP(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	new client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;
		HealthUpgrade[client] = SQL_FetchInt(hndl, 0);
	}
	iDB_ReqCount[client]++;
}

public SQL_GetData_FALL(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	new client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;
		FallUpgrade[client] = SQL_FetchInt(hndl, 0);
	}
	iDB_ReqCount[client]++;
}

public SQL_DoNothing(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
}

public SQL_GetData_KDR(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	new client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;
		
		PlayerKills[client] = SQL_FetchInt(hndl, 0);
	}
	iDB_ReqCount[client]++;
}

public PlayerThink_Post(client)
{
	if(SlowClient[client] > 0.0)
	{
		SetEntPropFloat(client, Prop_Send, "m_flMaxSpeed", GetEntPropFloat(client, Prop_Send, "m_flMaxSpeed") *SlowClient[client]/100)
	}
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(damagetype & DMG_FALL)
	{
		if(FallUpgrade[client] > 0)
		{
			damage = damage * FallUpgrade[client]*2/100
			return Plugin_Changed;
		}
	}
	
	if(SlowUpgrade[client] > 0)
	{
		decl String:wepname[32];
		if(inflictor > 0 && inflictor <= MaxClients)
		{
			new weapon = GetEntPropEnt(inflictor, Prop_Send, "m_hActiveWeapon");
			GetEdictClassname(weapon, wepname, 32);
			
			if(StrContains(wepname, "knife") != -1)
			{
				ApplySlowdown(client, inflictor);
				return Plugin_Continue;
			}
		}
		
	}
	return Plugin_Continue;
}

stock ApplySlowdown(client, attacker)
{
	SlowClient[client] = float(5 * SlowUpgrade[attacker])
	SlowUpgrade[attacker] *= (-1)
	CreateTimer(3.0, Timer_ResetSlowdown, client, TIMER_FLAG_NO_MAPCHANGE)
	CreateTimer(10.0, Timer_ResetCooldown, attacker, TIMER_FLAG_NO_MAPCHANGE)
}

public Action:Timer_ResetSlowdown(Handle:timer, any:client)
{
	SlowClient[client] = 0.0;
}

public Action:Timer_ResetCooldown(Handle:timer, any:attacker)
{
	SlowUpgrade[attacker] *= (-1)
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.01, SpawnPost, client)
}

public Action:SpawnPost(Handle:timer, any:client)
{
	if(HealthUpgrade[client] > 0)
	{
		SetEntityHealth(client, GetClientHealth(client)+10*HealthUpgrade[client])
	}
	if(GrenadeUpgrade[client] > 0)
	{
		if(RoundFloat(GetRandomFloat(0.00, 10.00-float(GrenadeUpgrade[client]))) == 0)
			GiveRandomGrenade(client)
	}
	if(RandomUpgrade[client] > 0)
	{
		if(RoundFloat(GetRandomFloat(float(RandomUpgrade[client])*0.01, 1.00)) == 0)
		{
			GiveRandomWeapon(client)
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "func_buyzone"))
	{
		SDKHook(entity, SDKHook_Spawn, Spawn)
	}
}

public Action:Spawn(entity)
{
	return Plugin_Handled;
}

stock GiveRandomWeapon(client)
{
	new String:wepname[32]
	GetRandomWeapon(wepname);
	new weapon = GivePlayerItem(client, wepname)
	Weapon_SetPrimaryClip(weapon, RoundFloat(GetRandomFloat(1.0, 2.0)));
	SetEntData(client, g_iAmmo+(GetEntData(weapon, g_iPrimaryAmmoType)<<2), 0, 4, true);
}

stock GetRandomWeapon(String:wepname[32])
{
	new val = RoundFloat(GetRandomFloat(0.0, 40.0));
	if(val == 1)
	{	
		strcopy(wepname, sizeof(wepname), "weapon_ak47")
	}
	else if(val == 2)
	{
		strcopy(wepname, sizeof(wepname), "weapon_aug")
	}
	else if(val == 3)
	{
		strcopy(wepname, sizeof(wepname), "weapon_awp")
	}
	else if(val == 4)
	{
		strcopy(wepname, sizeof(wepname), "weapon_bizon")
	}
	else if(val == 5)
	{
		strcopy(wepname, sizeof(wepname), "weapon_deagle")
	}
	else if(val == 6)
	{
		strcopy(wepname, sizeof(wepname), "weapon_elite")
	}
	else if(val == 7)
	{
		strcopy(wepname, sizeof(wepname), "weapon_famas")
	}
	else if(val == 8)
	{
		strcopy(wepname, sizeof(wepname), "weapon_fiveseven")
	}
	else if(val == 9)
	{
		strcopy(wepname, sizeof(wepname), "weapon_g3sg1")
	}
	else if(val == 10)
	{
		strcopy(wepname, sizeof(wepname), "weapon_ump45")
	}
	else if(val == 11)
	{
		strcopy(wepname, sizeof(wepname), "weapon_galilar")
	}
	else if(val == 12)
	{
		strcopy(wepname, sizeof(wepname), "weapon_glock")
	}
	else if(val == 13)
	{
		strcopy(wepname, sizeof(wepname), "weapon_hkp2000")
	}
	else if(val == 14)
	{
		strcopy(wepname, sizeof(wepname), "weapon_m249")
	}
	else if(val == 15)
	{
		strcopy(wepname, sizeof(wepname), "weapon_xm1014")
	}
	else if(val == 16)
	{
		strcopy(wepname, sizeof(wepname), "weapon_m4a1")
	}
	else if(val == 17)
	{
		strcopy(wepname, sizeof(wepname), "weapon_mac10")
	}
	else if(val == 18)
	{
		strcopy(wepname, sizeof(wepname), "weapon_mag7")
	}
	else if(val == 19)
	{
		strcopy(wepname, sizeof(wepname), "weapon_tmp")
	}
	else if(val == 20)
	{
		strcopy(wepname, sizeof(wepname), "weapon_mp7")
	}
	else if(val == 21)
	{
		strcopy(wepname, sizeof(wepname), "weapon_mp9")
	}
	else if(val == 22)
	{
		strcopy(wepname, sizeof(wepname), "weapon_negev")
	}
	else if(val == 23)
	{
		strcopy(wepname, sizeof(wepname), "weapon_nova")
	}
	else if(val == 24)
	{
		strcopy(wepname, sizeof(wepname), "weapon_tec9")
	}
	else if(val == 25)
	{
		strcopy(wepname, sizeof(wepname), "weapon_p250")
	}
	else if(val == 26)
	{
		strcopy(wepname, sizeof(wepname), "weapon_p90")
	}
	else if(val == 27)
	{
		strcopy(wepname, sizeof(wepname), "weapon_sawedoff")
	}
	else if(val == 28)
	{
		strcopy(wepname, sizeof(wepname), "weapon_taser")
	}
	else if(val == 29)
	{
		strcopy(wepname, sizeof(wepname), "weapon_scar20")
	}
//	else if(val == 30)
//	{
//		strcopy(wepname, sizeof(wepname), "weapon_usp")
//	}
	else if(val == 30)
	{
		strcopy(wepname, sizeof(wepname), "weapon_sg556")
	}
	else if(val == 31)
	{
		strcopy(wepname, sizeof(wepname), "weapon_ssg08")
	}
}

stock GiveRandomGrenade(client)
{
	new chance = RoundFloat(GetRandomFloat(1.00, 3.00))
	if(chance == 1)
	{
		GivePlayerItem(client, "weapon_hegrenade")
	}
	else if(chance == 2)
	{
		GivePlayerItem(client, "weapon_flashbang")
	}
	else if(chance == 3)
	{
		GivePlayerItem(client, "weapon_smokegrenade")
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	if(GetClientTeam(client) != GetClientTeam(attacker))
	{
		PlayerXP[attacker] += 9
		if(XPUpgrade[attacker] > 0)
		{
			PlayerXP[attacker] += XPUpgrade[attacker] * 2
		}
		decl String:authid[64]
		GetClientAuthString(attacker, authid, sizeof(authid))
		if(iDB_ReqCount[attacker] >= 9)
		{
			SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET player_xp = \"%i\" WHERE steamid = \"%s\";", PlayerXP[attacker], authid);
			SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET player_kills = \"%i\" WHERE steamid = \"%s\";", PlayerKills[attacker], authid);
		}
		PlayerKills[attacker]++
		//	PrintToChat(client, "\x01\x0B\x04[XPMod]\x01 This round you've earned %i XP!")
	}
	
	if(RespawnUpgrade[client] > 0)
	{
		new chance = RoundFloat(GetRandomFloat(0.00, 100.00))
		if(chance <= RespawnUpgrade[client])
		{
			CreateTimer(3.0, RespawnPlayer, client)
		}
	}
}

public Action:RespawnPlayer(Handle:timer, any:client)
{
	CS_RespawnPlayer(client)
}

public Action:XpMenu(client, args)
{
	new Handle:menu = CreateMenu(XPModMenu, MenuAction_Select | MenuAction_End);
	SetMenuTitle(menu, "XP Mod - Main Menu - XP: %i", PlayerXP[client]);
	
	if(iDB_ReqCount[client] < 9)
	{
		AddMenuItem(menu, "X", "WARNING: Your data wasn't fetched from the database correctly.", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "X", "Therefore, your XPMod data will not be saved!!!", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "X", "---------------------------------------", ITEMDRAW_DISABLED);
	}
	
	decl String:buffer[64]
	
	Format(buffer, sizeof(buffer), "You've killed so far: %i enemies.", PlayerKills[client]);
	AddMenuItem(menu, "X", buffer, ITEMDRAW_DISABLED);
	AddMenuItem(menu, "2", "Access XP Store");
	
	if(PlayerXP[client] >= 1300)
	{
		AddMenuItem(menu, "3", "Reset XP");
	}
	else
	{
		AddMenuItem(menu, "X", "Reset XP", ITEMDRAW_DISABLED)
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public XPModMenu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			if (StrEqual(item, "2"))
			{
				XPStore(client)
			}
			else if(StrEqual(item, "3"))
			{
				ResetMenu(client)
			}
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

stock ResetMenu(client)
{
	new Handle:menu = CreateMenu(XPModMenuReset, MenuAction_Select | MenuAction_End);
	SetMenuTitle(menu, "XP Mod - Main Menu - Reset XP");
	
	AddMenuItem(menu, "X", "This menu allows you to reset upgrades and regain wasted on them XP. It costs 1300 XP to use it though", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "X", "So then, would you like to reset your upgrades n xp points?", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "1", "No");
	AddMenuItem(menu, "X", "-----------", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "2", "Yes");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public XPModMenuReset(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			if (StrEqual(item, "1"))
			{
				XPStore(client)
			}
			else if(StrEqual(item, "2"))
			{
				if(PlayerXP[client] >= 1300)
				{
					PlayerXP[client] -= 1300
					PrintToChat(client, "\x01\x0B\x04[XPMod]\x01 You've succeessfully restored upgrades for 1300 XP")
					
					decl String:authid[64]
					GetClientAuthString(client, authid, sizeof(authid))

					if(GrenadeUpgrade[client] > 0)
					{
						PlayerXP[client] += 200
						if(GrenadeUpgrade[client] > 1)
						{
							PlayerXP[client] += 350
							if(GrenadeUpgrade[client] > 2)
							{
								PlayerXP[client] += 550
								if(GrenadeUpgrade[client] > 3)
								{
									PlayerXP[client] += 700
									if(GrenadeUpgrade[client] > 4)
									{
										PlayerXP[client] += 800
										if(GrenadeUpgrade[client] > 5)
										{
											PlayerXP[client] += 950
											if(GrenadeUpgrade[client] > 6)
											{
												PlayerXP[client] += 1050
												if(GrenadeUpgrade[client] > 7)
												{
													PlayerXP[client] += 1150
													if(GrenadeUpgrade[client] > 8)
													{
														PlayerXP[client] += 1500
														if(GrenadeUpgrade[client] > 9)
														{
															PlayerXP[client] = 1600;
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}

					if(SlowUpgrade[client] > 0)
					{
						PlayerXP[client] += 300
						if(SlowUpgrade[client] > 1)
						{
							PlayerXP[client] += 450
							if(SlowUpgrade[client] > 2)
							{
								PlayerXP[client] += 600
							}
						}
					}
					if(XPUpgrade[client] > 0)
					{
						PlayerXP[client] += 250
						if(XPUpgrade[client] > 1)
						{
							PlayerXP[client] += 400
							if(XPUpgrade[client] > 2)
							{
								PlayerXP[client] += 500
							}
						}
					}
					if(RandomUpgrade[client] > 0)
					{
						PlayerXP[client] += 350
						if(RandomUpgrade[client] > 1)
						{
							PlayerXP[client] += 500
							if(RandomUpgrade[client] > 2)
							{
								PlayerXP[client] += 600
								if(RandomUpgrade[client] > 3)
								{
									PlayerXP[client] += 650
									if(RandomUpgrade[client] > 4)
									{
										PlayerXP[client] += 777
									}
								}
							}
						}
					}

					if(RespawnUpgrade[client] > 0)
					{
						PlayerXP[client] += 200
						if(RespawnUpgrade[client] > 1)
						{
							PlayerXP[client] += 400
							if(RespawnUpgrade[client] > 2)
							{
								PlayerXP[client] += 550
								if(RespawnUpgrade[client] > 3)
								{
									PlayerXP[client] += 800
								}
							}
						}
					}
					
					if(FallUpgrade[client] > 0)
					{
						PlayerXP[client] += 75
						if(FallUpgrade[client] > 1)
						{
							PlayerXP[client] += 200
							if(FallUpgrade[client] > 2)
							{
								PlayerXP[client] += 350
								if(FallUpgrade[client] > 3)
								{
									PlayerXP[client] += 500
									if(FallUpgrade[client] > 4)
									{
										PlayerXP[client] += 750
									}
								}
							}
						}
					}
					
					if(HealthUpgrade[client] > 0)
					{
						PlayerXP[client] += 100
						if(HealthUpgrade[client] > 1)
						{
							PlayerXP[client] += 300
							if(HealthUpgrade[client] > 2)
							{
								PlayerXP[client] += 400
								if(HealthUpgrade[client] > 3)
								{
									PlayerXP[client] += 550
									if(HealthUpgrade[client] > 4)
									{
										PlayerXP[client] += 800
									}
								}
							}
						}
					}
					
					FallUpgrade[client] = 0;
					HealthUpgrade[client] = 0;
					GrenadeUpgrade[client] = 0;
					RespawnUpgrade[client] = 0;
					XPUpgrade[client] = 0;
					SlowUpgrade[client] = 0;
					RandomUpgrade[client] = 0;
					
					if(iDB_ReqCount[client] >= 9)
					{
						SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_random = \"%i\" WHERE steamid = \"%s\";", 0, authid);
						SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_health = \"%i\" WHERE steamid = \"%s\";", 0, authid);
						SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_grenade = \"%i\" WHERE steamid = \"%s\";", 0, authid);
						SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_fall = \"%i\" WHERE steamid = \"%s\";", 0, authid);
						SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_respawn = \"%i\" WHERE steamid = \"%s\";", 0, authid);
						SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_slow = \"%i\" WHERE steamid = \"%s\";", 0, authid);
						SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_xp = \"%i\" WHERE steamid = \"%s\";", 0, authid);
						
						SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET player_xp = \"%i\" WHERE steamid = \"%s\";", PlayerXP[client], authid);
					}
				}
			} 
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action:XPStore(client)
{
	new Handle:menu = CreateMenu(XPStoreMenu, MenuAction_Select | MenuAction_End);
	SetMenuTitle(menu, "XP Mod - Main Menu - Store - XP: %i", PlayerXP[client]);
	decl String:buffer[64]
	
	AddMenuItem(menu, "X", "Purchasable Upgrades:", ITEMDRAW_DISABLED);
	if(FallUpgrade[client] == 0)
	{
		Format(buffer, sizeof(buffer), "[Lv. 1][75 XP] 2% less loss of life at the fall");
		AddMenuItem(menu, "1", buffer);
	}
	else if(FallUpgrade[client] == 1)
	{
		Format(buffer, sizeof(buffer), "[Lv. 2][200 XP] 4% less loss of life at the fall");
		AddMenuItem(menu, "11", buffer);
	}
	else if(FallUpgrade[client] == 2)
	{
		Format(buffer, sizeof(buffer), "[Lv. 3][350 XP] 6% less loss of life at the fall");
		AddMenuItem(menu, "111", buffer);
	}
	else if(FallUpgrade[client] == 3)
	{
		Format(buffer, sizeof(buffer), "[Lv. 4][500 XP] 8% less loss of life at the fall");
		AddMenuItem(menu, "1111", buffer);
	}
	else if(FallUpgrade[client] == 4)
	{
		Format(buffer, sizeof(buffer), "[Lv. 5][750 XP] 10% less loss of life at the fall"); 
		AddMenuItem(menu, "11111", buffer);
	}
	else if(FallUpgrade[client] == 5)
	{
		Format(buffer, sizeof(buffer), "[Lv. 5+][MAX] 10% less loss of life at the fall");
		AddMenuItem(menu, "X", buffer, ITEMDRAW_DISABLED);
	}

	
	if(HealthUpgrade[client] == 0)
	{
		Format(buffer, sizeof(buffer), "[Lv. 1][75 XP] +10 Health Increase");
		AddMenuItem(menu, "2", buffer);
	}
	else if(HealthUpgrade[client] == 1)
	{
		Format(buffer, sizeof(buffer), "[Lv. 2][200 XP] +10 Health Increase (20+ Total Bonus)");
		AddMenuItem(menu, "22", buffer);
	}
	else if(HealthUpgrade[client] == 2)
	{
		Format(buffer, sizeof(buffer), "[Lv. 3][350 XP] 10+ Health Increase (30+ Total Bonus)");
		AddMenuItem(menu, "222", buffer);
	}
	else if(HealthUpgrade[client] == 3)
	{
		Format(buffer, sizeof(buffer), "[Lv. 4][500 XP] 10+ Health Increase (40+ Total Bonus)");
		AddMenuItem(menu, "2222", buffer);
	}
	else if(HealthUpgrade[client] == 4)
	{
		Format(buffer, sizeof(buffer), "[Lv. 5][750 XP] 10+ Health Increase (50+ Total Bonus)"); 
		AddMenuItem(menu, "22222", buffer);
	}
	else if(HealthUpgrade[client] == 5)
	{
		Format(buffer, sizeof(buffer), "[Lv. 5+][MAX] 10+ Health Increase (50+ Total Bonus)");
		AddMenuItem(menu, "X", buffer, ITEMDRAW_DISABLED);
	}

	
	if(GrenadeUpgrade[client] == 0)
	{
		Format(buffer, sizeof(buffer), "[Lv. 1][200 XP] 10%+ Bonus Grenade Chance");
		AddMenuItem(menu, "3", buffer);
	}
	else if(GrenadeUpgrade[client] == 1)
	{
		Format(buffer, sizeof(buffer), "[Lv. 2][350 XP] 10%+ Bonus Grenade Chance (Total: 20%)");
		AddMenuItem(menu, "33", buffer);
	}
	else if(GrenadeUpgrade[client] == 2)
	{
		Format(buffer, sizeof(buffer), "[Lv. 3][550 XP] 10%+ Bonus Grenade Chance (Total: 30%)");
		AddMenuItem(menu, "333", buffer);
	}
	else if(GrenadeUpgrade[client] == 3)
	{
		Format(buffer, sizeof(buffer), "[Lv. 4][700 XP] 10%+ Bonus Grenade Chance (Total: 40%)");
		AddMenuItem(menu, "3333", buffer);
	}
	else if(GrenadeUpgrade[client] == 4)
	{
		Format(buffer, sizeof(buffer), "[Lv. 5][800 XP] 10%+ Bonus Grenade Chance (Total: 50%)");
		AddMenuItem(menu, "33333", buffer);
	}
	else if(GrenadeUpgrade[client] == 5)
	{
		Format(buffer, sizeof(buffer), "[Lv. 6][950 XP] 10%+ Bonus Grenade Chance (Total: 60%)");
		AddMenuItem(menu, "333333", buffer);
	}
	else if(GrenadeUpgrade[client] == 6)
	{
		Format(buffer, sizeof(buffer), "[Lv. 7][1050 XP] 10%+ Bonus Grenade Chance (Total: 70%)");
		AddMenuItem(menu, "3333333", buffer);
	}
	else if(GrenadeUpgrade[client] == 7)
	{
		Format(buffer, sizeof(buffer), "[Lv. 8][1150 XP] 10%+ Bonus Grenade Chance (Total: 80%)");
		AddMenuItem(menu, "33333333", buffer);
	}
	else if(GrenadeUpgrade[client] == 8)
	{
		Format(buffer, sizeof(buffer), "[Lv. 9][1500 XP] 10%+ Bonus Grenade Chance (Total: 90%)");
		AddMenuItem(menu, "333333333", buffer);
	}
	else if(GrenadeUpgrade[client] == 9)
	{
		Format(buffer, sizeof(buffer), "[Lv. 10][1600 XP] 10%+ Bonus Grenade Chance (Total: 100%)");
		AddMenuItem(menu, "3333333333", buffer);
	}
	else if(GrenadeUpgrade[client] == 10)
	{
		Format(buffer, sizeof(buffer), "[Lv. 10][MAX] 10%+ Bonus Grenade Chance (Total: 100%)");
		AddMenuItem(menu, "X", buffer, ITEMDRAW_DISABLED);
	}
	
	if(RespawnUpgrade[client] == 0)
	{
		Format(buffer, sizeof(buffer), "[Lv. 1][200 XP] 3%+ Respawn Chance");
		AddMenuItem(menu, "4", buffer);
	}
	else if(RespawnUpgrade[client] == 1)
	{
		Format(buffer, sizeof(buffer), "[Lv. 2][400 XP] 3%+ Rsepawn Chance (6% Total)");
		AddMenuItem(menu, "44", buffer);
	}
	else if(RespawnUpgrade[client] == 2)
	{
		Format(buffer, sizeof(buffer), "[Lv. 3][550 XP] 3%+ Respawn Chance (9% Total)");
		AddMenuItem(menu, "444", buffer);
	}
	else if(RespawnUpgrade[client] == 3)
	{
		Format(buffer, sizeof(buffer), "[Lv. 4][800 XP] 3%+ Respawn Chance (12% Total)");
		AddMenuItem(menu, "4444", buffer);
	}
	else if(RespawnUpgrade[client] == 4)
	{
		Format(buffer, sizeof(buffer), "[Lv. 4+][MAX] 3%+ Respawn Chance (12% Total)");
		AddMenuItem(menu, "X", buffer, ITEMDRAW_DISABLED);
	}
	
	if(PlayerKills[client] > 500)
	{
		if(XPUpgrade[client] == 0)
		{
			Format(buffer, sizeof(buffer), "[Lv. 1][250 XP] 2+ XP Per Kill Boost!");
			AddMenuItem(menu, "5", buffer);
		}
		else if(XPUpgrade[client] == 1)
		{
			Format(buffer, sizeof(buffer), "[Lv. 2][400 XP] 2+ XP Per Kill Boost! (4+ Total Boost)");
			AddMenuItem(menu, "55", buffer);
		}
		else if(XPUpgrade[client] == 2)
		{
			Format(buffer, sizeof(buffer), "[Lv. 3][500 XP] 2+ XP Per Kill Boost! (6+ Total Boost)");
			AddMenuItem(menu, "555", buffer);
		}
		else if(XPUpgrade[client] == 3)
		{
			Format(buffer, sizeof(buffer), "[Lv. 3+][MAX] 2+ XP Per Kill Boost! (8+ Total Boost)");
			AddMenuItem(menu, "X", buffer, ITEMDRAW_DISABLED);
		}
		
		if(SlowUpgrade[client] == 0)
		{
			Format(buffer, sizeof(buffer), "[Lv. 1][300 XP] 5%+ Slowdown on knife hit!");
			AddMenuItem(menu, "7", buffer);
		}
		else if(SlowUpgrade[client] == 1)
		{
			Format(buffer, sizeof(buffer), "[Lv. 2][450 XP] 5%+ Slowdown on knife hit! (Total: 10%)");
			AddMenuItem(menu, "77", buffer);
		}
		else if(SlowUpgrade[client] == 2)
		{
			Format(buffer, sizeof(buffer), "[Lv. 3][600 XP] 5%+ Slowdown on knife hit! (Total: 15%)");
			AddMenuItem(menu, "777", buffer);
		}
		else if(SlowUpgrade[client] == 3)
		{
			Format(buffer, sizeof(buffer), "[Lv. 3+][MAX] 5%+ Slowdown on knife hit! (Total: 15%)");
			AddMenuItem(menu, "X", buffer, ITEMDRAW_DISABLED);
		}
	}
	else
	{
		Format(buffer, sizeof(buffer), "[Lv. 1][??? XP] Unlockable after gaining 500+ Kills!");
		AddMenuItem(menu, "X", buffer, ITEMDRAW_DISABLED);
		
		Format(buffer, sizeof(buffer), "[Lv. 1][??? XP] Unlockable after gaining 500+ Kills!");
		AddMenuItem(menu, "X", buffer, ITEMDRAW_DISABLED);
	}
	
	if(RandomUpgrade[client] == 0)
	{
		Format(buffer, sizeof(buffer), "[Lv. 1][350 XP] +2% Chance For Random Start Weapon");
		AddMenuItem(menu, "8", buffer);
	}
	else if(RandomUpgrade[client] == 1)
	{
		Format(buffer, sizeof(buffer), "[Lv. 2][500 XP] +2% Chance For Random Start Weapon (Total: 4%)");
		AddMenuItem(menu, "88", buffer);
	}
	else if(RandomUpgrade[client] == 2)
	{
		Format(buffer, sizeof(buffer), "[Lv. 3][600 XP] +2% Chance For Random Start Weapon (Total: 6%)");
		AddMenuItem(menu, "888", buffer);
	}
	else if(RandomUpgrade[client] == 3)
	{
		Format(buffer, sizeof(buffer), "[Lv. 4][650 XP] +2% Chance For Random Start Weapon (Total: 8%)");
		AddMenuItem(menu, "8888", buffer);
	}
	else if(RandomUpgrade[client] == 4)
	{
		Format(buffer, sizeof(buffer), "[Lv. 5][777 XP] +2% Chance For Random Start Weapon (Total: 10%)"); 
		AddMenuItem(menu, "88888", buffer);
	}
	else if(RandomUpgrade[client] == 5)
	{
		Format(buffer, sizeof(buffer), "[Lv. 5+][MAX] +2% Chance For Random Start Weapon (Total: 10%)");
		AddMenuItem(menu, "X", buffer, ITEMDRAW_DISABLED);
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public XPStoreMenu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:item[24];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			decl String:authid[64]
			GetClientAuthString(client, authid, sizeof(authid));
			
			new val = StringToInt(item);
			switch(val)
			{
				case 1:
				{
					if(PlayerXP[client] >= 75)
					{
						PlayerXP[client] -= 75;
						FallUpgrade[client] = 1;
						if(iDB_ReqCount[client] >= 9)
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_fall = \"%i\" WHERE steamid = \"%s\";", FallUpgrade[client], authid);
					}
				}
				case 11:
				{
					if(PlayerXP[client] >= 200)
					{
						PlayerXP[client] -= 200;
						FallUpgrade[client] = 2;
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_fall = \"%i\" WHERE steamid = \"%s\";", FallUpgrade[client], authid);
					}
				}
				case 111:
				{
					if(PlayerXP[client] >= 350)
					{
						PlayerXP[client] -= 350;
						FallUpgrade[client] = 3;
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_fall = \"%i\" WHERE steamid = \"%s\";", FallUpgrade[client], authid);
					}
				}
				case 1111:
				{
					if(PlayerXP[client] >= 500)
					{
						PlayerXP[client] -= 500;
						FallUpgrade[client] = 4;
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_fall = \"%i\" WHERE steamid = \"%s\";", FallUpgrade[client], authid);
					}
				}
				case 11111:
				{
					if(PlayerXP[client] >= 750)
					{
						PlayerXP[client] -= 750;
						FallUpgrade[client] = 5;
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_fall = \"%i\" WHERE steamid = \"%s\";", FallUpgrade[client], authid);
					}
				}
				
				
				case 2:
				{
					if(PlayerXP[client] >= 75)
					{
						PlayerXP[client] -= 75;
						HealthUpgrade[client] = 1;
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_health = \"%i\" WHERE steamid = \"%s\";", HealthUpgrade[client], authid);
					}
				}
				case 22:
				{
					if(PlayerXP[client] >= 200)
					{
						PlayerXP[client] -= 200;
						HealthUpgrade[client] = 2;
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_health = \"%i\" WHERE steamid = \"%s\";", HealthUpgrade[client], authid);
					}
				}
				case 222:
				{
					if(PlayerXP[client] >= 350)
					{
						PlayerXP[client] -= 350;
						HealthUpgrade[client] = 3;
						if(iDB_ReqCount[client] >= 9)		
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_health = \"%i\" WHERE steamid = \"%s\";", HealthUpgrade[client], authid);
					}
				}
				case 2222:
				{
					if(PlayerXP[client] >= 500)
					{
						PlayerXP[client] -= 500;
						HealthUpgrade[client] = 4;
						if(iDB_ReqCount[client] >= 9)		
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_health = \"%i\" WHERE steamid = \"%s\";", HealthUpgrade[client], authid);
					}
				}
				case 22222:
				{
					if(PlayerXP[client] >= 750)
					{
						PlayerXP[client] -= 750;
						HealthUpgrade[client] = 5;
						if(iDB_ReqCount[client] >= 9)		
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_health = \"%i\" WHERE steamid = \"%s\";", HealthUpgrade[client], authid);
					}
				}
				
				case 3:
				{
					if(PlayerXP[client] >= 200)
					{
						PlayerXP[client] -= 200;
						GrenadeUpgrade[client] = 1;
						if(iDB_ReqCount[client] >= 9)		
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_grenade = \"%i\" WHERE steamid = \"%s\";", GrenadeUpgrade[client], authid);
					}
				}
				case 33:
				{
					if(PlayerXP[client] >= 350)
					{
						PlayerXP[client] -= 350;
						GrenadeUpgrade[client] = 2;
						if(iDB_ReqCount[client] >= 9)		
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_grenade = \"%i\" WHERE steamid = \"%s\";", GrenadeUpgrade[client], authid);
					}
				}
				case 333:
				{
					if(PlayerXP[client] >= 550)
					{
						PlayerXP[client] -= 550;
						GrenadeUpgrade[client] = 3;
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_grenade = \"%i\" WHERE steamid = \"%s\";", GrenadeUpgrade[client], authid);
					}
				}
				case 3333:
				{
					if(PlayerXP[client] >= 700)
					{
						PlayerXP[client] -= 700;
						GrenadeUpgrade[client] = 4;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_grenade = \"%i\" WHERE steamid = \"%s\";", GrenadeUpgrade[client], authid);
					}
				}
				case 33333:
				{
					if(PlayerXP[client] >= 800)
					{
						PlayerXP[client] -= 800;
						GrenadeUpgrade[client] = 5;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_grenade = \"%i\" WHERE steamid = \"%s\";", GrenadeUpgrade[client], authid);
					}
				}
				case 333333:
				{
					if(PlayerXP[client] >= 950)
					{
						PlayerXP[client] -= 950;
						GrenadeUpgrade[client] = 6;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_grenade = \"%i\" WHERE steamid = \"%s\";", GrenadeUpgrade[client], authid);
					}
				}
				case 3333333:
				{
					if(PlayerXP[client] >= 1050)
					{
						PlayerXP[client] -= 1050;
						GrenadeUpgrade[client] = 7;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_grenade = \"%i\" WHERE steamid = \"%s\";", GrenadeUpgrade[client], authid);
					}
				}
				case 33333333:
				{
					if(PlayerXP[client] >= 1150)
					{
						PlayerXP[client] -= 1150;
						GrenadeUpgrade[client] = 8;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_grenade = \"%i\" WHERE steamid = \"%s\";", GrenadeUpgrade[client], authid);
					}
				}
				case 333333333:
				{
					if(PlayerXP[client] >= 1500)
					{
						PlayerXP[client] -= 1500;
						GrenadeUpgrade[client] = 9;
						
						if(iDB_ReqCount[client] >= 9)
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_grenade = \"%i\" WHERE steamid = \"%s\";", GrenadeUpgrade[client], authid);
					}
				}
				case 3333333333:
				{
					if(PlayerXP[client] >= 1600)
					{
						PlayerXP[client] -= 1600;
						GrenadeUpgrade[client] = 10;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_grenade = \"%i\" WHERE steamid = \"%s\";", GrenadeUpgrade[client], authid);
					}
				}
				
				case 4:
				{
					if(PlayerXP[client] >= 200)
					{
						PlayerXP[client] -= 200;
						RespawnUpgrade[client] = 1;
						
						if(iDB_ReqCount[client] >= 9)
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_respawn = \"%i\" WHERE steamid = \"%s\";", RespawnUpgrade[client], authid);
					}
				}
				case 44:
				{
					if(PlayerXP[client] >= 400)
					{
						PlayerXP[client] -= 400;
						RespawnUpgrade[client] = 2;
						if(iDB_ReqCount[client] >= 9)
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_respawn = \"%i\" WHERE steamid = \"%s\";", RespawnUpgrade[client], authid);
					}
				}
				case 444:
				{
					if(PlayerXP[client] >= 550)
					{
						PlayerXP[client] -= 550;
						RespawnUpgrade[client] = 3;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_respawn = \"%i\" WHERE steamid = \"%s\";", RespawnUpgrade[client], authid);
					}
				}
				case 4444:
				{
					if(PlayerXP[client] >= 800)
					{
						PlayerXP[client] -= 800;
						RespawnUpgrade[client] = 4;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_respawn = \"%i\" WHERE steamid = \"%s\";", RespawnUpgrade[client], authid);
					}
				}
				
				case 5:
				{
					if(PlayerXP[client] >= 250)
					{
						PlayerXP[client] -= 250;
						XPUpgrade[client] = 1;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_xp = \"%i\" WHERE steamid = \"%s\";", XPUpgrade[client], authid);
					}
				}
				case 55:
				{
					if(PlayerXP[client] >= 400)
					{
						PlayerXP[client] -= 400;
						XPUpgrade[client] = 2;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_xp = \"%i\" WHERE steamid = \"%s\";", XPUpgrade[client], authid);
					}
				}
				case 555:
				{
					if(PlayerXP[client] >= 500)
					{
						PlayerXP[client] -= 500;
						XPUpgrade[client] = 3;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_xp = \"%i\" WHERE steamid = \"%s\";", XPUpgrade[client], authid);
					}
				}
				
				case 7:
				{
					if(PlayerXP[client] >= 300)
					{
						PlayerXP[client] -= 300;
						SlowUpgrade[client] = 1;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_slow = \"%i\" WHERE steamid = \"%s\";", SlowUpgrade[client], authid);
					}
				}
				case 77:
				{
					if(PlayerXP[client] >= 450)
					{
						PlayerXP[client] -= 450;
						SlowUpgrade[client] = 2;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_slow = \"%i\" WHERE steamid = \"%s\";", SlowUpgrade[client], authid);
					}
				}
				case 777:
				{
					if(PlayerXP[client] >= 600)
					{
						PlayerXP[client] -= 600;
						SlowUpgrade[client] = 3;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_slow = \"%i\" WHERE steamid = \"%s\";", SlowUpgrade[client], authid);
					}
				}
				
				case 8:
				{
					if(PlayerXP[client] >= 350)
					{
						PlayerXP[client] -= 350;
						RandomUpgrade[client] = 1;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_random = \"%i\" WHERE steamid = \"%s\";", RandomUpgrade[client], authid);
					}
				}
				case 88:
				{
					if(PlayerXP[client] >= 500)
					{
						PlayerXP[client] -= 500;
						RandomUpgrade[client] = 2;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_random = \"%i\" WHERE steamid = \"%s\";", RandomUpgrade[client], authid);
					}
				}
				case 888:
				{
					if(PlayerXP[client] >= 600)
					{
						PlayerXP[client] -= 600;
						RandomUpgrade[client] = 3;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_random = \"%i\" WHERE steamid = \"%s\";", RandomUpgrade[client], authid);
					}
				}
				case 8888:
				{
					if(PlayerXP[client] >= 650)
					{
						PlayerXP[client] -= 650;
						RandomUpgrade[client] = 4;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_random = \"%i\" WHERE steamid = \"%s\";", RandomUpgrade[client], authid);
					}
				}
				case 88888:
				{
					if(PlayerXP[client] >= 777)
					{
						PlayerXP[client] -= 777;
						RandomUpgrade[client] = 5;
						
						if(iDB_ReqCount[client] >= 9)	
							SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET upgrade_random = \"%i\" WHERE steamid = \"%s\";", RandomUpgrade[client], authid);
					}
				}
			}
			XPStore(client)
			if(iDB_ReqCount[client] >= 9)	
				SQL_TQueryF(hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE xpmod_private SET player_xp = \"%i\" WHERE steamid = \"%s\";", PlayerXP[client], authid);
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}