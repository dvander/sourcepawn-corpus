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

	return Plugin_Handled;
}

public Action:Command_UnmuteNonAdmins(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (!CheckCommandAccess(i, "sm_mutenonadmins", ADMFLAG_GENERIC))
			{
				SetClientListeningFlags(i, VOICE_NORMAL);
			}  			
		}
	}

	ShowActivity2(client, "[SM]", "%N unmuted all non-admins", client);

	return Plugin_Handled;
}