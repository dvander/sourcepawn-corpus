#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <namechange>
#define MAX_NAME_LEGNTH 64
public Plugin:myinfo = 
{
	name = "Rename2",
	author = "Kyle Sanderson, AlliedModders LLC",
	description = "Allows you to rename a player using Drifter's extension",
	version = "1.0",
	url = "www.SourceMod.net"
}

new g_ModVersion = 0;
new String:g_NewName[MAXPLAYERS+2][MAX_NAME_LENGTH];

public OnPluginStart()
{
	RegAdminCmd("sm_rename2", Command_Rename, ADMFLAG_SLAY, "Allows you to rename a player provided you're using Drifter's Extension.");
	g_ModVersion = GuessSDKVersion();
	LoadTranslations("common.phrases");
	LoadTranslations("playercommands.phrases");
}

public Action:Command_Rename(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04[SourceMod]\x03 Usage: sm_rename2 <#userid|name> [newname]");
		return Plugin_Handled;
	}

	decl String:arg[MAX_NAME_LENGTH], String:arg2[MAX_NAME_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));

	new bool:randomize;
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	else
	{
		randomize = true;
	}
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_TARGET_NONE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		if (tn_is_ml)
		{
			ShowActivity2(client, "\x04[SourceMod]\x03 ", "%t", "Renamed target", target_name);
		}
		else
		{
			ShowActivity2(client, "\x04[SourceMod]\x03 ", "%t", "Renamed target", "_s", target_name);
		}

		if (target_count > 1) /* We cannot name everyone the same thing. */
		{
			randomize = true;
		}

		for (new i = 0; i < target_count; i++)
		{
			if(randomize)
			{
				RandomizeName(target_list[i]);
			}
			else
			{
				FormatEx(g_NewName[target_list[i]], MAX_NAME_LENGTH, "%s", arg2);
			}
			PerformRename(client, target_list[i]);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

RandomizeName(client)
{
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	new len = strlen(name);
	g_NewName[client][0] = '\0';

	for (new i = 0; i < len; i++)
	{
		g_NewName[client][i] = name[GetRandomInt(0, len - 1)];
	}
	g_NewName[client][len] = '\0';
}

PerformRename(client, target)
{
	LogAction(client, target, "\"%L\" renamed \"%L\" to \"%s\")", client, target, g_NewName[target]);

	/* Used on OB / L4D engine */
	if (g_ModVersion > SOURCE_SDK_EPISODE1)
	{
		SetClientInfo(target, "name", g_NewName[target]);
	}
	else /* Used on CSS and EP1 / older engine */
	{
		if (!IsPlayerAlive(target)) /* Lets tell them about the player renamed on the next round since they're dead. */
		{
			decl String:m_TargetName[MAX_NAME_LENGTH];

			GetClientName(target, m_TargetName, sizeof(m_TargetName));
			ReplyToCommand(client, "\x04[SourceMod]\x03 %t", "Dead Player Rename", m_TargetName);
		}
		ClientCommand(target, "name %s", g_NewName[target]);
	}
}

public Action:OnChangePlayerName(client, String:name[], String:oldname[])
{
	if(StrEqual, name, g_NewName[client][0])
	{
		g_NewName[client][0] = '\0';
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}