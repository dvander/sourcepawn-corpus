//Include data
#pragma semicolon 2
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <adminmenu>

//Definitions needed for plugin functionality
#define GETVERSION "1.0.6b"
#define DEBUG 0
#define DESIRED_FLAGS "ADMFLAG_SLAY"

//Colors
#define RED "189 9 13 255"
#define BLUE "34 22 173 255"
#define GREEN "34 120 24 255"
#define YELLOW "231 220 24 255"
#define BLACK "0 0 0 255"
#define WHITE "255 255 255 255"
#define TRANSPARENT "255 255 255 0"
#define HALFTRANSPARENT "255 255 255 180"

//Sounds
#define EXPLOSION_SOUND "ambient/explosions/explode_1.wav"
#define EXPLOSION_SOUND2 "ambient/explosions/explode_2.wav"
#define EXPLOSION_SOUND3 "ambient/explosions/explode_3.wav"
#define EXPLOSION_DEBRIS "animation/van_inside_debris.wav"

//Particles
#define FIRE_PARTICLE "gas_explosion_ground_fire"
#define EXPLOSION_PARTICLE "explosion_huge_b"
#define BURN_IGNITE_PARTICLE "fire_small_01"
#define BLEED_PARTICLE "blood_impact_infected_01_shotgun"

//Models
#define ZOEY_MODEL "models/survivors/survivor_teenangst.mdl"
#define FRANCIS_MODEL "models/survivors/survivor_biker.mdl"
#define LOUIS_MODEL "models/survivors/survivor_manager.mdl"

/*
 *Offsets, Handles, Bools, Floats, Integers, Strings, Vecs and everything needed for the commands
 */
 
//Strings

//Integers
/* Refers to the last selected userid by the admin client index. Doesn't matter if the admins leaves and another using the same index gets in
 * because if this admin uses the same menu item, the last userid will be reset.
 */
new g_iCurrentUserId[MAXPLAYERS+1] = 0; 

//Bools
new bool:g_bVehicleReady = false;
new bool:g_bStrike = false;
new bool:g_bGnomeRain = false;
new bool:g_bHasGod[MAXPLAYERS+1] = false;
//Floats

//Handles
new Handle:g_hTopMenu = INVALID_HANDLE;

//Offsets
static g_flLagMovement = 0;

//Vectors

//CVARS
new Handle:g_cvarRadius = INVALID_HANDLE;
new Handle:g_cvarPower = INVALID_HANDLE;
new Handle:g_cvarDuration = INVALID_HANDLE;
new Handle:g_cvarRainDur = INVALID_HANDLE;
new Handle:g_cvarRainRadius = INVALID_HANDLE;
new Handle:g_cvarLog = INVALID_HANDLE;

//Plugin Info
public Plugin:myinfo = 
{
	name = "[L4D] Custom admin commands",
	author = "honorcode23",
	description = "Allow admins to use new administrative or fun commands",
	version = GETVERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=133475"
}

public OnPluginStart()
{
	//Left 4 dead only
	decl String:sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead", false))
	{
		SetFailState("[L4D] Custom Commands supports Left 4 dead only!");
	}
	
	
	
	//Cvars
	CreateConVar("l4d_custom_commands_version", GETVERSION, "Version of Custom Admin Commands Plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvarRadius = CreateConVar("l4d_custom_commands_explosion_radius", "350", "Radius for the Create Explosion's command explosion", FCVAR_PLUGIN);
	g_cvarPower = CreateConVar("l4d_custom_commands_explosion_power", "350", "Power of the Create Explosion's command explosion", FCVAR_PLUGIN);
	g_cvarDuration = CreateConVar("l4d_custom_commands_explosion_duration", "15", "Duration of the Create Explosion's command explosion fire trace", FCVAR_PLUGIN);
	g_cvarRainDur = CreateConVar("l4d_custom_commands_rain_duration", "10", "Time out for the gnome's rain or l4d1 survivors rain", FCVAR_PLUGIN);
	g_cvarRainRadius = CreateConVar("l4d_custom_commands_rain_radius", "300", "Maximum radius of the gnome rain or l4d1 rain. Will also affect the air strike radius", FCVAR_PLUGIN);
	g_cvarLog = CreateConVar("l4d_custom_commands_log", "1", "Log admin actions when they use a command? [1: Yes 0: No", FCVAR_PLUGIN);
	
	
	//Commands
	//RegAdminCmd("sm_vomitplayer", CmdVomitPlayer, ADMFLAG_SLAY, "Vomits the desired player");
	RegAdminCmd("sm_incapplayer", CmdIncapPlayer, ADMFLAG_SLAY, "Incapacitates a survivor or tank");
	RegAdminCmd("sm_speedplayer", CmdSpeedPlayer, ADMFLAG_SLAY, "Set a player's speed");
	RegAdminCmd("sm_sethpplayer", CmdSetHpPlayer, ADMFLAG_SLAY, "Set a player's health");
	RegAdminCmd("sm_colorplayer", CmdColorPlayer, ADMFLAG_SLAY, "Set a player's model color");
	RegAdminCmd("sm_setexplosion", CmdSetExplosion, ADMFLAG_SLAY, "Creates an explosion on your feet or where you are looking at");
	RegAdminCmd("sm_sizeplayer", CmdSizePlayer, ADMFLAG_SLAY, "Resize a player's model (Most likely, their pants)");
	//RegAdminCmd("sm_norescue", CmdNoRescue, ADMFLAG_SLAY, "Forces the rescue vehicle to leave");
	//RegAdminCmd("sm_dontrush", CmdDontRush, ADMFLAG_SLAY, "Forces a player to re-appear in the starting safe zone");
	//RegAdminCmd("sm_bugplayer", CmdBugPlayer, ADMFLAG_SLAY, "Bugs a player forcing him to close the left4dead2.exe process by hand");
	//RegAdminCmd("sm_oldmovie", CmdOldMovie, ADMFLAG_SLAY, "Will add the black and white effect on the player");
	RegAdminCmd("sm_changehp", CmdChangeHp, ADMFLAG_SLAY, "Will switch a player's health between temporal or permanent");
	RegAdminCmd("sm_airstrike", CmdAirstrike, ADMFLAG_SLAY, "Will set an airstrike attack in the player's face");
	//RegAdminCmd("sm_gnomerain", CmdGnomeRain, ADMFLAG_SLAY, "Will rain gnomes within your position");
	//RegAdminCmd("sm_gnomewipe", CmdGnomeWipe, ADMFLAG_SLAY, "Will delete all the gnomes in the map");
	//RegAdminCmd("sm_wipebodies", CmdWipeBody, ADMFLAG_SLAY, "Will delete all the ragdoll entities in the map");
	RegAdminCmd("sm_godmode", CmdGodMode, ADMFLAG_SLAY, "Will activate or deactivate godmode from player");
	RegAdminCmd("sm_l4drain", CmdL4dRain, ADMFLAG_SLAY, "Will rain left 4 dead 1 survivors");
	RegAdminCmd("sm_colortarget", CmdColorTarget, ADMFLAG_SLAY, "Will color the aiming target entity");
	RegAdminCmd("sm_sizetarget", CmdSizeTarget, ADMFLAG_SLAY, "Will size the aiming target entity");
	RegAdminCmd("sm_shakeplayer", CmdShakePlayer, ADMFLAG_SLAY, "Will shake a player screen during the desired amount of time");
	//RegAdminCmd("sm_firework", CmdFireWork, ADMFLAG_SLAY, "Will launch a firework");
	//RegAdminCmd("sm_boomerrain", CmdBoomerRain, ADMFLAG_SLAY, "Will rain boomers");
	//RegAdminCmd("sm_charge", CmdCharge, ADMFLAG_SLAY, "Will launch a survivor far away");
	RegAdminCmd("sm_weaponrain", CmdWeaponRain, ADMFLAG_SLAY, "Will rain the specified weapon");
	RegAdminCmd("sm_cmdplayer", CmdConsolePlayer, ADMFLAG_SLAY, "Will control a player's console");
	RegAdminCmd("sm_bleedplayer", CmdBleedPlayer, ADMFLAG_SLAY, "Will force a player to bleed");
	//RegAdminCmd("sm_callrescue", CmdCallRescue, ADMFLAG_SLAY, "Will call the rescue vehicle");
	//RegAdminCmd("sm_hinttext", CmdHintText, ADMFLAG_SLAY, "Prints an instructor hint to all players");
	RegAdminCmd("sm_cheat", CmdCheat, ADMFLAG_SLAY, "Bypass any command and executes it. Rule: [command] [argument] EX: z_spawn tank");
	RegAdminCmd("sm_wipeentity", CmdWipeEntity, ADMFLAG_SLAY, "Wipe all entities with the given name");
	RegAdminCmd("sm_setmodel", CmdSetModel, ADMFLAG_SLAY, "Sets a player's model relavite to the models folder");
	RegAdminCmd("sm_setmodelentity", CmdSetModelEntity, ADMFLAG_SLAY, "Sets all entities model that match the given classname");
	RegAdminCmd("sm_createparticle", CmdCreateParticle, ADMFLAG_SLAY, "Creates a particle with the option to parent it");
	RegAdminCmd("sm_ignite", CmdIgnite, ADMFLAG_SLAY, "Ignites a survivor player");
	RegAdminCmd("sm_teleport", CmdTeleport, ADMFLAG_SLAY, "Teleports a player to your cursor position");
	RegAdminCmd("sm_teleportent", CmdTeleportEnt, ADMFLAG_SLAY, "Teleports all entities with the given classname to your cursor position");
	//RegAdminCmd("sm_ccinfo", CmdCCInfo, ADMFLAG_SLAY, "Prints all the commands and their syntax");
	
	//Development
	//RegAdminCmd("sm_entityinfo", CmdEntityInfo, ADMFLAG_SLAY, "Returns the aiming entity classname");
	//RegAdminCmd("sm_fakeride", CmdFakeRide, ADMFLAG_SLAY, "Fake ride");
	//RegAdminCmd("sm_destroyplayer", CmdDestroyPlayer, ADMFLAG_SLAY, "Will destroy the selected player in a single strike");
	RegAdminCmd("sm_ccrefresh", CmdCCRefresh, ADMFLAG_SLAY, "Refreshes the menu items");
	
	//Events
	
	HookEvent("round_end", OnRoundEnd);
	HookEvent("finale_vehicle_ready", OnVehicleReady);
	
	
	//Translations
	LoadTranslations("common.phrases");	
	if (LibraryExists("adminmenu") && ((g_hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(g_hTopMenu);
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		g_hTopMenu = INVALID_HANDLE;
	}
}

public OnMapStart()
{
	PrecacheSound(EXPLOSION_SOUND);
	
	PrecacheModel(ZOEY_MODEL);
	PrecacheModel(LOUIS_MODEL);
	PrecacheModel(FRANCIS_MODEL);
	PrecacheModel("sprites/muzzleflash4.vmt");
	
	PrefetchSound(EXPLOSION_SOUND);
	
	PrecacheParticle(FIRE_PARTICLE);
	PrecacheParticle(BURN_IGNITE_PARTICLE);
	PrecacheParticle(EXPLOSION_PARTICLE);
	//Get the offset
	g_flLagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
}

public OnMapEnd()
{
	g_bVehicleReady = false;
	for(new i=1; i<=MaxClients; i++)
	{
		g_bHasGod[i] = false;
	}
}

public Action:CmdCCRefresh(client, args)
{
	PrintToChat(client, "[SM] Refreshing the admin menu...");
	g_hTopMenu = GetAdminTopMenu();
	new TopMenuObject:players_commands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	new TopMenuObject:server_commands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_SERVERCOMMANDS);
	
	// now we add the function ...
	if (players_commands != INVALID_TOPMENUOBJECT)
	{
		//AddToTopMenu (g_hTopMenu, "l4dvomitplayer", TopMenuObject_Item, MenuItem_VomitPlayer, players_commands, "l4dvomitplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dincapplayer", TopMenuObject_Item, MenuItem_IncapPlayer, players_commands, "l4dincapplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dspeedplayer", TopMenuObject_Item, MenuItem_SpeedPlayer, players_commands, "l4dspeedplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dsethpplayer", TopMenuObject_Item, MenuItem_SetHpPlayer, players_commands, "l4dsethpplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dcolorplayer", TopMenuObject_Item, MenuItem_ColorPlayer, players_commands, "l4dcolorplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dsizeplayer", TopMenuObject_Item, MenuItem_ScalePlayer, players_commands, "l4dsizeplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dshakeplayer", TopMenuObject_Item, MenuItem_ShakePlayer, players_commands, "l4dshakeplayer", ADMFLAG_SLAY);
		//AddToTopMenu (g_hTopMenu, "l4dchargeplayer", TopMenuObject_Item, MenuItem_Charge, players_commands, "l4dchargeplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dteleplayer", TopMenuObject_Item, MenuItem_TeleportPlayer, players_commands, "l4dteleplayer", ADMFLAG_SLAY);
		
		//AddToTopMenu (g_hTopMenu, "l4ddontrush", TopMenuObject_Item, MenuItem_DontRush, players_commands, "l4ddontrush", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dairstrike", TopMenuObject_Item, MenuItem_Airstrike, players_commands, "l4dairstrike", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dchangehp", TopMenuObject_Item, MenuItem_ChangeHp, players_commands, "l4dchangehp", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dgodmode", TopMenuObject_Item, MenuItem_GodMode, players_commands, "l4dgodmode", ADMFLAG_SLAY);	
	}
	else
	{
		PrintToChat(client, "[SM] Player commands category is invalid!");
		return Plugin_Handled;
	}
	
	if(server_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu (g_hTopMenu, "l4dcreateexplosion", TopMenuObject_Item, MenuItem_CreateExplosion, server_commands, "l4dcreateexplosion", ADMFLAG_SLAY);
		//AddToTopMenu (g_hTopMenu, "l4dnorescue", TopMenuObject_Item, MenuItem_NoRescue, server_commands, "l4dnorescue", ADMFLAG_SLAY);
		//AddToTopMenu (g_hTopMenu, "l4dgnomerain", TopMenuObject_Item, MenuItem_GnomeRain, server_commands, "l4dgnomerain", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dsurvrain", TopMenuObject_Item, MenuItem_SurvRain, server_commands, "l4dsurvrain", ADMFLAG_SLAY);
		//AddToTopMenu (g_hTopMenu, "l4dgnomewipe", TopMenuObject_Item, MenuItem_GnomeWipe, server_commands, "l4dgnomewipe", ADMFLAG_SLAY);
		//AddToTopMenu (g_hTopMenu, "l4dwipebodies", TopMenuObject_Item, MenuItem_WipeBody, server_commands, "l4dwipebodies", ADMFLAG_SLAY);	
	}
	else
	{
		PrintToChat(client, "[SM] Server commands category is invalid!");
		return Plugin_Handled;
	}
	PrintToChat(client, "[SM] Successfully refreshed the admin menu");
	return Plugin_Handled;
}

//**********************************EVENTS*******************************************
public OnVehicleReady(Handle:event, String:event_name[], bool:dontBroadcast)
{
	g_bVehicleReady = true;
}

public OnRoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		g_bHasGod[i] = false;
	}
	g_bVehicleReady = false;
}

