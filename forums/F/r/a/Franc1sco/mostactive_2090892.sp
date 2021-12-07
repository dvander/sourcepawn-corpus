#pragma semicolon 1
#include <sourcemod>
#include <sdktools>


#define VERSION "v1.2"

new JugadoEspectador[MAXPLAYERS+1] = 0;
new JugadoT[MAXPLAYERS+1] = 0;
new JugadoCT[MAXPLAYERS+1] = 0;

new bool:conectado[MAXPLAYERS+1] = {false, ...};

new bool:in_db[MAXPLAYERS+1] = {false, ...};
new bool:checked_db[MAXPLAYERS+1] = {false, ...};


// DB handle
new Handle:g_hDB = INVALID_HANDLE;


new Handle:auto_createDatabase;

public Plugin:myinfo = 
{
	name = "SM Most Active",
	author = "Franc1sco Steam: franug",
	description = "A rank based in time played",
	version = VERSION,
	url = "http://www.servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{

	CreateConVar("sm_mostactive_version", VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
        RegAdminCmd("sm_resetdb", Command_Clear, ADMFLAG_ROOT);
        RegAdminCmd("sm_savedb", Command_save, ADMFLAG_ROOT);
        RegConsoleCmd("sm_active", DOMenu);

	auto_createDatabase = CreateConVar("mostactive_createsqlite", "1", "1 = Create mostactive sqlite database automatically to your config (Restart your Server after first lunch!) (Mysql you have to add for yourself, see how to install!!), 0 = off");

        InitDB();
}

public OnMapStart()
{
	if (GetConVarBool(auto_createDatabase)) otherlib_createDB();

	CreateTimer(1.0, Temporizador, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	SyncDB();
}


// by stamm
public otherlib_createDB()
{
	new String:dbPath[PLATFORM_MAX_PATH + 1];
	
	BuildPath(Path_SM, dbPath, sizeof(dbPath), "configs/databases.cfg");
	
	new Handle:dbHandle = CreateKeyValues("Databases");
	FileToKeyValues(dbHandle, dbPath);
	
	if (!KvJumpToKey(dbHandle, "mostactive_sql"))
	{
		KvJumpToKey(dbHandle, "mostactive_sql", true);
		
		KvSetString(dbHandle, "driver", "sqlite");
		KvSetString(dbHandle, "host", "localhost");
		KvSetString(dbHandle, "database", "Mostactive-DB");
		KvSetString(dbHandle, "user", "root");
		
		KvGoBack(dbHandle);
		
		KeyValuesToFile(dbHandle, dbPath);
		
		for (new i=0; i <= 20; i++) PrintToServer("Created Mostactive DB. To use it, please restart your Server now!!");
	}
	CloseHandle(dbHandle);
}
//

public Action:Temporizador(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i))
		{
	           new team = GetClientTeam(i);

                   if(team == 2)
	           {
                      ++JugadoT[i];

                   }
                   else if(team == 3)
                   {
                      ++JugadoCT[i];  
                   }
                   else  
                   {
                      ++JugadoEspectador[i];
	           }
		} 
	}
}

public Action:Command_save(admin, args)
{
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client) && checked_db[client])
		{
			InsertScoreInDB(client);
		}
	}
	
	ReplyToCommand(admin, "Players rank has been saved");
	
	return Plugin_Handled;
}


public OnClientPostAdminCheck(client)
{
    if (!client || IsFakeClient(client))
	 return;

    conectado[client] = true;

    JugadoEspectador[client] = 0;
    JugadoT[client] = 0;
    JugadoCT[client] = 0;
    in_db[client] = false;
    checked_db[client] = false;

    GetScoreFromDB(client);
}

public OnClientDisconnect(client)
{
       if(!conectado[client])
           return;

       if (!client || IsFakeClient(client))
	    return;

	
       InsertScoreInDB(client);

       conectado[client] = false;
}



// database



// Here we are creating SQL DB
public InitDB()
{
	new String:sqlError[255];
	
	g_hDB = SQL_Connect("mostactive_sql", true, sqlError, sizeof(sqlError));
	
	if (g_hDB == INVALID_HANDLE)
	{
		LogError("[ MOSTACTIVE ] couldn't connect to the Database!! Error: %s", sqlError);
		

	}
	else 
	{
	
		SQL_LockDatabase(g_hDB);
		SQL_FastQuery(g_hDB, "VACUUM");
		SQL_FastQuery(g_hDB, "CREATE TABLE IF NOT EXISTS saverank_time2 (steamid VARCHAR( 20 ) NOT NULL DEFAULT '', Nombre VARCHAR( 255 ) NOT NULL DEFAULT '',JugadoEspectador INT( 255 ) NOT NULL DEFAULT 0,JugadoT INT( 255 ) NOT NULL DEFAULT 0,JugadoCT INT( 255 ) NOT NULL DEFAULT 0,total INT( 255 ) NOT NULL DEFAULT 0, PRIMARY KEY (steamid));");
		SQL_UnlockDatabase(g_hDB);
	}
}


