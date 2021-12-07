#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define PLUGIN_VERSION "1.3"

#define MAX_LEVELS 17
#define MAX_PISTOL_LEVELS 2

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define IsValidClient(%1)  ( 1 <= %1 <= MaxClients && IsClientInGame(%1) )
#define IsValidAlive(%1) ( 1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1) )

#define MAX_PLAYERS 256 
new Handle:MenuTimers[MAX_PLAYERS+1]

public Plugin:myinfo =
{
    name = "Gun Xp Mod",
    author = "xbatista",
    description = "Kill enemies to get stronger",
    version = PLUGIN_VERSION,
    url = "www.laikiux.lt"
};

new const String:szTables[][] = 
{
	"CREATE TABLE IF NOT EXISTS `gunxpmod` ( `player_id` varchar(32) NOT NULL,`player_level` int(8) default NULL,`player_xp` int(16) default NULL,PRIMARY KEY (`player_id`) ) TYPE=MyISAM;"
}

new const String:WEAPONCONST[MAX_LEVELS][] = { 
	"weapon_pistol", 
	"weapon_pistol_magnum", // End of Secondary weapons '2'
	"weapon_smg", 
	"weapon_smg_silenced",
	"weapon_pumpshotgun", 
	"weapon_autoshotgun",
	"weapon_sniper_scout", 
	"weapon_shotgun_chrome", 
	"weapon_shotgun_spas", 
	"weapon_sniper_awp", 
	"weapon_hunting_rifle", 
	"weapon_rifle_ak47",
   	"weapon_smg_mp5", 
	"weapon_rifle", 
	"weapon_rifle_desert", 
	"weapon_sniper_military",
	"weapon_rifle_sg552"
};

new const LEVELS[MAX_LEVELS] = { 
90, // Needed on level 1
180, // Needed on level 2
300, // Needed on level 3
450, // Needed on level 4
700, // Needed on level 5
1200, // Needed on level 6
1800, // Needed on level 7
2800, // Needed on level 8
4100, // Needed on level 9
5200, // Needed on level 10
6000, // Needed on level 11
6800, // Needed on level 12
8200, // Needed on level 13
10200, // Needed on level 14
12000, // Needed on level 15
14200, // Needed on level 16
16000, // Needed on level 17
}; // Needed Xp on each Levels

//todo: rewrite comments..
new const GUN_LEVELS[MAX_LEVELS] = { 
0, 
1, 
2,
3,
4,
5,
6,
7,
8,
9,
10,
11,
12,
13,
14,
15,
16
}; // Needed Level to choose gun from menu

new const String:RANK[MAX_LEVELS][] = { "Pistol", "Desert Eagle", "SMG", "SMG Silenced", "Pump Shotgun", "Auto-Shotty", "Sniper Scout", "Chrome Shotgun", "SPAS Shotgun", 
 "Sniper AWP", "Hunting Rifle", "AK-47", "MP5","Rifle", "Desert Rifle", "Military Sniper", "SG552" };

new const AMMO_REWARD_LEVELS[] = {
	5,
	10,
	14
}

enum
{
	CLASS_SMOKER = 1,
	CLASS_BOOMER = 2,
	CLASS_HUNTER = 3,
	CLASS_SPITTER = 4,
	CLASS_JOCKEY = 5,
	CLASS_CHARGER = 6,
	CLASS_TANK = 7
};

new g_iClass = -1;

new bool:p_WeaponChoosen[MAXPLAYERS + 1];

new String:szPName[32];

new Handle:CvarXpKillInfected, Handle:CvarXpKillSurvivor, Handle:CvarXpKillSmoker,
Handle:CvarXpKillBoomer, Handle:CvarXpKillHunter, Handle:CvarXpKillSpitter,
Handle:CvarXpKillJockey, Handle:CvarXpKillCharger, Handle:CvarXpKillTank, Handle:CvarMenuTime,
Handle:CvarMenuDelay, Handle:CvarMenuReOpen, Handle:CvarSaveType, Handle:CvarEnableTop10,
Handle:CvarUpgradeHp, Handle:CvarUpgradeAmmo, Handle:CvarEnableAmmoPower, Handle:CvarMenuReOpenAfterTime, Handle:CvarMenuReOpenAfterTimeAnn, Handle:CvarEnableNameChanger, Handle:CvarWeaponRestriction, Handle:CvarAllowReopenOnLvlUP, Handle:CvarAutoReopenOnLvlUP;

