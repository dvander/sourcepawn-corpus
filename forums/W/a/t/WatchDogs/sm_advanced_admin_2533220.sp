#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <geoip>

#define VERSION "1.6.3"

public Plugin: myinfo =
{
	name = "[CSGO] Advanced Admin",
	author = "PeEzZ",
	description = "Advanced admin commands.",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=285493"
};

#define CMD_PREFIX "[SM] "

#define MODEL_CHICKEN_ZOMBIE "models/chicken/chicken_zombie.mdl"

new Handle: CVAR_CMD_ADMINS = INVALID_HANDLE,
	Handle: CVAR_JOIN_ANNOUNCE = INVALID_HANDLE,
	Handle: CVAR_SOUND_SPAWN = INVALID_HANDLE,
	Handle: CVAR_INVALID_MESSAGE = INVALID_HANDLE,
	Handle: CVAR_CMD_LOGGING = INVALID_HANDLE;

new String: SOUND_SPAWN[512];
new Float: ResetVector[3] = {0.0, 0.0, 0.0}, //This one is always 0, needed for reset the player's velocity
	Float: SAVELOC[MAXPLAYERS + 1][3];

new String: ValidItems[][] = //VALID WEAPON NAMES HERE
{
	"defuser", "c4", "knife", "knifegg", "taser", "healthshot", //misc
	"decoy", "flashbang", "hegrenade", "molotov", "incgrenade", "smokegrenade", "tagrenade", //grenades
	"usp_silencer", "glock", "tec9", "p250", "hkp2000", "cz75a", "deagle", "revolver", "fiveseven", "elite", //pistoles
	"nova", "xm1014", "sawedoff", "mag7", "m249", "negev", //heavy weapons
	"mp9", "mp7", "ump45", "p90", "bizon", "mac10", //smgs
	"ak47", "aug", "famas", "sg556", "galilar", "m4a1", "m4a1_silencer", //rifles
	"awp", "ssg08", "scar20", "g3sg1" //snipers
};

