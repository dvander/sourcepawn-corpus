#include <sourcemod>
#include <entity_prop_stocks>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>

#undef REQUIRE_EXTENSIONS
#include <steamtools>

// Include support for Opt-In MultiMod
// Default: OFF
//#define OIMM

#if defined OIMM
#undef REQUIRE_PLUGIN
#include <optin_multimod>
#endif

#pragma semicolon 1

#define BOW "tf_weapon_compound_bow"
#define CROSSBOW "tf_weapon_crossbow"
#define ARROW "tf_projectile_arrow"
#define HEALING_BOLT "tf_projectile_healing_bolt"
#define KILL_FLAMETHROWER "flamethrower"
#define KILL_FIREARROW "huntsman"
#define KILL_EXPLOSION "env_explosion"

#define JUMPCHARGETIME 1
#define JUMPCHARGE (25 * JUMPCHARGETIME)

#define VERSION "1.7.3"

public Plugin:myinfo = 
{
	name = "[TF2] Huntsman Hell",
	author = "Powerlord",
	description = "All Snipers, all with Huntsman and Jarate, most likely firing arrows that explode and set you on fire.  What could go wrong?",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=214679"
}

new String:g_Sounds_Explode[][] = {"weapons/explode1.wav", "weapons/explode2.wav", "weapons/explode3.wav" };
new String:g_Sounds_Jump[][] = { "vo/sniper_specialcompleted02.wav", "vo/sniper_specialcompleted17.wav", "vo/sniper_specialcompleted19.wav", "vo/sniper_laughshort01.wav", "vo/sniper_laughshort04.wav" };
new String:g_Sounds_MedicJump[][] = { "vo/medic_mvm_say_ready02.wav", "vo/medic_mvm_wave_end06.wav", "vo/medic_mvm_get_upgrade03.wav", "vo/medic_sf12_badmagic09.wav", "vo/medic_sf12_taunts03.wav" };

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_Explode = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeFire = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeFireSelf = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeRadius = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeDamage = INVALID_HANDLE;
new Handle:g_Cvar_FireArrows = INVALID_HANDLE;
new Handle:g_Cvar_ArrowCount = INVALID_HANDLE;
new Handle:g_Cvar_StartingHealth = INVALID_HANDLE;
new Handle:g_Cvar_SuperJump = INVALID_HANDLE;
new Handle:g_Cvar_DoubleJump = INVALID_HANDLE;
new Handle:g_Cvar_FallDamage = INVALID_HANDLE;
new Handle:g_Cvar_GameDescription = INVALID_HANDLE;
new Handle:g_Cvar_MedicRound = INVALID_HANDLE;
new Handle:g_Cvar_MedicArrowCount = INVALID_HANDLE;
new Handle:g_Cvar_MedicStartingHealth = INVALID_HANDLE;

new Handle:jumpHUD;

new Handle:g_hJumpTimer = INVALID_HANDLE;

new g_JumpCharge[MAXPLAYERS+1] = { 0, ... };

new bool:g_bDoubleJumped[MAXPLAYERS+1];
new g_LastButtons[MAXPLAYERS+1];

new bool:g_bSteamTools = false;

#if defined OIMM
new bool:g_bMultiMod = false;
#endif

new bool:g_bLateLoad = false;

