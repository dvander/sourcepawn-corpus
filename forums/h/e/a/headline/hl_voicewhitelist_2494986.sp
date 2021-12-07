#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[ANY] Voice Whitelister",
	author = "Headline",
	description = "Prevents people from talking unless they have access",
	version = "1.0",
	url = "http://michaelwflaherty.com/"
}

public void OnClientPostAdminCheck(int client)
{
	if (!CheckCommandAccess(client, "", ADMFLAG_CUSTOM1, true))
	{
		SetClientListeningFlags(client, VOICE_MUTED);
	}
}

