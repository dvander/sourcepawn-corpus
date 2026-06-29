#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sidewinder>

#define PLUGIN_VERSION "2.1"

public Plugin:myinfo = 
{
	name = "SideWinder Control",
	author = "Asherkin",
	description = "Enables/Disables SideWinder per player.",
	version = PLUGIN_VERSION,
	url = "http://mib.limetech.org"
};

public OnPluginStart()
{
	RegAdminCmd("sm_swon", Command_SideWinderON, ADMFLAG_ROOT, "Enables SideWinder for a client at a certain chance", "SideWinder");
	RegAdminCmd("sm_swoff", Command_SideWinderOFF, ADMFLAG_ROOT, "Disables SideWinder for a client", "SideWinder");
	SidewinderControl(true);
	LoadTranslations("common.phrases");
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	SidewinderTrackChance(client, 0);
	SidewinderSentryCritChance(client, 0);
	SidewinderFlags(client, NormalSentryRockets | NormalRockets | NormalArrows | NormalFlares | NormalPipes | NormalSyringe, true);
	return true;
}

public OnClientPostAdminCheck(client) {
	SidewinderTrackChance(client, 0);
	SidewinderSentryCritChance(client, 0);
	SidewinderFlags(client, NormalSentryRockets | NormalRockets | NormalArrows | NormalFlares | NormalPipes | NormalSyringe, true);
}

public OnClientDisconnect(client)
{
	SidewinderTrackChance(client, 0);
	SidewinderSentryCritChance(client, 0);
	SidewinderFlags(client, NormalSentryRockets | NormalRockets | NormalArrows | NormalFlares | NormalPipes | NormalSyringe, true);
}

public Action:Command_SideWinderON(client, args)
{
	decl String:arg1[32];
	decl String:arg2[32];
	decl String:arg3[32];
	if (args != 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_swon <target> <homingchance> <sentrycritchance> (chances out of 100)");
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		SidewinderTrackChance(target_list[i], StringToInt(arg2));
		SidewinderSentryCritChance(target_list[i], StringToInt(arg3));
		SidewinderFlags(target_list[i], CritSentryRockets | TrackingSentryRockets | TrackingRockets | TrackingArrows | TrackingFlares | TrackingPipes | NormalSyringe, true);
	}
	ShowActivity2(client, "[SM] ", "Enabled SideWinder on %s! (%s%% chance with %s%% sentry crit chance)", target_name, arg2, arg3);
	return Plugin_Handled;
}

public Action:Command_SideWinderOFF(client, args)
{
	decl String:arg1[32];
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_swoff <target>");
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		SidewinderTrackChance(target_list[i], 0);
		SidewinderSentryCritChance(target_list[i], 0);
		SidewinderFlags(target_list[i], NormalSentryRockets | NormalRockets | NormalArrows | NormalFlares | NormalPipes | NormalSyringe, true);
	}
	ShowActivity2(client, "[SM] ", "Disabled SideWinder on %s!", target_name);
	return Plugin_Handled;
}