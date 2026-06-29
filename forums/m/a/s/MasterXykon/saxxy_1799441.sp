#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Be Saxxy",
	author = "Master Xykon",
	description = "A Very Saxxy Plugin.",
	version = PLUGIN_VERSION,
	url = "http://tf2tms.com/"
}

new bool:issaxxy[MAXPLAYERS + 1] = { false, ... };
new bool:isAboutToExplode[MAXPLAYERS + 1] = { false, ... };
new Float:MdlScale[MAXPLAYERS + 1] = { -1.0, ... };

public OnPluginStart()
{
	RegConsoleCmd("sm_saxxy", Command_bethesaxxy);
	RegConsoleCmd("sm_besaxxy", Command_bethesaxxy);
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
}

public OnMapStart()
{
	AddFileToDownloadsTable("models/player/saxxy/players/demo.mdl");
	AddFileToDownloadsTable("models/player/saxxy/players/engineer.mdl");
	AddFileToDownloadsTable("models/player/saxxy/players/heavy.mdl");
	AddFileToDownloadsTable("models/player/saxxy/players/pyro.mdl");
	AddFileToDownloadsTable("models/player/saxxy/players/scout.mdl");
	AddFileToDownloadsTable("models/player/saxxy/players/sniper.mdl");
	AddFileToDownloadsTable("models/player/saxxy/players/soldier.mdl");
	AddFileToDownloadsTable("models/player/saxxy/players/spy.mdl");
}

public Action:Command_bethesaxxy(client, args)
{
	if (client == 0 && args < 1)
	{
		new String:arg0[10];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(client, "[SM] Usage: %s <name|#userid> [1/0] - Makes a player saxxy.", arg0);
		return Plugin_Handled;
	}
	new String:arg1[MAX_TARGET_LENGTH], String:arg2[10], toggle = 1;
	if (!CheckCommandAccess(client, "bethesaxxy", 0))
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Handled;
	}
	if (args < 1 || !CheckCommandAccess(client, "bethesaxxy_admin", ADMFLAG_SLAY))
		Format(arg1, sizeof(arg1), "@me");
	else
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		if (StrEqual(arg2, "0", false) || StrEqual(arg2, "off", false) || StrEqual(arg2, "no", false)) toggle = 0;
		if (StrEqual(arg2, "1", false) || StrEqual(arg2, "on", false) || StrEqual(arg2, "yes", false)) toggle = 2;
	}
	new String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE|args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		if (StrEqual(arg1, "@me")) Makesaxxy(client, client, 1);
		else ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	new success;
	for (new i = 0; i < target_count; i++)
	{
		if (Makesaxxy(target_list[i], client, toggle)) success++;
	}
	if (success > 0 && !StrEqual(arg1, "@me"))
	{
		new String:verb[15]; // Should be a mini-switch statement or whatever those are called (e.g. toggle ? "Disabled" : "Toggled" : "Enabled") but iunno how to do it for integers.
		if (toggle == 0) Format(verb, sizeof(verb), "Disabled");
		if (toggle == 1) Format(verb, sizeof(verb), "Toggled");
		if (toggle == 2) Format(verb, sizeof(verb), "Enabled");
		ShowActivity2(client, "[SM] ", "%s saxxy on %s.", verb, target_name);
	}
	else if (success < 1) ReplyToCommand(client, "[SM] Saxxy transformation failed! Remember: You cannot be saxxy as Medic or while taunting.");
	return Plugin_Handled;
}

public bool:Makesaxxy(client, admin, toggle)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	if (client != admin) TF2_RemoveCondition(client, TFCond_Taunting);
	else if (TF2_IsPlayerInCondition(client, TFCond_Taunting)) return false;
	if (toggle == 2 || (toggle == 1 && !issaxxy[client]))
	{
		if (SetModel(client)) issaxxy[client] = true;
		else return false;
	}
	else if (toggle == 0 || (toggle == 1 && issaxxy[client]))
	{
		if (RemoveModel(client)) issaxxy[client] = false;
		else return false;
	}
	return true;
}

public OnClientDisconnect(client)
{
	issaxxy[client] = false;
	isAboutToExplode[client] = false;
	MdlScale[client] = -1.0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	return Plugin_Continue;
}

stock bool:SetModel(client)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	new String:Mdl[PLATFORM_MAX_PATH];
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout: Format(Mdl, sizeof(Mdl), "scout");
		case TFClass_Soldier: Format(Mdl, sizeof(Mdl), "soldier");
		case TFClass_Pyro: Format(Mdl, sizeof(Mdl), "pyro");
		case TFClass_DemoMan: Format(Mdl, sizeof(Mdl), "demo");
		case TFClass_Heavy: Format(Mdl, sizeof(Mdl), "heavy");
		case TFClass_Engineer: Format(Mdl, sizeof(Mdl), "engineer");
		case TFClass_Sniper: Format(Mdl, sizeof(Mdl), "sniper");
		case TFClass_Spy: Format(Mdl, sizeof(Mdl), "spy");
		case TFClass_Medic: Format(Mdl, sizeof(Mdl), "");
	}
	if (!StrEqual(Mdl, ""))
	{
		Format(Mdl, sizeof(Mdl), "models/player/saxxy/players/%s.mdl", Mdl, Mdl);
		PrecacheModel(Mdl);
	}
	SetVariantString(Mdl);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	if (StrEqual(Mdl, "")) return false;
	return true;
}

stock bool:RemoveModel(client)
{
	if (!IsValidClient(client)) return false;
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	if (MdlScale[client] != -1.0) SetEntPropFloat(client, Prop_Send, "m_flModelScale", MdlScale[client]);
	MdlScale[client] = -1.0;
	return true;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}