public OnPluginStart()
{
	CreateConVar("sm_advanced_admin_version", VERSION, "The version of the advaced admin plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	CVAR_CMD_ADMINS			= CreateConVar("sm_advanced_admin_cmd_admins",			"1",	"Settings of !admins command, 0 - disable, 1 - show fake online admins, 2 - show true online admins", _, true, 0.0, true, 2.0);
	CVAR_JOIN_ANNOUNCE		= CreateConVar("sm_advanced_admin_join_announce",		"1",	"Join announce with country name, 0 - disable, 1 - enable", _, true, 0.0, true, 1.0);
	CVAR_INVALID_MESSAGE	= CreateConVar("sm_advanced_admin_invalid_message",		"1",	"If you give invalid item, then show it for all player, 0 - disable, 1 - enable", _, true, 0.0, true, 1.0);
	CVAR_CMD_LOGGING		= CreateConVar("sm_advanced_admin_log",					"1",	"Enable logging for plugin, 0 - disable, 1 - enable", _, true, 0.0, true, 1.0);
	
	CVAR_SOUND_SPAWN		= CreateConVar("sm_advanced_admin_spawn_sound",			"player/pl_respawn.wav", "Teleport and respawn sound. Leave blank to disable. Custom sounds not supported.");
	HookConVarChange(CVAR_SOUND_SPAWN, OnConVarChange);
	GetConVarString(CVAR_SOUND_SPAWN, SOUND_SPAWN, sizeof(SOUND_SPAWN));
	
	RegAdminCmd("sm_extend",		CMD_Extend,			ADMFLAG_CHANGEMAP,	"Extending the map");
	RegAdminCmd("sm_clearmap",		CMD_ClearMap,		ADMFLAG_GENERIC,	"Deleting all dropped weapons from map");
	RegAdminCmd("sm_restartgame",	CMD_RestartGame,	ADMFLAG_GENERIC,	"Restarting the round");
	RegAdminCmd("sm_rg",			CMD_RestartGame,	ADMFLAG_GENERIC,	"Restarting the round");
	RegAdminCmd("sm_restartround",	CMD_RestartGame,	ADMFLAG_GENERIC,	"Restarting the round");
	RegAdminCmd("sm_rr",			CMD_RestartGame,	ADMFLAG_GENERIC,	"Restarting the round");
	RegAdminCmd("sm_valid_weapons",	CMD_Valid_Weapons,	ADMFLAG_GENERIC,	"Showing the valid weapon names");
	//-----//
	RegAdminCmd("sm_teleport",		CMD_Teleport,		ADMFLAG_BAN,		"Teleporting a player");
	RegAdminCmd("sm_tp",			CMD_Teleport,		ADMFLAG_BAN,		"Teleporting a player");
	RegAdminCmd("sm_saveloc",		CMD_SaveLoc,		ADMFLAG_BAN,		"Saving position for teleport");
	//-----//
	RegAdminCmd("sm_team",			CMD_Team,			ADMFLAG_KICK,		"Set team of player");
	RegAdminCmd("sm_swap",			CMD_Swap,			ADMFLAG_KICK,		"Swap team of player");
	RegAdminCmd("sm_spec",			CMD_Spec,			ADMFLAG_KICK,		"Set player to spectator");
	// RegAdminCmd("sm_scramble",		CMD_Scramble,		ADMFLAG_KICK,		"Scramble the teams");
	RegAdminCmd("sm_balance",		CMD_Scramble,		ADMFLAG_KICK,		"Scramble the teams");
	//-----//
	RegAdminCmd("sm_give",			CMD_Give,			ADMFLAG_BAN,		"Give something to a player");
	RegAdminCmd("sm_equip",			CMD_Equip,			ADMFLAG_BAN,		"Equipping something to a player");
	RegAdminCmd("sm_melee",			CMD_Equip,			ADMFLAG_BAN,		"Equipping something to a player");
	RegAdminCmd("sm_disarm",		CMD_Disarm,			ADMFLAG_BAN,		"Disarming a player");
	//-----//
	RegAdminCmd("sm_bury",			CMD_Bury,			ADMFLAG_KICK,		"Bury a player");
	RegAdminCmd("sm_unbury",		CMD_UnBury,			ADMFLAG_KICK,		"Unbury a player");
	//-----//
	RegAdminCmd("sm_speed",			CMD_Speed,			ADMFLAG_BAN,		"Set speed of player");
	RegAdminCmd("sm_respawn",		CMD_Respawn,		ADMFLAG_KICK,		"Respawn a player");
	//-----//
	RegAdminCmd("sm_god",			CMD_God,			ADMFLAG_BAN,		"Set godmode of player");
	RegAdminCmd("sm_helmet",		CMD_Helmet,			ADMFLAG_KICK,		"Set helmet of player");
	//-----//
	RegAdminCmd("sm_hp",			CMD_Health,			ADMFLAG_KICK,		"Set health of player");
	RegAdminCmd("sm_health",		CMD_Health,			ADMFLAG_KICK,		"Set health of player");
	RegAdminCmd("sm_armour",		CMD_Armour,			ADMFLAG_KICK,		"Set armour of player");
	RegAdminCmd("sm_cash",			CMD_Cash,			ADMFLAG_BAN,		"Set cash of player");
	RegAdminCmd("sm_frags",			CMD_Kills,			ADMFLAG_BAN,		"Set kills of player");
	RegAdminCmd("sm_kills",			CMD_Kills,			ADMFLAG_BAN,		"Set kills of player");
	RegAdminCmd("sm_assists",		CMD_Assists,		ADMFLAG_BAN,		"Set assists of player");
	RegAdminCmd("sm_deaths",		CMD_Deaths,			ADMFLAG_BAN,		"Set deaths of player");
	RegAdminCmd("sm_mvps",			CMD_MVPs,			ADMFLAG_BAN, 		"Set MVPs of player");
	RegAdminCmd("sm_scores",		CMD_Scores,	 		ADMFLAG_BAN,		"Set scores of player");
	//-----//
	RegAdminCmd("sm_teamscores",	CMD_Team_Scores,	ADMFLAG_BAN,		"Set team scores");
	//-----//
	RegAdminCmd("sm_spawnchicken",	CMD_Spawn_Chicken,	ADMFLAG_GENERIC,	"Spawning a chicken to your aim position");
	RegAdminCmd("sm_sc",			CMD_Spawn_Chicken,	ADMFLAG_GENERIC,	"Spawning a chicken to your aim position");
	//=====//
	RegConsoleCmd("sm_admins",		CMD_Admins,			"Showing online admins");
	
	LoadTranslations("common.phrases");
	LoadTranslations("advanced_admin.phrases");
}

public OnMapStart()
{
	if(!StrEqual(SOUND_SPAWN, ""))
	{
		PrecacheSound(SOUND_SPAWN, true);
	}
	PrecacheModel("models/chicken/chicken.mdl", true);
	PrecacheModel(MODEL_CHICKEN_ZOMBIE, true);
}

//-----CVARCHANGE-----//
public OnConVarChange(Handle: convar, const String: oldValue[], const String: newValue[])
{
	if(!StrEqual(oldValue, newValue))
	{
		GetConVarString(CVAR_SOUND_SPAWN, SOUND_SPAWN, sizeof(SOUND_SPAWN));
		if(!StrEqual(SOUND_SPAWN, ""))
		{
			PrecacheSound(SOUND_SPAWN, true);
		}
	}
}

//-----CLIENT_AUTHORIZED-----//
public OnClientAuthorized(client, const String: auth[]) //Printing client's name and country on join
{
	if(GetConVarBool(CVAR_JOIN_ANNOUNCE))
	{
		new String: IP[65],
			String: Country[65];
		
		if(GetClientIP(client, IP, sizeof(IP)) && GeoipCountry(IP, Country, sizeof(Country)))
		{
			PrintToChatAll("%t", "Player_Connected_From", client, Country);
		}
		else
		{
			PrintToChatAll("%t", "Player_Connected", client);
		}
	}
}

//----------------------------//
//=====NON-ADMIN_COMMANDS=====//
public Action: CMD_Admins(client, args) //Showing all online admins for you
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(!(GetUserFlagBits(client) & ADMFLAG_GENERIC))
	{
		if(GetConVarInt(CVAR_CMD_ADMINS) == 0)
		{
			ReplyToCommand(client, "%t", "CMD_Disabled");
			return Plugin_Handled;
		}
		else if(GetConVarInt(CVAR_CMD_ADMINS) == 1)
		{
			ReplyToCommand(client, "%t", "CMD_Admins_Offline");
			return Plugin_Handled;
		}
	}
	
	new String: AdminNames[512],
		String: CurrentName[65];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && (GetUserFlagBits(i) & ADMFLAG_GENERIC))
		{			
			if(GetUserFlagBits(i) & ADMFLAG_ROOT)
			{
				Format(CurrentName, sizeof(CurrentName), "[R]%N", i);
			}
			else
			{
				Format(CurrentName, sizeof(CurrentName), "[A]%N", i);
			}
			
			if(StrEqual(AdminNames, ""))
			{
				Format(AdminNames, sizeof(AdminNames), "%s", CurrentName);
			}
			else
			{
				Format(AdminNames, sizeof(AdminNames), "%s, %s", AdminNames, CurrentName);
			}
		}
	}
	
	if(!StrEqual(AdminNames, ""))
	{
		ReplyToCommand(client, "%t", "CMD_Admins_Online", AdminNames);
	}
	else
	{
		ReplyToCommand(client, "%t", "CMD_Admins_Offline");
	}
	return Plugin_Handled;
}