//*********************************COMMANDS*******************************************
public Action:CmdIncapPlayer(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_incapplayer <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		IncapPlayer(target_list[i], client);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Incap Player' command on '%s'", name, arg);
	return Plugin_Handled;
}

public Action:CmdSpeedPlayer(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_speedplayer <#userid|name> [value]");
		return Plugin_Handled;
	}
	decl String:arg1[65], String:arg2[65], Float:speed;
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	speed = StringToFloat(arg2);
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		ChangeSpeed(target_list[i], client, speed);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Speed Player' command on '%s' with value <%f>", name, arg1, speed);
	return Plugin_Handled;
}

public Action:CmdSetHpPlayer(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_sethpplayer <#userid|name> [amount]");
		return Plugin_Handled;
	}
	decl String:arg1[65], String:arg2[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new health = StringToInt(arg2);
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		SetHealth(target_list[i], client, health);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Set Heealth' command on '%s' with value <%i>", name, arg1, health);
	return Plugin_Handled;
}

public Action:CmdColorPlayer(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_colorplayer <#userid|name> [R G B A]");
	}
	decl String:arg1[65], String:arg2[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		ChangeColor(target_list[i], client, arg2);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Speed Player' command on '%s' with value '%s'", name, arg1, arg2);
	return Plugin_Handled;
}

public Action:CmdColorTarget(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_colortarget [R G B A]");
	}
	new target = GetClientAimTarget(client, false);
	if(!IsValidEntity(target) || !IsValidEdict(target))
	{
		PrintToChat(client, "[SM] Invalid entity or looking to nothing");
	}
	decl String:arg[256];
	GetCmdArg(1, arg, sizeof(arg));
	DispatchKeyValue(target, "rendercolor", arg);
	DispatchKeyValue(target, "color", arg);
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Colot Target' command", name);
	return Plugin_Handled;
}

public Action:CmdSizeTarget(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_sizetarget [scale]");
	}
	new target = GetClientAimTarget(client, false);
	if(!IsValidEntity(target) || !IsValidEdict(target))
	{
		PrintToChat(client, "[SM] Invalid entity or looking to nothing");
	}
	decl String:arg[256];
	GetCmdArg(1, arg, sizeof(arg));
	new Float:scale = StringToFloat(arg);
	SetEntPropFloat(target, Prop_Send, "m_flModelScale", scale);
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Size Target' command", name);
	return Plugin_Handled;
}

public Action:CmdSetExplosion(client, args)
{
	if(args < 1 || args > 1)
	{
		PrintToChat(client, "[SM] Usage: sm_setexplosion [position | cursor]");
		return Plugin_Handled;
	}
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	if(StrContains(arg, "position", false) != -1)
	{
		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
		CreateExplosion(pos);
		decl String:name[256];
		GetClientName(client, name, sizeof(name));
		LogCommand("'%s' used the 'Set Explosion' command", name);
		return Plugin_Handled;
	}
	else if(StrContains(arg, "cursor", false) != -1)
	{
		decl Float:VecOrigin[3], Float:VecAngles[3];
		GetClientAbsOrigin(client, VecOrigin);
		GetClientEyeAngles(client, VecAngles);
		TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
		if(TR_DidHit(INVALID_HANDLE))
		{
			TR_GetEndPosition(VecOrigin);
		}
		else
		{
			PrintToChat(client, "Vector out of world geometry. Exploding on origin instead");
		}
		CreateExplosion(VecOrigin);
		decl String:name[256];
		GetClientName(client, name, sizeof(name));
		LogCommand("'%s' used the 'Set Explosion' command", name);
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client, "[SM] Specify the explosion position");
		return Plugin_Handled;
	}
}

public Action:CmdSizePlayer(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_sizeplayer <#userid|name> [value]");
	}
	decl String:arg1[65], String:arg2[65], Float:scale;
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	scale = StringToFloat(arg2);
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		ChangeScale(target_list[i], client, scale);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Scale Player' command on '%s' with value <%f>", name, arg1, scale);
	return Plugin_Handled;
}

public Action:CmdNoRescue(client, args)
{
	if(g_bVehicleReady)
	{
		decl String:map[32];
		GetCurrentMap(map, sizeof(map));
		if(StrEqual(map, "c1m4_atrium"))
		{
			CheatCommand(client, "ent_fire", "relay_car_escape trigger");
			CheatCommand(client, "ent_fire", "car_camera enable");
			EndGame();
		}
		else if(StrEqual(map, "c2m5_concert"))
		{
			CheatCommand(client, "ent_fire", "stadium_exit_left_chopper_prop setanimation exit2");
			CheatCommand(client, "ent_fire", "stadium_exit_left_outro_camera enable");
			EndGame();
		}
		else if(StrEqual(map, "c3m4_plantation"))
		{
			CheatCommand(client, "ent_fire", "camera_outro setparentattachment attachment_cam");
			CheatCommand(client, "ent_fire", "escape_boat_prop setanimation c3m4_outro_boat");
			CheatCommand(client, "ent_fire", "camera_outro enable");
			EndGame();
		}
		else if(StrEqual(map, "c4m5_milltown_escape"))
		{
			CheatCommand(client, "ent_fire", "model_boat setanimation c4m5_outro_boat");
			CheatCommand(client, "ent_fire", "camera_outro setparent model_boat");
			CheatCommand(client, "ent_fire", "camera_outro setparentattachment attachment_cam");
			EndGame();
		}
		else if(StrEqual(map, "c5m5_bridge"))
		{
			CheatCommand(client, "ent_fire", "heli_rescue setanimation 4lift");
			CheatCommand(client, "ent_fire", "camera_outro enable");
			EndGame();
		}
		else if(StrEqual(map, "c6m3_port"))
		{
			CheatCommand(client, "ent_fire", "outro_camera_1 setparentattachment Attachment_1");
			CheatCommand(client, "ent_fire", "car_dynamic Disable");
			CheatCommand(client, "ent_fire", "car_outro_dynamic enable");
			CheatCommand(client, "ent_fire", "ghostanim_outro enable");
			CheatCommand(client, "ent_fire", "ghostanim_outro setanimation c6m3_outro");
			CheatCommand(client, "ent_fire", "car_outro_dynamic setanimation c6m3_outro_charger");
			CheatCommand(client, "ent_fire", "outro_camera_1 enable");
			CheatCommand(client, "ent_fire", "c6m3_escape_music playsound");
			EndGame();
		}
		else
		{
			PrintToChat(client, "[SM] This map doesn't have a rescue vehicle or is not supported!");
		}
	}
	else
	{
		PrintToChat(client, "[SM] Wait for the rescue vehicle to be ready first!");
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'No Rescue' command");
	return Plugin_Handled;
}

public Action:CmdDontRush(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_dontrush <#userid|name>");
	}
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		TeleportBack(target_list[i], client);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Anti Rush' command on '%s'", name, arg);
	return Plugin_Handled;
}

public Action:CmdBugPlayer(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_bugplayer <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		AcceptEntityInput(target_list[i], "becomeragdoll");
	}
	return Plugin_Handled;
}

/*public Action:CmdDestroyPlayer(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_destroyplayer <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		LaunchMissile(target_list[i], client);
	}
	decl String:name[256];
	new target;
	for(new i=1; i<=MaxClients; i++)
	{
		if(AliveFilter(i))
		{
			GetClientName(i, name, sizeof(name));
			if(StrEqual(name, arg))
			{
				target = i;
			}
		}
	}
	LaunchMissile(target, client);
	return Plugin_Handled;
}
*/

public Action:CmdAirstrike(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_airstrike <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		Airstrike(target_list[i]);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Airstrike' command on '%s'", name, arg);
	return Plugin_Handled;
}

public Action:CmdOldMovie(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_oldmovie <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		BlackAndWhite(target_list[i], client);
	}
	return Plugin_Handled;
}

public Action:CmdChangeHp(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_changehp <#userid|name> [perm | temp]");
		return Plugin_Handled;
	}
	decl String:arg1[65], String:arg2[65];
	new type = 0;
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StrEqual(arg2, "perm"))
	{
		type = 1;
	}
	else if(StrEqual(arg2, "temp"))
	{
		type = 2;
	}
	if(type <= 0 || type > 2)
	{
		PrintToChat(client, "[SM] Specify the health style you want");
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		SwitchHealth(target_list[i], client, type);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Change Health Type' command on '%s' with value <%s>", name, arg1, arg2);
	return Plugin_Handled;
}

public Action:CmdGnomeRain(client, args)
{
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Gnome Rain' command");
	StartGnomeRain(client);
}

public Action:CmdL4dRain(client, args)
{
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'L4D1 rain' command");
	StartL4dRain(client);
}

public Action:CmdGnomeWipe(client, args)
{
	decl String:classname[256];
	new count = 0;
	for(new i=MaxClients; i<=GetMaxEntities(); i++)
	{
		if(!IsValidEntity(i) || !IsValidEdict(i))
		{
			continue;
		}
		GetEdictClassname(i, classname, sizeof(classname));
		if(StrEqual(classname, "weapon_gnome"))
		{
			RemoveEdict(i);
			count++;
		}
	}
	PrintToChat(client, "[SM] Succesfully wiped %i gnomes", count);
	count = 0;
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Gnome Wipe' command");
	return Plugin_Handled;
}