new bool:g_bMedicRound = false;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Steam_SetGameDescription");
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("huntsmanhell_version", VERSION, "Huntsman Hell Version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_Cvar_Enabled = CreateConVar("huntsmanhell_enabled", "1", "Enable Huntsman Hell?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_Explode = CreateConVar("huntsmanhell_explode", "1", "Should arrows explode when they hit something?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_ExplodeRadius = CreateConVar("huntsmanhell_exploderadius", "200", "If arrows explode, the radius of explosion in hammer units.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0);
	g_Cvar_ExplodeDamage = CreateConVar("huntsmanhell_explodedamage", "50", "If arrows explode, the damage the explosion does.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0);
	g_Cvar_ExplodeFire = CreateConVar("huntsmanhell_explodefire", "0", "Should explosions catch players on fire?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_ExplodeFireSelf = CreateConVar("huntsmanhell_explodefireself", "0", "Should explosions catch yourself on fire?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_FireArrows = CreateConVar("huntsmanhell_firearrows", "1", "Should all arrows catch on fire in Huntsman Hell?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_ArrowCount = CreateConVar("huntsmanhell_arrowmultiplier", "4.0", "How many times the normal number of arrows should we have? Normal arrow count is 12.5 (banker rounded down to 12)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 8.0);
	g_Cvar_StartingHealth = CreateConVar("huntsmanhell_health", "400", "Amount of Health players to start with", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 65.0, true, 800.0);
	g_Cvar_SuperJump = CreateConVar("huntsmanhell_superjump", "1", "Should super jump be enabled in Huntsman Hell?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_DoubleJump = CreateConVar("huntsmanhell_doublejump", "1", "Should double jump be enabled in Huntsman Hell?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_FallDamage = CreateConVar("huntsmanhell_falldamage", "0", "Should players take fall damage?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_GameDescription = CreateConVar("huntsmanhell_gamedescription", "1", "If SteamTools is loaded, set the Game Description to Huntsman Hell?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_MedicRound = CreateConVar("huntsmanhell_medicchance", "10", "Chance of the current round being a Medic round", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_Cvar_MedicArrowCount = CreateConVar("huntsmanhell_medicarrowmultiplier", "1.32", "How many times the normal number of arrows should we have? Normal arrow count is 37.5 (banker rounded up to 38)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 8.0);
	g_Cvar_MedicStartingHealth = CreateConVar("huntsmanhell_medichealth", "300", "Amount of Health players to start with during Medic rounds", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 65.0, true, 800.0);

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("post_inventory_application", Event_Inventory);
	//HookEvent("player_changeclass", Event_ChangeClass);
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	
	HookConVarChange(g_Cvar_Enabled, Cvar_Enabled);
	HookConVarChange(g_Cvar_GameDescription, Cvar_GameDescription);
	
	RegConsoleCmd("hh_help", Cmd_Help, "Huntsman Hell help");

	jumpHUD = CreateHudSynchronizer();
	LoadTranslations("common.phrases");
	LoadTranslations("huntsmanhell.phrases");
	AutoExecConfig(true, "huntsmanhell");
}

#if defined OIMM
public OnPluginEnd()
{
	if (g_bMultiMod)
	{
		OptInMultiMod_Unregister("huntsman-hell");
	}
}
#endif
	
public OnAllPluginsLoaded()
{
	g_bSteamTools = LibraryExists("SteamTools");
	if (g_bSteamTools)
	{
		UpdateGameDescription();
	}

#if defined OIMM
	g_bMultiMod = LibraryExists("optin_multimod");
	if (g_bMultiMod)
	{
		OptInMultiMod_Register("huntsman-hell", MultiMod_CheckValidMap, MultiMod_StatusChanged, MultiMod_TranslateName);
	}
#endif
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_bSteamTools = true;
		UpdateGameDescription();
	}
#if defined OIMM
	else if (StrEqual(name, "optin_multimod", false))
	{
		g_bMultiMod = true;
		OptInMultiMod_Register("Huntsman Hell", MultiMod_CheckValidMap, MultiMod_StatusChanged, MultiMod_TranslateName);
	}
#endif
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_bSteamTools = false;
	}
#if defined OIMM
	else if (StrEqual(name, "optin_multimod", false))
	{
		g_bMultiMod = false;
	}
#endif
}

public OnMapStart()
{
	for (new i = 0; i < sizeof(g_Sounds_Explode); ++i)
	{
		PrecacheSound(g_Sounds_Explode[i]);
	}
	
	for (new i = 0; i < sizeof(g_Sounds_Jump); ++i)
	{
		PrecacheSound(g_Sounds_Jump[i]);
	}
	
	for (new i = 0; i < sizeof(g_Sounds_MedicJump); ++i)
	{
		PrecacheSound(g_Sounds_MedicJump[i]);
	}
}

public OnMapEnd()
{
	if (g_hJumpTimer != INVALID_HANDLE)
	{
		CloseHandle(g_hJumpTimer);
		g_hJumpTimer = INVALID_HANDLE;
	}
}

public OnClientDisconnect_Post(client)
{
	g_bDoubleJumped[client] = false;
	g_LastButtons[client] = 0;
	g_JumpCharge[client] = 0;
}

public Action:Cmd_Help(client, args)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Continue;
	}
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new Handle:menu = CreateMenu(HelpHandler, MenuAction_Display | MenuAction_End | MenuAction_DisplayItem);
	
	SetMenuTitle(menu, "%T", "help_title", LANG_SERVER);

	AddMenuItem(menu, "help_basic", "help_basic", ITEMDRAW_DISABLED);
	
	new arrows = RoundToFloor(25.0 * (GetConVarFloat(g_Cvar_ArrowCount) / 2.0)) + 1;

	new String:numbers[5];
	IntToString(arrows, numbers, sizeof(numbers));
	AddMenuItem(menu, "help_arrows", numbers, ITEMDRAW_DISABLED);

	IntToString(GetConVarInt(g_Cvar_StartingHealth), numbers, sizeof(numbers));
	AddMenuItem(menu, "help_health", numbers, ITEMDRAW_DISABLED);
	
	if (GetConVarBool(g_Cvar_Explode))
	{
		AddMenuItem(menu, "help_explosions", "help_explosions", ITEMDRAW_DISABLED);
	}
	
	if (GetConVarBool(g_Cvar_DoubleJump))
	{
		AddMenuItem(menu, "help_doublejump", "help_doublejump", ITEMDRAW_DISABLED);
	}
	
	if (GetConVarBool(g_Cvar_SuperJump))
	{
		AddMenuItem(menu, "help_superjump", "help_superjump", ITEMDRAW_DISABLED);
	}
	
	if (!GetConVarBool(g_Cvar_FallDamage))
	{
		AddMenuItem(menu, "help_falldamage", "help_falldamage", ITEMDRAW_DISABLED);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public HelpHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Display:
		{
			new String:buffer[128];
			Format(buffer, sizeof(buffer), "%T", "help_title", param1);
			SetPanelTitle(Handle:param2, buffer);
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		
		case MenuAction_DisplayItem:
		{
			new String:item[20];
			new String:display[20];
			GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));
			
			new String:buffer[128];
			
			if (StrEqual(item, "help_basic"))
			{
				Format(buffer, sizeof(buffer), "%T", "help_basic", param1);
				return RedrawMenuItem(buffer);
			}
			else if (StrEqual(item, "help_arrows"))
			{
				new String:arrowType[30];
				if (GetConVarBool(g_Cvar_Explode) && GetConVarBool(g_Cvar_FireArrows))
				{
					strcopy(arrowType, sizeof(arrowType), "help_arrows_explodingfire");
				}
				else if (GetConVarBool(g_Cvar_Explode))
				{
					strcopy(arrowType, sizeof(arrowType), "help_arrows_exploding");
				}
				else if (GetConVarBool(g_Cvar_FireArrows))
				{
					strcopy(arrowType, sizeof(arrowType), "help_arrows_fire");
				}
				else
				{
					strcopy(arrowType, sizeof(arrowType), "help_arrows_normal");
				}
				
				Format(buffer, sizeof(buffer), "%T", "help_arrows", param1, StringToInt(display), arrowType);
				return RedrawMenuItem(buffer);
			}
			else if (StrEqual(item, "help_explosions"))
			{
				new String:explodeType[30];
				if (GetConVarBool(g_Cvar_ExplodeFireSelf))
				{
					strcopy(explodeType, sizeof(explodeType), "help_explosionsfireself");
				}
				else if (GetConVarBool(g_Cvar_ExplodeFire))
				{
					strcopy(explodeType, sizeof(explodeType), "help_explosionsfire");
				}
				Format(buffer, sizeof(buffer), "%T", explodeType, param1);
				return RedrawMenuItem(buffer);
			}
			else if (StrEqual(item, "help_health"))
			{
				Format(buffer, sizeof(buffer), "%T", "help_health", param1, StringToInt(display));
				return RedrawMenuItem(buffer);
			}
			else if (StrEqual(item, "help_doublejump"))
			{
				Format(buffer, sizeof(buffer), "%T", "help_doublejump", param1);
				return RedrawMenuItem(buffer);
			}
			else if (StrEqual(item, "help_superjump"))
			{
				Format(buffer, sizeof(buffer), "%T", "help_superjump", param1);
				return RedrawMenuItem(buffer);
			}
			else if (StrEqual(item, "help_falldamage"))
			{
				Format(buffer, sizeof(buffer), "%T", "help_falldamage", param1);
				return RedrawMenuItem(buffer);
			}
		}
	}
	
	return 0;
}

public Cvar_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(g_Cvar_Enabled))
	{
		ChooseMedicRound();
		PrintToChatAll("%t", "login_help");
		if (g_hJumpTimer == INVALID_HANDLE)
		{
			CreateTimer(0.2, JumpTimer, _, TIMER_REPEAT);
		}
	}
	else
	{
		// Stop the timer while we're not running
		CloseHandle(g_hJumpTimer);
		g_hJumpTimer = INVALID_HANDLE;
	}
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		TF2Attrib_RemoveAll(i);
		
		if (IsPlayerAlive(i))
		{
			TF2_RemoveAllWeapons(i);
			if (GetConVarBool(g_Cvar_Enabled))
			{
				//TF2_SetPlayerClass(i, TFClass_Sniper); // Might as well only respawn them once
				g_bDoubleJumped[i] = false;
				g_LastButtons[i] = 0;
				g_JumpCharge[i] = 0;
			}
			
			TF2_RespawnPlayer(i);
			TF2_RegeneratePlayer(i);
		}
	}
	
	UpdateGameDescription();
}	