//------------------------//
//=====ADMIN_COMMANDS=====//
//=========SERVER=========//
public Action: CMD_Extend(client, args) //Extending or abridge the current map
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 1)
	{
		ReplyToCommand(client, "%t", "CMD_Extend_Usage");
		return Plugin_Handled;
	}
	
	new String: amount_string[16];
	GetCmdArg(1, amount_string, sizeof(amount_string));
	
	new amount = StringToInt(amount_string);
	ExtendMapTimeLimit(amount * 60);
	
	ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Extend", amount);
	LogActionEx(client, "%t", "CMD_Extend", amount);
	return Plugin_Handled;
}
public Action: CMD_ClearMap(client, args) //Delete all weapons from ground
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	new String: classname[65];
	for(new entity = MaxClients; entity < GetMaxEntities(); entity++)
	{
		if(IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, sizeof(classname));
			if( ( ( (StrContains(classname, "weapon_", false) != -1) || (StrContains(classname, "item_", false) != -1) ) && (GetEntProp(entity, Prop_Data, "m_iState") == 0) && (GetEntProp(entity, Prop_Data, "m_spawnflags") != 1) ) || (StrContains(classname, "chicken", false) != -1) )
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
	
	ShowActivity2(client, CMD_PREFIX, "%t", "CMD_ClearMap");
	LogActionEx(client, "%t", "CMD_ClearMap");
	return Plugin_Handled;
}
public Action: CMD_RestartGame(client, args) //Restarting the game
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	new time = 1;
	if(args)
	{
		new String: amount_string[65];
		GetCmdArg(1, amount_string, sizeof(amount_string));
		
		new amount = StringToInt(amount_string);
		
		if(amount > time)
		{
			time = amount;
		}
	}
	ServerCommand("mp_restartgame %i", time);
	
	ShowActivity2(client, CMD_PREFIX, "%t", "CMD_RestartGame");
	LogActionEx(client, "%t", "CMD_RestartGame");
	return Plugin_Handled;
}
public Action: CMD_Valid_Weapons(client, args) //Showing valid weapon names
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	new String: buffer[1024];
	for(new i = 0; i < sizeof(ValidItems); i++)
	{
		if(StrEqual(buffer, ""))
		{
			Format(buffer, sizeof(buffer), "%s", ValidItems[i]);
		}
		else
		{
			Format(buffer, sizeof(buffer), "%s, %s", buffer, ValidItems[i]);
		}
	}
	PrintToConsole(client, "%t", "CMD_Valid_Weapons", buffer);
	ReplyToCommand(client, "%t", "CMD_Valid_Weapons_Printed");
	return Plugin_Handled;
}