/*public Action:CmdWipeBody(client, args)
{
	decl String:classname[256];
	new count = 0;
	for(new i=MaxClients; i<=GetMaxEntities(); i++)
	{
		if(!IsValidEntity(i) || !IsValidEdict(i))
		{
			continue;
		}
		GetEdictClassname(i, classname, sizeof(classname));
		if(StrEqual(classname, "prop_ragdoll"))
		{
			RemoveEdict(i);
			count++;
		}
	}
	PrintToChat(client, "[SM] Succesfully wiped %i bodies", count);
	count = 0;
}
*/

public Action:CmdGodMode(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_godmode <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		GodMode(target_list[i], client);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'God Mode' command on '%s'", name, arg);
	return Plugin_Handled;
}

public Action:CmdShakePlayer(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_shake <#userid|name> [duration]");
		return Plugin_Handled;
	}
	decl String:arg1[65], String:arg2[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	new Float:duration = StringToFloat(arg2);
	
	for (new i = 0; i < target_count; i++)
	{
		Shake(target_list[i], client, duration);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Shake' command on '%s' with value <%f>", name, arg1, duration);
	return Plugin_Handled;
}

public Action:CmdConsolePlayer(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_cmdplayer <#userid|name> [command]");
		return Plugin_Handled;
	}
	decl String:arg1[65], String:arg2[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		ClientCommand(target_list[i], arg2);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Client Console' command on '%s' with value <%s>", name, arg1, arg2);
	return Plugin_Handled;
}

public Action:CmdWeaponRain(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_weaponrain [weapon type] [Example: !weaponrain adrenaline]");
		return Plugin_Handled;
	}
	decl String:arg1[65];
	GetCmdArgString(arg1, sizeof(arg1));
	if(IsValidWeapon(arg1))
	{
		WeaponRain(arg1, client);
	}
	else
	{
		PrintToChat(client, "[SM] Wrong weapon type");
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Weapon Rain' command", name);
	return Plugin_Handled;
}

public Action:CmdBleedPlayer(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_bleedplayer <#userid|name> [duration]");
		return Plugin_Handled;
	}
	
	decl String:arg1[65], String:arg2[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	new Float:duration = StringToFloat(arg2);
	
	for (new i = 0; i < target_count; i++)
	{
		Bleed(target_list[i], client, duration);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Bleed' command on '%s' with value <%f>", name, arg1, duration);
	return Plugin_Handled;
}

public Action:CmdHintText(client, args)
{
	decl String:arg2[65];
	GetCmdArgString(arg2, sizeof(arg2));
	InstructorHint(arg2);
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Hint Text' command with value <%s>", name, arg2);
	return Plugin_Handled;
}

public Action:CmdCheat(client, args)
{
	decl String:buffer[256], String:buffer2[256];
	GetCmdArg(1, buffer, sizeof(buffer));
	GetCmdArg(2, buffer2, sizeof(buffer2));
	if(args < 2)
	{
		if(client == 0)
		{
			PrintToServer("[SM] Usage: sm_cheat <command> <arguments>");
		}
		else
		{
			PrintToChat(client, "[SM] Usage: sm_cheat <command> <arguments>");
		}
		return Plugin_Handled;
	}
	
	if(client == 0)
	{
		new cmdflags = GetCommandFlags(buffer);
		SetCommandFlags(buffer, cmdflags & ~FCVAR_CHEAT);
		ServerCommand("%s %s", buffer, buffer2);
		SetCommandFlags(buffer, cmdflags);
		LogCommand("'Console' used the 'Cheat' command with value <%s> <%s>", buffer, buffer2);
	}
	else
	{
		new cmdflags = GetCommandFlags(buffer);
		SetCommandFlags(buffer, cmdflags & ~FCVAR_CHEAT);
		ClientCommand(client, "%s %s", buffer, buffer2);
		SetCommandFlags(buffer, cmdflags);
		LogCommand("'%N' used the 'Cheat' command with value <%s> <%s>", client, buffer, buffer2);
	}	
	return Plugin_Handled;
}



public Action:CmdWipeEntity(client, args)
{
	decl String:arg[256], String:class[64];
	GetCmdArgString(arg, sizeof(arg));
	new count = 0;
	for(new i=MaxClients+1; i<=GetMaxEntities(); i++)
	{
		if(i > 0 && IsValidEntity(i) && IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if(StrEqual(class, arg))
			{
				AcceptEntityInput(i, "Kill");
				count++;
			}
		}
	}
	PrintToChat(client, "[SM] Succesfully deleted %i <%s> entities", count, arg);
	count = 0;
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Wipe Entity' command for classname <%s>", name, arg);
	return Plugin_Handled;
}

public Action:CmdSetModel(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_setmodel <#userid|name> [model]");
		PrintToChat(client, "Example: !setmodel @me models/props_interiors/table_bedside.mdl ");
		return Plugin_Handled;
	}
	decl String:arg1[256], String:arg2[256];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	PrecacheModel(arg2);
	for (new i = 0; i < target_count; i++)
	{
		SetEntityModel(target_list[i], arg2);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Set Model' command on '%s' with value <%s>", name, arg1, arg2);
	return Plugin_Handled;
}

public Action:CmdSetModelEntity(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_setmodelentity <classname> [model]");
		PrintToChat(client, "Example: !setmodelentity infected models/props_interiors/table_bedside.mdl");
		return Plugin_Handled;
	}
	decl String:arg1[256], String:arg2[256], String:class[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	PrecacheModel(arg2);
	new count = 0;
	for(new i=MaxClients+1; i<=GetMaxEntities(); i++)
	{
		if(i > 0 && IsValidEntity(i) && IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if(StrEqual(class, arg1))
			{
				SetEntityModel(i, arg2);
				count++;
			}
		}
	}
	PrintToChat(client, "[SM] Succesfully set the %s model to %i <%s> entities", arg2, count, arg1);
	count = 0;
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Set Model Entity' command on classname <%s>", name, arg2);
	return Plugin_Handled;
}

public Action:CmdCreateParticle(client, args)
{
	if(args < 4)
	{
		PrintToChat(client, "[SM] Usage: sm_createparticle <#userid|name> [particle] [parent: yes|no] [duration]");
		PrintToChat(client, "Example: !createparticle @me no 5 (Teleports the particle to my position, but don't parent it and stop the effect in 5 seconds)");
		return Plugin_Handled;
	}
	decl String:arg1[256], String:arg2[256], String:arg3[256], String:arg4[256];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	new bool:parent = false;
	if(StrEqual(arg3, "yes"))
	{
		parent = false;
	}
	else if(StrEqual(arg3, "no"))
	{
		parent = true;
	}
	else
	{
		PrintToChat(client, "[SM] No parent option given. As default it won't be parented");
	}
	new Float:duration = StringToFloat(arg4);
	for (new i = 0; i < target_count; i++)
	{
		CreateParticle(target_list[i], arg2, parent, duration);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Create Particle' command on '%s' with value <%s> <%s> <%f>", name, arg1, arg2, arg3, duration);
	return Plugin_Handled;
}

public Action:CmdIgnite(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_ignite <#userid|name> [duration]");
		return Plugin_Handled;
	}
	decl String:arg1[256], String:arg2[256];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	new Float:duration = StringToFloat(arg2);
	for (new i=0; i < target_count; i++)
	{
		IgnitePlayer(target_list[i], duration);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Ignite Player' command on '%s' with value <%f>", name, arg1, duration);
	return Plugin_Handled;
}

public Action:CmdTeleport(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_teleport <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[256];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArgString(arg, sizeof(arg));
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	decl Float:VecOrigin[3], Float:VecAngles[3];
	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
	if(TR_DidHit(INVALID_HANDLE))
	{
		TR_GetEndPosition(VecOrigin);
	}
	else
	{
		PrintToChat(client, "Vector out of world geometry. Teleporting on origin instead");
	}
	for (new i=0; i < target_count; i++)
	{
		TeleportEntity(target_list[i], VecOrigin, NULL_VECTOR, NULL_VECTOR);
	}
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Teleport' command on '%s'", name, arg);
	return Plugin_Handled;
}

public Action:CmdTeleportEnt(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_teleportent <classname>");
		return Plugin_Handled;
	}
	decl String:arg1[256], String:class[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	new count = 0;
	decl Float:VecOrigin[3], Float:VecAngles[3];
	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, client);
	if(TR_DidHit(INVALID_HANDLE))
	{
		TR_GetEndPosition(VecOrigin);
	}
	else
	{
		PrintToChat(client, "Vector out of world geometry. Teleporting on origin instead");
	}
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidEntity(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if(StrEqual(class, arg1))
			{
				TeleportEntity(i, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				count++;
			}
		}
	}
	PrintToChat(client, "[SM] Successfully teleported '%i' entities with <%s> classname", count, arg1);
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogCommand("'%s' used the 'Teleport Entity' command on '%i' entities with classname <%s>", name, count, arg1);
	return Plugin_Handled;
}


//******************************MENU RELATED****************************************

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_hTopMenu) return;
	g_hTopMenu = topmenu;
	new TopMenuObject:players_commands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	new TopMenuObject:server_commands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_SERVERCOMMANDS);
	
	// now we add the function ...
	if (players_commands != INVALID_TOPMENUOBJECT)
	{
		//AddToTopMenu (g_hTopMenu, "l4dvomitplayer", TopMenuObject_Item, MenuItem_VomitPlayer, players_commands, "l4dvomitplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dincapplayer", TopMenuObject_Item, MenuItem_IncapPlayer, players_commands, "l4dincapplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dspeedplayer", TopMenuObject_Item, MenuItem_SpeedPlayer, players_commands, "l4dspeedplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dsethpplayer", TopMenuObject_Item, MenuItem_SetHpPlayer, players_commands, "l4dsethpplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dcolorplayer", TopMenuObject_Item, MenuItem_ColorPlayer, players_commands, "l4dcolorplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dsizeplayer", TopMenuObject_Item, MenuItem_ScalePlayer, players_commands, "l4dsizeplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dshakeplayer", TopMenuObject_Item, MenuItem_ShakePlayer, players_commands, "l4dshakeplayer", ADMFLAG_SLAY);
		//AddToTopMenu (g_hTopMenu, "l4dchargeplayer", TopMenuObject_Item, MenuItem_Charge, players_commands, "l4dchargeplayer", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dteleplayer", TopMenuObject_Item, MenuItem_TeleportPlayer, players_commands, "l4dteleplayer", ADMFLAG_SLAY);
		
		//AddToTopMenu (g_hTopMenu, "l4ddontrush", TopMenuObject_Item, MenuItem_DontRush, players_commands, "l4ddontrush", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dairstrike", TopMenuObject_Item, MenuItem_Airstrike, players_commands, "l4dairstrike", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dchangehp", TopMenuObject_Item, MenuItem_ChangeHp, players_commands, "l4dchangehp", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dgodmode", TopMenuObject_Item, MenuItem_GodMode, players_commands, "l4dgodmode", ADMFLAG_SLAY);
		
		AddToTopMenu (g_hTopMenu, "l4dcreateexplosion", TopMenuObject_Item, MenuItem_CreateExplosion, server_commands, "l4dcreateexplosion", ADMFLAG_SLAY);
		//AddToTopMenu (g_hTopMenu, "l4dnorescue", TopMenuObject_Item, MenuItem_NoRescue, server_commands, "l4dnorescue", ADMFLAG_SLAY);
		//AddToTopMenu (g_hTopMenu, "l4dgnomerain", TopMenuObject_Item, MenuItem_GnomeRain, server_commands, "l4dgnomerain", ADMFLAG_SLAY);
		AddToTopMenu (g_hTopMenu, "l4dsurvrain", TopMenuObject_Item, MenuItem_SurvRain, server_commands, "l4dsurvrain", ADMFLAG_SLAY);
		//AddToTopMenu (g_hTopMenu, "l4dgnomewipe", TopMenuObject_Item, MenuItem_GnomeWipe, server_commands, "l4dgnomewipe", ADMFLAG_SLAY);
		//AddToTopMenu (g_hTopMenu, "l4dwipebodies", TopMenuObject_Item, MenuItem_WipeBody, server_commands, "l4dwipebodies", ADMFLAG_SLAY);		
	}
}

//---------------------------------Show Categories--------------------------------------------
public MenuItem_TeleportPlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Teleport Player", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplayTeleportPlayerMenu(param);
	}
}