public Cvar_GameDescription(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateGameDescription();
}

public OnConfigsExecuted()
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
			}
		}
		g_bLateLoad = false;
	}
	
	if (g_hJumpTimer == INVALID_HANDLE)
	{
		g_hJumpTimer = CreateTimer(0.2, JumpTimer, _, TIMER_REPEAT);
	}
	
	UpdateGameDescription(true);
	ChooseMedicRound();
}

UpdateGameDescription(bool:bAddOnly=false)
{
	if (g_bSteamTools)
	{
		new String:gamemode[64];
		if (GetConVarBool(g_Cvar_Enabled) && GetConVarBool(g_Cvar_GameDescription))
		{
			Format(gamemode, sizeof(gamemode), "Huntsman Hell v.%s", VERSION);
		}
		else if (bAddOnly)
		{
			// Leave it alone if we're not running, should only be used when configs are executed
			return;
		}
		else
		{
			strcopy(gamemode, sizeof(gamemode), "Team Fortress");
		}
		Steam_SetGameDescription(gamemode);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new TFClassType:class;
	if (g_bMedicRound)
	{
		class = TFClass_Medic;
	}
	else
	{
		class = TFClass_Sniper;
	}
	
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", class);
	
	PrintToChat(client, "%t", "login_help");
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Continue;
	}
	
	new victim = GetEventInt(event, "victim_entindex");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (StrEqual(weapon, KILL_FLAMETHROWER) && attacker != victim)
	{
		SetEventString(event, "weapon", "huntsman");
		SetEventInt(event, "damagebits", (GetEventInt(event, "damagebits") & DMG_CRIT) | DMG_BURN | DMG_PREVENT_PHYSICS_FORCE);
		SetEventInt(event, "customkill", TF_CUSTOM_BURNING_ARROW);
	}

	if (StrEqual(weapon, KILL_EXPLOSION))
	{
		SetEventString(event, "weapon", "tf_pumpkin_bomb");
		SetEventInt(event, "damagebits", (GetEventInt(event, "damagebits") & DMG_CRIT) | DMG_BLAST | DMG_RADIATION | DMG_POISON);
		SetEventInt(event, "customkill", TF_CUSTOM_PUMPKIN_BOMB);
	}
	
	return Plugin_Continue;
}