new Handle:hDatabase = INVALID_HANDLE;

new PlayerXp[MAXPLAYERS + 1]
new PlayerLevel[MAXPLAYERS + 1]
new g_remember_selection[MAXPLAYERS + 1], g_remember_selection_pistol[MAXPLAYERS + 1];

public OnPluginStart()
{
	CreateConVar("gunxpmod", PLUGIN_VERSION, "Gun Xp Mod", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Cvars
	CvarSaveType = CreateConVar("gxm_savetype", "2", "Save Data by : 0 = SteamID, 1 = IP, 2 = Name.")

	CvarWeaponRestriction = CreateConVar("gxm_restrict_gun", "1", "Restrict weapon picking, based on levels? 1 - Yes, 0 - No.")
	
	CvarXpKillInfected = CreateConVar("gxm_xp_kill_infected", "2", "XP for killing infected/entity")
	CvarXpKillSurvivor = CreateConVar("gxm_xp_kill_survivor", "50", "XP for killing survivor")
	CvarXpKillSmoker = CreateConVar("gxm_xp_kill_smoker", "5", "XP for killing smoker")
	CvarXpKillBoomer = CreateConVar("gxm_xp_kill_boomer", "5", "XP for killing boomer")
	CvarXpKillHunter = CreateConVar("gxm_xp_kill_hunter", "5", "XP for killing hunter")
	CvarXpKillSpitter = CreateConVar("gxm_xp_kill_spitter", "5", "XP for killing spitter")
	CvarXpKillJockey = CreateConVar("gxm_xp_kill_jockey", "5", "XP for killing jockey")
	CvarXpKillCharger = CreateConVar("gxm_xp_kill_charger", "5", "XP for killing charger")
	CvarXpKillTank = CreateConVar("gxm_xp_kill_tank", "5", "XP for killing tank")

	CvarMenuTime = CreateConVar("gxm_menu_time", "30", "Cvar for how many seconds menu is shown")
	CvarMenuDelay = CreateConVar("gxm_menu_delay", "3.0", "Delay to display menu when player spawned")
	CvarMenuReOpen = CreateConVar("gxm_menu_reopen", "1", "Enable menu re-open ? 1 - Yes, 0 - No.")
	
	CvarEnableTop10 = CreateConVar("gxm_enable_top10", "1", "Enable !top10 ? 1 - Yes, 0 - No.")
	CvarEnableNameChanger = CreateConVar("gxm_enable_namec", "1", "Enable Name changer, adds a level tag to your name ? 1 - Yes, 0 - No.")
	
	CvarUpgradeHp = CreateConVar("gxm_up_hp", "2", "Enable Health Upgrade ? >=1 - Yes, 0 - No.")
	CvarUpgradeAmmo = CreateConVar("gxm_up_ammo", "15", "Enable BpAmmo Upgrade ? >=1 - Yes, 0 - No.")
	CvarEnableAmmoPower = CreateConVar("gxm_up_ammopow", "1", "Enable Ammo Power, gives extra laser sight etc.. ? 1 - Yes, 0 - No.")

	CvarMenuReOpenAfterTime = CreateConVar("gxm_menu_reopen_after_time", "0", "Enable menu re-open after specified time ? 0 - No, >0 - Seconds after player can re-open menu.")
	CvarMenuReOpenAfterTimeAnn = CreateConVar("gxm_menu_reopen_after_time_ann", "0", "Print a message when menu can be re-opened ? 0 - No, 1 - Yes.")

	CvarAllowReopenOnLvlUP = CreateConVar("gxm_allow_reopen_on_lvlup", "0", "Allow re-open menu on new level ? 1 - Yes, 0 - No.")
	CvarAutoReopenOnLvlUP = CreateConVar("gxm_auto_reopen_on_lvlup", "0", "Automaticly display menu on new level ? 1 - Yes, 0 - No.")

	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("ammo_pickup", Event_AmmoPickup);
	HookEvent("item_pickup", Event_ItemPickup);
	HookEvent("player_changename", Event_PlayerChangename);

	g_iClass = FindSendPropInfo( "CTerrorPlayer", "m_zombieClass");
	
	RegConsoleCmd("say", Say_Command);
	
	MySQL_Init()

	AutoExecConfig( true, "gunxpmod");
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("set_p_xp", Native_SetPlayerXp);
	CreateNative("get_p_xp", Native_GetPlayerXp);

	return APLRes_Success;
}

public OnClientPutInServer(client)
{
	if ( IsValidClient(client) && !IsFakeClient(client) )
	{
		LoadData(client)

		g_remember_selection[client] = -1; //MAX_PISTOL_LEVELS;
		g_remember_selection_pistol[client] = 0;
		
		if ( GetConVarInt(CvarEnableNameChanger) )
		{
			decl String:szNameF[64];
			GetClientName( client, szPName, sizeof( szPName ) );
			
			Format( szNameF, sizeof( szNameF ), "[LvL%d]%s", PlayerLevel[client], szPName);
			
			SetClientInfo( client, "name", szNameF);
		}
	}

	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip)
}