public MenuItem_GodMode(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "God Mode", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplayGodModeMenu(param);
	}
}

public MenuItem_IncapPlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Incapacitate Player", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplayIncapPlayerMenu(param);
	}
}

public MenuItem_SpeedPlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Set player speed", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplaySpeedPlayerMenu(param);
	}
}

public MenuItem_SetHpPlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Set player health", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplaySetHpPlayerMenu(param);
	}
}

public MenuItem_ColorPlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Set player color", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplayColorPlayerMenu(param);
	}
}

public MenuItem_CreateExplosion(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Create explosion", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplayCreateExplosionMenu(param);
	}
}

public MenuItem_ScalePlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Set player scale", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplayScalePlayerMenu(param);
	}
}

public MenuItem_ShakePlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Shake player", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplayShakePlayerMenu(param);
	}
}

public MenuItem_NoRescue(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Force Vehicle Leaving", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		if(g_bVehicleReady)
		{
			decl String:map[32];
			GetCurrentMap(map, sizeof(map));
			if(StrEqual(map, "c1m4_atrium"))
			{
				CheatCommand(param, "ent_fire", "relay_car_escape trigger");
				CheatCommand(param, "ent_fire", "car_camera enable");
				EndGame();
			}
			else if(StrEqual(map, "c2m5_concert"))
			{
				CheatCommand(param, "ent_fire", "stadium_exit_left_chopper_prop setanimation exit2");
				CheatCommand(param, "ent_fire", "stadium_exit_left_outro_camera enable");
				EndGame();
			}
			else if(StrEqual(map, "c3m4_plantation"))
			{
				CheatCommand(param, "ent_fire", "camera_outro setparentattachment attachment_cam");
				CheatCommand(param, "ent_fire", "escape_boat_prop setanimation c3m4_outro_boat");
				CheatCommand(param, "ent_fire", "camera_outro enable");
				EndGame();
			}
			else if(StrEqual(map, "c4m5_milltown_escape"))
			{
				CheatCommand(param, "ent_fire", "model_boat setanimation c4m5_outro_boat");
				CheatCommand(param, "ent_fire", "camera_outro setparent model_boat");
				CheatCommand(param, "ent_fire", "camera_outro setparentattachment attachment_cam");
				EndGame();
			}
			else if(StrEqual(map, "c5m5_bridge"))
			{
				CheatCommand(param, "ent_fire", "heli_rescue setanimation 4lift");
				CheatCommand(param, "ent_fire", "camera_outro enable");
				EndGame();
			}
			else if(StrEqual(map, "c6m3_port"))
			{
				CheatCommand(param, "ent_fire", "outro_camera_1 setparentattachment Attachment_1");
				CheatCommand(param, "ent_fire", "car_dynamic Disable");
				CheatCommand(param, "ent_fire", "car_outro_dynamic enable");
				CheatCommand(param, "ent_fire", "ghostanim_outro enable");
				CheatCommand(param, "ent_fire", "ghostanim_outro setanimation c6m3_outro");
				CheatCommand(param, "ent_fire", "car_outro_dynamic setanimation c6m3_outro_charger");
				CheatCommand(param, "ent_fire", "outro_camera_1 enable");
				CheatCommand(param, "ent_fire", "c6m3_escape_music playsound");
				EndGame();
			}
			else
			{
				PrintToChat(param, "[SM] This map doesn't have a rescue vehicle or is not supported!");
			}
		}
		else
		{
			PrintToChat(param, "[SM] Wait for the rescue vehicle to be ready first!");
		}
		decl String:name[256];
		GetClientName(param, name, sizeof(name));
		LogCommand("%s used the 'No Rescue' command");
	}
}

public MenuItem_DontRush(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Anti Rush Player", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplayDontRushMenu(param);
	}
}

public MenuItem_Airstrike(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Send Airstrike", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplayAirstrikeMenu(param);
	}
}

public MenuItem_GnomeRain(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Gnome Rain", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		StartGnomeRain(param);
		PrintHintTextToAll("It's raining gnomes!");
	}
}

public MenuItem_SurvRain(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "L4D1 Survivor Rain", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		StartL4dRain(param);
		PrintHintTextToAll("It's raining... survivors?!");
	}
}

public MenuItem_GnomeWipe(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Wipe gnomes", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		decl String:classname[256];
		new count = 0;
		for(new i=MaxClients; i<=GetMaxEntities(); i++)
		{
			if(!IsValidEntity(i) || !IsValidEdict(i))
			{
				continue;
			}
			GetEdictClassname(i, classname, sizeof(classname));
			if(StrEqual(classname, "weapon_gnome"))
			{
				RemoveEdict(i);
				count++;
			}
		}
		PrintToChat(param, "[SM] Succesfully wiped %i gnomes", count);
		count = 0;
		decl String:name[256];
		GetClientName(param, name, sizeof(name));
		LogCommand("%s used the 'Gnome Wipe' command");
	}
}

public MenuItem_ChangeHp(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Switch Health Style", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		DisplayChangeHpMenu(param);
	}
}

/*public MenuItem_WipeBody(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Wipe bodies", "", param);
	}
	if(action == TopMenuAction_SelectOption)
	{
		decl String:classname[256];
		new count = 0;
		for(new i=MaxClients; i<=GetMaxEntities(); i++)
		{
			if(!IsValidEntity(i) || !IsValidEdict(i))
			{
				continue;
			}
			GetEdictClassname(i, classname, sizeof(classname));
			if(StrEqual(classname, "prop_ragdoll"))
			{
				RemoveEdict(i);
				count++;
			}
		}
		PrintToChat(param, "[SM] Succesfully wiped %i bodies", count);
		count = 0;
	}
}
*/
//---------------------------------Display menus---------------------------------------
DisplayTeleportPlayerMenu(client)
{
	new Handle:menu2 = CreateMenu(MenuHandler_TeleportPlayer);
	SetMenuTitle(menu2, "Select Player:");
	SetMenuExitBackButton(menu2, true);
	AddTargetsToMenu2(menu2, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(menu2, client, MENU_TIME_FOREVER);
}

DisplayGodModeMenu(client)
{
	new Handle:menu2 = CreateMenu(MenuHandler_GodMode);
	SetMenuTitle(menu2, "Select Player:");
	SetMenuExitBackButton(menu2, true);
	AddTargetsToMenu2(menu2, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(menu2, client, MENU_TIME_FOREVER);
}

DisplayIncapPlayerMenu(client)
{
	new Handle:menu3 = CreateMenu(MenuHandler_IncapPlayer);
	SetMenuTitle(menu3, "Select Player:");
	SetMenuExitBackButton(menu3, true);
	AddTargetsToMenu2(menu3, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(menu3, client, MENU_TIME_FOREVER);
}

DisplaySpeedPlayerMenu(client)
{
	new Handle:menu4 = CreateMenu(MenuSubHandler_SpeedPlayer);
	SetMenuTitle(menu4, "Select Player:");
	SetMenuExitBackButton(menu4, true);
	AddTargetsToMenu2(menu4, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(menu4, client, MENU_TIME_FOREVER);
}

DisplaySetHpPlayerMenu(client)
{
	new Handle:menu5 = CreateMenu(MenuSubHandler_SetHpPlayer);
	SetMenuTitle(menu5, "Select Player:");
	SetMenuExitBackButton(menu5, true);
	AddTargetsToMenu2(menu5, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(menu5, client, MENU_TIME_FOREVER);
}

DisplayChangeHpMenu(client)
{
	new Handle:menu5 = CreateMenu(MenuSubHandler_ChangeHp);
	SetMenuTitle(menu5, "Select Player:");
	SetMenuExitBackButton(menu5, true);
	AddTargetsToMenu2(menu5, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(menu5, client, MENU_TIME_FOREVER);
}

DisplayColorPlayerMenu(client)
{
	new Handle:menu6 = CreateMenu(MenuSubHandler_ColorPlayer);
	SetMenuTitle(menu6, "Select Player:");
	SetMenuExitBackButton(menu6, true);
	AddTargetsToMenu2(menu6, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(menu6, client, MENU_TIME_FOREVER);
}

DisplayCreateExplosionMenu(client)
{
	new Handle:menu7 = CreateMenu(MenuHandler_CreateExplosion);
	SetMenuTitle(menu7, "Select Position:");
	SetMenuExitBackButton(menu7, true);
	AddMenuItem(menu7, "onpos", "On Current Position");
	AddMenuItem(menu7, "onang", "On Cursor Position");
	DisplayMenu(menu7, client, MENU_TIME_FOREVER);
}

DisplayScalePlayerMenu(client)
{
	new Handle:menu8 = CreateMenu(MenuSubHandler_ScalePlayer);
	SetMenuTitle(menu8, "Select Player:");
	SetMenuExitBackButton(menu8, true);
	AddTargetsToMenu2(menu8, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(menu8, client, MENU_TIME_FOREVER);
}

DisplayShakePlayerMenu(client)
{
	new Handle:menu8 = CreateMenu(MenuSubHandler_ShakePlayer);
	SetMenuTitle(menu8, "Select Player:");
	SetMenuExitBackButton(menu8, true);
	AddTargetsToMenu2(menu8, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(menu8, client, MENU_TIME_FOREVER);
}

DisplayDontRushMenu(client)
{
	new Handle:menu10 = CreateMenu(MenuHandler_DontRush);
	SetMenuTitle(menu10, "Select Player:");
	SetMenuExitBackButton(menu10, true);
	AddTargetsToMenu2(menu10, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(menu10, client, MENU_TIME_FOREVER);
}

DisplayAirstrikeMenu(client)
{
	new Handle:menu11 = CreateMenu(MenuHandler_Airstrike);
	SetMenuTitle(menu11, "Select Player:");
	SetMenuExitBackButton(menu11, true);
	AddTargetsToMenu2(menu11, client, COMMAND_FILTER_CONNECTED);
	DisplayMenu(menu11, client, MENU_TIME_FOREVER);
}

//-------------------------------Sub Menus Needed-----------------------------
public MenuSubHandler_SpeedPlayer(Handle:menu4, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu4);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu4, param2, info, sizeof(info));
		g_iCurrentUserId[param1] = StringToInt(info);
		DisplaySpeedValueMenu(param1);
	}
}

public MenuSubHandler_SetHpPlayer(Handle:menu5, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu5);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu5, param2, info, sizeof(info));
		g_iCurrentUserId[param1] = StringToInt(info);
		DisplaySetHpValueMenu(param1);
	}
}

public MenuSubHandler_ChangeHp(Handle:menu5, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu5);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu5, param2, info, sizeof(info));
		g_iCurrentUserId[param1] = StringToInt(info);
		DisplayChangeHpStyleMenu(param1);
	}
}

public MenuSubHandler_ColorPlayer(Handle:menu6, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu6);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu6, param2, info, sizeof(info));
		g_iCurrentUserId[param1] = StringToInt(info);
		DisplayColorValueMenu(param1);
	}
}

public MenuSubHandler_ScalePlayer(Handle:menu8, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu8);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu8, param2, info, sizeof(info));
		g_iCurrentUserId[param1] = StringToInt(info);
		DisplayScaleValueMenu(param1);
	}
}

public MenuSubHandler_ShakePlayer(Handle:menu8, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu8);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu8, param2, info, sizeof(info));
		g_iCurrentUserId[param1] = StringToInt(info);
		DisplayShakeValueMenu(param1);
	}
}

DisplaySpeedValueMenu(client)
{
	new Handle:menu2a = CreateMenu(MenuHandler_SpeedPlayer);
	SetMenuTitle(menu2a, "New Speed:");
	SetMenuExitBackButton(menu2a, true);
	AddMenuItem(menu2a, "l4dspeeddouble", "x2 Speed");
	AddMenuItem(menu2a, "l4dspeedtriple", "x3 Speed");
	AddMenuItem(menu2a, "l4dspeedhalf", "1/2 Speed");
	AddMenuItem(menu2a, "l4dspeed3", "1/3 Speed");
	AddMenuItem(menu2a, "l4dspeed4", "1/4 Speed");
	AddMenuItem(menu2a, "l4dspeedquarter", "x4 Speed");
	AddMenuItem(menu2a, "l4dspeedfreeze", "0 Speed");
	AddMenuItem(menu2a, "l4dspeednormal", "Normal Speed");
	DisplayMenu(menu2a, client, MENU_TIME_FOREVER);
}

