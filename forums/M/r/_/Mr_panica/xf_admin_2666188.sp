#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "",
	author = "",
	description = "",
	version = "",
	url = ""
};

KeyValues g_Config = null;
Database g_DB = null;

public void OnPluginStart()
{
	if(SQL_CheckConfig("xf_admin"))
		Database.Connect(OnDbConnect, "xf_admin");
	else
		SetFailState("Can't found the entry \"xf_admin\" in your databases.cfg!");
	
	char szBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "configs/xf_admin.txt");
	if(!FileExists(szBuffer))
		SetFailState("Config file '%s' is not exists", szBuffer);
	
	g_Config = new KeyValues("xf_admin");
	if(!g_Config.ImportFromFile(szBuffer))
		SetFailState("Error reading config file '%s'. Check syntax", szBuffer);
	
	if(g_Config.GotoFirstSubKey())
	{
		char szFlags[64];
		int flag_bits;
		
		do
		{
			g_Config.GetString("flags", szFlags, sizeof(szFlags));
			flag_bits = ReadFlagString(szFlags);
			g_Config.SetNum("flag_bits", flag_bits);
		}
		while (g_Config.GotoNextKey());
	}
}

public void OnDbConnect(Database db, const char[] error, any data)
{
	if(db == null)
		SetFailState("Connection Error: %s", error);
	
	g_DB = db;
	g_DB.SetCharset("utf8");
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || IsFakeClient(client))
			continue;
		
		GetUserInfo(client);
	}
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	if(part == part)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if(!IsClientInGame(client) || IsFakeClient(client))
				continue;
			
			GetUserInfo(client);
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(g_DB == null)
		return;
	
	GetUserInfo(client);
}

void GetUserInfo(int client)
{
	char szAuth[32], szQuery[256];
	GetClientAuthId(client, AuthId_SteamID64, szAuth, sizeof(szAuth));
	g_DB.Format(szQuery, sizeof(szQuery), "SELECT b.username, b.user_group_id, b.secondary_group_ids \
						FROM xf_user_connected_account a INNER JOIN xf_user b ON a.user_id=b.user_id \
						WHERE a.provider='steam'AND a.provider_key='%s'", szAuth);
	g_DB.Query(Sql_GetClientInfo, szQuery, GetClientUserId(client));
}

public void Sql_GetClientInfo(Database db, DBResultSet results, const char[] error, any data)
{
	if(results == null)
		LogError("Sql error: %s", error);
	else
	{
		int client = GetClientOfUserId(data);
		if(client == 0)
			return;
		
		if(!results.FetchRow())
			return;
		
		char szBuffer[128];
		
		results.FetchString(2, szBuffer, sizeof(szBuffer));
		
		int pieces = GetCharCount(szBuffer, ',');
		if(pieces)
			pieces++;
		else if(szBuffer[0])
			pieces = 1;
		
		int[] groups = new int[pieces + 1];
		groups[0] = results.FetchInt(1);
		
		if(pieces)
		{
			char[][] szPieces = new char[pieces][6];
			ExplodeString(szBuffer, ",", szPieces, pieces, 6);
			for (int i = 0; i < pieces; i++)
				groups[i + 1] = StringToInt(szPieces[i]);
		}
		
		int flags = 0;
		int immunity = 0;
		
		char szNum[12];
		for (int i = 0, flag_bits, immunity_cfg; i < pieces + 1; i++)
		{
			IntToString(groups[i], szNum, sizeof(szNum));
			g_Config.Rewind();
			if(g_Config.JumpToKey(szNum))
			{
				flag_bits = g_Config.GetNum("flag_bits");
				immunity_cfg = g_Config.GetNum("immunity");
				
				flags |= flag_bits;
				if(immunity_cfg > immunity)
					immunity = immunity_cfg;
			}
		}
		
		if(flags || immunity)
		{
			char szName[128];
			results.FetchString(0, szName, sizeof(szName));
			Format(szName, sizeof(szName), "(F) %s", szName);
			AdminId admin = CreateAdmin(szName);
			
			AdminFlag admflags[AdminFlags_TOTAL];
			int total = FlagBitsToArray(flags, admflags, sizeof(admflags));
			for (int i = 0; i < total; i++)
				admin.SetFlag(admflags[i], true);
			
			admin.ImmunityLevel = immunity;
			
			SetUserAdmin(client, admin, true);
		}
	}
}

stock int GetCharCount(const char[] szStr, char ch)
{
	int len = strlen(szStr);
	int count = 0;
	for (int i = 0; i < len; i++)
	{
		if(szStr[i] == ch)
			count++;
	}
	
	return count;
}