/* sm_skinapp.sp
Name: Custom Skin Applier
Author: LumiStance
Date: 2009 - 12/06

Description: Gives each player a random custom skin.
	This plugin allows you to easily change the 'skin' on all players.
	You can specify between 1 to 8 separate models per team.
	The model is randomly selected each time the player spawns.
	The models used can be changed by updating ini files and doing a map change.

	No plugin code modification required to change customs models used.
	*.mdl file names are extracted from model ini files.  No CVAR's used.
	Comments, leading, and trailing white space allowed in ini files.

	The plugin will wait for a map change if it is loaded in the middle of a round.
	This ensures that clients download the files required to render the models.
	Make sure you copy the files to you fastdownload web server.

	Based upon TechKnow's masterchief Theme model changer plugin
		http://forums.alliedmods.net/showthread.php?t=77692
		sm_masterchief based partially on Preds Menu
		Posted 2008 - 09/19

	Meng maintains a Fork of TechKnow's plugin for applying custom skins to certain players (admins/bot/all)
		http://forums.alliedmods.net/showthread.php?t=98261
		http://forums.alliedmods.net/showpost.php?p=857070&postcount=17
		Posted 2009 - 07/24

	Uses SetEntityModel instead of SDK Calls, removing need for a custom gamedata file.
		Thanks DJ Tsunami for suggetion
		http://forums.alliedmods.net/showpost.php?p=691112&postcount=10
		Posted 2008 - 09/26

Files:
	cstrike/addons/sourcemod/plugins/sm_skinapp.smx
	cstrike/addons/sourcemod/configs/models_ct.ini
	cstrike/addons/sourcemod/configs/models_t.ini

Commands:
	sm_skinapp
		Lists available commands and plugin status
	sm_skinapp 0
		Disable plugin
		Models changed to game default now
	sm_skinapp 1
		Enable plugin
		Changes models now if not waiting for map change
	sm_skinapp list
		Lists models found in ini files

Versions: 1.0.5

Changelog:
	1.0.5 - 2009 - 12/06
		Replaced SDK Calls with SetEntityModel
		Removed CVAR's
		Added code to match /\*\.mdl$/ in ini files
		Replaced code to strip trailing newline in ini file with TrimString
		Added code to support multiple models per team
		Added code to prevent model change without client download files
		Added reporting and minor error handling
		Added code to list models found

	1.0 - 2008 - 09/19
		TechKnow's original sm_masterchief.sp
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.5"
#define MAX_FILE_LEN 256
#define MODELS_PER_TEAM 8

// Plugin definitions
public Plugin:myinfo =
{
	name = "Custom Skin Applier",
	author = "LumiStance",
	version = PLUGIN_VERSION,
	description = "Gives each player a random custom skin.",
	url = "http://srcds.LumiStance.com/"
};

// Plugin Mode
new bool:g_Use_Custom_Models = true;
new bool:g_PrecacheClean = false;
// Custom Models
new String:g_Models_CT[MODELS_PER_TEAM][MAX_FILE_LEN];
new String:g_Models_Count_CT;
new String:g_Models_T[MODELS_PER_TEAM][MAX_FILE_LEN];
new String:g_Models_Count_T;
// Default Models
static const String:ctmodels[4][] = {"models/player/ct_urban.mdl","models/player/ct_gsg9.mdl","models/player/ct_sas.mdl","models/player/ct_gign.mdl"};
static const String:tmodels[4][] = {"models/player/t_phoenix.mdl","models/player/t_leet.mdl","models/player/t_arctic.mdl","models/player/t_guerilla.mdl"};


public OnPluginStart()
{
	CreateConVar("sm_skinapp_version", PLUGIN_VERSION, "[SM] SkinApp Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_skinapp", Command_SetCustom, ADMFLAG_SLAY);

	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

public OnMapStart()
{
	g_Models_Count_CT = 0;
	g_Models_Count_T = 0;
	g_Models_Count_CT = LoadModels(g_Models_CT, "configs/models_ct.ini");
	g_Models_Count_T  = LoadModels(g_Models_T,  "configs/models_t.ini");

	if (g_Models_Count_CT == 0) SetFailState("[SM] sm_skinapp Error: No Custom CT Models found by SkinApp plugin");
	if (g_Models_Count_T == 0) SetFailState("[SM] sm_skinapp Error: No Custom T Models found by SkinApp plugin");
	PrintToServer("[SM] Custom Skin Applier v%s: %d models precached.", PLUGIN_VERSION, g_Models_Count_CT+g_Models_Count_T);

	// OnMapStart() is also called if plugin loaded in the middle of a round
	// We must wait for an actual map load before enabling the plugin
	if (GetClientCount(false) == 0) g_PrecacheClean = true;
}


stock LoadModels(String:models[][], String:ini_file[])
{
	decl String:buffer[MAX_FILE_LEN];
	decl String:file[MAX_FILE_LEN];
	new models_count;

	BuildPath(Path_SM, file, MAX_FILE_LEN, ini_file);

	//open precache file and add everything to download table
	new Handle:fileh = OpenFile(file, "r");
	while (ReadFileLine(fileh, buffer, MAX_FILE_LEN))
	{
		// Strip leading and trailing whitespace
		TrimString(buffer);

		// Skip non existing files (and Comments)
		if (FileExists(buffer))
		{
			// Tell Clients to download files
			AddFileToDownloadsTable(buffer);
			// Tell Clients to cache model
			if (StrEqual(buffer[strlen(buffer)-4], ".mdl", false) && (models_count<MODELS_PER_TEAM))
			{
				strcopy(models[models_count++], strlen(buffer)+1, buffer);
				PrecacheModel(buffer, true);
			}
		}
	}
	return models_count;
}


public Action:Command_SetCustom(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_skinapp <0/1/list>");
		ReplyToCommand(client, "    sm_skinapp = %d", ((g_Use_Custom_Models) ? 1 : 0));
		if (!g_PrecacheClean)
			ReplyToCommand(client, "    * Waiting for map change");
		return Plugin_Handled;
	}

	// Get the command
	decl String:command[MAX_FILE_LEN];
	GetCmdArg(1, command, MAX_FILE_LEN);

	// Disable Plugin - Used standard models
	if(command[0] == '0')
	{
		g_Use_Custom_Models = false;
		for(new client_index = 1; client_index <= MaxClients; client_index++)
		{
			if(IsClientInGame(client_index))
			{
				PrintToChat(client_index, "[SM] Your custom model has been removed");
				set_random_default_model(client_index);
			}
		}
	}

	// Enable Plugin - Used custom models
	if(command[0] == '1')
	{
		g_Use_Custom_Models = true;
		if (!g_PrecacheClean)
		{
			ReplyToCommand(client, "[SM] Changes will take affect after clients download models on map change");
			return Plugin_Handled;
		}
		for(new client_index = 1; client_index <= MaxClients; client_index++)
		{
			if(IsClientInGame(client_index))
			{
				PrintToChat(client_index, "[SM] You have been given a custom model");
				set_random_custom_model(client_index);
			}
		}
	}

	// List custom models by team
	if(StrEqual(command, "list"))
	{
		// List CT Models
		ReplyToCommand(client, "Counter Terrorist Models:");
		if(g_Models_Count_CT > 0)
			for(new model = 0; model < g_Models_Count_CT; ++model)
				ReplyToCommand(client, "    %s", g_Models_CT[model]);
		else
			ReplyToCommand(client, "    None found");
		// List T Models
		ReplyToCommand(client, "Terrorist Models:");
		if(g_Models_Count_T > 0)
			for(new model = 0; model < g_Models_Count_T; ++model)
				ReplyToCommand(client, "    %s", g_Models_T[model]);
		else
			ReplyToCommand(client, "    None found");
	}

	return Plugin_Continue;
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	// Set custom skin if plugin enabled
	if (g_Use_Custom_Models && g_PrecacheClean)
		set_random_custom_model(GetClientOfUserId(GetEventInt(event, "userid")));
	return Plugin_Continue;
}

stock set_random_custom_model(client_index)
{
	new team = GetClientTeam(client_index);
	if (team==2) //t
		SetEntityModel(client_index,g_Models_T[GetRandomInt(0, g_Models_Count_T-1)]);
	else if (team==3) //ct
		SetEntityModel(client_index,g_Models_CT[GetRandomInt(0, g_Models_Count_CT-1)]);
}

stock set_random_default_model(client_index)
{
	new random = GetRandomInt(0, 3);
	new team = GetClientTeam(client_index);
	if (team==2) //t
		SetEntityModel(client_index,tmodels[random]);
	else if (team==3) //ct
		SetEntityModel(client_index,ctmodels[random]);
}
