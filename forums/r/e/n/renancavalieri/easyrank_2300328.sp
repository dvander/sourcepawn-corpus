/* ----------------------------------------------------------------------
    EASY RANK SQL - SIMPLE RANKING MANAGER  
-------------------------------------------------------------------------
    
    This plugin is free software: you can redistribute 
    it and/or modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation, either version 3 of the License, or
    later version. 
    
    This plugin is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
    
    To use this plugin, you SHOULD NEVER remove our website.
    
    Copyright (c) Tec Dicas (www.tecdicas.com)

    Updates and changelog
    * https://forums.alliedmods.net/showthread.php?p=2300329
    
--------------------------------------------------------------------------*/
#include <sourcemod>
#include <tf2_stocks>
#pragma semicolon 1

new Handle:db = INVALID_HANDLE;
new rankcount[MAXPLAYERS+1];
new rank[MAXPLAYERS+1];
new Float:score[MAXPLAYERS+1];

new Float:LastQuery[MAXPLAYERS+1];

ConVar g_cvEnabled;
ConVar g_cvScoreKill;
ConVar g_cvScoreAssist;
ConVar g_cvScoreAssistMedic;
ConVar g_cvScoreDeath;

#define PLUGIN_VERSION "1.0.2"

public Plugin:myinfo =
{
    name = "Easy Rank SQL",
    author = "Tec Dicas",
    description = "An easy way to get ranking on your Team Fortress 2 server.",
    version = PLUGIN_VERSION,
    url = "http://www.tecdicas.com"
};

