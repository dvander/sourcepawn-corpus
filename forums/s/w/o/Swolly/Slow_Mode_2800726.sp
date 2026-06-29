#include <sourcemod>

#pragma tabsize 0
//////////////////////////////////////////////////////////////////////////////////////
int Kisisel_Slow_Mode[MAXPLAYERS + 1], Kisisel_Slow_Mode_Sure[MAXPLAYERS + 1]; 
int Genel_Slow_Mode_Sure[MAXPLAYERS + 1], Genel_Slow_Mode;
//////////////////////////////////////////////////////////////////////////////////////
Handle db;
//////////////////////////////////////////////////////////////////////////////////////
public Plugin myinfo = {
	name = "Slow Mode",
	author = "Swolly",
	description = "Slow Mode",
	url = "www.plugincim.com"
};
///////////////////////////////////////////////////////////////////////////////////////	
public OnPluginStart()
{
	//*************************************//			
	RegAdminCmd("sm_slowmode", Slow_Mode, ADMFLAG_GENERIC);
	
	DB_Baglan();	
	//*************************************//			
	LoadTranslations("common.phrases");
	//*************************************//			
}
//////////////////////////////////////////////////////////////////////////////////////
public Action Slow_Mode(client, args)
{
	//*************************************//				
	if(args == 1)
	{
		//*************************************//							
		char arg1[32], SQL_Kodu[200];
		GetCmdArg(1, arg1, 32);
		//*************************************//							
		PrintToChatAll("[SM] Made slow mode %d seconds by \x0b%N", StringToInt(arg1), client);
		Genel_Slow_Mode = StringToInt(arg1);
		//*************************************//							
		Format(SQL_Kodu, sizeof(SQL_Kodu), "UPDATE Slow_Mode SET `Sure` = %d WHERE steam_id = '1';", Genel_Slow_Mode);						  	
		SQL_TQuery(db, SQLErrorCheckCallback, SQL_Kodu);	
		//*************************************//							
	}
	else
	if(args == 2)	
	{
		//*************************************//							
		char arg1[32], arg2[32];
		GetCmdArg(1, arg1, 32);
		GetCmdArg(2, arg2, 32);		
		//*************************************//
		int Hedef = FindTarget(client, arg1, true, true);

		if(IsValidClient(Hedef))
		{
			//*************************************//								
			PrintToChatAll("[SM] \x01Slow mode made %d seconds by \x0b%N \x0f%N", StringToInt(arg2), Hedef, client);
			Kisisel_Slow_Mode[Hedef] = StringToInt(arg2);		
			//*************************************//				
			char Steam_ID[32], SQL_Kodu[200];
			GetClientAuthId(Hedef, AuthId_SteamID64, Steam_ID, sizeof(Steam_ID));
			//*************************************//	
			Format(SQL_Kodu, sizeof(SQL_Kodu), "UPDATE Slow_Mode SET `Sure` = %d WHERE steam_id = '%s';", Kisisel_Slow_Mode[Hedef], Steam_ID);						  	
			SQL_TQuery(db, SQLErrorCheckCallback, SQL_Kodu);	
			//*************************************//					
		}
		else
			PrintToChat(client, "[SM] \x01Destination not found!");							
		//*************************************//			
	}
	else
	{
		PrintToChat(client, "[SM] \x01Command Usage:");
		PrintToChat(client, "[SM] \x10!slowmode süre || !slowmode hedef süre");
	}
	//*************************************//					
}
//////////////////////////////////////////////////////////////////////////////////////
public Action OnClientSayCommand(client, const char[] command, const char[] sArgs)
{
	//*************************************//						
	if(Genel_Slow_Mode >= 1)
		if(Genel_Slow_Mode_Sure[client] >= 1)
		{
			PrintToChat(client, "[SM] \x01Slow mode is active. You can write chat a in %d seconds.", Genel_Slow_Mode);					
			return Plugin_Handled
		}
		else
		{
			//*************************************//	
			CreateTimer(1.0, Sure_Azalt_1, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
			Genel_Slow_Mode_Sure[client] = Genel_Slow_Mode;
			//*************************************//				
		}
	else
	if(Kisisel_Slow_Mode[client] >= 1)
		if(Kisisel_Slow_Mode_Sure[client] >= 1)
		{
			PrintToChat(client, "[SM] \x01You have slow mode. You can write chat a in %d seconds.", Kisisel_Slow_Mode[client]);					
			return Plugin_Handled
		}
		else
		{
			//*************************************//		
			CreateTimer(1.0, Sure_Azalt_2, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
			Kisisel_Slow_Mode_Sure[client] = Kisisel_Slow_Mode[client];
			//*************************************//							
		}
	//*************************************//			
	return Plugin_Continue;
	//*************************************//			
}
//////////////////////////////////////////////////////////////////////////////////////
public Action Sure_Azalt_1(Handle Timer, any client)
{
	//*************************************//						
	if(Genel_Slow_Mode == 0)
	{
		//*************************************//							
		Genel_Slow_Mode_Sure[client] = 0;		
		return Plugin_Stop;
		//*************************************//							
	}
	else
	if(Genel_Slow_Mode_Sure[client] >= 1)
		Genel_Slow_Mode_Sure[client]--;
	//*************************************//					
	if(Genel_Slow_Mode_Sure[client] == 0)
		return Plugin_Stop;
	//*************************************//							
	return Plugin_Continue;
	//*************************************//						
}
//////////////////////////////////////////////////////////////////////////////////////
public Action Sure_Azalt_2(Handle Timer, any client)
{
	//*************************************//						
	if(Kisisel_Slow_Mode[client] == 0)
	{
		//*************************************//							
		Kisisel_Slow_Mode_Sure[client] = 0;		
		return Plugin_Stop;
		//*************************************//							
	}
	else
	if(Kisisel_Slow_Mode_Sure[client] >= 1)
		Kisisel_Slow_Mode_Sure[client]--;
	//*************************************//					
	if(Kisisel_Slow_Mode_Sure[client] == 0)
		return Plugin_Stop;
	//*************************************//							
	return Plugin_Continue;
	//*************************************//						
}
//////////////////////////////////////////////////////////////////////////////////////
public DB_Baglan()
{
	//*************************************//
	char Hata[255], SQL_Kodu[256];
	//*************************************//
	db = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "Plugincim_Slow_Mode", Hata, sizeof(Hata), true, 0);	
	//*************************************//
	if(db == INVALID_HANDLE)
		SetFailState(Hata);
	//*************************************//
	SQL_LockDatabase(db);
	SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS Slow_Mode (steam_id TEXT, Sure INTEGER);");
	SQL_UnlockDatabase(db);
	//*************************************//
	Format(SQL_Kodu, sizeof(SQL_Kodu), "SELECT Sure FROM Slow_Mode WHERE steam_id = '1'");
	Handle query = SQL_Query(db, SQL_Kodu);
	//*************************************//
	if (query != INVALID_HANDLE)
	{
		//*************************************//								
		while(SQL_FetchRow(query) && !SQL_IsFieldNull(query, 0))
			Genel_Slow_Mode = SQL_FetchInt(query, 0);
		//*************************************//								
		CloseHandle(query);
		//*************************************//				
	}	
	//*************************************//	
}
//////////////////////////////////////////////////////////////////////////////////////
public OnClientPostAdminCheck(client)
{
	//*************************************//    
	char Steam_ID[32], SQL_Kodu[200];
	GetClientAuthId(client, AuthId_SteamID64, Steam_ID, sizeof(Steam_ID));
	//*************************************//	
	Format(SQL_Kodu, sizeof(SQL_Kodu), "SELECT Sure FROM Slow_Mode WHERE steam_id = '%s'", Steam_ID);		
	SQL_TQuery(db, Kontrol, SQL_Kodu);		
	//*************************************//		
	Kisisel_Slow_Mode_Sure[client] = 0;
	Kisisel_Slow_Mode[client] = 0;
	
	Genel_Slow_Mode_Sure[client] = 0;
	//*************************************//    	
}
//////////////////////////////////////////////////////////////////////////////////////
public Kontrol(Handle owner, Handle hndl, const char[] Hata, any client)
{
	//*************************************//
	if(IsValidClient(client))	
		if(SQL_FetchRow(hndl))
			Kisisel_Slow_Mode[client] = SQL_FetchInt(hndl, 0);
		else
		{
			//*************************************//	
			char Steam_ID[32], SQL_Kodu[200];
			GetClientAuthId(client, AuthId_SteamID64, Steam_ID, sizeof(Steam_ID));
			//*************************************//	
			Format(SQL_Kodu, sizeof(SQL_Kodu), "INSERT OR IGNORE INTO oynama_sureleri VALUES ('%s', '0')", Steam_ID);		
			SQL_TQuery(db, SQLErrorCheckCallback, SQL_Kodu);		
			//*************************************//	
		}
	//*************************************//
}
//////////////////////////////////////////////////////////////////////////////////////
public SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any:data)
{
}
//////////////////////////////////////////////////////////////////////////////////////
bool IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
} 
//////////////////////////////////////////////////////////////////////////////////////