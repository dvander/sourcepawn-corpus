#include <sourcemod>

#define PLUGIN_VERSION "1.1.1"

public Plugin:myinfo = 
{
	
	name = "[TF2] Sentry Immunity",
	
	author = "Tylerst",

	description = "Set Sentry Immunity on a target(s)",

	version = PLUGIN_VERSION,
	
	url = "None"

};
new Handle:hChat = INVALID_HANDLE;
new Handle:hLog = INVALID_HANDLE;
new Handle:hImmunityAll = INVALID_HANDLE;
new Immunity[MAXPLAYERS+1] = 0;

public OnPluginStart()
{
	TF2only();
	LoadTranslations("common.phrases");
	CreateConVar("sm_sentryimmunity_version", PLUGIN_VERSION, "Set Sentry Immunity on a target(s), Usage: sm_sentryimmunity <target> <0/1>", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hChat = CreateConVar("sm_sentryimmunity_chat", "1", "Enable/Disable(1/0) Showing Sentry Immunity changes in chat", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hLog = CreateConVar("sm_sentryimmunity_log", "1", "Enable/Disable(1/0) Logging of Sentry Immunity changes", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hImmunityAll = CreateConVar("sm_sentryimmunity_all", "0", "Enable/Disable(1/0) Sentry Immunity for everyone", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookEvent("player_spawn", PSpawn)
	RegAdminCmd("sm_sentryimmunity", Command_SImmunity, ADMFLAG_SLAY, "Set Sentry Immunity on a target(s)");
	HookConVarChange(hImmunityAll, SIA_Change);
}

public OnClientPutInServer(client)
{
	Immunity[client] = 0;
	if(GetConVarBool(hImmunityAll))
	{
		Immunity[client] = 1;	
	}
}

public OnClientDisconnect_Post(client)
{
	Immunity[client] = 0;
}



public Action:Command_SImmunity(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "Usage: sm_sentryimmunity <target> <0/1>");
		return Plugin_Handled;	
	}
	new String:SItarget[32], String:SIflag[5];
	GetCmdArg(1, SItarget, sizeof(SItarget));
	GetCmdArg(2, SIflag, sizeof(SIflag));
	new onoff = StringToInt(SIflag);
	if(onoff != 0 && onoff != 1)
	{
		ReplyToCommand(client, "Usage: sm_sentryimmunity <target> <0/1>");
		return Plugin_Handled;
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;		
	if ((target_count = ProcessTargetString(
			SItarget,
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

		if(onoff == 0 && Immunity[target_list[i]] == 1)
		{
			new flags = GetEntityFlags(target_list[i])&~FL_NOTARGET;
			SetEntityFlags(target_list[i], flags);
			Immunity[target_list[i]] = 0;
			if(GetConVarBool(hLog))
			{
				LogAction(client, target_list[i], "\"%L\" removed Sentry Immunity from \"%L\" Sentry Immunity", client, target_list[i]);	
			}
		}
		if(onoff == 1 && Immunity[target_list[i]] == 0)
		{
			new flags = GetEntityFlags(target_list[i])|FL_NOTARGET;
			SetEntityFlags(target_list[i], flags);
			Immunity[target_list[i]] = 1;
			if(GetConVarBool(hLog))
			{
				LogAction(client, target_list[i], "\"%L\" gave Sentry Immunity to \"%L\"", client, target_list[i]);	
			}
		}
	}
	if(GetConVarBool(hChat))
	{
		new String:Sonoff[5];
		if(onoff == 0) Sonoff = "Off"
		if(onoff == 1) Sonoff = "On"		
		ShowActivity2(client, "[SM] ","Set Sentry Immunity of %s %s", target_name, Sonoff);
	}
	return Plugin_Handled;
}

public Action:PSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (client > 0 && IsClientConnected(client)) 
	{
		if(GetConVarBool(hImmunityAll))
		{
			Immunity[client] = 1;	
		}
		if(Immunity[client] == 1)
		{
			new flags = GetEntityFlags(client)|FL_NOTARGET;
			SetEntityFlags(client, flags);
		}
	}
	return Plugin_Continue;
}

public SIA_Change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new oldint = StringToInt(oldValue);
	new newint = StringToInt(newValue);

	if (newint == 1 && oldint == 0)

	{	
		for (new i = 1; i < MaxClients; i++)

		{
			if(IsClientInGame(i) && IsValidEntity(i))
			{
				new flags = GetEntityFlags(i)|FL_NOTARGET;
				SetEntityFlags(i, flags);
				Immunity[i] = 1;
			}		
		}
		if(GetConVarBool(hChat))
		{
			PrintToChatAll("\x04[SM] \x01Sentry Immunity for everyone enabled");
		}		 
	}
	if (newint == 0 && oldint == 1)

	{	
		for (new i = 1; i < MaxClients; i++)

		{
			if(IsClientInGame(i) && IsValidEntity(i))
			{
				new flags = GetEntityFlags(i)&~FL_NOTARGET;
				SetEntityFlags(i, flags);
				Immunity[i] = 0;
			}		
		}
		if(GetConVarBool(hChat))
		{
			PrintToChatAll("\x04[SM] \x01Sentry Immunity for everyone disabled");
		}
	}

}

TF2only()
{
	new String:Game[10];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		SetFailState("This plugin only works for Team Fortress 2");
	}
}