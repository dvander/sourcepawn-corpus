#include <sdktools>

#define PLUGIN_VERSION "1.0.2"

#define MAXCHARS 500

new String:g_Filename[PLATFORM_MAX_PATH];

new CountChars;
enum CharEnum
{
	String:Char1[5],
	String:Char2[5],
};
new CharRepl[MAXCHARS+1][CharEnum];


public Plugin:myinfo =
{
	name = "Replace Characters",
	author = "Mitchell",
	description = "Changes characters in the name to preset in a config.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1844120"
}


public OnPluginStart()
{
	CreateConVar("sm_replacecharacters_version", PLUGIN_VERSION, "Replace Characters version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	BuildPath(Path_SM, g_Filename, sizeof(g_Filename), "configs/charconfig.cfg");
	RegAdminCmd("sm_reloadchar", Command_ReloadConfig, ADMFLAG_CONFIG, "Reloads Character Replacer's config file");
}

public Action:Command_ReloadConfig(client, args) {
	
	InitiateConfig();
	LogAction(client, -1, "Reloaded Replace Characters config file");
	ReplyToCommand(client, "[STC] Replace Character's config file.");
	return Plugin_Handled;
}
public OnMapStart()
{
	InitiateConfig();
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			FindCharsInName(i);
}

stock InitiateConfig()
{
	for(new i=0;i<MAXCHARS;i++)
	{
		Format(CharRepl[i][Char1], 5, "");
		Format(CharRepl[i][Char2], 5, "");
	}
	new Handle:kvs = CreateKeyValues("CharConfig");
	FileToKeyValues(kvs, g_Filename);
	KvGotoFirstSubKey(kvs);
	CountChars = 0;
	new String:sBuffer[10];
	do
	{
		KvGetSectionName(kvs, sBuffer, sizeof(sBuffer));
		if(StrEqual(sBuffer,"quote",false))
			Format(CharRepl[CountChars][Char1], 5, "\"");
		else Format(CharRepl[CountChars][Char1], 5, "%s", sBuffer);
		if(!StrEqual(CharRepl[CountChars][Char1],"",false))
		{
			KvGetString(kvs,"replace", CharRepl[CountChars][Char2], 5);
			CountChars++;
		}
	} while (KvGotoNextKey(kvs))
	CloseHandle(kvs);	
}
FindCharsInName(client)
{
	if((1<=client<=MaxClients) && IsClientInGame(client))
	{
		new String:sName[32];
		new String:sNewName[32];
		GetClientName(client,sName,sizeof(sName));
		GetClientName(client,sNewName,sizeof(sNewName));
		new bool:bNameChanged = false;
		for(new i=0;i<CountChars;i++)
		{
			if(StrContains(sName,CharRepl[i][Char1])!=-1)
			{
				ReplaceString(sNewName, sizeof(sNewName), CharRepl[i][Char1], CharRepl[i][Char2]);
				bNameChanged = true;
			}
		}
		if(bNameChanged)
		{
			//PrintToChatAll("Found Invalid Characters in Name: %s\nNew Name: %s", sName, sNewName);
			CS_SetClientName(client, sNewName);
		}
	}
}

public OnClientPutInServer(client)
	FindCharsInName(client);

public OnClientSettingsChanged(client)
	FindCharsInName(client);


stock CS_SetClientName(client, const String:name[])
{
    decl String:oldname[MAX_NAME_LENGTH];
    GetClientName(client, oldname, sizeof(oldname));

    SetClientInfo(client, "name", name);
    SetEntPropString(client, Prop_Data, "m_szNetname", name);

    new Handle:event = CreateEvent("player_changename");

    if (event != INVALID_HANDLE)
    {
        SetEventInt(event, "userid", GetClientUserId(client));
        SetEventString(event, "oldname", oldname);
        SetEventString(event, "newname", name);
        FireEvent(event);
    }
}