#include <sourcemod>
#include <sdktools>
#include <attributes>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"


////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "tAttributes Mod, AdminCommands",
	author = "Thrawn",
	description = "Simple commands to set attributes etc",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	// C O M M A N D S //
	RegAdminCmd("sm_att_get", Command_GetPlayerInfos, ADMFLAG_KICK);
	RegAdminCmd("sm_att_set", Command_SetPlayerAttribute, ADMFLAG_KICK);
	RegAdminCmd("sm_att_list", Command_ShowList, ADMFLAG_KICK);
}

////////////////////
//C O M M A N D S //
////////////////////

public Action:Command_SetPlayerAttribute(client, args)
{
	if(!att_IsEnabled()) {
		ReplyToCommand(client, "[SM] Plugin tAttributes is disabled");
		return Plugin_Handled;
	}

	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_att_set <OPT:#id|name> <#attributeID|'all'> <value>");
		return Plugin_Handled;
	}

	if (args == 2) {
		new String:arg2[64];
		GetCmdArg(2, arg2, sizeof(arg2));
		new newLevel = StringToInt(arg2);

		new String:arg1[64];
		GetCmdArg(1, arg1, sizeof(arg1));

		if(strcmp(arg1, "all", false) == 0) {
			new count = att_GetAttributeCount();
			for(new i = 0; i < count; i++) {
				new aID = att_GetAttributeID(i);

				new String:aName[64];
				if(att_GetAttributeName(aID,aName)) {
					ReplyToCommand(client, "Your %s has been set to %i", aName, newLevel);
					att_SetClientAttributeValue(client, aID, newLevel);
				}
			}
		} else {
			new aID = StringToInt(arg1);

			new String:aName[64];
			if(att_GetAttributeName(aID,aName)) {
				ReplyToCommand(client, "Your %s has been set to %i", aName, newLevel);
				att_SetClientAttributeValue(client, aID, newLevel);
			}
		}

	} else if (args == 3) {
		decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));

		// Process the targets
		decl String:strTargetName[MAX_TARGET_LENGTH];
		decl TargetList[MAXPLAYERS], TargetCount;
		decl bool:TargetTranslate;

		if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
											   strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
		{
			ReplyToTargetError(client, TargetCount);
			return Plugin_Handled;
		}

		new String:arg3[64];
		GetCmdArg(3, arg3, sizeof(arg3));

		new newLevel = StringToInt(arg3);

		// Apply to all targets
		for (new i = 0; i < TargetCount; i++)
		{
			if (!IsClientConnected(TargetList[i])) continue;
			if (!IsClientInGame(TargetList[i]))    continue;

			new String:arg2[64];
			GetCmdArg(2, arg2, sizeof(arg2));

			if(strcmp(arg2, "all", false) == 0) {
				new count = att_GetAttributeCount();
				for(new j = 0; j < count; i++) {
					new aID = att_GetAttributeID(j);

					new String:aName[64];
					if(att_GetAttributeName(aID,aName)) {
						ReplyToCommand(client, "Your %s has been set to %i", aName, newLevel);
						att_SetClientAttributeValue(client, aID, newLevel);
					}
				}
			} else {
				new aID = StringToInt(arg2);

				new String:aName[64];
				if(att_GetAttributeName(aID,aName)) {
					ReplyToCommand(client, "Your %s has been set to %i", aName, newLevel);
					att_SetClientAttributeValue(client, aID, newLevel);
				}
			}
		}
	}

	return Plugin_Handled;
}



public Action:Command_GetPlayerInfos(client, args)
{
	if(!att_IsEnabled()) {
		ReplyToCommand(client, "[SM] Plugin tAttributes is disabled");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_att_get <#id|name>");
		return Plugin_Handled;
	}

	new count = att_GetAttributeCount();
	if (count < 1)
	{
		ReplyToCommand(client, "No attributes registered!");
		return Plugin_Handled;
	}

	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));

	// Process the targets
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl TargetList[MAXPLAYERS], TargetCount;
	decl bool:TargetTranslate;

	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
										   strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
	{
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}

	// Apply to all targets
	for (new j = 0; j < TargetCount; j++)
	{
		new target = TargetList[j];
		if (!IsClientConnected(target)) continue;
		if (!IsClientInGame(target))    continue;

		ReplyToCommand(client, "Player %N has:", target);

		for(new i = 0; i < count; i++) {
			new aID = att_GetAttributeID(i);

			new String:aName[64];
			if(att_GetAttributeName(aID,aName)) {
				ReplyToCommand(client, "%s: %i", aName, att_GetClientAttributeValue(target, aID));
			}
		}
		ReplyToCommand(client, "---");
	}

	return Plugin_Handled;
}

public Action:Command_ShowList(client, args)
{
	if(!att_IsEnabled()) {
		ReplyToCommand(client, "[SM] Plugin tAttributes is disabled");
		return Plugin_Handled;
	}

	new count = att_GetAttributeCount();
	for(new i = 0; i < count; i++) {
		new aID = att_GetAttributeID(i);

		new String:aName[64];
		att_GetAttributeName(aID,aName);

		ReplyToCommand(client, "%i: %s", aID, aName);
	}

	return Plugin_Handled;
}