//=========CLIENT=========//
public Action: CMD_Teleport(client, args) //Teleporting a player to another player, or saved location
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if((args != 1) && (args != 2))
	{
		ReplyToCommand(client, "%t", "CMD_Teleport_Usage");
		return Plugin_Handled;
	}
	
	new String: target1_string[65],
		String: target2_string[65];
	
	GetCmdArg(1, target1_string, sizeof(target1_string));
	GetCmdArg(2, target2_string, sizeof(target2_string));
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target1_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new Float: pos[3];
	if(!StrEqual(target2_string, ""))
	{
		new target2 = FindTarget(client, target2_string, false, false);
		if(!IsClientValid(target2) || !IsClientInGame(target2))
		{
			return Plugin_Handled;
		}
		
		GetClientAbsOrigin(target2, pos);
		
		if(tn_is_ml)
		{
			ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Teleport_To_Player", target_name, target2);
			LogActionEx(client, "%t", "CMD_Teleport_To_Player", target_name, target2);
		}
		else
		{
			ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Teleport_To_Player", "_s", target_name, target2);
			LogActionEx(client, "%t", "CMD_Teleport_To_Player", "_s", target_name, target2);
		}
	}
	else
	{
		if((SAVELOC[client][0] == 0.0) && (SAVELOC[client][1] == 0.0) && (SAVELOC[client][2] == 0.0))
		{
			ReplyToCommand(client, "%t", "CMD_Teleport_NoSaved");
			return Plugin_Handled;
		}
		else
		{
			pos = SAVELOC[client];
			if(tn_is_ml)
			{
				ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Teleport_To_Saved", target_name);
				LogActionEx(client, "%t", "CMD_Teleport_To_Saved", target_name);
			}
			else
			{
				ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Teleport_To_Saved", "_s", target_name);
				LogActionEx(client, "%t", "CMD_Teleport_To_Saved", "_s", target_name);
			}
		}
	}
	pos[2] = pos[2] + 2.0;
	
	for(new i = 0; i < target_count; i++)
	{
		TeleportEntity(target_list[i], pos, NULL_VECTOR, ResetVector);
		if(!StrEqual(SOUND_SPAWN, ""))
		{
			EmitSoundToAll(SOUND_SPAWN, target_list[i]);
		}
	}
	return Plugin_Handled;
}
public Action: CMD_SaveLoc(client, args) //Saving current location to your variables for teleport
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	GetClientAbsOrigin(client, SAVELOC[client]);
	ReplyToCommand(client, "%t", "CMD_SaveLoc");
	return Plugin_Handled;
}

//==========//
public Action: CMD_Team(client, args) //Set player's team
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_Team_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
	
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
		
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new team;
	if(StrEqual(amount_string, "t") || StrEqual(amount_string, "2"))
	{
		team = CS_TEAM_T;
		if(tn_is_ml)
		{
			ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Team_T", target_name);
			LogActionEx(client, "%t", "CMD_Team_T", target_name);
		}
		else
		{
			ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Team_T", "_s", target_name);
			LogActionEx(client, "%t", "CMD_Team_T", "_s", target_name);
		}
	}
	else if(StrEqual(amount_string, "ct") || StrEqual(amount_string, "3"))
	{
		team = CS_TEAM_CT;
		if(tn_is_ml)
		{
			ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Team_CT", target_name);
			LogActionEx(client, "%t", "CMD_Team_CT", target_name);
		}
		else
		{
			ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Team_CT", "_s", target_name);
			LogActionEx(client, "%t", "CMD_Team_CT", "_s", target_name);
		}
	}
	else if(StrEqual(amount_string, "spectator") || StrEqual(amount_string, "spec") || StrEqual(amount_string, "1"))
	{
		team = CS_TEAM_SPECTATOR;
		if(tn_is_ml)
		{
			ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Team_Spec", target_name);
			LogActionEx(client, "%t", "CMD_Team_Spec", target_name);
		}
		else
		{
			ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Team_Spec", "_s", target_name);
			LogActionEx(client, "%t", "CMD_Team_Spec", "_s", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "%t", "CMD_Invalid_Team");
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		ChangeClientTeam(target_list[i], team);
	}
	return Plugin_Handled;
}
public Action: CMD_Swap(client, args) //Swap player's team
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 1)
	{
		ReplyToCommand(client, "%t", "CMD_Swap_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65];
	GetCmdArg(1, target_string, sizeof(target_string));
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		new team = GetClientTeam(target_list[i]);
		if(team == CS_TEAM_T)
		{
			CS_SwitchTeam(target_list[i], CS_TEAM_CT);
			CS_RespawnPlayer(target_list[i]);
		}
		else if(team == CS_TEAM_CT)
		{
			CS_SwitchTeam(target_list[i], CS_TEAM_T);
			CS_RespawnPlayer(target_list[i]);
		}
		else
		{
			ReplyToCommand(client, "%t", "CMD_OnlyInTeam");
			return Plugin_Handled;
		}
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Swap", target_name);
		LogActionEx(client, "%t", "CMD_Swap", target_name);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Swap", "_s", target_name);
		LogActionEx(client, "%t", "CMD_Swap", "_s", target_name);
	}
	return Plugin_Handled;
}
public Action: CMD_Spec(client, args) //Move the player to spectators
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 1)
	{
		ReplyToCommand(client, "%t", "CMD_Team_Spec_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65];
	GetCmdArg(1, target_string, sizeof(target_string));
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		ChangeClientTeam(target_list[i], CS_TEAM_SPECTATOR);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Team_Spec", target_name);
		LogActionEx(client, "%t", "CMD_Team_Spec", target_name);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Team_Spec", "_s", target_name);
		LogActionEx(client, "%t", "CMD_Team_Spec", "_s", target_name);
	}
	return Plugin_Handled;
}

public Action: CMD_Scramble(client, args) //Scramble the two teams
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	ServerCommand("mp_scrambleteams");
	
	ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Scramble");
	LogActionEx(client, "%t", "CMD_Scramble");
	return Plugin_Handled;
}


