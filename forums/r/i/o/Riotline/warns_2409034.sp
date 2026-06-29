#include <sourcemod>
#include <morecolors>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "[ANY] Warnings",
	author = "Astrak, Riotline",
	description = "Publicly humiliate and warn a player for f**king up.",
	version = PLUGIN_VERSION,
	url = "http://riotline-is-a-dick-mucher.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_warn", Command_Warn, ADMFLAG_KICK, "sm_warn <#userid|name> <reason> [SLAY|KICK|SLAP] - Warn a player for being very dumb.");
	CreateConVar("warn_version", PLUGIN_VERSION, "Plugin Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:Command_Warn(client,args)
{
	//If the client doesn't enter at least 2 arguments after sm_warn, tell them how they fucked up.
	if(args<2)
	{
		if(IsValidClient(client))
		{
			PrintToChat(client, "[SM] Usage: sm_warn <#userid|name> <reason> [SLAY|KICK|SLAP]");
			return Plugin_Handled;
		}
	}

	//String creation. The maxlengths are a bit wonky but they should be fine for a small plugin like this.
	new String:reason[256];
	new String:punishment[128];
	
	//Targeting shit. Probably redundant now but I'm an old fucking and can't be arsed changing my ways. Fix it if you want but it should work fine.
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	GetCmdArg(1, buffer, sizeof(buffer));
	
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
			ReplyToTargetError(client, target_count)
			return Plugin_Handled;
	}
	
	GetCmdArg(2, reason, sizeof(reason));

	//If the client only uses two arguments (not providing a punishment) then just show the warning.	
	if(args==2)
	{
		CPrintToChatAll("{fullred}[{red}WARN{fullred}] {white}%s {community}has been warned for {white}%s{community}.", target_name, reason);
	}
	
	//If the client uses at least 3 arguments (should be exactly 3 but whatever) then use all the fuckery below to try and formulate a punishment.
	//Feel free to change any of the text down there. I haven't done any colours by default but you can choose your own.
	if(args>=3)
	{
		GetCmdArg(3, punishment, sizeof(punishment));
		
		if(StrEqual(punishment, "slay", false))
		{
			CPrintToChatAll("{fullred}[{red}WARN{fullred}] {white}%s {community}has been warned for {white}%s{community} and has been brutally slain.", target_name, reason);
			ServerCommand("sm_slay %s", buffer);
		}
		else if(StrEqual(punishment, "slap", false))
		{
			CPrintToChatAll("{fullred}[{red}WARN{fullred}] {white}%s {community}has been warned for {white}%s{community} and has been angrily slapped.", target_name, reason);
			ServerCommand("sm_slap %s", buffer);
		}
		else if(StrEqual(punishment, "kick", false))
		{
			CPrintToChatAll("{fullred}[{red}WARN{fullred}] {white}%s {community}has been warned for {white}%s{community} and has received a boot up his ass.", target_name, reason);
			ServerCommand("sm_kick %s %s", buffer, reason);
		}
		else
		{
			CPrintToChatAll("{fullred}[{red}WARN{red}] {white}%s {community}has been warned for {white}%s{community} and null", target_name, reason);
		}
	}

	//Tell the server to stop listening for more things to do.
	return Plugin_Handled;
}

//Check that there is actually a target for the command and that they're not a bot.
public bool:IsValidClient(client)
{
	if(IsClientInGame(client) && (!IsFakeClient(client)))
	{
		return true;
	}
	else
	{
		return false;
	}
}