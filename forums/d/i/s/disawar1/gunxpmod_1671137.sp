#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define PLUGIN_VERSION "1.6"

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define IsValidClient(%1)  ( 1 <= %1 <= MaxClients && IsClientInGame(%1) )
#define IsValidAlive(%1) ( 1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1) )

public Plugin:myinfo =
{
    name = "Gun Xp Mod",
    author = "xbatista, fix by raziEiL [disawar1]",
    description = "Kill enemies to get stronger",
    version = PLUGIN_VERSION,
    url = "www.laikiux.lt"
};

#define MAX_LEVELS 27
#define MAX_SECONDARY_LEVELS 12

new const String:WEAPONCONST[MAX_LEVELS][] = { 
	"frying_pan", 
	"cricket_bat",
	"tonfa",
	"electric_guitar",
	"golfclub",
	"baseball_bat",
	"crowbar",
	"machete",
	"katana",
	"fireaxe",
	"weapon_pistol",
	"weapon_pistol_magnum", // End of Secondary weapons '13'
	"weapon_smg", 
	"weapon_smg_silenced",
	"weapon_pumpshotgun", 
	"weapon_autoshotgun",
	"weapon_shotgun_chrome", 
	"weapon_shotgun_spas", 
	"weapon_hunting_rifle", 
	"weapon_rifle_sg552", 
	"weapon_sniper_awp", 
	"weapon_rifle_ak47", 
	"weapon_rifle", 
	"weapon_rifle_desert", 
	"weapon_sniper_military",
	"weapon_grenade_launcher",
	"weapon_rifle_m60" // End of Primary weapons '28'
};

new const LEVELS[MAX_LEVELS] = { 
50,
150,
200,
300,
400,
500,
700,
800,
900,
1000,
1190, 
1300, 
1400, 
1600, 
1900, 
2300, 
3000, 
3400,
4000,
4400,
6500,
8000, 
10000,
13000, 
20000,
23000,
30000 // Needed on level 28
}; // Needed Xp on each Levels

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
9, // level 10, Melee weapon.
10, // Pistol.
11, // Pistol_Magnum.
12, // Smg.
13, // Smg Silenced.
14, // Pump Shotgun.
15, // Auto-Shotty.
16, // Shotgun Chrome.
17, // Shotgun SPAS.
18, // Hunting Rifle.
19, // Sniper Scout.
20, // Sniper AWP.
21, // Ak-47.
22, // Rifle.
23, // Rifle Desert.
24, // Sniper Military.
25, // Grenade Launcher
26, // M60 // End of Primary Weapons.
}; // Needed Level to choose gun from menu

new const String:RANK[MAX_LEVELS][] = { "Frying Pan", "Cricked Bat", "Tonfa", "Electric Guitar", "GolfClub", "BaseBall Bat",
"Crowbar", "Machete", "Katana", "FireAxe", "Pistol", "Desert Eagle", "SMG", "SMG Silenced", "Pump Shotgun", "Auto-Shotty", "Chrome Shotgun", "SPAS Shotgun", 
"Hunting Rifle", "Rifle SG552", "Sniper AWP", "AK-47", "Rifle", "Desert Rifle", "Military Sniper", "Grenade Launcher", "M60" };

enum
{
	CLASS_SMOKER = 1,
	CLASS_BOOMER = 2,
	CLASS_HUNTER = 3,
	CLASS_SPITTER = 4,
	CLASS_JOCKEY = 5,
	CLASS_CHARGER = 6,
	CLASS_WITCH = 7,
	CLASS_TANK = 8
};

new g_iClass = -1;

new bool:p_WeaponChoosen[MAXPLAYERS + 1];

new Handle:CvarXpKillInfected, Handle:CvarXpKillSurvivor, Handle:CvarXpKillSmoker,
Handle:CvarXpKillBoomer, Handle:CvarXpKillHunter, Handle:CvarXpKillSpitter,
Handle:CvarXpKillJockey, Handle:CvarXpKillCharger, Handle:CvarXpKillWitch, Handle:CvarXpKillTank, Handle:CvarMenuTime,
Handle:CvarMenuDelay, Handle:CvarMenuReOpen, Handle:CvarSaveType, Handle:CvarEnableTop10,
Handle:CvarWeaponRestriction, Handle:CvarRemoveWeaponEnts, Handle:CvarMenuAutoReOpenTime, Handle:CvarSaveBy;