DisplaySetHpValueMenu(client)
{
	new Handle:menu2b = CreateMenu(MenuHandler_SetHpPlayer);
	SetMenuTitle(menu2b, "New Health:");
	SetMenuExitBackButton(menu2b, true);
	AddMenuItem(menu2b, "l4dhpdouble", "x2 Health");
	AddMenuItem(menu2b, "l4dhptriple", "x3 Health");
	AddMenuItem(menu2b, "l4dhphalf", "1/2 Health");
	AddMenuItem(menu2b, "l4dhp3", "1/3 Health");
	AddMenuItem(menu2b, "l4dhp4", "1/4 Health");
	AddMenuItem(menu2b, "l4dhpquarter", "x4 Health");
	AddMenuItem(menu2b, "l4dhppls100", "+100 Health");
	AddMenuItem(menu2b, "l4dhppls50", "+50 Health");
	DisplayMenu(menu2b, client, MENU_TIME_FOREVER);
}

DisplayColorValueMenu(client)
{
	new Handle:menu2c = CreateMenu(MenuHandler_ColorPlayer);
	SetMenuTitle(menu2c, "Select Color:");
	SetMenuExitBackButton(menu2c, true);
	AddMenuItem(menu2c, "l4dcolorred", "Red");
	AddMenuItem(menu2c, "l4dcolorblue", "Blue");
	AddMenuItem(menu2c, "l4dcolorgreen", "Green");
	AddMenuItem(menu2c, "l4dcoloryellow", "Yellow");
	AddMenuItem(menu2c, "l4dcolorblack", "Black");
	AddMenuItem(menu2c, "l4dcolorwhite", "White - Normal");
	AddMenuItem(menu2c, "l4dcolortrans", "Transparent");
	AddMenuItem(menu2c, "l4dcolorhtrans", "Semi Transparent");
	DisplayMenu(menu2c, client, MENU_TIME_FOREVER);
}

DisplayScaleValueMenu(client)
{
	new Handle:menu2a = CreateMenu(MenuHandler_ScalePlayer);
	SetMenuTitle(menu2a, "New Scale:");
	SetMenuExitBackButton(menu2a, true);
	AddMenuItem(menu2a, "l4dscaledouble", "x2 Scale");
	AddMenuItem(menu2a, "l4dscaletriple", "x3 Scale");
	AddMenuItem(menu2a, "l4dscalehalf", "1/2 Scale");
	AddMenuItem(menu2a, "l4dscale3", "1/3 Scale");
	AddMenuItem(menu2a, "l4dscale4", "1/4 Scale");
	AddMenuItem(menu2a, "l4dscalequarter", "x4 Scale");
	AddMenuItem(menu2a, "l4dscalefreeze", "0 Scale");
	AddMenuItem(menu2a, "l4dscalenormal", "Normal scale");
	DisplayMenu(menu2a, client, MENU_TIME_FOREVER);
}

DisplayShakeValueMenu(client)
{
	new Handle:menu2a = CreateMenu(MenuHandler_ShakePlayer);
	SetMenuTitle(menu2a, "Shake duration:");
	AddMenuItem(menu2a, "shake60", "1 Minute");
	AddMenuItem(menu2a, "shake45", "45 Seconds");
	AddMenuItem(menu2a, "shake30", "30 Seconds");
	AddMenuItem(menu2a, "shake15", "15 Seconds");
	AddMenuItem(menu2a, "shake10", "10 Seconds");
	AddMenuItem(menu2a, "shake5", "5 Seconds");
	AddMenuItem(menu2a, "shake1", "1 Second");
	SetMenuExitBackButton(menu2a, true);
	DisplayMenu(menu2a, client, MENU_TIME_FOREVER);
}

DisplayChangeHpStyleMenu(client)
{
	new Handle:menu2a = CreateMenu(MenuHandler_ChangeHpPlayer);
	SetMenuTitle(menu2a, "Select Style:");
	SetMenuExitBackButton(menu2a, true);
	AddMenuItem(menu2a, "l4dperm", "Permanent Health");
	AddMenuItem(menu2a, "l4dtemp", "Temporal Health");
	DisplayMenu(menu2a, client, MENU_TIME_FOREVER);
}
	
//-------------------------------Do action------------------------------------
public MenuHandler_TeleportPlayer(Handle:menu2, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu2);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		GetMenuItem(menu2, param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);
		decl Float:VecOrigin[3], Float:VecAngles[3];
		GetClientAbsOrigin(param1, VecOrigin);
		GetClientEyeAngles(param1, VecAngles);
		TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, param1);
		if(TR_DidHit(INVALID_HANDLE))
		{
			TR_GetEndPosition(VecOrigin);
		}
		else
		{
			PrintToChat(param1, "Vector out of world geometry. Teleporting on origin instead");
		}
		TeleportEntity(target, VecOrigin, NULL_VECTOR, NULL_VECTOR);
		decl String:name[256], String:name2[256];
		GetClientName(param1, name, sizeof(name));
		GetClientName(target, name2, sizeof(name2));
		LogCommand("'%s' used the 'Teleport' command on '%s'", name, name2);
	}
}

public MenuHandler_GodMode(Handle:menu2, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu2);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		GetMenuItem(menu2, param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);
		GodMode(target, param1);
		decl String:name[256], String:name2[256];
		GetClientName(param1, name, sizeof(name));
		GetClientName(target, name2, sizeof(name2));
		LogCommand("%s used the 'Gpd Mode' command on '%s'", name, name2);
		DisplayGodModeMenu(param1);
	}
}

public MenuHandler_IncapPlayer(Handle:menu3, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu3);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		GetMenuItem(menu3, param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);
		IncapPlayer(target, param1);
		decl String:name[256], String:name2[256];
		GetClientName(param1, name, sizeof(name));
		GetClientName(target, name2, sizeof(name2));
		LogCommand("%s used the 'Incap Player' command on '%s'", name, name2);
		DisplayIncapPlayerMenu(param1);
	}
}

public MenuHandler_SpeedPlayer(Handle:menu2a, MenuAction:action, param1, param2)
{	
	if (action == MenuAction_End)
	{
		CloseHandle(menu2a);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		new Float:speed;
		new target = GetClientOfUserId(g_iCurrentUserId[param1]);
		switch(param2)
		{
			case 0:
			{
				speed = GetEntDataFloat(target, g_flLagMovement) * 2;
				ChangeSpeed(target, param1, speed);
				DisplaySpeedPlayerMenu(param1);
			}
			case 1:
			{
				speed = GetEntDataFloat(target, g_flLagMovement) * 3;
				ChangeSpeed(target, param1, speed);
				DisplaySpeedPlayerMenu(param1);
			}
			case 2:
			{
				speed = GetEntDataFloat(target, g_flLagMovement) / 2;
				ChangeSpeed(target, param1, speed);
				DisplaySpeedPlayerMenu(param1);
			}
			case 3:
			{
				speed = GetEntDataFloat(target, g_flLagMovement) / 3;
				ChangeSpeed(target, param1, speed);
				DisplaySpeedPlayerMenu(param1);
			}
			case 4:
			{
				speed = GetEntDataFloat(target, g_flLagMovement) / 4;
				ChangeSpeed(target, param1, speed);
				DisplaySpeedPlayerMenu(param1);
			}
			case 5:
			{
				speed = GetEntDataFloat(target, g_flLagMovement) * 4.0;
				ChangeSpeed(target, param1, speed);
				DisplaySpeedPlayerMenu(param1);
			}
			case 6:
			{
				speed = 0.0;
				ChangeSpeed(target, param1, speed);
				DisplaySpeedPlayerMenu(param1);
			}
			case 7:
			{
				
				speed = 1.0;
				ChangeSpeed(target, param1, speed);
				DisplaySpeedPlayerMenu(param1);
			}
		}
		decl String:name[256], String:name2[256];
		GetClientName(param1, name, sizeof(name));
		GetClientName(target, name2, sizeof(name2));
		LogCommand("%s used the 'Speed Player' command on '%s' with value <%f>", name, name2, speed);
	}
}

public MenuHandler_SetHpPlayer(Handle:menu2b, MenuAction:action, param1, param2)
{	
	if (action == MenuAction_End)
	{
		CloseHandle(menu2b);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		new health;
		new target = GetClientOfUserId(g_iCurrentUserId[param1]);
		switch(param2)
		{
			case 0:
			{
				health = GetClientHealth(target) * 2;
				SetHealth(target, param1, health);
				DisplaySetHpPlayerMenu(param1);
			}
			case 1:
			{
				health = GetClientHealth(target) * 3;
				SetHealth(target, param1, health);
				DisplaySetHpPlayerMenu(param1);
			}
			case 2:
			{
				health = GetClientHealth(target) / 2;
				SetHealth(target, param1, health);
				DisplaySetHpPlayerMenu(param1);
			}
			case 3:
			{
				health = GetClientHealth(target) / 3;
				SetHealth(target, param1, health);
				DisplaySetHpPlayerMenu(param1);
			}
			case 4:
			{
				health = GetClientHealth(target) / 4;
				SetHealth(target, param1, health);
				DisplaySetHpPlayerMenu(param1);
			}
			case 5:
			{
				health = GetClientHealth(target) * 4;
				SetHealth(target, param1, health);
				DisplaySetHpPlayerMenu(param1);
			}
			case 6:
			{
				health = GetClientHealth(target) + 100;
				SetHealth(target, param1, health);
				DisplaySetHpPlayerMenu(param1);
			}
			case 7:
			{
				health = GetClientHealth(target) + 50;
				SetHealth(target, param1, health);
				DisplaySetHpPlayerMenu(param1);
			}
		}
		decl String:name[256], String:name2[256];
		GetClientName(param1, name, sizeof(name));
		GetClientName(target, name2, sizeof(name2));
		LogCommand("%s used the 'Set Health' command on '%s' with value <%i>", name, name2, health);
	}
}

public MenuHandler_ColorPlayer(Handle:menu2c, MenuAction:action, param1, param2)
{	
	if (action == MenuAction_End)
	{
		CloseHandle(menu2c);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		new target = GetClientOfUserId(g_iCurrentUserId[param1]);
		switch(param2)
		{
			case 0:
			{
				ChangeColor(target, param1, RED);
				DisplayColorPlayerMenu(param1);
			}
			case 1:
			{
				ChangeColor(target, param1, BLUE);
				DisplayColorPlayerMenu(param1);
			}
			case 2:
			{
				ChangeColor(target, param1, GREEN);
				DisplayColorPlayerMenu(param1);
			}
			case 3:
			{
				ChangeColor(target, param1, YELLOW);
				DisplayColorPlayerMenu(param1);
			}
			case 4:
			{
				ChangeColor(target, param1, BLACK);
				DisplayColorPlayerMenu(param1);
			}
			case 5:
			{
				ChangeColor(target, param1, WHITE);
				DisplayColorPlayerMenu(param1);
			}
			case 6:
			{
				ChangeColor(target, param1, TRANSPARENT);
				DisplayColorPlayerMenu(param1);
			}
			case 7:
			{
				ChangeColor(target, param1, HALFTRANSPARENT);
				DisplayColorPlayerMenu(param1);
			}
		}
		decl String:name[256], String:name2[256];
		GetClientName(param1, name, sizeof(name));
		GetClientName(target, name2, sizeof(name2));
		LogCommand("%s used the 'Set Color' command on '%s'", name, name2);
	}
}

public MenuHandler_CreateExplosion(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				decl Float:pos[3];
				GetClientAbsOrigin(param1, pos);
				CreateExplosion(pos);
			}
			case 1:
			{
				decl Float:VecOrigin[3], Float:VecAngles[3];
				GetClientAbsOrigin(param1, VecOrigin);
				GetClientEyeAngles(param1, VecAngles);
				TR_TraceRayFilter(VecOrigin, VecAngles, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitSelf, param1);
				if(TR_DidHit(INVALID_HANDLE))
				{
					TR_GetEndPosition(VecOrigin);
				}
				else
				{
					PrintToChat(param1, "Vector out of world geometry. Exploding on origin instead");
				}
				CreateExplosion(VecOrigin);
			}
		}
		decl String:name[256];
		GetClientName(param1, name, sizeof(name));
		LogCommand("'%s' used the 'Set Explosion' command", name);
		DisplayCreateExplosionMenu(param1);
	}
}

