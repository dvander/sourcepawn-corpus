#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "MuteAllButAdmins",
	author = "Stds! Gotta Catchem All",
	description = "Mutes all players without admin flags",
	version = PLUGIN_VERSION,
	url = "http://www.gflclan.com"
}

public OnPluginStart()
{
    CreateConVar("sm_mutenonadmins_version", PLUGIN_VERSION, "MuteNonAdmin's version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	
    RegAdminCmd("sm_mutenonadmins", Command_MuteNonAdmins, ADMFLAG_GENERIC, "Mute Non-Admins");
    RegAdminCmd("sm_mna", Command_MuteNonAdmins, ADMFLAG_GENERIC, "Mute Non-Admins");
    RegAdminCmd("sm_unmutenonadmins", Command_UnmuteNonAdmins, ADMFLAG_GENERIC, "Mute Non-Admins");
    RegAdminCmd("sm_umna", Command_UnmuteNonAdmins, ADMFLAG_GENERIC, "Mute Non-Admins");
}

public Action:Command_MuteNonAdmins(client, args)
{
	///////////////////////////////////////////////////////
	//Test The arguments to make sure it is a valid command
	///////////////////////////////////////////////////////
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_mutenonadmins <@dead or @alive or @all>");
		return Plugin_Handled;	
	}
	new caseNum;
	new String:szArg[65];
	
	GetCmdArg(1, szArg, sizeof(szArg));
	
	/////////////////////////////////////////////////
	//Set the appropriate case based on the arguments
	/////////////////////////////////////////////////
	if(strcmp(szArg, "@dead", false) == 0)
		caseNum=0;
	else if(strcmp(szArg, "@alive", false) == 0)
		caseNum=1;
	else if(strcmp(szArg, "@all", false) == 0)
		caseNum=2;
	else 
		caseNum=3;
	
	/////////////////////////
	//Perform the actual task
	/////////////////////////
	switch(caseNum)
	{
		case 0: 
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i))
				{
					if (!CheckCommandAccess(i, "sm_mutenonadmins", ADMFLAG_GENERIC))
					{
						SetClientListeningFlags(i, VOICE_MUTED);
					}  			
				}
			}
			ShowActivity2(client, "[SM]", "%N muted dead non-admins", client);
		}
		case 1:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
				{
					if (!CheckCommandAccess(i, "sm_mutenonadmins", ADMFLAG_GENERIC))
					{
						SetClientListeningFlags(i, VOICE_MUTED);
					}  			
				}
			}
			ShowActivity2(client, "[SM]", "%N muted alive non-admins", client);
		}
		case 2:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					if (!CheckCommandAccess(i, "sm_mutenonadmins", ADMFLAG_GENERIC))
					{
						SetClientListeningFlags(i, VOICE_MUTED);
					}  			
				}
			}
			ShowActivity2(client, "[SM]", "%N muted all non-admins", client);
		}
		case 3: ReplyToCommand(client, "[SM] Usage: sm_mutenonadmins <@dead or @alive or @all>"); 
	}
	return Plugin_Handled;
}

public Action:Command_UnmuteNonAdmins(client, args)
{
	///////////////////////////////////////////////////////
	//Test The arguments to make sure it is a valid command
	///////////////////////////////////////////////////////
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unmutenonadmins <@dead or @alive or @all>");
		return Plugin_Handled;	
	}
	
	new caseNum;
	new String:szArg[65];
	
	GetCmdArg(1, szArg, sizeof(szArg));
	
	/////////////////////////////////////////////////
	//Set the appropriate case based on the arguments
	/////////////////////////////////////////////////
	if(strcmp(szArg, "@dead", false) == 0)
		caseNum=0;
	else if(strcmp(szArg, "@alive", false) == 0)
		caseNum=1;
	else if(strcmp(szArg, "@all", false) == 0)
		caseNum=2;
	else 
		caseNum=3;
	
	/////////////////////////
	//Perform the actual task
	/////////////////////////
	switch(caseNum)
	{
		case 0:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i))
				{
					if (!CheckCommandAccess(i, "sm_unmutenonadmins", ADMFLAG_GENERIC))
					{
						SetClientListeningFlags(i, VOICE_NORMAL);
					}  			
				}
			}
			ShowActivity2(client, "[SM]", "%N unmuted dead non-admins", client);
		}
		case 1:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
				{
					if (!CheckCommandAccess(i, "sm_unmutenonadmins", ADMFLAG_GENERIC))
					{
						SetClientListeningFlags(i, VOICE_NORMAL);
					}  			
				}
			}
			ShowActivity2(client, "[SM]", "%N unmuted alive non-admins", client);
		}
		case 2:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					if (!CheckCommandAccess(i, "sm_unmutenonadmins", ADMFLAG_GENERIC))
					{
						SetClientListeningFlags(i, VOICE_NORMAL);
					}  			
				}
			}
			ShowActivity2(client, "[SM]", "%N unmuted all non-admins", client);
		}
		case 3: ReplyToCommand(client, "[SM] Usage: sm_unmutenonadmins <@dead or @alive or @all>");
	}
	return Plugin_Handled;
}