#undef REQUIRE_PLUGIN
#include <sourceirc>
#include <basecomm>

#pragma semicolon 1
#pragma tabsize 0


public Plugin:myinfo = {
	name = "SourceIRC -> Silence",
	author = "RogueDarkJedi",
	description = "Adds silence command to SourceIRC",
	version = IRC_VERSION,
	url = "http://roguedarkjedi.com"
};

public OnPluginStart() {	
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.basecommands");
}

public OnAllPluginsLoaded() {
	if (LibraryExists("sourceirc"))
		IRC_Loaded();
}

public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "sourceirc"))
		IRC_Loaded();
}

IRC_Loaded() {
	IRC_CleanUp(); // Call IRC_CleanUp as this function can be called more than once.
	IRC_RegAdminCmd("silence", Command_Silence, ADMFLAG_KICK, "silence <#userid|name> - Prohibits player from talking");
  IRC_RegAdminCmd("unsilence", Command_Unsilence, ADMFLAG_KICK, "unsilence <#userid|name> - Allows player to talk again.");
}

stock processSilence(const String:nick[], bool:silence, args)
{
  decl String:Arguments[256];
	IRC_GetCmdArgString(Arguments, sizeof(Arguments));

	decl String:arg[65];
	new len = BreakString(Arguments, arg, sizeof(arg));
	
	if (len == -1)
	{
		/* Safely null terminate */
		len = 0;
		Arguments[0] = '\0';
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			0, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		if (tn_is_ml)
    {
      if(silence)
        IRC_ReplyToCommand(nick, "silenced %N.", target_list[0]);
      else
        IRC_ReplyToCommand(nick, "unsilenced %N.", target_list[0]);
    }
		else
    {
      if(silence)
        IRC_ReplyToCommand(nick, "silenced %N.", target_list[0]);
      else
        IRC_ReplyToCommand(nick, "unsilenced %N.", target_list[0]);
		}
		for (new i = 0; i < target_count; i++)
		{
      if(silence == true)
        SilenceClient(target_list[i]);
      else
        UnsilenceClient(target_list[i]);
		}
	}
	else
	{
		IRC_ReplyToTargetError(nick, target_count);
	}
}
public Action:Command_Silence(const String:nick[], args) {

	if (args < 1)
	{
		IRC_ReplyToCommand(nick, "Usage: silence <#userid|name>");
		return Plugin_Handled;
	}
  processSilence(nick, true, args);
  
	return Plugin_Handled;
}


public Action:Command_Unsilence(const String:nick[], args) {
	if (args < 1)
	{
		IRC_ReplyToCommand(nick, "Usage: unsilence <#userid|name>");
		return Plugin_Handled;
	}
  processSilence(nick, false, args);

	return Plugin_Handled;
}

stock SilenceClient(target)
{
	BaseComm_SetClientGag(target, true);
  BaseComm_SetClientMute(target, true);
}

stock UnsilenceClient(target)
{
	BaseComm_SetClientGag(target, false);
  BaseComm_SetClientMute(target, false);
}

public OnPluginEnd() {
	IRC_CleanUp();
}
