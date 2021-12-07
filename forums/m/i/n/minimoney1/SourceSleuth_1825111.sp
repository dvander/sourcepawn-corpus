#pragma semicolon 1
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <sourcebans>

#define PLUGIN_VERSION "1.0.0"

//- Handles -//
new Handle:hDatabase = INVALID_HANDLE;
new Handle:g_cVar_actions = INVALID_HANDLE;
new Handle:g_cVar_banduration = INVALID_HANDLE;
new Handle:g_cVar_sbprefix = INVALID_HANDLE;

//- Bools -//
new bool:CanUseSourcebans = false;

public Plugin:myinfo = 
{
	name	= "SourceSleuth",
	author	= "ecca",
	description= "Useful for TF2 servers. Plugin will check for banned ips and ban the player.",
	version	= PLUGIN_VERSION,
	url		= "http://sourcemod.net"
};

public OnPluginStart()
{
	LoadTranslations("sourcesleuth.phrases");
	
	CreateConVar("sm_sourcesleuth_version", PLUGIN_VERSION, "SourceSleuth plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cVar_actions = CreateConVar("sm_sleuth_actions", "3", "Sleuth Ban Type: 1 - Original Length, 2 - Custom Length, 3 - Double Length, 4 - Notify Admins Only", FCVAR_PLUGIN, true, 1.0, true, 4.0);
	g_cVar_banduration = CreateConVar("sm_sleuth_duration", "0", "Required: sm_sleuth_actions 1: Bantime to ban player if we got a match (0 = permanent (defined in minutes) )", FCVAR_PLUGIN);
	g_cVar_sbprefix = CreateConVar("sm_sleuth_prefix", "sb", "Prexfix for sourcebans tables: Default sb", FCVAR_PLUGIN);
	
	AutoExecConfig(true, "Sm_SourceSleuth");

	SQL_TConnect(SQL_OnConnect, "sourcebans");

}

public OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans"))
	{
		CanUseSourcebans = true;
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual("sourcebans", name))
	{
		CanUseSourcebans = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual("sourcebans", name))
	{
		CanUseSourcebans = false;
	}
}

public SQL_OnConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SourceSleuth: Database connection error: %s", error);
	} 
	else 
	{
		hDatabase = hndl; 
	}
}

public OnClientPostAdminCheck(client)
{
	if(CanUseSourcebans && !IsFakeClient(client))
	{
		new String:IP[32], String:steamid[32], String:Prefix[64];
		GetClientAuthString(client, steamid, sizeof(steamid));
		GetClientIP(client, IP, sizeof(IP));
		GetConVarString(g_cVar_sbprefix, Prefix, sizeof(Prefix));
		
		new String:query[255];
		FormatEx(query, sizeof(query),  "SELECT * FROM %s_bans WHERE ip='%s' AND RemovedBy IS NULL AND  RemoveType IS NULL AND  RemovedOn IS NULL AND  ureason IS NULL", Prefix, IP);
		
		new Handle:datapack = CreateDataPack();

		WritePackCell(datapack, GetClientUserId(client));
		WritePackString(datapack, steamid);
		WritePackString(datapack, IP);
		ResetPack(datapack);
		
		SQL_TQuery(hDatabase, SQL_CheckHim, query, datapack);
	}
}

public SQL_CheckHim(Handle:owner, Handle:hndl, const String:error[], any:datapack)
{
	new client;
	new String:steamid[32], String:IP[32], String:Reason[255], String:text[255];
	
	if(datapack != INVALID_HANDLE)
	{
		client = GetClientOfUserId(ReadPackCell(datapack));
		ReadPackString(datapack, steamid, sizeof(steamid));
		ReadPackString(datapack, IP, sizeof(IP));
		CloseHandle(datapack); 
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("MAC: Query error: %s", error);
	}
	
	if (SQL_FetchRow(hndl))
	{
		switch (GetConVarInt(g_cVar_actions))
		{
			case 1:
			{
				new length = SQL_FetchInt(hndl, 6);
				new time = length*60;
				
				Format(Reason, sizeof(Reason), "[SourceSleuth] %t", "sourcesleuth_banreason");
				
				SBBanPlayer(0, client, time, Reason);
			}
			case 2:
			{
				new time = GetConVarInt(g_cVar_banduration);

				Format(Reason, sizeof(Reason), "[SourceSleuth] %t", "sourcesleuth_banreason");
				
				SBBanPlayer(0, client, time, Reason);
			}
			case 3:
			{
				new length = SQL_FetchInt(hndl, 6);
				new time = length/60*2;

				Format(Reason, sizeof(Reason), "[SourceSleuth] %t", "sourcesleuth_banreason");
				
				SBBanPlayer(0, client, time, Reason);
			}
			case 4:
			{
				Format(text, sizeof(text), "[SourceSleuth] %t", "sourcesleuth_admintext",client, steamid, IP);
				PrintToAdmins("%s", text);
			}
		}
	}
}

PrintToAdmins(const String:format[], any:...)
{
	new String:g_Buffer[256];
	
	for (new i=1;i<=MaxClients;i++)
	{
		if (CheckCommandAccess(i, "sm_sourcesleuth_printtoadmins", ADMFLAG_BAN) && IsClientInGame(i))
		{
			VFormat(g_Buffer, sizeof(g_Buffer), format, 2);
			
			PrintToChat(i, "%s", g_Buffer);
		}
	}
}