// Admin command that clears all player's scores
public Action:Command_Clear(admin, args)
{
	
	ClearDBQuery();


	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
	                JugadoEspectador[client] = 0;
	                JugadoT[client] = 0;
	                JugadoCT[client] = 0;
 			in_db[client] = false;

		}
	}
	
	ReplyToCommand(admin, "Players rank has been reset");
	
	return Plugin_Handled;
}


// Doing clearing stuff
public ClearDBQuery()
{
	// Clearing SQL DB
	SQL_LockDatabase(g_hDB);
	SQL_FastQuery(g_hDB, "DELETE FROM saverank_time2;");
	SQL_UnlockDatabase(g_hDB);
}


public InsertScoreInDB(client)
{
	decl String:steamId[30];
	GetClientAuthString(client, steamId, sizeof(steamId));

	new save1 = JugadoEspectador[client];
	new save2 = JugadoT[client];
	new save3 = JugadoCT[client];
        new save4 = (save2 + save3);
	

        decl String:name[32],String:name2[32];
        GetClientName(client, name, sizeof(name));

        SQL_EscapeString(g_hDB, name, name2, sizeof(name2));

	decl String:query[256];

	if(!in_db[client])
	{
		Format(query, sizeof(query), "INSERT INTO saverank_time2 VALUES ('%s', '%s',%d,%d,%d,%d);", steamId, name2,save1,save2,save3,save4);
		in_db[client] = true;
	}
	else
		Format(query, sizeof(query), "UPDATE saverank_time2 SET Nombre='%s', JugadoEspectador='%d', JugadoT='%d', JugadoCT='%d', total='%d' WHERE steamid = '%s';", name2,save1,save2,save3,save4,steamId);


	SQL_FastQuery(g_hDB, query);

	
}

// Syncronize DB with score varibles
public SyncDB()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client) && checked_db[client])
		{
			InsertScoreInDB(client);
		}
	}
}

// Now we need get this information back...
public GetScoreFromDB(client)
{
	
	decl String:steamId[30];
	decl String:query[200];
	
	GetClientAuthString(client, steamId, sizeof(steamId));
	Format(query, sizeof(query), "SELECT * FROM	saverank_time2 WHERE steamId = '%s';", steamId);
	SQL_TQuery(g_hDB, SetPlayerScore, query, client);
}

// ...and set player's score and cash if needed
public SetPlayerScore(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", error);
		return;
	}
	
	if (SQL_GetRowCount(hndl) == 0)
	{
		checked_db[client] = true;
		return;
	}

        if(!SQL_FetchRow(hndl))
	{
		checked_db[client] = true;
        	return;
	}
	

	new save1 = SQL_FetchInt(hndl,2);
	new save2 = SQL_FetchInt(hndl,3);
	new save3 = SQL_FetchInt(hndl,4);


        JugadoEspectador[client] = save1;
        JugadoT[client] = save2;
        JugadoCT[client] = save3;

	checked_db[client] = true;
	in_db[client] = true;

        //LogMessage("%N se le han restaurado el tiempo", client);
}


public showTOP(client){

	if (g_hDB != INVALID_HANDLE)
	{
		decl String:buffer[200];
		Format(buffer, sizeof(buffer), "SELECT * FROM saverank_time2 ORDER BY total DESC LIMIT 999");
		SQL_TQuery(g_hDB, SQLTopShow, buffer, client);
	} else {
		PrintToChat(client, "Rank System is now not avilable");
	}
}

