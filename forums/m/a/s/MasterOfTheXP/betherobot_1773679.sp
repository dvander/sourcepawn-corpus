#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo = 
{
	name = "Be the Robot",
	author = "MasterOfTheXP",
	description = "Beep boop son, beep boop.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
}

new bool:isRobot[MAXPLAYERS + 1] = { false, ... };

public OnPluginStart()
{
	RegConsoleCmd("sm_robot", Command_betherobot);
	RegConsoleCmd("sm_tobor", Command_betherobot);
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Post);
	AddNormalSoundHook(SoundHook);
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
}

public Action:Command_betherobot(client, args)
{
	if (client == 0 && args < 1)
	{
		new String:arg0[10];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(client, "[SM] Usage: %s <name|#userid> [1/0] - Transforms a player into a robot. Beep boop.", arg0);
		return Plugin_Handled;
	}
	new String:arg1[MAX_TARGET_LENGTH], String:arg2[10], toggle = 1;
	if (!CheckCommandAccess(client, "betherobot", 0))
	{
		ReplyToCommand(client, "[SM] %t.", "No Access");
		return Plugin_Handled;
	}
	if (args < 1 || !CheckCommandAccess(client, "betherobot_admin", ADMFLAG_SLAY))
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
		if (StrEqual(arg1, "@me")) MakeRobot(client, 1);
		else ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	new success;
	for (new i = 0; i < target_count; i++)
	{
		if (MakeRobot(target_list[i], toggle)) success++;
	}
	if (success > 0 && !StrEqual(arg1, "@me"))
	{
		new String:verb[15]; // Should be a mini-switch statement or whatever those are called (e.g. toggle ? "Disabled" : "Toggled" : "Enabled") but iunno how to do it for integers.
		if (toggle == 0) Format(verb, sizeof(verb), "Disabled");
		if (toggle == 1) Format(verb, sizeof(verb), "Toggled");
		if (toggle == 2) Format(verb, sizeof(verb), "Enabled");
		ShowActivity2(client, "[SM] ", "%s robot on %s.", verb, target_name);
	}
	else if (success < 1) ReplyToCommand(client, "[SM] Robot transformation failed! Remember: You cannot be a robot as Engineer.");
	return Plugin_Handled;
}

public bool:MakeRobot(client, toggle)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	if (toggle == 2 || (toggle == 1 && !isRobot[client]))
	{
		if (SetModel(client)) isRobot[client] = true;
		else return false;
	}
	else if (toggle == 0 || (toggle == 1 && isRobot[client]))
	{
		if (RemoveModel(client)) isRobot[client] = false;
		else return false;
	}
	return true;
}

public OnClientDisconnect(client) isRobot[client] = false;

public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (isRobot[client]) SetModel(client);
	return Plugin_Continue;
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &client, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	if (!isRobot[client]) return Plugin_Continue;
	if (StrContains(sound, "vo/", false) == -1) return Plugin_Continue;
	if (StrContains(sound, "announcer", false) != -1) return Plugin_Continue;
	ReplaceString(sound, sizeof(sound), "vo/", "vo/mvm/norm/", false);
	ReplaceString(sound, sizeof(sound), ".wav", ".mp3", false); // yay for valve being smart
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout: ReplaceString(sound, sizeof(sound), "scout_", "scout_mvm_", false);
		case TFClass_Soldier: ReplaceString(sound, sizeof(sound), "soldier_", "soldier_mvm_", false);
		case TFClass_Pyro: ReplaceString(sound, sizeof(sound), "pyro_", "pyro_mvm_", false);
		case TFClass_DemoMan: ReplaceString(sound, sizeof(sound), "demoman_", "demoman_mvm_", false);
		case TFClass_Heavy: ReplaceString(sound, sizeof(sound), "heavy_", "heavy_mvm_", false);
		case TFClass_Medic: ReplaceString(sound, sizeof(sound), "medic_", "medic_mvm_", false);
		case TFClass_Sniper: ReplaceString(sound, sizeof(sound), "sniper_", "sniper_mvm_", false);
		case TFClass_Spy: ReplaceString(sound, sizeof(sound), "spy_", "spy_mvm_", false);
	}
	new String:soundchk[PLATFORM_MAX_PATH];
	Format(soundchk, sizeof(soundchk), "sound/%s", sound);
	if (!FileExists(soundchk)) return Plugin_Continue;
	PrecacheSound(sound);
	return Plugin_Changed;
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
		case TFClass_Medic: Format(Mdl, sizeof(Mdl), "medic");
		case TFClass_Sniper: Format(Mdl, sizeof(Mdl), "sniper");
		case TFClass_Spy: Format(Mdl, sizeof(Mdl), "spy");
		case TFClass_Engineer: Format(Mdl, sizeof(Mdl), "");
	}
	if (!StrEqual(Mdl, ""))
	{
		Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", Mdl, Mdl);
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
	return true;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}