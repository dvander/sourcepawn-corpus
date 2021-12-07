#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <store>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[Store] Daily Credits",
	author = "kRatoss"
};

Handle g_hDataBase;

public void OnPluginStart()
{
	SQL_TConnect(OnDBConnected, "skins_shop");
	RegConsoleCmd("sm_daily", Command_Daily);
}

public Action Command_Daily(int Client, int Args)
{
	if(IsValidClient(Client) && g_hDataBase != INVALID_HANDLE)
	{
		char Steam[32], Buffer[128];
		if(GetClientAuthId(Client, AuthId_SteamID64, Steam, sizeof(Steam)))
		{
			Format(Buffer, sizeof(Buffer), "SELECT reward_time FROM skins_daily WHERE steamid = '%s';", Steam);
			SQL_TQuery(g_hDataBase, SQLT_LoadDaily, Buffer, Client);
		}
	}
}

public void SQLT_LoadDaily(Handle DataBase, Handle Results, const char[] sError, any Client)
{
	if(strlen(sError))
	{
		LogError("Error: %s", sError);
		return;
	}
		
	if(DataBase == INVALID_HANDLE)
	{
		SetFailState("Databases Error( %s )", sError);
		return;
	}
	
	if(IsValidClient(Client))
	{
		SQL_FetchRow(Results);
		if(SQL_GetRowCount(Results) == 0)
		{
			char Steam[32], Buffer[128];
			GetClientAuthId(Client, AuthId_SteamID64, Steam, sizeof(Steam));
			
			Format(Buffer, sizeof(Buffer), "\
			INSERT INTO skins_daily \
				(steamid, reward_time) \
			VALUES \
				('%s', '%i'); ", Steam, GetTime() + 86400);
			kQuery(g_hDataBase, Buffer, "SQLT_LoadDaily");
		}
		else
		{
			Menu Daily = new Menu(DailyMenuHandler);
			char Title[128], Time[32];
			int Hours = 0, Minutes = 0, Seconds = SQL_FetchInt(Results, 0); 
			
			if (GetTime() > Seconds)
			{
				PrintToChat(Client, "test");
					
				Format(Title, sizeof(Title), "\
				Daily Bonus\n\
				--------------------------- \n\
				You can colect your bonus now \n\
				---------------------------\n");
				Daily.AddItem("1", "Get 50 Credits", ITEMDRAW_DEFAULT);
			}
			else
			{
				Seconds = Seconds - GetTime();
				while(Seconds > 3600)
				{
					Hours++;
					Seconds -= 3600;
				}
				while(Seconds > 60)
				{
					Minutes++;
					Seconds -= 60;
				}
				
				if(Hours >= 1)
					Format(Time, sizeof(Time), "%d Hrs %d Mins %d Secs", Hours, Minutes, Seconds );
				else if(Minutes >= 1)
					Format(Time, sizeof(Time), "%d Mins %d Secs", Minutes, Seconds );
				else
					Format(Time, sizeof(Time), "%d Secs", Seconds );
				
				PrintToChat(Client, "test 2");
				Format(Title, sizeof(Title), "\
				Daily Bonus\n\
				--------------------------- \n\
				You will be able to collect in %s\n\
				---------------------------\n", Time);		
				Daily.AddItem("1", "Get 50 Credits", ITEMDRAW_DISABLED);
			}
			Daily.SetTitle(Title);
			Daily.Display(Client, MENU_TIME_FOREVER);
		}
	}
}

public int DailyMenuHandler(Handle hMenu, MenuAction pAction, int Client, int Selection)
{
	if (pAction == MenuAction_Select)
	{
		if(g_hDataBase != INVALID_HANDLE)
		{
			char Steam[32], sQuery[128];
			if(GetClientAuthId(Client, AuthId_SteamID64, Steam, sizeof(Steam)))
			{
				PrintToChat(Client, "[\x04SHOP\x01] You've Collected\x04 50\x01 Credits!");
				Format(sQuery, sizeof(sQuery), "UPDATE skins_daily SET reward_time = '%i' WHERE steamid = '%s';", GetTime() + 86400, Steam);
				kQuery(g_hDataBase, sQuery, "DailyMenuHandler");
				//SS_SetTokens(Client, SS_GetTokens(Client) + 50);
				Store_SetClientCredits(Client, Store_GetClientCredits(Client) + 50);
			}
		}
	}
}

public int OnDBConnected(Handle hOwner, Handle hHandle, char [] sError, any Data)
{
	if(hHandle == INVALID_HANDLE)
	{
		SetFailState("Databases does not work. Error: %s", sError);
	}
	else
	{
		g_hDataBase = hHandle;
		kQuery(g_hDataBase, "\
		CREATE TABLE IF NOT EXISTS `skins_daily` (`steamid` varchar(32) PRIMARY KEY NOT NULL, `reward_time` int(16) NOT NULL); ", "OnDBConnected(1)");
	}
}

stock void kQuery(Handle pDatabase, char[] szQuery, const char[] sFunction)
{
	if (!SQL_FastQuery(pDatabase, szQuery))
	{
		char szError[255];
		SQL_GetError(pDatabase, szError, sizeof(szError));
		//SetFailState("MySQL Error @%s : %s", sFunction, szError);
		LogError("MySQL Error @%s : %s", sFunction, szError);
	}
}

stock bool IsValidClient(int client)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || client < 0)
    {
        return false; 
    }
    return IsClientInGame(client); 
}