new Handle:hDatabase = INVALID_HANDLE;
new Handle:MenuTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

new PlayerXp[MAXPLAYERS + 1]
new PlayerLevel[MAXPLAYERS + 1]
new g_remember_selection[MAXPLAYERS + 1], g_remember_selection_pistol[MAXPLAYERS + 1];

public OnPluginStart()
{
	CreateConVar("gunxpmod", PLUGIN_VERSION, "Gun Xp Mod", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Cvars
	CvarSaveBy = CreateConVar("gxm_saveby", "0", "Save Data by : 1 = MySQL, 0 = SQLite.")
	CvarSaveType = CreateConVar("gxm_savetype", "2", "Save Data Type : 0 = SteamID, 1 = IP, 2 = Name.")

	CvarWeaponRestriction = CreateConVar("gxm_restrict_guns", "1", "Restrict weapon picking, based on levels? 1 - Yes, 0 - No.")

	CvarRemoveWeaponEnts = CreateConVar("gxm_remove_guns", "1", "Remove weapons from the ground? 1 - Yes, 0 - No.")
	
	CvarXpKillInfected = CreateConVar("gxm_xp_kill_infected", "2", "XP for killing infected/entity")
	CvarXpKillSurvivor = CreateConVar("gxm_xp_kill_survivor", "100", "XP for killing survivor")
	CvarXpKillSmoker = CreateConVar("gxm_xp_kill_smoker", "15", "XP for killing smoker")
	CvarXpKillBoomer = CreateConVar("gxm_xp_kill_boomer", "15", "XP for killing boomer")
	CvarXpKillHunter = CreateConVar("gxm_xp_kill_hunter", "15", "XP for killing hunter")
	CvarXpKillSpitter = CreateConVar("gxm_xp_kill_spitter", "15", "XP for killing spitter")
	CvarXpKillJockey = CreateConVar("gxm_xp_kill_jockey", "15", "XP for killing jockey")
	CvarXpKillCharger = CreateConVar("gxm_xp_kill_charger", "15", "XP for killing charger")
	CvarXpKillWitch = CreateConVar("gxm_xp_kill_witch", "25", "XP for killing witch")
	CvarXpKillTank = CreateConVar("gxm_xp_kill_tank", "45", "XP for killing tank")

	CvarMenuTime = CreateConVar("gxm_menu_time", "30", "Cvar for how many seconds menu is shown")
	CvarMenuDelay = CreateConVar("gxm_menu_delay", "3.0", "Delay to display menu when player spawned")
	CvarMenuReOpen = CreateConVar("gxm_menu_reopen", "1", "Enable menu re-open ? 1 - Yes, 0 - No.")
	CvarMenuAutoReOpenTime = CreateConVar("gxm_menu_reopen_auto", "180.0", ">0 - Amount of time that menu shall open, 0 - Don't reopen.")
	
	CvarEnableTop10 = CreateConVar("gxm_enable_top10", "1", "Enable !top10 ? 1 - Yes, 0 - No.")

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);

	g_iClass = FindSendPropInfo( "CTerrorPlayer", "m_zombieClass");
	
	RegConsoleCmd("say", Say_Command);
	
	MySQL_Init();

	AutoExecConfig( false, "gunxpmod");
}
public OnMapStart()
{
	PrecacheWeaponModels();
}
PrecacheWeaponModels()
{
	//Precache weapon models if they're not loaded. Thanks Crimson_Fox
	if ( !IsModelPrecached("models/w_models/weapons/w_rifle_sg552.mdl") ) PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl")
	if ( !IsModelPrecached("models/w_models/weapons/w_smg_mp5.mdl") ) PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl")
	if ( !IsModelPrecached("models/w_models/weapons/w_sniper_awp.mdl") ) PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl")
	if ( !IsModelPrecached("models/w_models/weapons/w_sniper_scout.mdl") ) PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl")
	if ( !IsModelPrecached("models/w_models/weapons/w_eq_bile_flask.mdl") ) PrecacheModel("models/w_models/weapons/w_eq_bile_flask.mdl")
	if ( !IsModelPrecached("models/v_models/v_rif_sg552.mdl") ) PrecacheModel("models/v_models/v_rif_sg552.mdl")
	if ( !IsModelPrecached("models/v_models/v_smg_mp5.mdl") ) PrecacheModel("models/v_models/v_smg_mp5.mdl")
	if ( !IsModelPrecached("models/v_models/v_snip_awp.mdl") ) PrecacheModel("models/v_models/v_snip_awp.mdl")
	if ( !IsModelPrecached("models/v_models/v_snip_scout.mdl") ) PrecacheModel("models/v_models/v_snip_scout.mdl")
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("set_p_xp", Native_SetPlayerXp);
	CreateNative("get_p_xp", Native_GetPlayerXp);
	CreateNative("get_p_level", Native_GetPlayerLevel);

	return APLRes_Success;
}