//==========//
public Action: CMD_Give(client, args) //Give weapons or something to player
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if((args != 1) && (args != 2))
	{
		ReplyToCommand(client, "%t", "CMD_Give_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: weapon_string[256];
	
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, weapon_string, sizeof(weapon_string));
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if(StrEqual(weapon_string, ""))
	{
		Format(weapon_string, sizeof(weapon_string), "knife");
	}
	
	if(!IsItemValid(weapon_string))
	{
		if(GetConVarBool(CVAR_INVALID_MESSAGE))
		{
			if(tn_is_ml)
			{
				PrintToChatAll("%s%t", CMD_PREFIX, "CMD_Give", target_name, weapon_string);
			}
			else
			{
				PrintToChatAll("%s%t", CMD_PREFIX, "CMD_Give", "_s", target_name, weapon_string);
			}
		}
		ReplyToCommand(client, "%t", "CMD_Invalid_Weapon");
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		if((StrContains(weapon_string, "knife", false) != -1) && !GetConVarBool(FindConVar("mp_drop_knife_enable")))
		{
			new knife = -1;
			while((knife = GetPlayerWeaponSlot(target_list[i], 2)) != -1)
			{
				if(IsValidEntity(knife))
				{
					RemovePlayerItem(target_list[i], knife);
				}
			}
		}
		GivePlayerWeapon(target_list[i], weapon_string);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Give", target_name, weapon_string);
		LogActionEx(client, "%t", "CMD_Give", target_name, weapon_string);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Give", "_s", target_name, weapon_string);
		LogActionEx(client, "%t", "CMD_Give", "_s", target_name, weapon_string);
	}
	return Plugin_Handled;
}
public Action: CMD_Equip(client, args) //Disarm player and give another weapon
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if((args != 1) && (args != 2))
	{
		ReplyToCommand(client, "%t", "CMD_Equip_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: weapon_string[256];
	
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, weapon_string, sizeof(weapon_string));
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
		
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if(StrEqual(weapon_string, ""))
	{
		Format(weapon_string, sizeof(weapon_string), "knife");
	}
	
	if(!IsItemValid(weapon_string))
	{
		if(GetConVarBool(CVAR_INVALID_MESSAGE))
		{
			if(tn_is_ml)
			{
				PrintToChatAll("%s%t", CMD_PREFIX, "CMD_Equip", target_name, weapon_string);
			}
			else
			{
				PrintToChatAll("%s%t", CMD_PREFIX, "CMD_Equip", "_s", target_name, weapon_string);
			}
		}
		ReplyToCommand(client, "%t", "CMD_Invalid_Weapon");
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		DisarmPlayerWeapons(target_list[i]);
		GivePlayerWeapon(target_list[i], weapon_string);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Equip", target_name, weapon_string);
		LogActionEx(client, "%t", "CMD_Equip", target_name, weapon_string);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Equip", "_s", target_name, weapon_string);
		LogActionEx(client, "%t", "CMD_Equip", "_s", target_name, weapon_string);
	}
	return Plugin_Handled;
}
public Action: CMD_Disarm(client, args) //Disarming the player
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 1)
	{
		ReplyToCommand(client, "%t", "CMD_Disarm_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65];
	GetCmdArg(1, target_string, sizeof(target_string));
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		DisarmPlayerWeapons(target_list[i]);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Disarm", target_name);
		LogActionEx(client, "%t", "CMD_Disarm", target_name);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Disarm", "_s", target_name);
		LogActionEx(client, "%t", "CMD_Disarm", "_s", target_name);
	}
	return Plugin_Handled;
}

//==========//
public Action: CMD_Bury(client, args) //Bury the player
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 1)
	{
		ReplyToCommand(client, "%t", "CMD_Bury_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65];
	GetCmdArg(1, target_string, sizeof(target_string));
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new Float: pos[3];
	for(new i = 0; i < target_count; i++)
	{
		GetClientAbsOrigin(target_list[i], pos);
		pos[2] -= 36.5;
		TeleportEntity(target_list[i], pos, NULL_VECTOR, ResetVector);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Bury", target_name);
		LogActionEx(client, "%t", "CMD_Bury", target_name);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Bury", "_s", target_name);
		LogActionEx(client, "%t", "CMD_Bury", "_s", target_name);
	}
	return Plugin_Handled;
}
public Action: CMD_UnBury(client, args) //Unbury the player
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 1)
	{
		ReplyToCommand(client, "%t", "CMD_UnBury_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65];
	GetCmdArg(1, target_string, sizeof(target_string));
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
		
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new Float: pos[3];
	for(new i = 0; i < target_count; i++)
	{
		GetClientAbsOrigin(target_list[i], pos);
		pos[2] += 36.5;
		TeleportEntity(target_list[i], pos, NULL_VECTOR, ResetVector);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_UnBury", target_name);
		LogActionEx(client, "%t", "CMD_UnBury", target_name);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_UnBury", "_s", target_name);
		LogActionEx(client, "%t", "CMD_UnBury", "_s", target_name);
	}
	return Plugin_Handled;
}
public Action: CMD_Speed(client, args) //Modify player's lagged movement speed
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_Speed_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
	
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new Float: amount = StringToFloat(amount_string);
	if((amount < 0.0) || (amount > 500.0))
	{
		ReplyToCommand(client, "%t", "CMD_Speed_Usage");
		return Plugin_Handled;
	}
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		SetEntPropFloat(target_list[i], Prop_Data, "m_flLaggedMovementValue", amount);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Speed", target_name, amount_string);
		LogActionEx(client, "%t", "CMD_Speed", target_name, amount_string);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Speed", "_s", target_name, amount_string);
		LogActionEx(client, "%t", "CMD_Speed", "_s", target_name, amount_string);
	}
	return Plugin_Handled;
}