public SQLTopShow(Handle:owner, Handle:hndl, const String:error[], any:client){

		if(hndl == INVALID_HANDLE)
		{
			LogError(error);
			PrintToServer("Last Connect SQL Error: %s", error);
			return;
		}

		new Handle:menu2 = CreateMenu(DIDMenuHandler2);
		SetMenuTitle(menu2, "Top Total played");


                new orden = 0;
                decl String:numero[64];
		decl String:name[64];
		decl String:texto[128];

		if (SQL_HasResultSet(hndl))
		{
			while (SQL_FetchRow(hndl))
			{
                                orden++;
                                Format(numero,64, "option%i", orden);
				SQL_FetchString(hndl, 1, name, sizeof(name));
	                        new Time = SQL_FetchInt(hndl,5);
	                        new Hours = (Time/60/60);
	                        new Minutes = (Time/60)%(60);
	                        new Seconds = (Time%60);

        
	
                                Format(texto,128, "n%i %s - %d h. %d m. %d s.", orden,name,Hours, Minutes, Seconds);    
    
                                AddMenuItem(menu2, numero, texto);


			}
		}

		if(orden < 1) 
		{
			AddMenuItem(menu2, "empty", "TOP is empty!");
		}
		
                SetMenuExitButton(menu2, true);
                DisplayMenu(menu2, client, MENU_TIME_FOREVER);

}

public showTOP2(client){

	if (g_hDB != INVALID_HANDLE)
	{
		decl String:buffer[200];
		Format(buffer, sizeof(buffer), "SELECT * FROM saverank_time2 ORDER BY JugadoEspectador DESC LIMIT 999");
		SQL_TQuery(g_hDB, SQLTopShow2, buffer, client);
	} else {
		PrintToChat(client, "Rank System is now not avilable");
	}
}

public SQLTopShow2(Handle:owner, Handle:hndl, const String:error[], any:client){

		if(hndl == INVALID_HANDLE)
		{
			LogError(error);
			PrintToServer("Last Connect SQL Error: %s", error);
			return;
		}

		new Handle:menu2 = CreateMenu(DIDMenuHandler2);
		SetMenuTitle(menu2, "Top Spectator");


                new orden = 0;
                decl String:numero[64];
		decl String:name[64];
		decl String:texto[128];

		if (SQL_HasResultSet(hndl))
		{
			while (SQL_FetchRow(hndl))
			{
                                orden++;
                                Format(numero,64, "option%i", orden);
				SQL_FetchString(hndl, 1, name, sizeof(name));
	                        new Time = SQL_FetchInt(hndl,2);
	                        new Hours = (Time/60/60);
	                        new Minutes = (Time/60)%(60);
	                        new Seconds = (Time%60);

        
	
                                Format(texto,128, "n%i %s - %d h. %d m. %d s.", orden,name,Hours, Minutes, Seconds);   
    
                                AddMenuItem(menu2, numero, texto);


			}
		} 

		if(orden < 1) 
		{
			AddMenuItem(menu2, "empty", "TOP is empty!");
		}
		
                SetMenuExitButton(menu2, true);
                DisplayMenu(menu2, client, MENU_TIME_FOREVER);

}

public showTOP3(client){

	if (g_hDB != INVALID_HANDLE)
	{
		decl String:buffer[200];
		Format(buffer, sizeof(buffer), "SELECT * FROM saverank_time2 ORDER BY JugadoT DESC LIMIT 999");
		SQL_TQuery(g_hDB, SQLTopShow3, buffer, client);
	} else {
		PrintToChat(client, "Rank System is now not avilable");
	}
}

public SQLTopShow3(Handle:owner, Handle:hndl, const String:error[], any:client){

		if(hndl == INVALID_HANDLE)
		{
			LogError(error);
			PrintToServer("Last Connect SQL Error: %s", error);
			return;
		}

		new Handle:menu2 = CreateMenu(DIDMenuHandler2);
		SetMenuTitle(menu2, "Top T");


                new orden = 0;
                decl String:numero[64];
		decl String:name[64];
		decl String:texto[128];

		if (SQL_HasResultSet(hndl))
		{
			while (SQL_FetchRow(hndl))
			{
                                orden++;
                                Format(numero,64, "option%i", orden);
				SQL_FetchString(hndl, 1, name, sizeof(name));
	                        new Time = SQL_FetchInt(hndl,3);
	                        new Hours = (Time/60/60);
	                        new Minutes = (Time/60)%(60);
	                        new Seconds = (Time%60);
        
	
                                Format(texto,128, "n%i %s - %d h. %d m. %d s.", orden,name,Hours, Minutes, Seconds);    
    
                                AddMenuItem(menu2, numero, texto);


			}
		} 

		if(orden < 1) 
		{
			AddMenuItem(menu2, "empty", "TOP is empty!");
		}
		
                SetMenuExitButton(menu2, true);
                DisplayMenu(menu2, client, MENU_TIME_FOREVER);

}