public OnClientPutInServer(client)
{
	if ( IsValidClient(client) && !IsFakeClient(client) )
	{
		LoadData(client)

		g_remember_selection[client] = MAX_SECONDARY_LEVELS;
		g_remember_selection_pistol[client] = 0;
	}

	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip)
}
public OnClientDisconnect(client)
{
	if ( IsClientInGame(client) && !IsFakeClient(client) )
	{
		SaveData(client)
	}
}

public Action:OnWeaponEquip(client, weapon)
{
	if ( !IsValidAlive(client) || IsFakeClient(client) || GetClientTeam(client) == TEAM_INFECTED || !GetConVarInt(CvarWeaponRestriction) )
		return Plugin_Continue;

	decl String:sWeapon[32], String: sWeapon2[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if( StrEqual( sWeapon, "weapon_melee" ) )
	{	
		GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", sWeapon2, sizeof(sWeapon2));
		
		for (new level_equip_id = PlayerLevel[client] + 1; level_equip_id < MAX_LEVELS; level_equip_id++) 
		{
			if( StrEqual(sWeapon2, WEAPONCONST[level_equip_id]) )
			{
				return Plugin_Handled;
			}
		}
	}
	else
	{
		for (new level_equip_id = PlayerLevel[client] + 1; level_equip_id < MAX_LEVELS; level_equip_id++) 
		{ 
			if( StrEqual(sWeapon, WEAPONCONST[level_equip_id]) )
			{
				return Plugin_Handled;
			}
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
			MenuTimer[client] = CreateTimer( GetConVarFloat(CvarMenuDelay), MainWeaponMenu2, client, TIMER_FLAG_NO_MAPCHANGE );
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue
}

public Action:Event_PlayerChangename(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:szNewName[32], String:szOldName[32];
	new client = GetClientOfUserId( GetEventInt(event,"userid") );
	GetEventString( event, "newname", szNewName, sizeof( szNewName ) );
	GetEventString( event, "oldname", szOldName, sizeof( szOldName ) );
	
	if ( !IsValidClient(client) )
		return Plugin_Continue;

	if ( GetConVarInt(CvarSaveType) == 2 && !StrEqual( szOldName, szNewName )  )
	{
		PlayerLevel[client] = 0;
		PlayerXp[client] = 0;
		
		g_remember_selection_pistol[client] = 0;
		g_remember_selection[client] = MAX_SECONDARY_LEVELS;
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
					case CLASS_WITCH:
					{
						Set_Player_Xp(attacker, PlayerXp[attacker] + GetConVarInt(CvarXpKillWitch) )
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

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt(CvarRemoveWeaponEnts) )
	{
		decl String:szClassname[32];
		new MaxEnts = GetMaxEntities();
		
		for( new ents = MaxClients + 1; ents < MaxEnts; ents++)
		{
			if ( IsValidEdict(ents) )
			{
				GetEdictClassname( ents, szClassname, sizeof(szClassname) );

				if ( StrEqual( szClassname, "weapon_spawn") || StrEqual( szClassname, "weapon_melee_spawn") )
				{ 
					AcceptEntityInput( ents, "Kill");
				}	
			}
		}
	}
	CreateTimer(1.0, Melee);
	
	return Plugin_Continue;
}

public Action:Melee(Handle:timer)
{
	new const String:MaxMelees[][] = 
	{ 
		"frying_pan", 
		"cricket_bat",
		"tonfa",
		"electric_guitar",
		"golfclub",
		"baseball_bat",
		"crowbar",
		"machete",
		"katana",
		"fireaxe"
	}
	
	for( new MEnts = CreateEntityByName( "weapon_melee" ); MEnts < sizeof MaxMelees; ++MEnts)
	{
		DispatchKeyValue( MEnts, "melee_script_name", MaxMelees[MEnts] );
		DispatchSpawn( MEnts );
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if ( !IsValidAlive(client) || GetClientTeam(client) == TEAM_INFECTED )
		return Plugin_Continue;
	
	p_WeaponChoosen[client] = false;
	
	Strip_User_Weapons(client)
	
	if ( GetConVarInt(CvarRemoveWeaponEnts) && IsFakeClient(client) )
	{
		Give_Weapon_Menu( client, GetRandomInt( 0, MAX_SECONDARY_LEVELS - 1 ), 0);
		Give_Weapon_Menu( client, GetRandomInt( MAX_SECONDARY_LEVELS, MAX_LEVELS - 1 ), 0);
	}

	MenuTimer[client] = CreateTimer( GetConVarFloat(CvarMenuDelay), MainWeaponMenu2, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue
}
// Menus
public Action:MainWeaponMenu2(Handle:timer, any:client)
{
	MenuTimer[client] = INVALID_HANDLE; 
	KillTimer(timer);

	if ( !IsValidAlive(client) || GetClientTeam(client) == TEAM_INFECTED )
		return Plugin_Continue;

	p_WeaponChoosen[client] = false;
	
	MainWeaponMenu(client)

	return Plugin_Continue;
}
public MainWeaponMenu(client)
{
	new Handle:menu = CreateMenu(WeaponMenu);

	SetMenuTitle(menu, "Level Weapons");

	AddMenuItem(menu, "class_id", "Choose Weapon")
	AddMenuItem(menu, "class_id", "Last Selected Weapons")

	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, GetConVarInt(CvarMenuTime) );
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
				p_WeaponChoosen[client] = true;
				
				if ( PlayerLevel[client] > MAX_SECONDARY_LEVELS - 1 )
				{
					Give_Weapon_Menu(client, g_remember_selection[client], 1);
					Give_Weapon_Menu(client, g_remember_selection_pistol[client], 0);
				}
				else if ( PlayerLevel[client] < MAX_SECONDARY_LEVELS )
				{
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

	for (new item_id = 0; item_id < MAX_SECONDARY_LEVELS; item_id++)
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
public WeaponMenu_Pistol(Handle:menu, MenuAction:action, client, item)
{
	if( action == MenuAction_Select )
	{
		p_WeaponChoosen[client] = true;
		
		MenuTimer[client] = CreateTimer( GetConVarFloat(CvarMenuAutoReOpenTime), MainWeaponMenu2, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
		g_remember_selection_pistol[client] = item;

		Give_Weapon_Menu(client, item, 1);
	
		if ( PlayerLevel[client] > MAX_SECONDARY_LEVELS - 1 )
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

	for (new item_id = MAX_SECONDARY_LEVELS; item_id < MAX_LEVELS; item_id++)
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
		g_remember_selection[client] = item + MAX_SECONDARY_LEVELS;
	
		Give_Weapon_Menu(client, item + MAX_SECONDARY_LEVELS, 0);
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
		if (x != 2 && x != 3 && (wepIdx = GetPlayerWeaponSlot(client, x)) != -1)
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
public Native_GetPlayerLevel(Handle:plugin, numParams)
{
	new client = GetNativeCell( 1 );

	return PlayerLevel[client];
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
	
	if ( GetConVarInt(CvarSaveBy) )
		hDatabase = SQL_DefConnect( Error, sizeof(Error) )
	else
		hDatabase = SQLite_UseDatabase( "gunxpmod", Error, sizeof( Error ) );
	
	if ( hDatabase == INVALID_HANDLE )
	{
		PrintToServer("Failed to connect: %s", Error)
		LogError( "%s", Error ); 
	}
	
	decl String:TQuery[512];
	
	if ( GetConVarInt(CvarSaveBy) )
	{
		Format( TQuery, sizeof( TQuery ), "CREATE TABLE IF NOT EXISTS `gunxpmod` ( `player_id` varchar(32) NOT NULL,`player_level` int(8) default NULL,`player_xp` int(16) default NULL,PRIMARY KEY (`player_id`) ) TYPE=MyISAM;" );
	}
	else
	{
		Format( TQuery, sizeof( TQuery ), "CREATE TABLE IF NOT EXISTS `gunxpmod` ( `player_id` TEXT NOT NULL,`player_level` INTEGER DEFAULT NULL,`player_xp` INTEGER DEFAULT NULL,PRIMARY KEY (`player_id`) );" );
	}
	
	SQL_TQuery( hDatabase, QueryCreateTable, TQuery)
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

		SetMenuExitButton( Top10Panel, false);
		SetMenuPagination( Top10Panel, 10 );
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