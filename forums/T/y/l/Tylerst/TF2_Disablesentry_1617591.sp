#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "TF2 DisableSentry",
	author = "Tylerst",
	description = "Disable target(s) sentrygun",
	version = PLUGIN_VERSION,
	url = "none"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

new bool:SentryDisabled[MAXPLAYERS+1] = false;

public OnPluginStart()
{	
	RegAdminCmd("sm_disablesentry", Command_DisableSentry, ADMFLAG_SLAY, "Disable target(s) sentrygun Usage: sm_disablesentry \"target\" \"1/0\"");	
	LoadTranslations("common.phrases");
}

public OnClientPutInServer(client)
{
	SentryDisabled[client] = false;
}
public OnClientDisconnect_Post(client)
{
	SentryDisabled[client] = false;
}

public Action:Command_DisableSentry(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_disablesentry \"target\" \"1/0\"");
		return Plugin_Handled;
	}

	new String:disabletarget[32], String:strdisable[32], disable;

	GetCmdArg(1, disabletarget, sizeof(disabletarget));
	GetCmdArg(2, strdisable, sizeof(strdisable));
	disable = StringToInt(strdisable);

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			disabletarget,
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

	for (new i = 0; i < target_count; i++)
	{
		if(disable)
		{
			SentryDisabled[target_list[i]] = true;
		}
		else
		{
			SentryDisabled[target_list[i]] = false;	
			ToggleSentry(target_list[i], true);
		}
	}
	return Plugin_Handled;
}

public OnGameFrame()
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(SentryDisabled[i])
		{
			ToggleSentry(i, false);
		}
	}
}

public ToggleSentry(client, bool:enable)
{
	new sentrygun = -1; 
	while ((sentrygun = FindEntityByClassname(sentrygun, "obj_sentrygun"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(sentrygun) && GetEntPropEnt(sentrygun, Prop_Send, "m_hBuilder") == client)
		{
			if(enable) SetEntProp(sentrygun, Prop_Send, "m_bDisabled", false);
			else SetEntProp(sentrygun, Prop_Send, "m_bDisabled", true);
		}
	}
}