//==========//
public Action: CMD_Respawn(client, args) //Respawn the player
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 1)
	{
		ReplyToCommand(client, "%t", "CMD_Respawn_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65];
	GetCmdArg(1, target_string, sizeof(target_string));
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
		
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		if(GetClientTeam(target_list[i]) > 1)
		{
			CS_RespawnPlayer(target_list[i]);
			if(!StrEqual(SOUND_SPAWN, ""))
			{
				EmitSoundToAll(SOUND_SPAWN, target_list[i]);
			}
		}
		else
		{
			ReplyToCommand(client, "%t", "CMD_OnlyInTeam");
		}
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Respawn", target_name);
		LogActionEx(client, "%t", "CMD_Respawn", target_name);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Respawn", "_s", target_name);
		LogActionEx(client, "%t", "CMD_Respawn", "_s", target_name);
	}
	return Plugin_Handled;
}
public Action: CMD_God(client, args) //Modify player's god mode
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_God_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
	
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new amount = StringToInt(amount_string);
	
	if((amount != 0) && (amount != 1))
	{
		ReplyToCommand(client, "%t", "CMD_God_Usage");
		return Plugin_Handled;
	}
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		SetEntProp(target_list[i], Prop_Data, "m_takedamage", amount?0:2);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_God", target_name, amount);
		LogActionEx(client, "%t", "CMD_God", target_name, amount);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_God", "_s", target_name, amount);
		LogActionEx(client, "%t", "CMD_God", "_s", target_name, amount);
	}
	return Plugin_Handled;
}
//==========//
public Action: CMD_Health(client, args) //Modify the player's health
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_Health_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
	
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new amount = StringToInt(amount_string);
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new target = 0; target < target_count; target++)
	{
		if((amount_string[0] == '+') || (amount_string[0] == '-'))
		{
			amount = amount + GetEntProp(target_list[target], Prop_Data, "m_iHealth");
		}
		
		SetEntProp(target_list[target], Prop_Data, "m_iHealth", amount);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Health", target_name, amount);
		LogActionEx(client, "%t", "CMD_Health", target_name, amount);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Health", "_s", target_name, amount);
		LogActionEx(client, "%t", "CMD_Health", "_s", target_name, amount);
	}
	return Plugin_Handled;
}
public Action: CMD_Armour(client, args) //Modify the player's armour
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_Armour_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
		
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new amount = StringToInt(amount_string);
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i = 0; i < target_count; i++)
	{
		if((amount_string[0] == '+') || (amount_string[0] == '-'))
		{
			amount = amount + GetEntProp(target_list[i], Prop_Data, "m_ArmorValue");
		}
		SetEntProp(target_list[i], Prop_Data, "m_ArmorValue", amount);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Armour", target_name, amount);
		LogActionEx(client, "%t", "CMD_Armour", target_name, amount);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Armour", "_s", target_name, amount);
		LogActionEx(client, "%t", "CMD_Armour", "_s", target_name, amount);
	}
	return Plugin_Handled;
}
public Action: CMD_Helmet(client, args) //Modify the player's helmet
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_Helmet_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
		
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new amount = StringToInt(amount_string);
	if((amount != 0) && (amount != 1))
	{
		ReplyToCommand(client, "%t", "CMD_Helmet_Usage");
		return Plugin_Handled;
	}
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i = 0; i < target_count; i++)
	{
		SetEntProp(target_list[i], Prop_Send, "m_bHasHelmet", amount);
	}

	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Helmet", target_name, amount);
		LogActionEx(client, "%t", "CMD_Helmet", target_name, amount);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Helmet", "_s", target_name, amount);
		LogActionEx(client, "%t", "CMD_Helmet", "_s", target_name, amount);
	}
	return Plugin_Handled;
}
//==========//
public Action: CMD_Cash(client, args) //Modify the player's cash
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_Cash_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
		
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new amount = StringToInt(amount_string);
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i = 0; i < target_count; i++)
	{
		if((amount_string[0] == '+') || (amount_string[0] == '-'))
		{
			amount = amount + GetEntProp(target_list[i], Prop_Send, "m_iAccount");
		}
		SetEntProp(target_list[i], Prop_Send, "m_iAccount", amount);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Cash", target_name, amount);
		LogActionEx(client, "%t", "CMD_Cash", target_name, amount);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Cash", "_s", target_name, amount);
		LogActionEx(client, "%t", "CMD_Cash", "_s", target_name, amount);
	}
	return Plugin_Handled;
}
public Action: CMD_Kills(client, args) //Modify the player's kills
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_Kills_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
	
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new amount = StringToInt(amount_string);
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i = 0; i < target_count; i++)
	{
		if((amount_string[0] == '+') || (amount_string[0] == '-'))
		{
			amount = amount + GetEntProp(target_list[i], Prop_Data, "m_iFrags");
		}
		SetEntProp(target_list[i], Prop_Data, "m_iFrags", amount);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Kills", target_name, amount);
		LogActionEx(client, "%t", "CMD_Kills", target_name, amount);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Kills", "_s", target_name, amount);
		LogActionEx(client, "%t", "CMD_Kills", "_s", target_name, amount);
	}
	return Plugin_Handled;
}
public Action: CMD_Assists(client, args) //Modify the player's assists
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_Assists_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
	
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new amount = StringToInt(amount_string);
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		if((amount_string[0] == '+') || (amount_string[0] == '-'))
		{
			amount = amount + CS_GetClientAssists(target_list[i]);
		}
		CS_SetClientAssists(target_list[i], amount);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Assists", target_name, amount);
		LogActionEx(client, "%t", "CMD_Assists", target_name, amount);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Assists", "_s", target_name, amount);
		LogActionEx(client, "%t", "CMD_Assists", "_s", target_name, amount);
	}
	return Plugin_Handled;
}
public Action: CMD_Deaths(client, args) //Modify the player's deaths
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_Deaths_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
	
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new amount = StringToInt(amount_string);
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i = 0; i < target_count; i++)
	{
		if((amount_string[0] == '+') || (amount_string[0] == '-'))
		{
			amount = amount + GetEntProp(target_list[i], Prop_Data, "m_iDeaths");
		}
		SetEntProp(target_list[i], Prop_Data, "m_iDeaths", amount);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Deaths", target_name, amount);
		LogActionEx(client, "%t", "CMD_Deaths", target_name, amount);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Deaths", "_s", target_name, amount);
		LogActionEx(client, "%t", "CMD_Deaths", "_s", target_name, amount);
	}
	return Plugin_Handled;
}
public Action: CMD_MVPs(client, args) //Modify the player's MVPs
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_MVPS_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
	
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new amount = StringToInt(amount_string);
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i = 0; i < target_count; i++)
	{
		if((amount_string[0] == '+') || (amount_string[0] == '-'))
		{
			amount = amount + CS_GetMVPCount(target_list[i]);
		}
		CS_SetMVPCount(target_list[i], amount);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_MVPS", target_name, amount);
		LogActionEx(client, "%t", "CMD_MVPS", target_name, amount);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_MVPS", "_s", target_name, amount);
		LogActionEx(client, "%t", "CMD_MVPS", "_s", target_name, amount);
	}
	return Plugin_Handled;
}
public Action: CMD_Scores(client, args) //Modify the player's scores
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_Scores_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
	
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new amount = StringToInt(amount_string);
	
	new String: target_name[MAX_TARGET_LENGTH],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	if((target_count = ProcessTargetString(target_string, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		if((amount_string[0] == '+') || (amount_string[0] == '-'))
		{
			amount = amount + CS_GetClientContributionScore(target_list[i]);
		}
		CS_SetClientContributionScore(target_list[i], amount);
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Scores", target_name, amount);
		LogActionEx(client, "%t", "CMD_Scores", target_name, amount);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Scores", "_s", target_name, amount);
		LogActionEx(client, "%t", "CMD_Scores", "_s", target_name, amount);
	}
	return Plugin_Handled;
}
public Action: CMD_Team_Scores(client, args) //Modify the team's scores
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(args != 2)
	{
		ReplyToCommand(client, "%t", "CMD_Team_Scores_Usage");
		return Plugin_Handled;
	}
	
	new String: target_string[65],
		String: amount_string[65];
	
	GetCmdArg(1, target_string, sizeof(target_string));
	GetCmdArg(2, amount_string, sizeof(amount_string));
	
	new amount = StringToInt(amount_string);
	
	if(StrEqual(target_string, "t") || StrEqual(target_string, "2"))
	{
		if((amount_string[0] == '+') || (amount_string[0] == '-'))
		{
			amount = amount + GetTeamScore(CS_TEAM_T);
		}
		SetTeamScore(CS_TEAM_T, amount);
		
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Team_Scores_T", amount);
		LogActionEx(client, "%t", "CMD_Team_Scores_T", amount);
	}
	else if(StrEqual(target_string, "ct") || StrEqual(target_string, "3"))
	{
		if((amount_string[0] == '+') || (amount_string[0] == '-'))
		{
			amount = amount + GetTeamScore(CS_TEAM_CT);
		}
		SetTeamScore(CS_TEAM_CT, amount);
		
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Team_Scores_CT", amount);
		LogActionEx(client, "%t", "CMD_Team_Scores_CT", amount);
	}
	else
	{
		ReplyToCommand(client, "%t", "CMD_Invalid_Team");
	}
	return Plugin_Handled;
}
public Action: CMD_Spawn_Chicken(client, args) //Spawning a chicken
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	new Float: eye_pos[3],
		Float: eye_ang[3];
	
	GetClientEyePosition(client, eye_pos);
	GetClientEyeAngles(client, eye_ang);
	
	new Handle: trace = TR_TraceRayFilterEx(eye_pos, eye_ang, MASK_SOLID, RayType_Infinite, Filter_DontHitPlayers);
	if(!TR_DidHit(trace))
	{
		return Plugin_Handled;
	}
	
	new chicken = CreateEntityByName("chicken");
	if(!IsValidEntity(chicken))
	{
		return Plugin_Handled;
	}
	
	new Float: end_pos[3];
	TR_GetEndPosition(end_pos, trace);
	end_pos[2] = (end_pos[2] + 10.0);
	
	new String: buffer_str[6][5],
		buffer_int[6];
	
	for(new i = 0; i < 6; i++)
	{
		GetCmdArg(i+1, buffer_str[i], sizeof(buffer_str[]));
		buffer_int[i] = StringToInt(buffer_str[i]);
	}
	
	if( ((buffer_int[0] < 0) || (buffer_int[0] > 1)) || ((buffer_int[1] < -1) || (buffer_int[1] > 9999)) || ((buffer_int[2] < 0) || (buffer_int[2] > 255)) || ((buffer_int[3] < 0) || (buffer_int[3] > 255)) || ((buffer_int[4] < 0) || (buffer_int[4] > 255)) || ((buffer_int[5] < 0) || (buffer_int[5] > 3)) )
	{
		ReplyToCommand(client, "%t", "CMD_Spawn_Chicken_Usage");
		return Plugin_Handled;
	}
	
	new String: color_str[16];
	Format(color_str, sizeof(color_str), "%s %s %s", buffer_str[2], buffer_str[3], buffer_str[4]);
	DispatchKeyValue(chicken, "glowcolor", color_str);
	DispatchKeyValue(chicken, "glowdist", "512");
	DispatchKeyValue(chicken, "glowstyle", buffer_str[5]);
	DispatchKeyValue(chicken, "glowenabled", "1");
	DispatchKeyValue(chicken, "ExplodeDamage", buffer_str[1]);
	DispatchKeyValue(chicken, "ExplodeRadius", "0");
	DispatchSpawn(chicken);
	
	if(buffer_int[1] < 0)
	{
		SetEntProp(chicken, Prop_Data, "m_takedamage", 0);
	}
	
	if(buffer_int[0] > 0)
	{
		SetEntityModel(chicken, MODEL_CHICKEN_ZOMBIE);
	}
	else
	{
		SetEntProp(chicken, Prop_Data, "m_nSkin", GetRandomInt(0, 1));
	}
	
	//SetEntProp(chicken, Prop_Data, "m_nBody", 5); // Bodygroups 0-5
	
	TeleportEntity(chicken, end_pos, NULL_VECTOR, NULL_VECTOR);
	EmitSoundToAll(SOUND_SPAWN, chicken);
	
	ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Spawn_Chicken", buffer_int[0], buffer_int[1], buffer_int[2], buffer_int[3], buffer_int[4], buffer_int[5]);
	LogActionEx(client, "%t", "CMD_Spawn_Chicken", buffer_int[0], buffer_int[1], buffer_int[2], buffer_int[3], buffer_int[4], buffer_int[5]);
	
	return Plugin_Handled;
}