ChooseMedicRound()
{
	new percent = GetConVarInt(g_Cvar_MedicRound);
	// Do a switch so we don't waste our time with random if it's always on or off.
	switch (percent)
	{
		case 0:
		{
			g_bMedicRound = false;
		}
		
		case 100:
		{
			g_bMedicRound = true;
		}
		
		default:
		{
			new chance = GetRandomInt(1, 100);
			if (chance <= percent)
			{
				g_bMedicRound = true;
			}
			else
			{
				g_bMedicRound = false;
			}
			
		}
	}

}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		g_JumpCharge[i] = 0;
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_Cvar_Enabled))
	{
		ChooseMedicRound();
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	g_bDoubleJumped[client] = false;
	g_LastButtons[client] = 0;
	g_JumpCharge[client] = 0;
	
	new TFClassType:class = TFClassType:GetEventInt(event, "class");
	
	if (g_bMedicRound)
	{
		if (class != TFClass_Medic)
		{
			// Directions say param 3 is both ignored and to set it to false in a player spawn hook...
			TF2_SetPlayerClass(client, TFClass_Medic, false); 
			
			TF2_RespawnPlayer(client);
			TF2_RegeneratePlayer(client);
		}
	}
	else
	{
		if (class != TFClass_Sniper)
		{
			// Directions say param 3 is both ignored and to set it to false in a player spawn hook...
			TF2_SetPlayerClass(client, TFClass_Sniper, false); 
			
			TF2_RespawnPlayer(client);
			TF2_RegeneratePlayer(client);
		}
	}

	//SetEntProp(client, Prop_Data, "m_iMaxHealth", GetConVarInt(g_Cvar_StartingHealth));
	//SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(g_Cvar_StartingHealth));
}

public Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new healthDiff = (GetConVarInt(g_Cvar_StartingHealth) - 125);

	if (g_bMedicRound)
	{
		// This is to prevent replacing their inventory if they just spawned as a different class and we haven't changed them yet
		if (TF2_GetPlayerClass(client) != TFClass_Medic)
		{
			return;
		}
		
		new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if (primary == -1)
		{
			new Handle:item = TF2Items_CreateItem(OVERRIDE_ALL);
			TF2Items_SetClassname(item, "tf_weapon_crossbow");
			TF2Items_SetItemIndex(item, 305);
			TF2Items_SetLevel(item, 15);
			TF2Items_SetQuality(item, 6);
			TF2Items_SetNumAttributes(item, 3);
			TF2Items_SetAttribute(item, 0, 199, 1.0); // "fires healing bolts"
			TF2Items_SetAttribute(item, 1, 42, 1.0); // "sniper no headshots"
			TF2Items_SetAttribute(item, 2, 77, 0.25); // "maxammo primary reduced"
			primary = TF2Items_GiveNamedItem(client, item);
			CloseHandle(item);
			EquipPlayerWeapon(client, primary);
		}
		
		// Base is 150 and normally set to 0.25
		TF2Attrib_SetByName(primary, "maxammo primary reduced", GetConVarFloat(g_Cvar_MedicArrowCount) * 0.25);
		
		// Medic base health is 150
		healthDiff = (GetConVarInt(g_Cvar_MedicStartingHealth) - 150);
	}
	else
	{
		// This is to prevent replacing their inventory if they just spawned as a different class and we haven't changed them yet
		if (TF2_GetPlayerClass(client) != TFClass_Sniper)
		{
			return;
		}
		
		new secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		
		if (secondary == -1)
		{
			new Handle:item = TF2Items_CreateItem(OVERRIDE_ALL);
			TF2Items_SetClassname(item, "tf_weapon_jar");
			TF2Items_SetItemIndex(item, 58);
			TF2Items_SetLevel(item, 5);
			TF2Items_SetQuality(item, 6);
			TF2Items_SetNumAttributes(item, 2);
			TF2Items_SetAttribute(item, 0, 56, 1.0); // "jarate description"
			TF2Items_SetAttribute(item, 1, 292, 4.0); // "kill eater score type"
			secondary = TF2Items_GiveNamedItem(client, item);
			CloseHandle(item);
			EquipPlayerWeapon(client, secondary);
		}

		new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if (primary == -1)
		{
			new Handle:item = TF2Items_CreateItem(OVERRIDE_ALL);
			TF2Items_SetClassname(item, "tf_weapon_compound_bow");
			TF2Items_SetItemIndex(item, 56);
			TF2Items_SetLevel(item, 10);
			TF2Items_SetQuality(item, 6);
			TF2Items_SetNumAttributes(item, 2);
			TF2Items_SetAttribute(item, 0, 37, 0.5);
			TF2Items_SetAttribute(item, 1, 328, 1.0);
			primary = TF2Items_GiveNamedItem(client, item); // disable fancy class select anim
			CloseHandle(item);
			EquipPlayerWeapon(client, primary);
		}
		// Base is 25 and normally set to 0.50
		TF2Attrib_SetByName(primary, "hidden primary max ammo bonus", GetConVarFloat(g_Cvar_ArrowCount) * 0.5);

		// Sniper base health is 125
		healthDiff = (GetConVarInt(g_Cvar_StartingHealth) - 125);
	}
	
	if (healthDiff > 0)
	{
		TF2Attrib_SetByName(client, "max health additive bonus", float(healthDiff));
	}
	else if (healthDiff < 0)
	{
		TF2Attrib_SetByName(client, "max health additive penalty", float(healthDiff));
	}
	
	if (!GetConVarBool(g_Cvar_FallDamage))
	{
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	}
	
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	static Handle:item = INVALID_HANDLE;
	
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Continue;
	}
	
	if (item != INVALID_HANDLE)
	{
		CloseHandle(item);
		item = INVALID_HANDLE;
	}
	
	// Block SMG, shields, and sniper rifles
	if (StrEqual(classname, "tf_weapon_smg") || iItemDefinitionIndex == 57 || iItemDefinitionIndex == 231 || iItemDefinitionIndex == 642 || StrEqual(classname, "tf_weapon_sniperrifle") || StrEqual(classname, "tf_weapon_sniperrifle_decap"))
	{
		return Plugin_Handled;
	}
	
	// Block Syringe Guns and Mediguns
	if (StrEqual(classname, "tf_weapon_syringegun_medic") || StrEqual(classname, "tf_weapon_medigun"))
	{
		return Plugin_Handled;
	}
	
	
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	if (StrEqual(classname, ARROW))
	{
		if (GetConVarBool(g_Cvar_Explode))
		{
			SDKHook(entity, SDKHook_StartTouchPost, Arrow_Explode);
		}
	}

	if (StrEqual(classname, HEALING_BOLT))
	{
		if (GetConVarBool(g_Cvar_Explode))
		{
			SDKHook(entity, SDKHook_StartTouchPost, Arrow_Explode);
		}
		
		if (GetConVarBool(g_Cvar_FireArrows))
		{
			SDKHook(entity, SDKHook_SpawnPost, Arrow_Light);
		}
	}
}