public showTOP4(client){

	if (g_hDB != INVALID_HANDLE)
	{
		decl String:buffer[200];
		Format(buffer, sizeof(buffer), "SELECT * FROM saverank_time2 ORDER BY JugadoCT DESC LIMIT 999");
		SQL_TQuery(g_hDB, SQLTopShow4, buffer, client);
	} else {
		PrintToChat(client, "Rank System is now not avilable");
	}
}

public SQLTopShow4(Handle:owner, Handle:hndl, const String:error[], any:client){

		if(hndl == INVALID_HANDLE)
		{
			LogError(error);
			PrintToServer("Last Connect SQL Error: %s", error);
			return;
		}

		new Handle:menu2 = CreateMenu(DIDMenuHandler2);
		SetMenuTitle(menu2, "Top CT");


                new orden = 0;
                decl String:numero[64];
		decl String:name[64];
		decl String:texto[128];

		if (SQL_HasResultSet(hndl))
		{
			while (SQL_FetchRow(hndl))
			{
                                orden++;
                                Format(numero,64, "option%i", orden);
				SQL_FetchString(hndl, 1, name, sizeof(name));
	                        new Time = SQL_FetchInt(hndl,4);
	                        new Hours = (Time/60/60);
	                        new Minutes = (Time/60)%(60);
	                        new Seconds = (Time%60);

        
	
                                Format(texto,128, "n%i %s - %d h. %d m. %d s.", orden,name,Hours, Minutes, Seconds); 
    
                                AddMenuItem(menu2, numero, texto);


			}
		} 

		if(orden < 1) 
		{
			AddMenuItem(menu2, "empty", "TOP is empty!");
		}
		
                SetMenuExitButton(menu2, true);
                DisplayMenu(menu2, client, MENU_TIME_FOREVER);

}

stock mostrartiempo(Time, any:client)
{

	new Hours = (Time/60/60);
	new Minutes = (Time/60)%(60);
	new Seconds = (Time%60);

        
	if(Hours >= 1)
        {
           PrintToChat(client, "\x04%d hours %d minutes %d seconds", Hours, Minutes, Seconds );
        }
        else if(Minutes >= 1)
        {
           PrintToChat(client, "\x04%d minutes %d seconds", Minutes, Seconds );
        }
        else PrintToChat(client, "\x04%d seconds", Seconds );
}

public DIDMenuHandler2(Handle:menu, MenuAction:action, client, itemNum) 
{
    /*if ( action == MenuAction_Select ) 
    {

    }*/
    if (action == MenuAction_Cancel) 
    { 
        PrintToServer("Client %d's menu was cancelled.  Reason: %d", client, itemNum); 
    } 

    else if (action == MenuAction_End)
    {
	CloseHandle(menu);
    }
} 

public Action:DOMenu(clientId,args)
{
    new Handle:menu = CreateMenu(DIDMenuHandler);
    SetMenuTitle(menu, "Most Active");
    AddMenuItem(menu, "option1", "View your time");
    AddMenuItem(menu, "option2", "View Top total played");
    AddMenuItem(menu, "option3", "View Top Spectator");
    AddMenuItem(menu, "option4", "View Top T");
    AddMenuItem(menu, "option5", "View Top CT");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    
    return Plugin_Handled;
}


public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
    if ( action == MenuAction_Select ) 
    {
        new String:info[32];
        
        GetMenuItem(menu, itemNum, info, sizeof(info));

        if ( strcmp(info,"option1") == 0 ) 
        {
              PrintToChat(client, "\x03Espectator:");	
              mostrartiempo(JugadoEspectador[client], client);
              PrintToChat(client, "\x03Terrorist:");
              mostrartiempo(JugadoT[client], client);
              PrintToChat(client, "\x03Counter-terrorist:");
              mostrartiempo(JugadoCT[client], client);
              PrintToChat(client, "\x03Total played:");
              new totalt = (JugadoT[client] + JugadoCT[client]);
              mostrartiempo(totalt, client);
              //DID(client);
        }

        else if ( strcmp(info,"option2") == 0 ) 
        {
              showTOP(client);
              //DID(client);
            
        }
        else if ( strcmp(info,"option3") == 0 ) 
        {
              showTOP2(client);
              //DID(client);
            
        }
        else if ( strcmp(info,"option4") == 0 ) 
        {
              showTOP3(client);
              //DID(client);
            
        }
        else if ( strcmp(info,"option5") == 0 ) 
        {
              showTOP4(client);
              //DID(client);
            
        }
    }
    else if (action == MenuAction_Cancel) 
    { 
        PrintToServer("Client %d's menu was cancelled.  Reason: %d", client, itemNum); 
    } 

    else if (action == MenuAction_End)
    {
	CloseHandle(menu);
    }
}