public OnClientDisconnect(client)
{
	if ( IsClientInGame(client) && !IsFakeClient(client) )
	{
		if ( GetConVarInt(CvarEnableNameChanger) )
		{
			SetClientInfo( client, "name", szPName);
		}

		SaveData(client)
	}

	if (MenuTimers[client] != INVALID_HANDLE)
	{
		KillTimer(MenuTimers[client])
		MenuTimers[client] = INVALID_HANDLE
	}

}

public Action:OnWeaponEquip(client, weapon)
{
	if ( !IsValidAlive(client) || IsFakeClient(client) || GetClientTeam(client) == TEAM_INFECTED || !GetConVarInt(CvarWeaponRestriction) )
		return Plugin_Continue;

	decl String:sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
    
	for (new level_equip_id = PlayerLevel[client] + 1; level_equip_id < MAX_LEVELS; level_equip_id++) 
	{ 
		if( StrEqual(sWeapon, WEAPONCONST[level_equip_id]) )
		{
			return Plugin_Handled;
		}
	}
    
	return Plugin_Continue;
}
public Action:Say_Command(client, args)
{
	if ( !IsValidClient(client) )
		return Plugin_Continue;
	
	decl String:Text[192];
	decl String:szArg1[16]
	GetCmdArgString(Text, sizeof(Text));

	StripQuotes(Text)

	BreakString(Text, szArg1, sizeof(szArg1))
	
	if( StrEqual(szArg1, "!level") || StrEqual(szArg1, "level") )
	{
		CPrintToChat(client, "{blue}LEVEL {default}[{green}%d{default}]", PlayerLevel[client] ) 
		CPrintToChat(client, "{blue}XP {default}[{green}%d {default}/ {green}%d{default}]", PlayerXp[client], LEVELS[PlayerLevel[client]]) 
		
		return Plugin_Handled
	}
	else if ( StrEqual(szArg1, "!top10") || StrEqual(szArg1, "top10") && GetConVarInt(CvarEnableTop10) )
	{
		decl String:szQuery[ 256 ]; 
	
		Format( szQuery, sizeof( szQuery ), "SELECT `player_id`, `player_level`, `player_xp` FROM `gunxpmod` ORDER BY `player_xp` DESC LIMIT 10;" );
	
		SQL_TQuery( hDatabase, QueryShowTopTable, szQuery, client)
		
		return Plugin_Handled;
	}
	else if ( StrEqual(szArg1, "!guns") || StrEqual(szArg1, "guns") && GetConVarInt(CvarMenuReOpen) )
	{
		if ( !p_WeaponChoosen[client] )
		{
			CPrintToChat(client, "{green}Menu successfully re-opened!" ) 
			CreateTimer( 0.5, MainWeaponMenu2, client);
		}else{
			CPrintToChat(client, "{green}You can't re-open menu so soon.");
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue
}

public Action:Event_PlayerChangename(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:szNewName[32], String:szNameF[64];
	new client = GetClientOfUserId( GetEventInt(event,"userid") );
	
	if ( !IsValidClient(client) || IsFakeClient(client) || !GetConVarInt(CvarEnableNameChanger) )
		return Plugin_Continue;
	
	GetEventString( event, "newname", szNewName, sizeof( szNewName ) );
	
	Format( szNameF, sizeof( szNameF ), "[LvL%d]%s", PlayerLevel[client], szNewName);
		
	SetClientInfo( client, "name", szNameF);
	
	return Plugin_Continue;
}
public Action:Event_AmmoPickup (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId( GetEventInt(event,"userid") );

	if ( !IsValidAlive(client) || GetClientTeam(client) == TEAM_INFECTED || GetConVarInt(CvarUpgradeAmmo) < 1 )
		return Plugin_Continue;

	for (new item_id = 0; item_id < MAX_LEVELS; item_id++)
	{
		SetBpAmmo( client, WEAPONCONST[item_id], GetConVarInt(CvarUpgradeAmmo) * PlayerLevel[client] );
	}
	
	return Plugin_Continue;
}
public Action:Event_ItemPickup (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId( GetEventInt(event,"userid") );

	if ( !IsValidAlive(client) || GetClientTeam(client) == TEAM_INFECTED )
		return Plugin_Continue;

	if ( GetConVarInt(CvarUpgradeAmmo) > 0 )
	{
		new String:stWpn[24], String:stWpn2[32];
		GetEventString( event, "item", stWpn, sizeof(stWpn) );
	
		Format( stWpn2, sizeof( stWpn2 ), "weapon_%s", stWpn);
	
		SetBpAmmo( client, stWpn2, GetConVarInt(CvarUpgradeAmmo) * PlayerLevel[client] );
	}
	
	if ( GetConVarInt(CvarEnableAmmoPower) )
	{
		if ( PlayerLevel[client] == AMMO_REWARD_LEVELS[0] )
		{
			CheatCommand( client, "upgrade_add", "INCENDIARY_AMMO" );
		}
		else if ( PlayerLevel[client] == AMMO_REWARD_LEVELS[1] )
		{
			CheatCommand( client, "upgrade_add", "LASER_SIGHT" );
		}
		else if ( PlayerLevel[client] == AMMO_REWARD_LEVELS[2] )
		{
			CheatCommand( client, "upgrade_add", "EXPLOSIVE_AMMO" );
		}
	}

	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid") );
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker") );

	if ( !IsValidClient(attacker) )
		return Plugin_Continue

	if ( attacker != victim )
	{
		new iClass = GetEntData( victim, g_iClass);
		
		if ( !IsValidClient(victim) && GetClientTeam(attacker) == TEAM_SURVIVOR )
		{
			Set_Player_Xp(attacker, PlayerXp[attacker] + GetConVarInt(CvarXpKillInfected) )
		}
		else if ( IsValidClient(victim) )
		{
			if ( GetClientTeam(victim) == TEAM_SURVIVOR )
			{
				Set_Player_Xp(attacker, PlayerXp[attacker] + GetConVarInt(CvarXpKillSurvivor) )
			}
			else if ( GetClientTeam(victim) == TEAM_INFECTED )
			{
				switch ( iClass )
				{
					case CLASS_SMOKER:
					{
						Set_Player_Xp(attacker, PlayerXp[attacker] + GetConVarInt(CvarXpKillSmoker) )
					}
					case CLASS_BOOMER:
					{
						Set_Player_Xp(attacker, PlayerXp[attacker] + GetConVarInt(CvarXpKillBoomer) )
					}
					case CLASS_HUNTER:
					{
						Set_Player_Xp(attacker, PlayerXp[attacker] + GetConVarInt(CvarXpKillHunter) )
					}
					case CLASS_SPITTER:
					{
						Set_Player_Xp(attacker, PlayerXp[attacker] + GetConVarInt(CvarXpKillSpitter) )
					}
					case CLASS_JOCKEY:
					{
						Set_Player_Xp(attacker, PlayerXp[attacker] + GetConVarInt(CvarXpKillJockey) )
					}
					case CLASS_CHARGER:
					{
						Set_Player_Xp(attacker, PlayerXp[attacker] + GetConVarInt(CvarXpKillCharger) )
					}
					case CLASS_TANK:
					{
						Set_Player_Xp(attacker, PlayerXp[attacker] + GetConVarInt(CvarXpKillTank) )
					}
				}
			}
		}
	}

	return Plugin_Continue
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if ( !IsValidAlive(client) || GetClientTeam(client) == TEAM_INFECTED )
		return Plugin_Continue;
	
	p_WeaponChoosen[client] = false;
	
	if ( GetConVarInt(CvarUpgradeHp) > 0 )
	{
		SetEntityHealth( client, GetClientHealth(client) + GetConVarInt(CvarUpgradeHp) * PlayerLevel[client] );
	}

	Strip_User_Weapons(client)

	CreateTimer( GetConVarFloat(CvarMenuDelay), MainWeaponMenu2, client);
	
	return Plugin_Continue
}
// Menus
public Action:MainWeaponMenu2(Handle:timer, any:client)
{
	KillTimer(timer);

	if ( !IsValidAlive(client) || GetClientTeam(client) == TEAM_INFECTED )
		return Plugin_Stop;

	MainWeaponMenu(client)

	return Plugin_Stop;
}
public MainWeaponMenu(client)
{
	new Handle:menu = CreateMenu(WeaponMenu);

	SetMenuTitle(menu, "Level Weapons");

	AddMenuItem(menu, "class_id", "Choose Weapon(s)")
	
	//did player selected some guns before?
	if (g_remember_selection[client] != -1){
		AddMenuItem(menu, "class_id", "Last Selected Weapons")
	}else{
		AddMenuItem(menu, "class_id", "Last Selected Weapons", ITEMDRAW_DISABLED)
	}

	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, GetConVarInt(CvarMenuTime) );
}

public Action:UnlockMenu(Handle:timer, any:client)
{
	MenuTimers[client] = INVALID_HANDLE

	if( GetConVarInt(CvarMenuReOpenAfterTimeAnn)>0 && p_WeaponChoosen[client] ){
		CPrintToChat(client, "{green}Now you can again use !guns menu.");
	}

	p_WeaponChoosen[client] = false;
}

public set_p_WeaponChoosen_true(client){
	p_WeaponChoosen[client] = true;
	if (GetConVarInt(CvarMenuReOpenAfterTime)>0){
		MenuTimers[client] = CreateTimer(GetConVarFloat(CvarMenuReOpenAfterTime), UnlockMenu, client)
	}
}

public WeaponMenu(Handle:menu, MenuAction:action, client, item)
{
	if( action == MenuAction_Select )
	{	
		switch (item)
		{
			case 0: // show pistols
			{
				MainWeaponMenu_Pistol(client);
			}
			case 1: // last weapons
			{
				//p_WeaponChoosen[client] = true;
				set_p_WeaponChoosen_true(client);
				
				if ( PlayerLevel[client] > MAX_PISTOL_LEVELS - 1 )
				{
					if (g_remember_selection_pistol[client] != -1)
						Give_Weapon_Menu(client, g_remember_selection_pistol[client], 0);
					
					if (g_remember_selection[client] != -1)//this should be always true, but who knows..		
					Give_Weapon_Menu(client, g_remember_selection[client], 1);
				}
				else if ( PlayerLevel[client] < MAX_PISTOL_LEVELS )
				{
					if (g_remember_selection_pistol[client] != -1)
						Give_Weapon_Menu(client, g_remember_selection_pistol[client], 1);
				}
			}
		}
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
}

public Action:MainWeaponMenu_Pistol(client)
{
	new Handle:menu = CreateMenu(WeaponMenu_Pistol);

	decl String:szMsg[60]
	decl String:szItems[60]
	Format(szMsg, sizeof( szMsg ), "Level %d [%i / %i]", PlayerLevel[client], PlayerXp[client], LEVELS[PlayerLevel[client]])
	
	SetMenuTitle(menu, szMsg);

	for (new item_id = 0; item_id < MAX_PISTOL_LEVELS; item_id++)
	{
		if ( PlayerLevel[client] >= GUN_LEVELS[item_id] )
		{
			Format(szItems, sizeof( szItems ), "%s (%d)", RANK[item_id], GUN_LEVELS[item_id] )

			AddMenuItem(menu, "class_id", szItems)
		}
		else
		{
			Format(szItems, sizeof( szItems ), "%s (%d)", RANK[item_id], GUN_LEVELS[item_id] )
			
			AddMenuItem(menu, "class_id", szItems, ITEMDRAW_DISABLED)
		}
}

	//check if player has something else
	if (GetPlayerWeaponSlot(client, 1) != -1){
		AddMenuItem(menu, "class_id", "Skip selection of pistols")
	}else{
		AddMenuItem(menu, "class_id", "Skip selection of pistols", ITEMDRAW_DISABLED)
	}

	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, GetConVarInt(CvarMenuTime) );
}
public WeaponMenu_Pistol(Handle:menu, MenuAction:action, client, item)
{
	if( action == MenuAction_Select )
	{
		//p_WeaponChoosen[client] = true;
		//set_p_WeaponChoosen_true(client);
		
		if (item != MAX_PISTOL_LEVELS){
			g_remember_selection_pistol[client] = item;
			Give_Weapon_Menu(client, item, 1);
		}else{
			g_remember_selection_pistol[client] = -1;		
		}
	
		if ( PlayerLevel[client] > MAX_PISTOL_LEVELS - 1 )
		{
			MainWeaponMenu_Prim(client);
		}
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
}
public Action:MainWeaponMenu_Prim(client)
{
	new Handle:menu = CreateMenu(WeaponMenu_Prim);

	decl String:szMsg[60]
	decl String:szItems[60]
	Format(szMsg, sizeof( szMsg ), "Level %d [%i / %i]", PlayerLevel[client], PlayerXp[client], LEVELS[PlayerLevel[client]])
	
	SetMenuTitle(menu, szMsg);

	for (new item_id = MAX_PISTOL_LEVELS; item_id < MAX_LEVELS; item_id++)
	{
		if ( PlayerLevel[client] >= GUN_LEVELS[item_id] )
		{
			Format(szItems, sizeof( szItems ), "%s (%d)", RANK[item_id], GUN_LEVELS[item_id] )

			AddMenuItem(menu, "class_id", szItems)
		}
		else
		{
			Format(szItems, sizeof( szItems ), "%s (%d)", RANK[item_id], GUN_LEVELS[item_id] )
			
			AddMenuItem(menu, "class_id", szItems, ITEMDRAW_DISABLED)
		}
	}

	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, GetConVarInt(CvarMenuTime) );
}

public WeaponMenu_Prim(Handle:menu, MenuAction:action, client, item)
{
	if( action == MenuAction_Select )
	{
		g_remember_selection[client] = item + MAX_PISTOL_LEVELS;
		
		//just before giving a weapon we set the flag
		set_p_WeaponChoosen_true(client);
		Give_Weapon_Menu(client, item + MAX_PISTOL_LEVELS, 0);
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
}

public Give_Weapon_Menu(client, selection, strip)
{
	if( IsValidAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR ) 
	{
		if ( strip )
		{
			Strip_User_Weapons(client);
		}
		
		CheatCommand( client, "give", WEAPONCONST[selection] );
	}
}

CheatCommand( client, const String:command[], const String:arguments[] )
{
	new Flagsgive = GetCommandFlags( command );
	SetCommandFlags( command, Flagsgive & ~FCVAR_CHEAT);
	FakeClientCommand( client, "%s %s", command, arguments );
	SetCommandFlags( command, Flagsgive | FCVAR_CHEAT);
}

// Usefull Stocks
public Action:Strip_User_Weapons(client)
{
	if ( !IsValidAlive(client) )
		return Plugin_Continue

	new wepIdx;
	for (new x = 0; x <= 4; x++)
	{
		if (x != 2 && (wepIdx = GetPlayerWeaponSlot(client, x)) != -1)
		{  
			RemovePlayerItem(client, wepIdx);
			RemoveEdict(wepIdx);
		}
	}
  
	return Plugin_Continue
}
public Action:Set_Player_Xp(client, value)
{
	if ( !IsValidClient(client) )
		return Plugin_Continue;

	if( PlayerLevel[client] < MAX_LEVELS - 1 ) 
	{
		PlayerXp[client] = value

		if ( PlayerXp[client] < 0 )
		{
			PlayerXp[client] = 0;
		}

		if( PlayerXp[client] >= LEVELS[PlayerLevel[client]])
		{
			PlayerLevel[client]++;	
			
			CPrintToChat(client, "Level up to {green}%d{default}!", PlayerLevel[client] ) 

       			if (GetConVarInt(CvarAllowReopenOnLvlUP)>0){
                p_WeaponChoosen[client] = false;
                CPrintToChat(client, "{green}You can select new weapon.") 
                if (GetConVarInt(CvarAutoReopenOnLvlUP)>0){
                    CPrintToChat(client, "{green}Auto openning menu.") 
                    CreateTimer( 0.5, MainWeaponMenu2, client);                    
                }
            }

		}
	}

	return Plugin_Continue;
}
public Native_SetPlayerXp(Handle:plugin, numParams)
{
	new client = GetNativeCell( 1 );
	new value = GetNativeCell( 2 );

	if ( !IsValidClient(client) )
		return;

	if( PlayerLevel[client] < MAX_LEVELS - 1 ) 
	{
		PlayerXp[client] = value

		if ( PlayerXp[client] < 0 )
		{
			PlayerXp[client] = 0;
		}

		if( PlayerXp[client] >= LEVELS[PlayerLevel[client]])
		{
			PlayerLevel[client]++;	
			
			CPrintToChat(client, "Level up to {green}%d{default}!", PlayerLevel[client] ) 
		}
	}
}

public Native_GetPlayerXp(Handle:plugin, numParams)
{
	new client = GetNativeCell( 1 );

	return PlayerXp[client];
}

public SetBpAmmo( client, String:stWpn[], Ammo)
{
	new iAmmoOffs = FindDataMapOffs( client, "m_iAmmo" );
	new iMaxAmmo;

	if ( StrEqual( stWpn, "weapon_rifle", false)
	|| StrEqual( stWpn, "weapon_rifle_desert", false)
	|| StrEqual( stWpn, "weapon_rifle_ak47", false) )
	{
		iAmmoOffs += 12;
		iMaxAmmo = GetConVarInt(FindConVar("ammo_assaultrifle_max"));
	}
	else if ( StrEqual( stWpn, "weapon_smg", false) 
	|| StrEqual( stWpn, "weapon_smg_silenced", false)
    ||  StrEqual( stWpn, "weapon_smg_mp5", false) )
	{
		iAmmoOffs += 20;
		iMaxAmmo = GetConVarInt(FindConVar("ammo_smg_max"));

	}
	else if ( StrEqual( stWpn, "weapon_pumpshotgun", false) 
	|| StrEqual( stWpn, "weapon_shotgun_chrome", false) )
	{
		iAmmoOffs += 24;
		iMaxAmmo = GetConVarInt(FindConVar("ammo_shotgun_max"));
	}
	else if ( StrEqual( stWpn, "weapon_autoshotgun", false) 
	|| StrEqual( stWpn, "weapon_shotgun_spas", false) )
	{
		iAmmoOffs += 28;
		iMaxAmmo = GetConVarInt(FindConVar("ammo_autoshotgun_max"));
	}
	else if ( StrEqual( stWpn, "weapon_hunting_rifle", false) )
	{
		iAmmoOffs += 32;
		iMaxAmmo = GetConVarInt(FindConVar("ammo_huntingrifle_max"));
	}
	else if ( StrEqual(stWpn, "weapon_sniper_military", false) )
	{
		iAmmoOffs += 36;
		iMaxAmmo = GetConVarInt(FindConVar("ammo_sniperrifle_max"));
	}
	else if ( StrEqual(stWpn, "weapon_grenade_launcher", false) )
	{
		iAmmoOffs += 64;
		iMaxAmmo = GetConVarInt(FindConVar("ammo_grenadelauncher_max"));
	}
	
	SetEntData( client, iAmmoOffs, iMaxAmmo + Ammo );
}
 
public Save_GetKey( client, String:szKey[], maxlen )
{
	switch( GetConVarInt( CvarSaveType ) )
	{
		case 2:
		{
			GetClientName( client, szKey, maxlen );

			ReplaceString( szKey, maxlen, "'", "\'" );
		}

		case 1:	GetClientIP( client, szKey, maxlen );
		case 0:	GetClientAuthString( client, szKey, maxlen );
	}
}

public MySQL_Init()
{
	new String:Error[255];
	hDatabase = SQL_DefConnect( Error, sizeof(Error) )
	
	if ( hDatabase == INVALID_HANDLE )
	{
		PrintToServer("Failed to connect: %s", Error)
	}
	
	for ( new i = 0; i < sizeof szTables; i++ )
	{
		SQL_TQuery( hDatabase, QueryCreateTable, szTables[i])
	}
}

public SaveData(client)
{
	decl String:szQuery[ 256 ]; 
	
	decl String:szKey[64];
	Save_GetKey( client, szKey, sizeof( szKey ) );
	
	Format( szQuery, sizeof( szQuery ), "REPLACE INTO `gunxpmod` (`player_id`, `player_level`, `player_xp`) VALUES ('%s', '%d', '%d');", szKey , PlayerLevel[client], PlayerXp[client] );
	
	SQL_TQuery( hDatabase, QuerySetData, szQuery, client)
}
public LoadData(client)
{
	decl String:szQuery[ 256 ]; 
	
	decl String:szKey[64];
	Save_GetKey( client, szKey, sizeof( szKey ) );
	
	Format( szQuery, sizeof( szQuery ), "SELECT `player_level`, `player_xp` FROM `gunxpmod` WHERE ( `player_id` = '%s' );", szKey );
	
	SQL_TQuery( hDatabase, QuerySelectData, szQuery, client)
}
public QueryCreateTable( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl == INVALID_HANDLE )
	{
		LogError( "%s", error ); 
		
		return;
	} 
}
public QuerySetData( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl == INVALID_HANDLE )
	{
		LogError( "%s", error ); 
		
		return;
	} 
} 
public QuerySelectData( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl != INVALID_HANDLE )
	{
		while ( SQL_FetchRow(hndl) ) 
		{
			PlayerLevel[data] = SQL_FetchInt(hndl, 0);
			PlayerXp[data] = SQL_FetchInt(hndl, 1);
		}
	} 
	else
	{
		LogError( "%s", error ); 
		
		return;
	}
}
public QueryShowTopTable( Handle:owner, Handle:hndl, const String:error[], any:data)
{ 
	if ( hndl != INVALID_HANDLE )
	{
		if ( !IsValidClient(data) )
			return;
		
		decl String:Name[64], String:szInfo[128];

		new Handle:Top10Panel = CreateMenu(Top10PanelHandler), iLevel, iXp;
		SetMenuTitle( Top10Panel, "Top 10 Players" );

		while ( SQL_FetchRow(hndl) )
		{
			SQL_FetchString( hndl, 0, Name, sizeof(Name) );
			iLevel = SQL_FetchInt( hndl, 1);
			iXp = SQL_FetchInt( hndl, 2);
			
			ReplaceString(Name, sizeof(Name), "&lt;", "<");
			ReplaceString(Name, sizeof(Name), "&gt;", ">");
			ReplaceString(Name, sizeof(Name), "&#37;", "%");
			ReplaceString(Name, sizeof(Name), "&#61;", "=");
			ReplaceString(Name, sizeof(Name), "&#42;", "*");
			
			Format( szInfo, sizeof( szInfo ), "%s - Level %d [ %d / %d ]", Name, iLevel, iXp, LEVELS[iLevel] );

			AddMenuItem(Top10Panel, "top10", szInfo);
		}

		SetMenuPagination( Top10Panel, 10 );
		SetMenuExitButton( Top10Panel, false);
		DisplayMenu( Top10Panel, data, GetConVarInt(CvarMenuTime) );
		
		CloseHandle(Top10Panel);
	} 
	else
	{
		LogError( "%s", error ); 
		
		return;
	}
}
public Top10PanelHandler(Handle:menu, MenuAction:action, client, item)
{
	
}