public Arrow_Explode(entity, other)
{
	new Float:origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new team = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	
	new explosion = CreateEntityByName("env_explosion");
	
	if (!IsValidEntity(explosion))
	{
		return;
	}
	
	new String:teamString[2];
	new String:magnitudeString[6];
	new String:radiusString[5];
	IntToString(team, teamString, sizeof(teamString));
	
	GetConVarString(g_Cvar_ExplodeDamage, magnitudeString, sizeof(magnitudeString));
	GetConVarString(g_Cvar_ExplodeRadius, radiusString, sizeof(radiusString));
	
	DispatchKeyValue(explosion, "iMagnitude", magnitudeString);
	DispatchKeyValue(explosion, "iRadiusOverride", radiusString);
	DispatchKeyValue(explosion, "TeamNum", teamString);
	
	SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", owner);
	
	TeleportEntity(explosion, origin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(explosion);
	
	AcceptEntityInput(explosion, "Explode");
	// Destroy it after a tenth of a second so it still exists during OnTakeDamagePost
	CreateTimer(0.1, Timer_DestroyExplosion, EntIndexToEntRef(explosion), TIMER_FLAG_NO_MAPCHANGE);
	
	new random = GetRandomInt(0, sizeof(g_Sounds_Explode)-1);
	EmitSoundToAll(g_Sounds_Explode[random], entity, SNDCHAN_WEAPON, _, _, _, _, _, origin);
}

public Arrow_Light(entity)
{
	// Sniper arrows will be already lit, but Medic arrows won't
	if (!GetEntProp(entity, Prop_Send, "m_bArrowAlight"))
	{
		SetEntProp(entity, Prop_Send, "m_bArrowAlight", true);
	}
}


public Action:Timer_DestroyExplosion(Handle:timer, any:explosionRef)
{
	new explosion = EntRefToEntIndex(explosionRef);
	if (explosion != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(explosion, "Kill");
	}
	
	return Plugin_Continue;
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (!GetConVarBool(g_Cvar_Enabled) || !GetConVarBool(g_Cvar_ExplodeFire) || victim <= 0 || victim > MaxClients ||
	attacker <= 0 || attacker > MaxClients || !IsValidEntity(inflictor))
	{
		return;
	}
	
	
	new String:classname[64];
	if (GetEntityClassname(inflictor, classname, sizeof(classname)) && StrEqual(classname, "env_explosion"))
	{
		new attackerTeam = GetClientTeam(attacker);
		new victimTeam = GetClientTeam(victim);

		if ((!GetConVarBool(g_Cvar_ExplodeFireSelf) && victim == attacker) || (victim != attacker && attackerTeam == victimTeam))
		{
			return;
		}
		TF2_IgnitePlayer(victim, attacker);
	}
}

public Action:JumpTimer(Handle:hTimer)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Stop;
	}
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		
		if (g_bDoubleJumped[i] && (GetEntityFlags(i) & FL_ONGROUND))
		{
			g_bDoubleJumped[i] = false;
		}
		
		if (GetConVarBool(g_Cvar_FireArrows) && !g_bMedicRound)
		{
			new primary = GetPlayerWeaponSlot(i, TFWeaponSlot_Primary);
			new currentWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if (primary == currentWeapon && GetEntProp(primary, Prop_Send, "m_bArrowAlight") == 0)
			{
				SetEntProp(primary, Prop_Send, "m_bArrowAlight", 1);
			}
		}
		
		if (!GetConVarBool(g_Cvar_SuperJump))
		{
			continue;
		}
		
		SetHudTextParams(-1.0, 0.88, 0.35, 255, 255, 255, 255);
		new buttons = GetClientButtons(i);
		if (((buttons & IN_DUCK) || (buttons & IN_ATTACK2)) && (g_JumpCharge[i] >= 0) && !(buttons & IN_JUMP))
		{
			if (g_JumpCharge[i] + 5 < JUMPCHARGE)
			{
				g_JumpCharge[i] += 5;
			}
			else
			{
				g_JumpCharge[i] = JUMPCHARGE;
			}
			
			ShowSyncHudText(i, jumpHUD, "%t", "jump_status", g_JumpCharge[i]*4);
		}
		else if (g_JumpCharge[i] < 0)
		{
			g_JumpCharge[i] += 5;
			ShowSyncHudText(i, jumpHUD, "%t", "jump_status_2", -g_JumpCharge[i]/20);
		}
		else
		{
			decl Float:ang[3];
			GetClientEyeAngles(i, ang);
			if ((ang[0] < -45.0) && (g_JumpCharge[i] > 1))
			{
				decl Float:pos[3];
				decl Float:vel[3];
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", vel);
				vel[2]=750 + g_JumpCharge[i] * 13.0;
				SetEntProp(i, Prop_Send, "m_bJumping", 1);
				vel[0] *= (1+Sine(float(g_JumpCharge[i]) * FLOAT_PI / 50));
				vel[1] *= (1+Sine(float(g_JumpCharge[i]) * FLOAT_PI / 50));
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vel);
				g_JumpCharge[i]=-120;
				
				if (g_bMedicRound)
				{
					new random = GetRandomInt(0, sizeof(g_Sounds_MedicJump)-1);
					EmitSoundToAll(g_Sounds_MedicJump[random], i, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, _, _, _, _, pos);
				}
				else
				{
					new random = GetRandomInt(0, sizeof(g_Sounds_Jump)-1);
					EmitSoundToAll(g_Sounds_Jump[random], i, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, _, _, _, _, pos);
				}
			}
			else
			{
				g_JumpCharge[i] = 0;
			}
		}
	}
	
	return Plugin_Continue;
}

