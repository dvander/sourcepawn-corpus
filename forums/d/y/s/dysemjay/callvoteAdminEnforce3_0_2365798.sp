/**
 * SourceMod admin immunity is not automatically enforced for callvoting commands in Dystopia.
 * It is possible for a regular player to use the callvote commands against an administrator
 * which could result in them being banned from their own server.
*/

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Callvote Command Admin Immunity",
	author = "emjay",
	description = "Enforces admin immunity on callvote commands.",
	version = "3.0",
	url = "https://forums.alliedmods.net/showthread.php?t=275167"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	/* Hook the callvote command. */
	AddCommandListener(Command_Callvote, "callvote");
}

public Action Command_Callvote(int client, const char[] command, int argc)
{
	/* Allow command to continue normally if there is no vote specified (simply typing callvote into console). */
	if(argc < 2)
	{
		return Plugin_Continue;
	}
	
	char subject[10];
	GetCmdArg(1, subject, sizeof(subject));

	if( StrEqual(subject, "kick", false) ||
	    StrEqual(subject, "ban", false) || 
	    StrEqual(subject, "forcespec", false) || 
	    StrEqual(subject, "kickid", false) || 
	    StrEqual(subject, "banid", false) )
	{
		char name[MAX_NAME_LENGTH + 1];
		GetCmdArg( 2, name, sizeof(name) );
		
		/* Include '#' at beginning of the name string, in case a userid is entered. */
		Format(name, sizeof(name), "#%s", name);
		int target = FindTarget(client, name, false, false);

		if(target == -1)
		{
			return Plugin_Continue;
		}

		AdminId ClientAdmin = GetUserAdmin(client);
		AdminId TargetAdmin = GetUserAdmin(target);	

		if( (ClientAdmin == INVALID_ADMIN_ID && TargetAdmin == INVALID_ADMIN_ID) || 
		    CanAdminTarget(ClientAdmin, TargetAdmin) )
		{
			return Plugin_Continue;
		}
		else
		{
			ReplyToCommand(client, "[SM] You may not start this vote against players with higher SourceMod admin immunity than your own.");
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}