//-----STOCKS-----//
GivePlayerWeapon(client, String: weaponname[])
{
	new String: classname[65];
	if(StrEqual(weaponname, "defuser"))
	{
		Format(classname, sizeof(classname), "item_%s", weaponname);
	}
	else
	{
		Format(classname, sizeof(classname), "weapon_%s", weaponname);
	}
	return GivePlayerItem(client, classname);
}

DisarmPlayerWeapons(client)
{
	for(new i = 0; i < 5; i++)
	{
		new weapon = -1;
		while((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			if(IsValidEntity(weapon))
			{
				RemovePlayerItem(client, weapon);
			}
		}
	}
}

LogActionEx(client, String: message[], any: ...)
{
	if(GetConVarBool(CVAR_CMD_LOGGING))
	{
		new String: buffer[256];
		SetGlobalTransTarget(LANG_SERVER);
		VFormat(buffer, sizeof(buffer), message, 3);
		LogMessage("%N: %s", client, buffer);
	}
}

bool: IsClientValid(client)
{
	return ((client > 0) && (client <= MaxClients));
}

bool: IsItemValid(String: item[])
{
	for(new i = 0; i < sizeof(ValidItems); i++)
	{
		if(StrEqual(item, ValidItems[i]))
		{
			return true;
		}
	}
	return false;
}

//-----FILTERS-----//
public bool: Filter_DontHitPlayers(entity, contentsMask, any: data)
{
	return !((entity > 0) && (entity <= MaxClients));
}