// Use the 1.4 compat version
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!GetConVarBool(g_Cvar_Enabled) || !GetConVarBool(g_Cvar_DoubleJump))
	{
		return Plugin_Continue;
	}
	
	if ((buttons & IN_JUMP) && !(g_LastButtons[client] & IN_JUMP) && !(GetEntityFlags(client) & FL_ONGROUND) && !g_bDoubleJumped[client])
	{
		DoClientDoubleJump(client);
		g_bDoubleJumped[client] = true;
	}
	g_LastButtons[client] = buttons;
	return Plugin_Continue;
}

stock DoClientDoubleJump(client)
{
	decl Float:forwardVector[3];
	new Float:x, Float:y, Float:z;
	CleanupClientDirection(client, GetClientButtons(client), x, y, z);
	forwardVector[0] = x;
	forwardVector[1] = y;
	forwardVector[2] = z;
	new Float:speed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	ScaleVector(forwardVector, speed);
//	GetClientEyeAngles(client, clientEyeAngle);
//	clientEyeAngle[2] = 290.0;
//	GetAngleVectors(clientEyeAngle, forwardVector, NULL_VECTOR, NULL_VECTOR);
//	NormalizeVector(forwardVector, forwardVector);
//	ScaleVector(forwardVector, 290.0);
	forwardVector[2] = 245.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, forwardVector);
}