public MenuHandler_ScalePlayer(Handle:menu2a, MenuAction:action, param1, param2)
{	
	if (action == MenuAction_End)
	{
		CloseHandle(menu2a);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		new Float:scale;
		new target = GetClientOfUserId(g_iCurrentUserId[param1]);
		switch(param2)
		{
			case 0:
			{
				scale = GetEntPropFloat(target, Prop_Send, "m_flModelScale")  * 2;
				ChangeScale(target, param1, scale);
				DisplayScalePlayerMenu(param1);
			}
			case 1:
			{
				scale = GetEntPropFloat(target, Prop_Send, "m_flModelScale")  * 3;
				ChangeScale(target, param1, scale);
				DisplayScalePlayerMenu(param1);
			}
			case 2:
			{
				scale = GetEntPropFloat(target, Prop_Send, "m_flModelScale")  / 2;
				ChangeScale(target, param1, scale);
				DisplayScalePlayerMenu(param1);
			}
			case 3:
			{
				scale = GetEntPropFloat(target, Prop_Send, "m_flModelScale")  / 3;
				ChangeScale(target, param1, scale);
				DisplayScalePlayerMenu(param1);
			}
			case 4:
			{
				scale = GetEntPropFloat(target, Prop_Send, "m_flModelScale")  / 4;
				ChangeScale(target, param1, scale);
				DisplayScalePlayerMenu(param1);
			}
			case 5:
			{
				scale = GetEntPropFloat(target, Prop_Send, "m_flModelScale")  * 4;
				ChangeScale(target, param1, scale);
				DisplayScalePlayerMenu(param1);
			}
			case 6:
			{
				scale = 0.0;
				ChangeScale(target, param1, scale);
				DisplayScalePlayerMenu(param1);
			}
			case 7:
			{
				scale = 1.0;
				ChangeScale(target, param1, scale);
				DisplayScalePlayerMenu(param1);
			}
		}
		decl String:name[256], String:name2[256];
		GetClientName(param1, name, sizeof(name));
		GetClientName(target, name2, sizeof(name2));
		LogCommand("'%s' used the 'Scale Player' command on '%s' with value <%f>", name, name2, scale);
	}
}

public MenuHandler_ShakePlayer(Handle:menu2a, MenuAction:action, param1, param2)
{	
	if (action == MenuAction_End)
	{
		CloseHandle(menu2a);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		new target = GetClientOfUserId(g_iCurrentUserId[param1]);
		switch(param2)
		{
			case 0:
			{
				Shake(target, param1, 60.0);
				DisplayShakePlayerMenu(param1);
			}
			case 1:
			{
				Shake(target, param1, 45.0);
				DisplayShakePlayerMenu(param1);
			}
			case 2:
			{
				Shake(target, param1, 30.0);
				DisplayShakePlayerMenu(param1);
			}
			case 3:
			{
				Shake(target, param1, 15.0);
				DisplayShakePlayerMenu(param1);
			}
			case 4:
			{
				Shake(target, param1, 10.0);
				DisplayShakePlayerMenu(param1);
			}
			case 5:
			{
				Shake(target, param1, 5.0);
				DisplayShakePlayerMenu(param1);
			}
			case 6:
			{
				Shake(target, param1, 1.0);
				DisplayShakePlayerMenu(param1);
			}
		}
		decl String:name[256], String:name2[256];
		GetClientName(param1, name, sizeof(name));
		GetClientName(target, name2, sizeof(name2));
		LogCommand("'%s' used the 'Shake Player' command on '%s'", name, name2);
	}
}
	
public MenuHandler_DontRush(Handle:menu10, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu10);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		GetMenuItem(menu10, param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);
		TeleportBack(target, param1);
		decl String:name[256], String:name2[256];
		GetClientName(param1, name, sizeof(name));
		GetClientName(target, name2, sizeof(name2));
		LogCommand("'%s' used the 'Antirush' command on '%s'", name, name2);
		DisplayDontRushMenu(param1);
	}
}

public MenuHandler_Airstrike(Handle:menu2, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu2);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		GetMenuItem(menu2, param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);
		if(target == 0)
		{
			PrintToChat(param1, "[SM] Client is invalid");
			return;
		}
		if(GetClientTeam(target) == 1)
		{
			PrintToChat(param1, "[SM] Spectators cannot be targets");
			return;
		}
		Airstrike(target);
		decl String:name[256], String:name2[256];
		GetClientName(param1, name, sizeof(name));
		GetClientName(target, name2, sizeof(name2));
		LogCommand("'%s' used the 'Airstrike' command on '%s'", name, name2);
		DisplayAirstrikeMenu(param1);
	}
}

public MenuHandler_ChangeHpPlayer(Handle:menu2, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu2);
	}
	
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				SwitchHealth(GetClientOfUserId(g_iCurrentUserId[param1]), param1, 1);
			}
			case 1:
			{
				SwitchHealth(GetClientOfUserId(g_iCurrentUserId[param1]), param1, 2);
			}
		}
		decl String:name[256], String:name2[256];
		GetClientName(param1, name, sizeof(name));
		GetClientName(GetClientOfUserId(g_iCurrentUserId[param1]), name2, sizeof(name2));
		LogCommand("'%s' used the 'Switch Health Style' command on '%s'", name, name2);
		DisplayChangeHpMenu(param1);
	}
}
//*******************************************FUNCTIONS******************************************
IncapPlayer(target, sender)
{
	if(target == 0)
	{
		PrintToChat(sender, "[SM]Client is invalid");
		return;
	}
	if(target == -1)
	{
		PrintToChat(sender, "[SM]No targets with the given name!");
		return;
	}
	
	if(GetClientTeam(target) == 1)
	{
		PrintToChat(sender, "[SM]Spectators cannot be incapacitated!");
		return;
	}
	else if(GetClientTeam(target) == 3 && GetEntProp(target, Prop_Send, "m_zombieClass") != 8)
	{
		PrintToChat(sender, "[SM]Only survivors and tanks can be incapacitated!");
		return;
	}
	else if(GetClientTeam(target) == 2 && GetEntProp(target, Prop_Send, "m_isIncapacitated") == 1)
	{
		PrintToChat(sender, "[SM]Cannot incap incapped survivors!");
		return;
	}
	
	if(IsValidEntity(target))
	{
		new iDmgEntity = CreateEntityByName("point_hurt");
		SetEntityHealth(target, 1);
		DispatchKeyValue(target, "targetname", "bm_target");
		DispatchKeyValue(iDmgEntity, "DamageTarget", "bm_target");
		DispatchKeyValue(iDmgEntity, "Damage", "100");
		DispatchKeyValue(iDmgEntity, "DamageType", "0");
		DispatchSpawn(iDmgEntity);
		AcceptEntityInput(iDmgEntity, "Hurt", target);
		DispatchKeyValue(target, "targetname", "bm_targetoff");
		RemoveEdict(iDmgEntity);
	}
}

ChangeSpeed(target, sender, Float:newspeed)
{
	if(target == 0)
	{
		PrintToChat(sender, "[SM]Client is invalid");
		return;
	}
	if(target == -1)
	{
		PrintToChat(sender, "[SM]No targets with the given name!");
		return;
	}
	
	if(GetClientTeam(target) == 1)
	{
		PrintToChat(sender, "[SM]Cannot set a spectator's speed!");
		return;
	}
	SetEntDataFloat(target, g_flLagMovement, newspeed, true);
}

SetHealth(target, sender, amount)
{
	if(target == 0)
	{
		PrintToChat(sender, "[SM]Client is invalid");
		return;
	}
	if(target == -1)
	{
		PrintToChat(sender, "[SM]No targets with the given name!");
		return;
	}
	
	if(GetClientTeam(target) == 1)
	{
		PrintToChat(sender, "[SM]Spectators have no health!");
		return;
	}
	SetEntityHealth(target, amount);
}

ChangeColor(target, sender, String:color[])
{
	if(target == 0)
	{
		PrintToChat(sender, "[SM]Client is invalid");
		return;
	}
	if(target == -1)
	{
		PrintToChat(sender, "[SM]No targets with the given name!");
		return;
	}
	
	if(GetClientTeam(target) == 1)
	{
		PrintToChat(sender, "[SM]Cannot change color of an spectator");
		return;
	}
	DispatchKeyValue(target, "rendercolor", color);
}

CreateExplosion(Float:carPos[3])
{
	decl String:sRadius[256];
	decl String:sPower[256];
	new Float:flMxDistance = GetConVarFloat(g_cvarRadius);
	new Float:power = GetConVarFloat(g_cvarPower);
	IntToString(GetConVarInt(g_cvarRadius), sRadius, sizeof(sRadius));
	IntToString(GetConVarInt(g_cvarPower), sPower, sizeof(sPower));
	new exParticle2 = CreateEntityByName("info_particle_system");
	new exTrace = CreateEntityByName("info_particle_system");
	new exPhys = CreateEntityByName("env_physexplosion");
	new exHurt = CreateEntityByName("point_hurt");
	new exEntity = CreateEntityByName("env_explosion");
	
	//Set up the particle explosion	
	DispatchKeyValue(exParticle2, "effect_name", EXPLOSION_PARTICLE);
	DispatchSpawn(exParticle2);
	ActivateEntity(exParticle2);
	TeleportEntity(exParticle2, carPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exTrace, "effect_name", FIRE_PARTICLE);
	DispatchSpawn(exTrace);
	ActivateEntity(exTrace);
	TeleportEntity(exTrace, carPos, NULL_VECTOR, NULL_VECTOR);
	
	
	//Set up explosion entity
	DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
	DispatchKeyValue(exEntity, "iMagnitude", sPower);
	DispatchKeyValue(exEntity, "iRadiusOverride", sRadius);
	DispatchKeyValue(exEntity, "spawnflags", "828");
	DispatchSpawn(exEntity);
	TeleportEntity(exEntity, carPos, NULL_VECTOR, NULL_VECTOR);
	
	//Set up physics movement explosion
	DispatchKeyValue(exPhys, "radius", sRadius);
	DispatchKeyValue(exPhys, "magnitude", sPower);
	DispatchSpawn(exPhys);
	TeleportEntity(exPhys, carPos, NULL_VECTOR, NULL_VECTOR);
	
	
	//Set up hurt point
	DispatchKeyValue(exHurt, "DamageRadius", sRadius);
	DispatchKeyValue(exHurt, "DamageDelay", "0.5");
	DispatchKeyValue(exHurt, "Damage", "5");
	DispatchKeyValue(exHurt, "DamageType", "8");
	DispatchSpawn(exHurt);
	TeleportEntity(exHurt, carPos, NULL_VECTOR, NULL_VECTOR);
	
	switch(GetRandomInt(1,3))
	{
		case 1:
		{
			if(!IsSoundPrecached(EXPLOSION_SOUND))
			{
				PrecacheSound(EXPLOSION_SOUND);
			}
			EmitSoundToAll(EXPLOSION_SOUND);
		}
		case 2:
		{
			if(!IsSoundPrecached(EXPLOSION_SOUND2))
			{
				PrecacheSound(EXPLOSION_SOUND2);
			}
			EmitSoundToAll(EXPLOSION_SOUND2);
		}
		case 3:
		{
			if(!IsSoundPrecached(EXPLOSION_SOUND3))
			{
				PrecacheSound(EXPLOSION_SOUND3);
			}
			EmitSoundToAll(EXPLOSION_SOUND3);
		}
	}
	
	if(!IsSoundPrecached(EXPLOSION_DEBRIS))
	{
		PrecacheSound(EXPLOSION_DEBRIS);
	}
	EmitSoundToAll(EXPLOSION_DEBRIS);
	
	//BOOM!
	AcceptEntityInput(exParticle2, "Start");
	AcceptEntityInput(exTrace, "Start");
	AcceptEntityInput(exEntity, "Explode");
	AcceptEntityInput(exPhys, "Explode");
	AcceptEntityInput(exHurt, "TurnOn");
	
	new Handle:pack2 = CreateDataPack();
	WritePackCell(pack2, exParticle2);
	WritePackCell(pack2, exTrace);
	WritePackCell(pack2, exEntity);
	WritePackCell(pack2, exPhys);
	WritePackCell(pack2, exHurt);
	CreateTimer(GetConVarFloat(g_cvarDuration)+1.5, timerDeleteParticles, pack2, TIMER_FLAG_NO_MAPCHANGE);
	
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, exTrace);
	WritePackCell(pack, exHurt);
	CreateTimer(GetConVarFloat(g_cvarDuration), timerStopFire, pack, TIMER_FLAG_NO_MAPCHANGE);
	
	decl Float:survivorPos[3], Float:traceVec[3], Float:resultingFling[3], Float:currentVelVec[3];
	for(new i=1; i<=MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
		{
			continue;
		}

		GetEntPropVector(i, Prop_Data, "m_vecOrigin", survivorPos);
		
		//Vector and radius distance calcs by AtomicStryker!
		if(GetVectorDistance(carPos, survivorPos) <= flMxDistance)
		{
			MakeVectorFromPoints(carPos, survivorPos, traceVec);				// draw a line from car to Survivor
			GetVectorAngles(traceVec, resultingFling);							// get the angles of that line
			
			resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;	// use trigonometric magic
			resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
			resultingFling[2] = power;
			
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
			resultingFling[0] += currentVelVec[0];
			resultingFling[1] += currentVelVec[1];
			resultingFling[2] += currentVelVec[2];
			
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
		}
	}
}

