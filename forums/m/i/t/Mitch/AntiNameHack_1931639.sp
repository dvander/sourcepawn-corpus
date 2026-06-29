#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <sourcebans>
#define PLUGIN_VERSION "1.1"
new bool:g_bSBAvailable = false;
new clientnamematch[MAXPLAYERS+1] = 0;
new clientnamechange[MAXPLAYERS+1] = 0;
new bool:clienthaschanged[MAXPLAYERS+1] = false;
new Handle:CvarChanges = INVALID_HANDLE;
new MaxNameChanges = 10;
new Handle:CvarMatches = INVALID_HANDLE;
new MaxNameMatches = 4;
public Plugin:myinfo = 
{
	name = "[TF2] AntiNameHack",
	author = "Mitch",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}
public OnAllPluginsLoaded() 
{	
	if (LibraryExists("sourcebans"))
		g_bSBAvailable = true;
}
public OnLibraryAdded(const String:name[]) 
{
	if (StrEqual(name, "sourcebans"))
		g_bSBAvailable = true;
}
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
		g_bSBAvailable = false;
}
public OnPluginStart()
{
	CreateConVar("sm_anh_version", PLUGIN_VERSION, "AntiNameHack Version", FCVAR_PLUGIN|FCVAR_NOTIFY);
	CvarChanges = CreateConVar("sm_anh_changes", "10", "Number of name changes before a player is banned. default is 10", FCVAR_PLUGIN);
	CvarMatches = CreateConVar("sm_anh_matches", "4", "Number of name matches before a player is banned. default is 4", FCVAR_PLUGIN);
	HookConVarChange(CvarChanges, OnCvarChanged);
	HookConVarChange(CvarMatches, OnCvarChanged);
	HookEvent("player_changename", OnChange, EventHookMode_Post);
	CreateTimer(300.0, NameCheckClear);
}
public OnCvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == CvarChanges)
	{
		MaxNameChanges = StringToInt(newVal);
	}
	else if(cvar == CvarMatches)
	{
		MaxNameMatches = StringToInt(newVal);
	}
}
public Action:NameCheckClear(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && clienthaschanged[i] == false)
		{
			clientnamematch[i] = 0;
		}
		clienthaschanged[i] = false;
		clientnamechange[i] = 0;
	}
}
public OnClientPutInServer(client)
{
	clientnamematch[client] = 0;
	clientnamechange[client] = 0;
	clienthaschanged[client] = false;
}
public OnClientDisconnect(client)
{
	clientnamematch[client] = 0;
	clientnamechange[client] = 0;
	clienthaschanged[client] = false;
}
public Action:OnChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		clienthaschanged[client] = true;
		clientnamechange[client]++;
		//decl String:oldName[MAX_NAME_LENGTH];
		//GetEventString(event, "newname", oldName, sizeof(oldName));
		//LogMessage("%L Has changed name to \"%s\"",  client, oldName);
		NameStealCheck(client);
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			if(clientnamechange[client] >= MaxNameChanges)
			{
				if(g_bSBAvailable)
				{
					decl String:reason[128];
					Format(reason, sizeof(reason), "[Auto]Detected Namehacking #1-%i-%i", clientnamechange[client], clientnamematch[client]);
					SBBanPlayer(0, client, 0, reason);
				}
				else
				{
					BanClient(client, 0, BANFLAG_AUTHID, "[Auto]Detected Namehacking #1", "[Auto]Detected Namehacking #1", "Anti-NameHack");
				}
			}
		}
	}
}
NameStealCheck(client)
{
	decl String:Name[MAX_NAME_LENGTH];
	decl String:iName[MAX_NAME_LENGTH];
	GetClientName(client, Name, sizeof(Name));
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && client != i)
		{
			GetClientName(i, iName, sizeof(iName));
			if((StrContains(iName, " ", false) != -1))
			{
				decl String:NameCopy[MAX_NAME_LENGTH];
				Format(NameCopy, MAX_NAME_LENGTH, "%s", Name);
				ReplaceString(NameCopy, MAX_NAME_LENGTH, "\xC2\xA0", " ", false);
				
				decl String:iNameCopy[MAX_NAME_LENGTH];
				Format(iNameCopy, MAX_NAME_LENGTH, "%s", iName);
				
				if(StrEqual(NameCopy, iNameCopy, true))
				{
					clientnamematch[client]++;
					LogMessage("%L was detected using %L's name. %i, type 2-1",  client, i, clientnamematch[client]);
					if(clientnamematch[client] >= MaxNameMatches)
					{
						decl String:clientip[17];
						GetClientIP(client, clientip, sizeof(clientip), true);
						if(g_bSBAvailable)
						{
							decl String:reason[128];
							Format(reason, sizeof(reason), "[Auto]Detected Namehacking #2-%i-%i", clientnamechange[client], clientnamematch[client]);
							SBBanPlayer(0, client, 0, reason);
							ServerCommand("sm_banip %s 0 [Auto]Detected Namehacking #2", clientip); 
						}
						else
						{
							BanClient(client, 0, BANFLAG_AUTHID, "[Auto]Detected Namehacking #2", "[Auto]Detected Namehacking #2", "Anti-NameHack");
							ServerCommand("sm_banip %s 0 [Auto]Detected Namehacking #2", clientip);
						}
					}
				}
			}
		
			if(StrContains(Name, iName, false) != -1)
			{
				clientnamematch[client]++;
				LogMessage("%L was detected using %L's name. %i, type 2-2",  client, i, clientnamematch[client]);
				if(clientnamematch[client] >= MaxNameMatches)
				{
					decl String:clientip[17];
					GetClientIP(client, clientip, sizeof(clientip), true);
					if(g_bSBAvailable)
					{
						decl String:reason[128];
						Format(reason, sizeof(reason), "[Auto]Detected Namehacking #2-%i-%i", clientnamechange[client], clientnamematch[client]);
						SBBanPlayer(0, client, 0, reason);
						ServerCommand("sm_banip %s 0 [Auto]Detected Namehacking #2", clientip); 
					}
					else
					{
						BanClient(client, 0, BANFLAG_AUTHID, "[Auto]Detected Namehacking #2", "[Auto]Detected Namehacking #2", "Anti-NameHack");
						ServerCommand("sm_banip %s 0 [Auto]Detected Namehacking #2", clientip);
					}
				}
			}
		}
	}
}