stock CleanupClientDirection(client, buttons, &Float:x, &Float:y, &Float:z)
{
//	if (buttons & IN_LEFT) PrintToChatAll("left");
//	if (buttons & IN_RIGHT) PrintToChatAll("right");
	buttons = buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT);
//	if (buttons & IN_FORWARD) PrintToChatAll("forward");
//	if (buttons & IN_BACK) PrintToChatAll("back");
//	if (buttons & IN_MOVELEFT) PrintToChatAll("moveleft");
//	if (buttons & IN_MOVERIGHT) PrintToChatAll("moveright");
	if ((buttons & (IN_FORWARD|IN_BACK)) == (IN_FORWARD|IN_BACK))
	{
		buttons &= ~IN_FORWARD;
		buttons &= ~IN_BACK;
	}
	if ((buttons & (IN_MOVELEFT|IN_MOVERIGHT)) == (IN_MOVELEFT|IN_MOVERIGHT))
	{
		buttons &= ~IN_MOVELEFT;
		buttons &= ~IN_MOVERIGHT;
	}
	if ((buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)) == 0)
	{
		x = 0.0;
		y = 0.0;
		z = 230.0;
//		PrintToChatAll("Returning prematurely");
		return;
	}
	decl Float:clientEyeAngle[3];
	GetClientEyeAngles(client, clientEyeAngle);
	clientEyeAngle[0] = 0.0;
	clientEyeAngle[2] = 0.0;
	switch (buttons)
	{
		case (IN_FORWARD|IN_MOVELEFT): clientEyeAngle[1] += 45.0;
		case (IN_FORWARD|IN_MOVERIGHT): clientEyeAngle[1] -= 45.0;
		case (IN_BACK|IN_MOVELEFT): clientEyeAngle[1] += 135.0;
		case (IN_BACK|IN_MOVERIGHT): clientEyeAngle[1] -= 135.0;
		case (IN_MOVELEFT): clientEyeAngle[1] += 90.0;
		case (IN_BACK): clientEyeAngle[1] += 179.9;
		case (IN_MOVERIGHT): clientEyeAngle[1] -= 90.0;
		default: {}
	}
	if (clientEyeAngle[1] <= -180.0) clientEyeAngle[1] += 360.0;
	if (clientEyeAngle[1] > 180.0) clientEyeAngle[1] -= 360.0;
//	PrintToChatAll("%.2f yaw", clientEyeAngle[1]);
	GetAngleVectors(clientEyeAngle, clientEyeAngle, NULL_VECTOR, NULL_VECTOR);
//	PrintToChatAll("%.2f %.2f %.2f direction", clientEyeAngle[0],clientEyeAngle[1],clientEyeAngle[2]);
	NormalizeVector(clientEyeAngle, clientEyeAngle);
//	PrintToChatAll("%.2f %.2f %.2f direnormal", clientEyeAngle[0],clientEyeAngle[1],clientEyeAngle[2]);
//	AddVectors(clientEyeAngle, vector, vector);
//	NormalizeVector(vector, vector);
	x = clientEyeAngle[0];
	y = clientEyeAngle[1];
	z = clientEyeAngle[2];
}

public bool:MultiMod_CheckValidMap(const String:map[])
{
	// Doesn't work so well on Mann Vs. Machine, Vs. Saxton Hale, or Prop Hunt maps
	if (StrContains(map, "mvm_", false) != -1 || StrContains(map, "vsh_", false) != -1 || StrContains(map, "ph_", false) != -1 || StrContains(map, "dr_", false) != -1)
	{
		return false;
	}
	
	return true;
}

public MultiMod_StatusChanged(bool:enabled)
{
	SetConVarBool(g_Cvar_Enabled, enabled);
}

public MultiMod_TranslateName(client, String:translation[], maxlength)
{
	Format(translation, maxlength, "%T", "game_mode", client);
}
