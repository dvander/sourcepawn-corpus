new Handle:sv_downloadurl = INVALID_HANDLE;
new Handle:sm_fakedownloadurl_enabled = INVALID_HANDLE;
new bool:fakeURL_enabled;
new Handle:sm_fakedownloadurl = INVALID_HANDLE;
new String:fakeURL[100];

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Fake sv_downloadurl to players",
	author = "Bacardi",
	description = "Send fake sv_downloadurl \"URL\" to all players, they still download missing content from your real URL",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	if((sv_downloadurl = FindConVar("sv_downloadurl")) == INVALID_HANDLE)
	{
		SetFailState("Convar sv_downloadurl not found");
	}

	sm_fakedownloadurl = CreateConVar("sm_fakedownloadurl", "", "Fake dowload URL to players, text max 99 length", FCVAR_NONE);
	GetConVarString(sm_fakedownloadurl, fakeURL, sizeof(fakeURL));
	HookConVarChange(sm_fakedownloadurl, ConVarChange);

	sm_fakedownloadurl_enabled = CreateConVar("sm_fakedownloadurl_enabled", "1", "Enable/Disable Fake dowload URL to players", FCVAR_NONE, true, 0.0, true, 1.0);
	fakeURL_enabled = GetConVarBool(sm_fakedownloadurl_enabled);
	HookConVarChange(sm_fakedownloadurl_enabled, ConVarChange);

	CreateConVar("sm_fakedownloadurl_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVarString(sm_fakedownloadurl, fakeURL, sizeof(fakeURL));

	if(convar == sm_fakedownloadurl_enabled && StringToInt(oldValue) != StringToInt(newValue))
	{
		fakeURL_enabled = GetConVarBool(sm_fakedownloadurl_enabled);

		if(fakeURL_enabled)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					OnClientPutInServer(i);
				}
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if(fakeURL_enabled && !IsFakeClient(client))
	{
		SendConVarValue(client, sv_downloadurl, fakeURL);
	}
} 