public Action:timerStopFire(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new particle = ReadPackCell(pack);
	new hurt = ReadPackCell(pack);
	CloseHandle(pack);
	
	if(IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "Stop");
	}
	if(IsValidEntity(hurt))
	{
		AcceptEntityInput(hurt, "TurnOff");
	}
}

public Action:timerDeleteParticles(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	
	new entity;
	for (new i = 1; i <= 5; i++)
	{
		entity = ReadPackCell(pack);
		
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	CloseHandle(pack);
}

Bleed(target, sender, Float:duration)
{
	if(target == 0)
	{
		PrintToChat(sender, "[SM] Client is invalid");
		return;
	}
	if(target == -1)
	{
		PrintToChat(sender, "[SM] No targets with the given name!");
		return;
	}
	if(GetClientTeam(target) == 1)
	{
		PrintToChat(sender, "[SM] Spectators can't bleed!");
		return;
	}
	//Userid for targetting
	new userid = GetClientUserId(target);
	decl Float:pos[3], String:sName[64], String:sTargetName[64];
	new Particle = CreateEntityByName("info_particle_system");
	
	GetClientAbsOrigin(target, pos);
	TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
	
	Format(sName, sizeof(sName), "%d", userid+25);
	DispatchKeyValue(target, "targetname", sName);
	GetEntPropString(target, Prop_Data, "m_iName", sName, sizeof(sName));
	
	Format(sTargetName, sizeof(sTargetName), "%d", userid+1000);
	
	DispatchKeyValue(Particle, "targetname", sTargetName);
	DispatchKeyValue(Particle, "parentname", sName);
	DispatchKeyValue(Particle, "effect_name", BLEED_PARTICLE);
	
	DispatchSpawn(Particle);
	
	DispatchSpawn(Particle);
	
	//Parent:		
	SetVariantString(sName);
	AcceptEntityInput(Particle, "SetParent", Particle, Particle);
	ActivateEntity(Particle);
	AcceptEntityInput(Particle, "start");
	
	CreateTimer(duration, timerEndEffect, Particle, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:timerEndEffect(Handle:timer, any:entity)
{
	if(entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

ChangeScale(target, sender, Float:scale)
{
	if(target == 0)
	{
		PrintToChat(sender, "[SM] Client is invalid");
		return;
	}
	if(target == -1)
	{
		PrintToChat(sender, "[SM] No targets with the given name!");
		return;
	}
	
	if(GetClientTeam(target) == 1)
	{
		PrintToChat(sender, "[SM] Spectators don't have a model with a default scale");
		return;
	}
	SetEntPropFloat(target, Prop_Send, "m_flModelScale", scale);
}

TeleportBack(target, sender)
{
	decl String:map[32], Float:pos[3];
	GetCurrentMap(map, sizeof(map));
	if(target == 0)
	{
		PrintToChat(sender, "[SM]Client is invalid");
		return;
	}
	if(target == -1)
	{
		PrintToChat(sender, "[SM]No targets with the given name!");
		return;
	}
	
	if(GetClientTeam(target) == 1)
	{
		PrintToChat(sender, "[SM]Spectators cannot even rush!");
		return;
	}
	if(StrEqual(map, "c1m1_hotel"))
	{
		pos[0] = 568.0;
		pos[1] = 5707.0;
		pos[2] = 2848.0;
	}
	else if(StrEqual(map, "c1m2_streets"))
	{
		pos[0] = 2049.0;
		pos[1] = 4460.0;
		pos[2] = 1235.0;
	}
	else if(StrEqual(map, "c1m3_mall"))
	{
		pos[0] = 6697.0;
		pos[1] = -1424.0;
		pos[2] = 86.0;
	}
	else if(StrEqual(map, "c1m4_atrium"))
	{	
		pos[0] = -2046.0;
		pos[1] = -4641.0;
		pos[2] = 598.0;
	}
	else if(StrEqual(map, "c2m1_highway"))
	{
		pos[0] = 10855.0;
		pos[1] = 7864.0;
		pos[2] = -488.0;
	}
	else if(StrEqual(map, "c2m2_fairgrounds"))
	{
		pos[0] = 1653.0;
		pos[1] = 2796.0;
		pos[2] = 32.0;
	}
	else if(StrEqual(map, "c2m3_coaster"))
	{
		pos[0] = 4336.0;
		pos[1] = 2048.0;
		pos[2] = -1.0;
	}
	else if(StrEqual(map, "c2m4_barns"))
	{
		pos[0] = 3057.0;
		pos[1] = 3632.0;
		pos[2] = -152.0;
	}
	else if(StrEqual(map, "c2m5_concert"))
	{
		pos[0] = -938.0;
		pos[1] = 2194.0;
		pos[2] = -193.0;
	}
	else if(StrEqual(map, "c3m1_plankcountry"))
	{
		pos[0] = -12549.0;
		pos[1] = 10488.0;
		pos[2] = 270.0;
	}
	else if(StrEqual(map, "c3m2_swamp"))
	{
		pos[0] = -8158.0;
		pos[1] = 7531.0;
		pos[2] = 32.0;
	}
	else if(StrEqual(map, "c3m3_shantytown"))
	{
		pos[0] = -5718.0;
		pos[1] = 2137.0;
		pos[2] = 170.0;
	}
	else if(StrEqual(map, "c3m4_plantation"))
	{
		pos[0] = -5027.0;
		pos[1] = -1662.0;
		pos[2] = -34.0;
	}
	else if(StrEqual(map, "c4m1_milltown_a"))
	{
		pos[0] = -7097.0;
		pos[1] = 7706.0;
		pos[2] = 175.0;
	}
	else if(StrEqual(map, "c4m2_sugarmill_a"))
	{
		pos[0] = 3617.0;
		pos[1] = -1659.0;
		pos[2] = 270.0;
	}
	else if(StrEqual(map, "c4m3_sugarmill_b"))
	{
		pos[0] = -1788.0;
		pos[1] = -13701.0;
		pos[2] = 170.0;
	}
	else if(StrEqual(map, "c4m4_milltown_b"))
	{
		pos[0] = 3883.0;
		pos[1] = -1484.0;
		pos[2] = 270.0;
	}
	else if(StrEqual(map, "c4m5_milltown_escape"))
	{
		pos[0] = -3146.0;
		pos[1] = 7818.0;
		pos[2] = 182.0;
	}
	else if(StrEqual(map, "c5m1_waterfront"))
	{
		pos[0] = 790.0;
		pos[1] = 686.0;
		pos[2] = -419.0;
	}
	else if(StrEqual(map, "c5m2_park"))
	{
		pos[0] = -4119.0;
		pos[1] = -1263.0;
		pos[2] = -281.0;
	}
	else if(StrEqual(map, "c5m3_cemetery"))
	{
		pos[0] = 6361.0;
		pos[1] = 8372.0;
		pos[2] = 62.0;
	}
	else if(StrEqual(map, "c5m4_quarter"))
	{
		pos[0] = -3235.0;
		pos[1] = 4849.0;
		pos[2] = 130.0;
	}
	else if(StrEqual(map, "c5m5_bridge"))
	{
		pos[0] = -12062.0;
		pos[1] = 5913.0;
		pos[2] = 574.0;
	}
	else if(StrEqual(map, "c6m1_riverbank"))
	{
		pos[0] = 913.0;
		pos[1] = 3750.0;
		pos[2] = 156.0;
	}
	else if(StrEqual(map, "c6m2_bedlam"))
	{
		pos[0] = 3014.0;
		pos[1] = -1216.0;
		pos[2] = -233.0;
	}
	else if(StrEqual(map, "c6m3_port"))
	{
		pos[0] = -2364.0;
		pos[1] = -471.0;
		pos[2] = -193.0;
	}
	else
	{
		PrintToChat(sender, "[SM] This commands doesn't support the current map!");
	}
	TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);
	PrintHintText(target, "You were teleported to the beginning of the map for rushing!");
}

EndGame()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsClientObserver(i) && GetClientTeam(i) == 2)
		{
			ForcePlayerSuicide(i);
		}
	}
}

/*LaunchMissile(target, sender)
{
	//Missile: Doesn't exist
	decl Float:flCpos[3], Float:flTpos[3], Float:flDistance, Float:power, Float:distance[3], Float:flCang[3];
	power = 350.0;
	if(!AliveFilter(target))
	{
		PrintToChat(sender, "[SM] The user is not alive!");
		return;
	}
	GetClientAbsOrigin(sender, flCpos);
	GetClientEyeAngles(sender, flCang);
	decl String:angles[32];
	Format(angles, sizeof(angles), "%f %f %f", flCang[0], flCang[1], flCang[2]);
	
	//Missile is being created
	new iMissile = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(iMissile, "model", MISSILE_MODEL);
	DispatchKeyValue(iMissile, "angles", angles);
	DispatchSpawn(iMissile);
	
	//Missile created but not visible. Teleporting
	TeleportEntity(iMissile, flCpos, NULL_VECTOR, NULL_VECTOR);
	
	decl Float:addVel[3], Float:final[3], Float:tvec[3], Float:ratio[3];
	GetEntPropVector(target, Prop_Data, "m_vecOrigin", flTpos);
	distance[0] = (flCpos[0] - flTpos[0]);
	distance[1] = (flCpos[1] - flTpos[1]);
	distance[2] = (flCpos[2] - flTpos[2]);
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", tvec);
	ratio[0] =  FloatDiv(distance[0], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));//Ratio x/hypo
	ratio[1] =  FloatDiv(distance[1], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));//Ratio y/hypo
	
	addVel[0] = FloatMul(ratio[0]*-1, power);
	addVel[1] = FloatMul(ratio[1]*-1, power);
	addVel[2] = power;
	final[0] = FloatAdd(addVel[0], tvec[0]);
	final[1] = FloatAdd(addVel[1], tvec[1]);
	final[2] = power;
	FlingPlayer(target, addVel, target);
	TeleportEntity(iMissile, NULL_VECTOR, NULL_VECTOR, final);
}
*/

Airstrike(client)
{
	g_bStrike = true;
	CreateTimer(6.0, timerStrikeTimeout, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, timerStrike, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action:timerStrikeTimeout(Handle:timer)
{
	g_bStrike = false;
}

public Action:timerStrike(Handle:timer, any:client)
{
	if(!g_bStrike)
	{
		return Plugin_Stop;
	}
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	new Float:radius = GetConVarFloat(g_cvarRainRadius);
	pos[0] += GetRandomFloat(radius*-1, radius);
	pos[1] += GetRandomFloat(radius*-1, radius);
	CreateExplosion(pos);		
	return Plugin_Continue;
}

BlackAndWhite(target, sender)
{
	if(target > 0 && IsValidEntity(target) && IsClientInGame(target) && IsPlayerAlive(target))
	{
		if(GetClientTeam(target) != 2)
		{
			PrintToChat(sender, "[SM] This command can be used on survivors only");
		}
		SetEntityHealth(target, 1);
		SetEntPropFloat(target, Prop_Send, "m_healthBufferTime", GetGameTime());
		SetEntPropFloat(target, Prop_Send, "m_healthBuffer", 30.0);
		SetEntProp(target, Prop_Send, "m_isGoingToDie", 1);
	}
}

SwitchHealth(target, sender, type)
{
	if(target > 0 && IsValidEntity(target) && IsClientInGame(target) && IsPlayerAlive(target))
	{
		if(GetClientTeam(target) != 2)
		{
			PrintToChat(sender, "[SM] This command can be used on survivors only");
		}
		if(type == 1)
		{
			decl Float:temphp;
			new hp, total;
			temphp = GetEntPropFloat(target, Prop_Send, "m_healthBuffer");
			hp = GetClientHealth(target);
			total = hp+RoundToFloor(temphp);
			CheatCommand(target, "give", "health");
			SetEntityHealth(target, total);
		}
		else if(type == 2)
		{
			decl Float:flhp;
			new hp = GetClientHealth(target);
			flhp = hp*1.0;
			SetEntityHealth(target, 1);
			SetEntPropFloat(target, Prop_Send, "m_healthBufferTime", GetGameTime());
			SetEntPropFloat(target, Prop_Send, "m_healthBuffer", flhp);
		}
	}
}

WeaponRain(String:weapon[], sender)
{
	decl String:item[64];
	Format(item, sizeof(item), "weapon_%s", weapon);
	g_bGnomeRain = true;
	CreateTimer(GetConVarFloat(g_cvarRainDur), timerRainTimeout, TIMER_FLAG_NO_MAPCHANGE);
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, sender);
	WritePackString(pack, item);
	CreateTimer(0.1, timerSpawnWeapon, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action:timerSpawnWeapon(Handle:timer, Handle:pack)
{
	decl String:item[96];
	ResetPack(pack);
	new client = ReadPackCell(pack);
	ReadPackString(pack, item, sizeof(item));
	
	
	decl Float:pos[3];
	new weap = CreateEntityByName(item);
	DispatchSpawn(weap);
	if(!g_bGnomeRain)
	{
		return Plugin_Stop;
	}
	GetClientAbsOrigin(client, pos);
	pos[2] += 350.0;
	new Float:radius = GetConVarFloat(g_cvarRainRadius);
	pos[0] += GetRandomFloat(radius*-1, radius);
	pos[1] += GetRandomFloat(radius*-1, radius);
	TeleportEntity(weap, pos, NULL_VECTOR, NULL_VECTOR);	
	return Plugin_Continue;
}

StartGnomeRain(client)
{
	g_bGnomeRain = true;
	CreateTimer(GetConVarFloat(g_cvarRainDur), timerRainTimeout, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, timerSpawnGnome, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

StartL4dRain(client)
{
	g_bGnomeRain = true;
	CreateTimer(GetConVarFloat(g_cvarRainDur), timerRainTimeout, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.7, timerSpawnL4d, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

GodMode(target, sender)
{
	if(GetClientTeam(target) == 1)
	{
		PrintToChat(sender, "[SM] You cannot use this command on spectators");
	}
	if(g_bHasGod[target])
	{
		SetEntProp(target, Prop_Data, "m_takedamage", 2, 1);
		g_bHasGod[target] = false;
		PrintToChat(sender, "[SM] The selected player has now god mode [Deactivated]");
	}
	else
	{
		SetEntProp(target, Prop_Data, "m_takedamage", 0, 1);
		g_bHasGod[target] = true;
		PrintToChat(sender, "[SM] The selected player has now god mode [Activated]");
	}
}

public Action:timerRainTimeout(Handle:timer)
{
	g_bGnomeRain = false;
}

public Action:timerSpawnGnome(Handle:timer, any:client)
{
	decl Float:pos[3];
	new gnome = CreateEntityByName("weapon_gnome");
	DispatchSpawn(gnome);
	if(!g_bGnomeRain)
	{
		return Plugin_Stop;
	}
	GetClientAbsOrigin(client, pos);
	pos[2] += 350.0;
	new Float:radius = GetConVarFloat(g_cvarRainRadius);
	pos[0] += GetRandomFloat(radius*-1, radius);
	pos[1] += GetRandomFloat(radius*-1, radius);
	TeleportEntity(gnome, pos, NULL_VECTOR, NULL_VECTOR);	
	return Plugin_Continue;
}

public Action:timerSpawnL4d(Handle:timer, any:client)
{
	decl Float:pos[3];
	new body = CreateEntityByName("prop_ragdoll");
	switch(GetRandomInt(1,3))
	{
		case 1:
		{
			DispatchKeyValue(body, "model", ZOEY_MODEL);
		}
		case 2:
		{
			DispatchKeyValue(body, "model", FRANCIS_MODEL);
		}
		case 3:
		{
			DispatchKeyValue(body, "model", LOUIS_MODEL);
		}
	}
	DispatchSpawn(body);
	if(!g_bGnomeRain)
	{
		return Plugin_Stop;
	}
	GetClientAbsOrigin(client, pos);
	pos[2] += 350.0;
	new Float:radius = GetConVarFloat(g_cvarRainRadius);
	pos[0] += GetRandomFloat(radius*-1, radius);
	pos[1] += GetRandomFloat(radius*-1, radius);
	TeleportEntity(body, pos, NULL_VECTOR, NULL_VECTOR);	
	return Plugin_Continue;
}
	
stock bool:AliveFilter(client)
{
	if(client > 0 && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		return true;
	}
	return false;
}

CheatCommand(client, const String:command [], const String:arguments [])
{
	if (!client) return;
	if (!IsClientInGame(client)) return;
	if (!IsValidEntity(client)) return;
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_SLAY);
	new flags = GetCommandFlags (command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}

public Action:Shake(target, sender, Float:duration)
{
	new Handle:hBf=StartMessageOne("Shake", target);
	if(hBf!=INVALID_HANDLE)
	{
		BfWriteByte(hBf, 0);                
		BfWriteFloat(hBf, 16.0);            // shake magnitude/amplitude
		BfWriteFloat(hBf, 0.5);                // shake noise frequency
		BfWriteFloat(hBf, duration);                // shake lasts this long
		EndMessage();
	}
}

stock InstructorHint(String:content[])
{	
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i))
		{
			ClientCommand(i, "gameinstructor_enable 1");
		}
	}
	
	new iEntity = CreateEntityByName("env_instructor_hint");
	if(IsValidEntity(iEntity))
	{
		DispatchKeyValue(iEntity, "hint_auto_start", "0");
		DispatchKeyValue(iEntity, "hint_alphaoption", "1");
		DispatchKeyValue(iEntity, "hint_timeout", "10");
		DispatchKeyValue(iEntity, "hint_forcecaption", "Yes");
		DispatchKeyValue(iEntity, "hint_static", "1");
		DispatchKeyValue(iEntity, "hint_icon_offscreen", "icon_alert");
		DispatchKeyValue(iEntity, "hint_icon_onscreen", "icon_alert");
		DispatchKeyValue(iEntity, "hint_caption", content);
		DispatchKeyValue(iEntity, "hint_range", "1");
		DispatchKeyValue(iEntity, "hint_color", "255 255 255");
		
		DispatchSpawn(iEntity);
		AcceptEntityInput(iEntity, "ShowHint");
		CreateTimer(15.0, timerRemoveEntity, iEntity, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		LogError("Failed to create the instructor hint entity.");
	}
}

public Action:timerRemoveEntity(Handle:timer, any:entity)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i))
		{
			ClientCommand(i, "gameinstructor_enable 0");
		}
	}
	if(entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

stock bool:IsValidWeapon(String:weapon[])
{
	if(StrEqual(weapon, "rifle")
	|| StrEqual(weapon, "sniper_military")
	|| StrEqual(weapon, "smg")
	|| StrEqual(weapon, "first_aid_kit")
	|| StrEqual(weapon, "autoshotgun")
	|| StrEqual(weapon, "molotov")
	|| StrEqual(weapon, "pain_pills")
	|| StrEqual(weapon, "pipe_bomb")
	|| StrEqual(weapon, "hunting_rifle")
	|| StrEqual(weapon, "pistol")
	|| StrEqual(weapon, "gascan")
	|| StrEqual(weapon, "propanetank"))
	{
		return true;
	}
	else 
	{
		return false;
	}
}

stock CreateParticle(client, String:Particle_Name[], bool:Parent, Float:duration)
{
	decl Float:pos[3], String:sName[64], String:sTargetName[64];
	new Particle = CreateEntityByName("info_particle_system");
	GetClientAbsOrigin(client, pos);
	TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Particle, "effect_name", Particle_Name);
	
	if(Parent)
	{
		new userid = GetClientUserId(client);
		Format(sName, sizeof(sName), "%d", userid+25);
		DispatchKeyValue(client, "targetname", sName);
		GetEntPropString(client, Prop_Data, "m_iName", sName, sizeof(sName));
		
		Format(sTargetName, sizeof(sTargetName), "%d", userid+1000);
		DispatchKeyValue(Particle, "targetname", sTargetName);
		DispatchKeyValue(Particle, "parentname", sName);
	}
	DispatchSpawn(Particle);
	DispatchSpawn(Particle);
	if(Parent)
	{
		SetVariantString(sName);
		AcceptEntityInput(Particle, "SetParent", Particle, Particle);
	}
	ActivateEntity(Particle);
	AcceptEntityInput(Particle, "start");
	CreateTimer(duration, timerStopAndRemoveParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:timerStopAndRemoveParticle(Handle:timer, any:entity)
{
	if(entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

stock IgnitePlayer(client, Float:duration)
{
	new team = GetClientTeam(client);
	if(team != 2)
	{
		IgniteEntity(client, duration);
	}
	else
	{
		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
		decl String:sUser[256];
		IntToString(GetClientUserId(client)+25, sUser, sizeof(sUser));
		CreateParticle(client, BURN_IGNITE_PARTICLE, true, duration);
		new Damage = CreateEntityByName("point_hurt");
		DispatchKeyValue(Damage, "Damage", "1");
		DispatchKeyValue(Damage, "DamageType", "8");
		DispatchKeyValue(client, "targetname", sUser);
		DispatchKeyValue(Damage, "DamageTarget", sUser);
		DispatchSpawn(Damage);
		TeleportEntity(Damage, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(Damage, "Hurt");
		CreateTimer(0.1, timerHurtMe, Damage, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(duration, timerStopAndRemoveParticle, Damage, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:timerHurtMe(Handle:timer, any:hurt)
{
	if(IsValidEntity(hurt) && IsValidEdict(hurt))
	{
		AcceptEntityInput(hurt, "Hurt");
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) // Check if the TraceRay hit the itself.
	{
		return false; // Don't let the entity be hit
	}
	return true; // It didn't hit itself
}
/***************DEVELOPMENT*********************************/

public Action:CmdEntityInfo(client, args)
{
	decl String:Classname[128];
	new entity = GetClientAimTarget(client, false);

	if ((entity == -1) || (!IsValidEntity (entity)))
	{
		ReplyToCommand (client, "Invalid entity, or looking to nothing");
	}
	GetEdictClassname(entity, Classname, sizeof(Classname));
	PrintToChat(client, "Classname: %s", Classname);
}

stock PrecacheParticle(String:ParticleName[])
{
	new Particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		DispatchKeyValue(Particle, "effect_name", ParticleName);
		DispatchSpawn(Particle);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");
		CreateTimer(0.3, timerRemovePrecacheParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:timerRemovePrecacheParticle(Handle:timer, any:Particle)
{
	if(IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		AcceptEntityInput(Particle, "Kill");
	}
}

stock LogCommand(const String:format[], any:...)
{
	if(!GetConVarBool(g_cvarLog))
	{
		return;
	}
	decl String:buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);
	new Handle:file;
	decl String:FileName[256], String:sTime[256];
	FormatTime(sTime, sizeof(sTime), "%Y%m%d");
	BuildPath(Path_SM, FileName, sizeof(FileName), "logs/customcmds_%s.log", sTime);
	file = OpenFile(FileName, "a+");
	FormatTime(sTime, sizeof(sTime), "%b %d |%H:%M:%S| %Y");
	WriteFileLine(file, "%s: %s", sTime, buffer);
	FlushFile(file);
	CloseHandle(file);
}

#if 0
public Action:CmdCCInfo(client, args)
{
}
#endif