public OnPluginStart() 
{
    PrintToServer("[EasyRank] Loading..");    
    PrintToServer("[EasyRank] Checking databases.cfg..");
    
    decl String:error[256];
    error[0] = '\0';
    
    if(SQL_CheckConfig("default")) 
    {
        //I don't like to use "custom" database, but if you need, just change "default" to your database
        db = SQL_Connect("default", true, error, sizeof(error));
    } 
    
    PrintToServer("[EasyRank] Conecting to database..");
    
    if(db==INVALID_HANDLE) 
    {
        LogError("[EasyRank] Could not connect to default database: %s", error);
        return;
    }
    
    PrintToServer("[EasyRank] Connection successful.");
    
    // ----------------------------------------------------------------------
    // SQL TABLE
    // ----------------------------------------------------------------------
    // TABLE: sm_easyrank
    // PK   NAME        TYPE         NULL    DEFAULT    OBS
    // X    steamid     varchar(32)  N       -          SteamID of Player
    //      name        varchar(64)  N       -          Player name
    //      score       float        N       0.0        Player score
    // ----------------------------------------------------------------------
    
    PrintToServer("[EasyRank] Creating tables (if not exists)..");
    
    SQL_TQuery(db, SQLErrorCallback, "CREATE TABLE IF NOT EXISTS sm_easyrank (steamid varchar(32) NOT NULL PRIMARY KEY, name varchar(64) NOT NULL, score float NOT NULL DEFAULT 0.0)");
    
    // ----------------------------------------------------------------------
    // COMMANDS AND CONVAR
    // ----------------------------------------------------------------------
    PrintToServer("[EasyRank] Loading commands and convars..");
    
    CreateConVar("sm_easyrank_version", PLUGIN_VERSION, "Easy Rank SQL", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    g_cvEnabled = CreateConVar("sm_easyrank_enable", "1", "Set to 1 to enable or 0 to disable EasyRank (Default 1)");
    
    // You can set values greater than max, but is NOT recommended; Also, NEVER insert negative values;
    g_cvScoreKill = CreateConVar("sm_easyrank_scorekill", "10", "Set how many points you will earn on killing players (default 10)");
    g_cvScoreAssist = CreateConVar("sm_easyrank_scoreassist", "5", "Set how many points you will earn on assists (default 5)");
    g_cvScoreAssistMedic = CreateConVar("sm_easyrank_scoreassist_medic", "10", "Set how many points you will earn on assists playing as medic (default: 10)");
    g_cvScoreDeath = CreateConVar("sm_easyrank_scoredeath", "3", "Set how many points you will lose on deaths (default 3)");
    
    //Add hook to avoid negative values;
    g_cvEnabled.AddChangeHook(checkConVar);
    g_cvScoreKill.AddChangeHook(checkConVar);
    g_cvScoreAssist.AddChangeHook(checkConVar);
    g_cvScoreAssistMedic.AddChangeHook(checkConVar);
    g_cvScoreDeath.AddChangeHook(checkConVar);
    
    RegAdminCmd("sm_easyrank_sync", syncDatabase, ADMFLAG_SLAY);
    RegAdminCmd("sm_easyrank_reset_id", resetId, ADMFLAG_SLAY);
    RegAdminCmd("sm_easyrank_reset_all", resetAll, ADMFLAG_SLAY);
  
    //Show the rank
    RegConsoleCmd("sm_rank", sm_rank);
    
    //show plugin about
    RegConsoleCmd("sm_easyrank", sm_easyrank);
    
    //events hooking
    HookEvent("player_changename", Event_Player_Changename, EventHookMode_Post);
    HookEvent("player_death", Event_player_death);
    
    syncDatabase_exec();
    
    PrintToServer("[EasyRank] Loaded.");
    
}

// check if convar is not negative (I know about max and min, but I choose this way)
public void checkConVar(ConVar convar, char[] oldValue, char[] newValue)
{
    if (StringToInt(newValue) < 0)
    {
        convar.FloatValue = 1.0;
        LogError("ConVar MUST be positive");
    }
}

// Reset score from SteamID3
public Action resetId(int client, int args)
{
    if (g_cvEnabled.FloatValue==1) 
    {
        if (args < 1)
        {
            ReplyToCommand(client, "[EasyRank] Usage example: sm_easyrank_reset_id \"[U:1:66789468]\"");
            return Plugin_Handled;
        }
        
        new String:arg[65];
        GetCmdArg(1, arg, sizeof(arg));
        
        decl    String:query[512],
                String:safeArg[sizeof(arg)*2+1] ;
                
        query[0] = '\0'; 
        safeArg[0] = '\0';
        
        SQL_EscapeString(db, arg, safeArg, sizeof(safeArg));
        
        Format(query, sizeof(query), "SELECT steamid FROM sm_easyrank WHERE steamid LIKE '%s' ", safeArg);
        SQL_TQuery(db, SQLResetId, query, GetClientUserId(client));
    }
    else
    {
        ReplyToCommand(client, "[EasyRank] Easy Rank are disabled");
    }
    return Plugin_Handled;
}

public SQLResetId(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client;
   
    if((client = GetClientOfUserId(data))==0) 
    {
        return;
    }
    
    while(SQL_FetchRow(hndl)) 
    {
        new String:arg[65];
        
        decl String:query[512];
        query[0] = '\0';
        
        SQL_FetchString(hndl, 0, arg, sizeof(arg));
        Format(query, sizeof(query), "UPDATE sm_easyrank SET score = 0.0 WHERE steamid = '%s' ", arg);
        SQL_TQuery(db, SQLErrorCallback , query);
        ReplyToCommand(client, "[EasyRank] %s was reset", arg);
        syncDatabase_exec();
        return;
    }
    ReplyToCommand(client, "[EasyRank] cannot reset, check your syntax. ");
    return;
}

// Truncate database
public Action:resetAll(int client, int args)
{
    if (g_cvEnabled.FloatValue==1) 
    {
        if (args < 1)
        {
            ReplyToCommand(client, "[EasyRank] Usage example: sm_easyrank_reset_all CONFIRM");
            return Plugin_Handled;
        }
        
        new String:arg[65];
        GetCmdArg(1, arg, sizeof(arg));
        
        if (StrEqual(arg,"CONFIRM"))
        {
            decl String:query[512];
            query[0] = '\0';
            
            Format(query, sizeof(query), "truncate sm_easyrank");
            SQL_TQuery(db, SQLErrorCallback, query);
            syncDatabase_exec();
            ReplyToCommand(client, "[EasyRank] Your database was reseted");
            return Plugin_Handled;
        }
        
        ReplyToCommand(client, "[EasyRank] You have to confirm this action");
    }
    else
    {
        ReplyToCommand(client, "[EasyRank] Easy Rank are disabled");
    }
    
    return Plugin_Handled;
}

// Sync Database
public Action:syncDatabase(client,args)
{
    if (g_cvEnabled.FloatValue == 1 )
    {
        ReplyToCommand(client, "[EasyRank] Database refreshed");
        syncDatabase_exec();
    }
    else
    {
        ReplyToCommand(client, "[EasyRank] Easy Rank are disabled");
    }
    return Plugin_Handled;
}

public syncDatabase_exec()
{
    decl String:clientid[32], String:query[256];
    query[0] = '\0'; clientid[0] = '\0';
    
    for(new i=1; i<= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {   
            if(!(IsFakeClient(i)))
            {
                new userid = GetClientUserId(i);
                GetClientAuthId(i, AuthId_Steam3, clientid, sizeof(clientid));
                LastQuery[i] = 0.0;
                Format(query, sizeof(query), "SELECT score FROM sm_easyrank WHERE steamid='%s'", clientid);
                SQL_TQuery(db, SQLQueryConnect, query, userid);
            }
        }
    }
}

// Log erros about SQL Query
public SQLErrorCallback(Handle:owner, Handle:hndl, const String:error[], any:data) {
    if(!StrEqual("", error)) 
    {
        LogError("Query failed: %s", error);
    }
    return false;
}


public OnClientPutInServer(client) 
{
    if (g_cvEnabled.FloatValue == 1 )
    {
        if(IsClientInGame(client))
        {   
            if(!IsFakeClient(client)) 
            {
                decl String:clientid[32], String:query[256];
                query[0] = '\0'; clientid[0] = '\0';
                
                new userid = GetClientUserId(client);
                GetClientAuthId(client, AuthId_Steam3, clientid, sizeof(clientid));
                LastQuery[client] = 0.0;
                Format(query, sizeof(query), "SELECT score FROM sm_easyrank WHERE steamid='%s'", clientid);
                SQL_TQuery(db, SQLQueryConnect, query, userid);    
            }
        }
    }
}

public SQLQueryConnect(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
    new client;
   
    if((client = GetClientOfUserId(data))==0) 
    {
        return;
    }
    
    if(hndl==INVALID_HANDLE) 
    {
        LogError("Query failed: %s", error);
    }
    else 
    {
        decl    String:query[512], 
                String:clientname[(MAX_NAME_LENGTH*2)+1], 
                String:unsafeclientname[MAX_NAME_LENGTH], 
                String:clientid[32];
                
        query[0] = '\0'; 
        clientid[0] = '\0'; 
        clientname[0] = '\0';
        
        GetClientName(client, unsafeclientname, sizeof(unsafeclientname));
        
        //ReplaceString(clientname, sizeof(clientname), "'", "");
        SQL_EscapeString(db, unsafeclientname, clientname, sizeof(clientname));
        
        
        
        GetClientAuthId(client, AuthId_Steam3, clientid, sizeof(clientid));
        if(!SQL_MoreRows(hndl)) 
        {
            Format(query, sizeof(query), "INSERT INTO sm_easyrank (steamid, name, score) VALUES ('%s', '%s', 0.0)", clientid, clientname);
            SQL_TQuery(db, SQLErrorCallback, query);
            score[client] =  0.0;
            PrintToServer("[EasyRank] %s(%s) was added to rank.",clientname,clientid);
        } 
        else 
        {
            Format(query, sizeof(query), "UPDATE sm_easyrank SET name='%s' WHERE steamid='%s'", client, clientname, clientid);
            SQL_TQuery(db, SQLErrorCallback, query);
        }
        
        while(SQL_FetchRow(hndl)) 
        {
            score[client] = SQL_FetchFloat(hndl, 0);
        }  
    }
}

public SQLQueryRank(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
    new client;
    if((client = GetClientOfUserId(data))==0) 
    {
        return;
    }
    
    if(hndl==INVALID_HANDLE) 
    {
        LogError("Query failed: %s", error);
        return;
    } 
    
    decl String:clientid[32], String:query[256];
    clientid[0] = '\0'; query[0] = '\0'; 
    
    GetClientAuthId(client, AuthId_Steam3, clientid, sizeof(clientid));
    
    Format(query, sizeof(query), "SELECT count(*) FROM sm_easyrank WHERE (score >= (SELECT (score) FROM sm_easyrank WHERE steamid = '%s'))", clientid);
    
    PrintToChat(client,"\x04[EasyRank]");
    
    SQL_TQuery(db, SQLQueryCount, query, GetClientUserId(client));
    SQL_TQuery(db, SQLQueryCountTotal, "SELECT count(*) FROM sm_easyrank", GetClientUserId(client));
}

public SQLQueryCount(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
    new client;
    if((client = GetClientOfUserId(data))==0) 
    {
        return;
    }
    
    while(SQL_FetchRow(hndl)) {
       rank[client] = SQL_FetchInt(hndl, 0);
    }
    
    PrintToChat(client,"\x03  Score:\x01 %i points", RoundToZero(score[client]));
    
    switch(rank[client])
    {
        // Why break does't work? ( put x_files.avi here )
        
        case 1: PrintToChat(client,"\x03  Rank Position:\x01 %ist, congratulations! ", rank[client]);
        case 2: PrintToChat(client,"\x03  Rank Position:\x01 %ind, you're close! ", rank[client]);
        case 3: PrintToChat(client,"\x03  Rank Position:\x01 %ird, keep trying! ", rank[client]);
        default: PrintToChat(client,"\x03  Rank Position:\x01 %ith", rank[client]);
    } 
}

public SQLQueryCountTotal(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
    new client;
    if((client = GetClientOfUserId(data))==0) 
    {
        return;
    }
        
    while(SQL_FetchRow(hndl)) {
       rankcount[client] = SQL_FetchInt(hndl, 0); 
    }
        
    
    PrintToChat(client,"\x03  Total of:\x01 %i players", rankcount[client]);
    PrintToChat(client,"\x03  -------------------------");
}

//Best players
public SQLQueryTop10(Handle:owner, Handle:hndl, const String:error[], any:data) {
    new client;
    if((client = GetClientOfUserId(data))==0) 
    {
        return;
    }
    
    if(hndl==INVALID_HANDLE) 
    {
        LogError("Query failed: %s", error);
    } 
    
    else 
    {
        decl String:qname[64], String:qscore[8], String:buffer[68];
        qname[0] = '\0'; qscore[0] = '\0'; buffer[0] = '\0'; 
        new i = 0;
        new y = 1;
        new Handle:panel = CreatePanel();
        SetPanelTitle(panel, "[EasyRank] Top players on this server");
        while(SQL_FetchRow(hndl)) {
            SQL_FetchString(hndl, 0, qname, sizeof(qname));
            SQL_FetchString(hndl, 1, qscore, sizeof(qscore));
            
            switch(y)
            {
                case 1: Format(buffer, sizeof(buffer), "%ist - %s: %s points", y, qname, qscore);
                case 2: Format(buffer, sizeof(buffer), "%ind - %s: %s points", y, qname, qscore);
                case 3: Format(buffer, sizeof(buffer), "%ird - %s: %s points", y, qname, qscore);
                default: Format(buffer, sizeof(buffer), "%ith - %s: %s points", y, qname, qscore);
            }
            
            DrawPanelText(panel, buffer);
            i++;
            y++;
        }
        DrawPanelItem(panel, "Close");
        SendPanelToClient(panel, client, PanelHandlerNothing, 15);
        CloseHandle(panel);
    }
}

// Rename player
public Action:Event_Player_Changename(Handle:event, const String:name[], bool:dontBroadcast) 
{
    if (g_cvEnabled.FloatValue==1) 
    {
        decl    String:clientname[MAX_NAME_LENGTH], 
                String:clientid[32], 
                String:query[512], 
                String:unsafeNewName[MAX_NAME_LENGTH],
                String:NewName[(MAX_NAME_LENGTH*2)+1];
                
        clientname[0] = '\0'; 
        clientid[0] = '\0'; 
        query[0] = '\0'; 
        unsafeNewName[0] = '\0'; 
        NewName[0] = '\0'; 
        
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        GetClientName(client, clientname, sizeof(clientname));
        GetEventString(event, "newname", unsafeNewName, sizeof(unsafeNewName));
        
        SQL_EscapeString(db, unsafeNewName, NewName, sizeof(NewName));
        
        GetClientAuthId(client, AuthId_Steam3, clientid, sizeof(clientid));
        Format(query, sizeof(query), "UPDATE sm_easyrank SET name='%s' WHERE steamid='%s'", NewName, clientid);
        PrintToServer("[EasyRank] %s %s was renamed to %s.",clientname,clientid, NewName);
        SQL_TQuery(db, SQLErrorCallback, query);
    }
}

public Action:sm_easyrank(client,args)
{
    PrintToChat(client,"\x04Welcome to Easy Rank SQL");
    PrintToChat(client,"\x04For help with this plugin, visit the websites:");
    PrintToChat(client,"\x03https://forums.alliedmods.net/");
    PrintToChat(client,"\x03http://www.tecdicas.com");
}

// Hook deaths
public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast) {
    if (g_cvEnabled.FloatValue==1) 
    {
        
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        new assister = GetClientOfUserId(GetEventInt(event, "assister"));
        
        if(client!=0 && attacker!=0) 
        {
            if(!IsFakeClient(client)&&!IsFakeClient(attacker)&&client!=attacker) 
            {
                decl String:clientid[32], String:attackerid[32], String:query[512];
                clientid[0] = '\0'; attackerid[0] = '\0'; query[0] = '\0';
                
                GetClientAuthId(client, AuthId_Steam3, clientid, sizeof(clientid));
                GetClientAuthId(attacker, AuthId_Steam3, attackerid, sizeof(attackerid));
                if((assister!=0) && !(IsFakeClient(assister))) 
                {
                    decl String:assisterid[32];
                    assisterid[0] = '\0';
                    
                    GetClientAuthId(assister, AuthId_Steam3, assisterid, sizeof(assister));
                    
                    if(TF2_GetPlayerClass(assister) != TFClass_Medic) 
                    {
                        score[assister] += g_cvScoreAssist.FloatValue;
                    }
                    else
                    {
                        score[assister]+= g_cvScoreAssistMedic.FloatValue;
                    }
                    
                    Format(query, sizeof(query), "UPDATE sm_easyrank SET score=%f WHERE steamid='%s'", score[assister], assisterid);
                    SQL_TQuery(db, SQLErrorCallback, query);
                }
                if ((score[client] <= 0) || (score[client] - g_cvScoreDeath.FloatValue <= 0))
                {
                    score[client] = 0.0;
                }
                else
                {
                    score[client] -= g_cvScoreDeath.FloatValue;
                }
                
                score[attacker] += g_cvScoreKill.FloatValue;
                
                Format(query, sizeof(query), "UPDATE sm_easyrank SET score=%f WHERE steamid='%s'", score[client], clientid);
                SQL_TQuery(db, SQLErrorCallback, query);
                
                Format(query, sizeof(query), "UPDATE sm_easyrank SET score=%f WHERE steamid='%s'", score[attacker], attackerid);
                SQL_TQuery(db, SQLErrorCallback, query);
            }
        }
    }
}
public Action:sm_rank(client,args)
{
    if (g_cvEnabled.FloatValue==1) 
    {
        if (LastQuery[client] + 10 <= GetTickedTime()) 
        {
            LastQuery[client] = GetTickedTime();
            decl String:clientid[32];
            clientid[0] = '\0';
            GetClientAuthId(client, AuthId_Steam3, clientid, sizeof(clientid));
            
            decl String:query[512];
            query[0] = '\0';
            Format(query, sizeof(query), "SELECT * FROM sm_easyrank WHERE score>%f", score[client]);
            SQL_TQuery(db, SQLQueryRank, query, GetClientUserId(client));
        
            SQL_TQuery(db, SQLQueryTop10, "SELECT name,score FROM sm_easyrank ORDER BY score DESC LIMIT 0,10", GetClientUserId(client));
        }
        else
        {
            ReplyToCommand(client,"[EasyRank] You have to wait to use this command again.");
        }
    }
    else
    {
        ReplyToCommand(client,"[EasyRank] Easy Rank are disabled");
    }
    return Plugin_Handled;
}

// delete players that has been banned
public Action:OnBanClient(client, time, flags, const String:reason[], const String:kick_message[], const String:command[], any:admin) 
{
    if (g_cvEnabled.FloatValue==1) 
    {
        
        decl    String:query[255], 
                String:clientid[32], 
                String:player_name[MAX_NAME_LENGTH];
                
        query[0] = '\0'; 
        clientid[0] = '\0'; 
        player_name[0] = '\0';
        
        GetClientName(client, player_name, sizeof(player_name));
        GetClientAuthId(client, AuthId_Steam3, clientid, sizeof(clientid));
        
        Format(query, sizeof(query), "DELETE FROM sm_easyrank WHERE steamid LIKE '%s' ", clientid);
        SQL_TQuery(db, SQLErrorCallback, query);
        
        PrintToChatAll("\x04[EasyRank] \x03%s was banned and removed from rank", player_name);
        PrintToServer("[EasyRank] %s was banned and removed from rank", player_name);
    }
    return Plugin_Handled;
}

public PanelHandlerNothing(Handle:menu, MenuAction:action, param1, param2){}

public OnClientDisconnect(client)
{
    LastQuery[client] = 0.0;
}