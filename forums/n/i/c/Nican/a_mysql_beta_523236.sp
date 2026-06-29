#include <sourcemod>


//0=steamid, 1=name, 2=ip
#define SAVE_TYPE 0

new Handle:db;
new String:SelectQuery[2048];

new Handle:adt_names;
new Handle:adt_global;
new Totalcount;

new maxplayers;


#define CVAR_CONFIG 0
#define CVAR_PERSIT 1
#define CVAR_AUTOLITE 2
#define CVAR_SAVELEVEL 3
#define CVAR_COUNT 4

new Handle:g_cvars[CVAR_COUNT];

new Handle:OnClientFinish;
new Handle:OnUpdateDatabase;
new Handle:OnKeyValueUpdated;

new ismysql = -1;
new bool:AlredyOnCahe = false;

new RowsEnabled = 0;

new Handle:SteamIdColumn = INVALID_HANDLE;
new Handle:IdCoulmn = INVALID_HANDLE;

#define DB_INT 0
#define DB_STRING 1
#define DB_FLOAT 2

#define DB_DT_ADRESS 0
#define DB_DT_TYPE 1
#define DB_DT_ENABLED 2
#define DB_DT_SIZE 3

#define DEBUG 1

static String:SaveTypeNames[ 3 ][] = { "steam" , "plname" , "ipadr" };

//#include "a_mysql/player.sp"
//#include "a_mysql/keyvalue.sp"

public Plugin:myinfo = 
{
  name = "Database manager",
  author = "Nican132",
  description = "So Plugins can have only 1 user database",
  version = "4.3beta",
  url = "http://sourcemod.net/"
};       

public OnPluginStart()
{
    CreateConVar("sm_db_manager", "4.2", "SM DB version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
     
    g_cvars[CVAR_CONFIG] = CreateConVar("sm_db_config","default","The connection DB manager will use");
    HookConVarChange(g_cvars[CVAR_CONFIG], ConVarChanged);
    g_cvars[CVAR_PERSIT] = CreateConVar("sm_db_persit","1","Set to true to use persistant connection");
    HookConVarChange(g_cvars[CVAR_PERSIT], ConVarChanged);
    g_cvars[CVAR_AUTOLITE] = CreateConVar("sm_db_autolite","1","If the DB does not exist, SQLite will be used");
    g_cvars[CVAR_SAVELEVEL] = CreateConVar("sm_db_savelevel","3","1=round_start 2=player_death 3=both");
    
    OnClientFinish=CreateGlobalForward("DB_OnClientUpdate",ET_Ignore,Param_Cell);
    OnUpdateDatabase=CreateGlobalForward("DB_OnRowsUpdated",ET_Ignore);
    OnKeyValueUpdated=CreateGlobalForward("DB_OnKeyValueUpdated",ET_Ignore);
    
    adt_global = CreateArray(4);
    adt_names = CreateArray(65);

    HookEvent("round_start", EventRoundEnd, EventHookMode_PostNoCopy);	
    HookEvent("player_death", EventPlayerDeath, EventHookMode_PostNoCopy);
}

public OnConfigsExecuted(){
    ConnectToMysql();
    KeyValueStart();
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
    if( GetConVarInt( g_cvars[CVAR_SAVELEVEL] ) & (1<<1) ){
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if(IsClientInGame( client )){
            UpdateClientInfo( client );       
        }  
    }
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
    if( GetConVarInt( g_cvars[CVAR_SAVELEVEL] ) & (1<<0) ){
        new i;
        
        for(i=1; i<= maxplayers; i++){
            if(IsClientInGame(i)){
                UpdateClientInfo(i);       
            }   
        }   
    }
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
    ConnectToMysql();
}

public bool:MakeDBhandle(){
    decl String:buffer[255], String:dbname[64];
    GetConVarString(g_cvars[CVAR_CONFIG], dbname, 64);
    db = SQL_Connect(dbname, GetConVarBool(g_cvars[CVAR_PERSIT]), buffer, sizeof(buffer)); 
    
    if(db == INVALID_HANDLE){
        LogMessage("Connection error: %s", buffer);
        
        if(GetConVarBool( g_cvars[CVAR_AUTOLITE] )){
            //LogMessage("DB MANAGER SAYS:");
            LogMessage("Unable to connect to %s configuration...", dbname);
            LogMessage("Using SQLite instead...");
              
            if(SQL_CheckConfig("storage-local")){
                db = SQL_Connect("storage-local", GetConVarBool(g_cvars[CVAR_PERSIT]), buffer, sizeof(buffer));
            }
            //I am not using else, I want to be sure it is working... (if storage-local fails)
            if( db == INVALID_HANDLE ) {
                db = SQL_ConnectEx(SQL_GetDriver("sqlite"),"","","","sm_users", buffer, sizeof(buffer), GetConVarBool(g_cvars[CVAR_PERSIT]));
            }
            
            if(db != INVALID_HANDLE){
                 //Who knows if storage-local is not mysql?
                RecheckConStatus();
                return true;                    
            }
        }
        
        LogMessage("[MYSQLmanager] %s",buffer);
        ismysql = -1;
        return false;
    }
    
    RecheckConStatus();
    
    return true;
}

public RecheckConStatus(){
    decl String:buffer[64];
    SQL_GetDriverIdent( SQL_ReadDriver(db), buffer, sizeof(buffer));
    ismysql = StrEqual(buffer,"mysql", false) ? 1 : 0;
}

public ConnectToMysql(){
    if(AlredyOnCahe)
        return;
    
    decl String:buffer[512];    
    if(!MakeDBhandle()){
         //Lets istead just give a nice little error
        //SetFailState("[MYSQLmanager] Fail state: Could not connect to mysql");
        
        LogMessage("ATTETION! ATTETION! ATTETION!");
        LogMessage("MySQL manager was unable to connect to the database, no data will be saved");
        LogMessage("ATTETION! ATTETION! ATTETION!");
        return;
    }
    
    if(ismysql == 1){
        Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `sm_users` (`id` int(11) NOT NULL auto_increment,`steam` varchar(31) NOT NULL,PRIMARY KEY  (`id`),UNIQUE KEY `steam` (`steam`))");
    }else{
        Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS sm_users(id INTEGER PRIMARY KEY AUTOINCREMENT, steam TEXT UNIQUE );");
    }
    
    SQL_TQuery(db, OnTableCreated, buffer);
    
    /*if (!SQL_FastQuery(db, buffer)){
        LogMessage("[MYSQLmanager] ERROR: Could not create player table!");
        LogMessage("[MYSQLmanager] ERROR: Could not create player table!");
        return;
    }
    
    SQL_TQuery(db, OnTableCreated, buffer);
    //Gr... Two completly different functions to the same thing
   
        
    SQL_TQuery(db, OnTableUpdated, buffer); */
    
}

public OnTableCreated(Handle:owner, Handle:hQuery, const String:error[], any:nothing){
    if (hQuery == INVALID_HANDLE){
        LogMessage("[MYSQLmanager] ERROR: Could not create player table!");
        LogMessage("[MYSQLmanager] ERROR: No information will be saved!");
        return;
    }
    
    AlredyOnCahe = true;
    
    if(ismysql == 1)
        SQL_TQuery(db, OnTableUpdated, "SHOW COLUMNS FROM sm_users");
    else
        SQL_TQuery(db, OnTableUpdated, "PRAGMA table_info(sm_users)");
}

public OnTableUpdated(Handle:owner, Handle:hQuery, const String:error[], any:nothing){
    if (hQuery == INVALID_HANDLE){
        LogMessage("[MYSQLmanager] %s", error);
        LogMessage("[MYSQLmanager] Fail state: Could not show coulums from sm_users");
        LogMessage("[MYSQLmanager] NO PLAYER DATA WILL BE SAVED");
        AlredyOnCahe = false;
        KeyValueDataStart();
        return;
    }

    //Clear off any old data, but close the handles first
    new size = GetArraySize(adt_global);
    for(new i=0; i< size; i++){
        CloseHandle(GetRowDataArray(i));        
    }
    ClearArray(adt_names);
    ClearArray(adt_global);
    
    
    new String:columnname[65], String:columntype[65];
    new array_push[4];
    while (SQL_FetchRow(hQuery)){
        SQL_FetchString(hQuery, ismysql == 1 ? 0 : 1, columnname, 64);        
        SQL_FetchString(hQuery, ismysql == 1 ? 1 : 2, columntype, 64);
        
        if( StrContains(columntype,"var", false) >= 0 ){
            array_push[ DB_DT_SIZE ] = GetCharSize (columntype);
            array_push[ DB_DT_ADRESS ] = CreateDataArray(ByteCountToCells( array_push[ DB_DT_SIZE ] ) );
            array_push[ DB_DT_TYPE ] = DB_STRING;
            
        } else if( StrContains(columntype,"text", false) >= 0 || StrContains(columntype,"blob", false) >= 0 ) {
            array_push[ DB_DT_SIZE ] = 512;
            array_push[ DB_DT_ADRESS ] = CreateDataArray(ByteCountToCells( 512 ) );
            array_push[ DB_DT_TYPE ] = DB_STRING; 
            
        } else if(StrContains(columntype,"int", false) >= 0){
            array_push[ DB_DT_SIZE ] = 1;
            array_push[ DB_DT_ADRESS ] = CreateDataArray( array_push[ DB_DT_SIZE ] );
            array_push[ DB_DT_TYPE ] = DB_INT;
            
        }
        else if( StrContains(columntype,"float", false) >= 0 || StrContains(columntype,"real", false) >= 0){
            array_push[ DB_DT_SIZE ] = 1;
            array_push[ DB_DT_ADRESS ] = CreateDataArray( array_push[ DB_DT_SIZE ] );
            array_push[ DB_DT_TYPE ] = DB_FLOAT;
            
        } else {
           LogMessage("Unknow row type %s, on row %s... Iginoring it.", columntype, columnname);
           continue; 
        }
        
        PushArrayString(adt_names, columnname);
        Totalcount = PushArrayArray(adt_global, array_push);
        
        if( StrEqual(columnname, SaveTypeNames[SAVE_TYPE]) ){
            SteamIdColumn = Handle:array_push[ DB_DT_ADRESS ];
        }
        if( StrEqual(columnname, SaveTypeNames[SAVE_TYPE]) ){
            IdCoulmn = Handle:array_push[ DB_DT_ADRESS ];
        }
    }
    LogMessage("[MYSQLmanager] Found %d colums in sm_users", Totalcount + 1);
    
    if(SteamIdColumn == INVALID_HANDLE){
        decl String:query[1023];    
    
        if(ismysql == 1){
            Format(query, sizeof(query), "ALTER TABLE `sm_users` ADD `%s` VARCHAR(32) NOT NULL",SaveTypeNames[SAVE_TYPE]);
            SQL_FastQuery(db, query);
            
            Format(query, sizeof(query), "ALTER TABLE `smf_servers` ADD UNIQUE (`%s`)",SaveTypeNames[SAVE_TYPE]);
            SQL_FastQuery(db, query);
        } else {
            Format(query, sizeof(query), "ALTER TABLE sm_users ADD `%s` TEXT",SaveTypeNames[SAVE_TYPE]);
            SQL_FastQuery(db, query);
            
            Format(query, sizeof(query), "CREATE UNIQUE INDEX IF NOT EXISTS steamunique ON sm_users(%s)",SaveTypeNames[SAVE_TYPE]);
            SQL_FastQuery(db, query);
        }
    
        array_push[ DB_DT_SIZE ] = 32;
        array_push[ DB_DT_ADRESS ] = CreateDataArray(ByteCountToCells(32));
        array_push[ DB_DT_TYPE ] = DB_STRING;
        
        PushArrayString(adt_names, SaveTypeNames[SAVE_TYPE]);
        Totalcount = PushArrayArray(adt_global, array_push); 
        
        SteamIdColumn = Handle:array_push[ DB_DT_ADRESS ];          
    }
    
    if(IdCoulmn == INVALID_HANDLE){
    
        if(ismysql == 1){
            SQL_FastQuery(db, "ALTER TABLE `sm_users` ADD `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY");
        } else {        
            SQL_FastQuery(db, "ALTER TABLE sm_users ADD `id` INTEGER PRIMARY KEY AUTOINCREMENT");
            //SQL_FastQuery(db, "CREATE UNIQUE INDEX IF NOT EXISTS primaryid ON sm_users(id)");
            
            //BIG PROBLEM, CAN NOT CREATE AUTOINCREMENT AFTER TABLE HAS BEEN CREATED WITH SQLITE
        }
    
        array_push[ DB_DT_SIZE ] = 32;
        array_push[ DB_DT_ADRESS ] = CreateDataArray(ByteCountToCells(32));
        array_push[ DB_DT_TYPE ] = DB_STRING;
        
        PushArrayString(adt_names, "id");
        Totalcount = PushArrayArray(adt_global, array_push); 
        
        SteamIdColumn = Handle:array_push[ DB_DT_ADRESS ];          
    }
    
    CloseHandle(hQuery);
    
    AlredyOnCahe = false;

    Call_StartForward(OnUpdateDatabase);
    Call_Finish();    
    
    KeyValueDataStart();
}

stock GetCharSize(const String:res[]){
    new pos;    
    if((pos = StrContains(res, "(")) > -1)
        return StringToInt(res[pos + 1]) + 1;
    return 1;
}

public RecieveUpdateQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
    if (hndl == INVALID_HANDLE){
        PrintToServer("Failed to query (error: %s)", error);
    }
}


public OnMapStart(){
    maxplayers = GetMaxClients();

    if(GetArraySize(adt_global) == 0){
        ConnectToMysql();
    } else {
        new Handle:dump;
        for(new i=0; i<= Totalcount; i++){
            dump = GetRowDataArray(i);
            
            if (GetArraySize(dump) + 1 != maxplayers){
                ResizeArray(dump,  maxplayers + 1 );            
            }
        }    
    }
}

public OnMapEnd(){
    //I don't save player data here, because players get disconnect/connected every map change
    
    SaveKeyValue();
}


public bool:AskPluginLoad(Handle:myself, bool:late, String:Error[])
{
  // General
  CreateNative("DB_GetColumnId", Db_GetColumnId);
  CreateNative("DB_EnableId", Db_EnableColumn);
  CreateNative("DB_DisableId", Db_DisableColumn);
  CreateNative("DB_ColumnType", ReturnColumnType);
  CreateNative("DB_GetHandle", DB_ReturnHandle);
  //CreateNative("DB_CreateRow", DB_CreateNewRow);
  
  CreateNative("DB_SetInfo", SetColumnInfo);
  CreateNative("DB_SetInfoString", SetColumnInfoString);
  
  CreateNative("DB_GetColumn", GetColumnInfo);
  CreateNative("DB_GetColumnString", GetColumnInfoString);
  
  KeyValueOnPluginLoad();

  return true;
}

//Let's do this different
//rowname, auto-enable, autoinsert, rowtype, rowsize
public Db_GetColumnId(Handle:plugin,argc){
    if(argc==5){
        decl String:name[32], String:ColumnName[64];
        GetNativeString(1,name,32);
        
        //LogMessage("Starting row %s",name);
        
        for(new i=0; i<= Totalcount; i++){
            GetArrayString( adt_names , i, ColumnName, 64);
             
            //LogMessage("%s -- %s", name, ColumnName)
                 
            if(StrEqual(name, ColumnName)){
                //Cell 2 alredy keeps true/false
                if(GetNativeCell(2))
                    EnableRow( i );
                else
                    DisableRow( i );            
                return i;                
            }
        }
        
        LogMessage("Row %s not found, creating it!",name);
        
        //So the row does not exists and he wants to create  a new row
        if(GetNativeCell(3))
            return InsertNewRow(name, GetNativeCell(4), GetNativeCell(5), GetNativeCell(2));
    }
    return -1;
}

public InsertNewRow(const String:name[], rowtype, size, autoenable){
    decl String:buffer[512];    
    for(new i=0; i<= Totalcount; i++){
        GetArrayString(adt_names, i, buffer, 64);
        if(StrEqual(name, buffer)){
            ThrowNativeError(0, "A row with that name alredy exists!");
            return -1;
        }                
    }
    
    if(ismysql == 1){
        switch( rowtype ){
            case DB_INT: {
                if(size <= 0 || size > 11) size = 11;
                Format(buffer, sizeof(buffer), "ALTER TABLE `sm_users` ADD `%s` INT( %d ) NOT NULL", name, size);
            }
            case DB_FLOAT: Format(buffer, sizeof(buffer), "ALTER TABLE `sm_users` ADD `%s` FLOAT NOT NULL", name);
            case DB_STRING: {
                 if(size <= 0 || size > 999) size = 32;
                 Format(buffer, sizeof(buffer), "ALTER TABLE `sm_users` ADD `%s` VARCHAR( %d ) NOT NULL", name, size);
            }
            default:{
                ThrowNativeError(0, "Invalid Row type!");
                return -1;
            }
        }
    } else {
        switch( rowtype ){
            case DB_INT: Format(buffer, sizeof(buffer), "ALTER TABLE sm_users ADD %s INTEGER", name);
            case DB_FLOAT: Format(buffer, sizeof(buffer), "ALTER TABLE sm_users ADD %s REAL", name);
            case DB_STRING: Format(buffer, sizeof(buffer), "ALTER TABLE sm_users ADD %s TEXT",name);
            default:{
                ThrowNativeError(0, "Invalid Row type!");
                return -1;
            }    
        }
    }
    
    //Sorry, but I can not pass a string and 3 ints trought that
    
    if (ismysql >= 0){
        if( !SQL_FastQuery(db, buffer) ){
            ThrowNativeError(0,"[MYSQLmanager] Fail state: Could not add row!");
            return -1;
        }
    }
    
    new array_push[4];
    
    array_push[ DB_DT_ADRESS ] = CreateDataArray(rowtype == DB_STRING ? ByteCountToCells(size) : 1);
    array_push[ DB_DT_TYPE ] = rowtype
    array_push[ DB_DT_ENABLED ] = false;
    array_push[ DB_DT_SIZE ] = rowtype == DB_STRING ? size : 1

    PushArrayString(adt_names, name);
    
    Totalcount = PushArrayArray(adt_global, array_push);
    
    if(autoenable)
        EnableRow( Totalcount );
    else
        DisableRow( Totalcount );
    
    return Totalcount;
}

stock CreateDataArray(size){
    if( maxplayers > 0 ) {
        return _:CreateArray(size , maxplayers + 1)
    } else {
        return _:CreateArray(size , MAXPLAYERS + 1)
    }
}

public Db_EnableColumn(Handle:plugin,argc){
    if(argc==1){
        new column = GetNativeCell(1);
        if(column >Totalcount ){
            ThrowNativeError(0, "Invalid column!");
            return false;    
        }
                
        EnableRow(column);
        
        return true;
    }
    return false;
}

public Db_DisableColumn(Handle:plugin,argc){
    if(argc==1){
        new column = GetNativeCell(1);
        if(column > Totalcount ){
            ThrowNativeError(0, "Invalid column!");
            return false;    
        }    
            
        DisableRow(column);
        
        return true;
    }
    return false;
}

//Client, column, int/float, addto
public SetColumnInfo(Handle:plugin,argc){ 
    if(argc==4){
        new client = GetNativeCell(1);
        if(client > MAXPLAYERS )
            ThrowNativeError(0, "Invalid client!");
            
        new column = GetNativeCell(2);
        if(column > Totalcount )
            ThrowNativeError(0, "Invalid column!");
        
        new Handle:temp = GetRowDataArray(column);
        
        switch( GetColumnType(column) ){
            case DB_INT: {
                new value = GetNativeCell(3);
                if(GetNativeCell(4))
                    value += GetArrayCell(temp, client);
                SetArrayCell(temp, client, value);
            }
            case DB_FLOAT: {
                new Float:value = GetNativeCell(3);
                if(GetNativeCell(4))
                    value = FloatAdd( value, GetArrayCell(temp, client));
                
                SetArrayCell(temp, client, value);
            }
            case DB_STRING: ThrowNativeError(0, "Column is not a string!");
        }        
    }
}

//Client, column, string
public SetColumnInfoString(Handle:plugin,argc){
    if(argc==3){
        new client = GetNativeCell(1);
        if(client > MAXPLAYERS )
            ThrowNativeError(0, "Invalid client!");
            
        new column = GetNativeCell(2);
        if(column > Totalcount )
            ThrowNativeError(0, "Invalid column!");            
        
        switch( GetColumnType(column) ){
            case DB_INT, DB_FLOAT: {
                 ThrowNativeError(0, "Column is not a int/float!");
                 return;
            }
            case DB_STRING: {
                new size;
                GetNativeStringLength(3, size)
                size += 1;
                decl String:temp[size];
                
                GetNativeString(3, temp, size);                
                SetArrayString( GetRowDataArray(column) , client, temp );
            }
        }
    }
}

//Client, column
public GetColumnInfo(Handle:plugin,argc){
    if(argc==2){
        new client = GetNativeCell(1);
        if(client > MAXPLAYERS )
            ThrowNativeError(0, "Invalid client!");
            
        new column = GetNativeCell(2);
        if(column > Totalcount )
            ThrowNativeError(0, "Invalid column!");            
        
        switch(  GetColumnType(column) ){
            case DB_INT, DB_FLOAT: {
                return GetArrayCell( GetRowDataArray(column) , client);
            }
            case DB_STRING: ThrowNativeError(0, "Column is not a string!");
        }        
    }
    return -1;
}

//Client, column, sting, maxsize
public GetColumnInfoString(Handle:plugin,argc){
    if(argc==4){
        new client = GetNativeCell(1);
        if(client > MAXPLAYERS )
            ThrowNativeError(0, "Invalid client!");
            
        new column = GetNativeCell(2);
        if(column > Totalcount )
            ThrowNativeError(0, "Invalid column!");            
        
        switch( GetColumnType(column) ){
            case DB_INT, DB_FLOAT: ThrowNativeError(0, "Column is not a int/float!");
            case DB_STRING: {
                new size = GetNativeCell(4);
                decl String:temp[size];
                GetArrayString( GetRowDataArray(column) , client ,temp, size);
                SetNativeString(3, temp, size);
            }
        }
    }
}

public ReturnColumnType(Handle:plugin,argc){
    if(argc==1){
        new column = GetNativeCell(1);
        if(column >Totalcount )
            ThrowNativeError(0, "Invalid column!");
        else
            GetColumnType(column);
    }
    return -1;
}

public RemakeSelectquery(){
    if(RowsEnabled == 0)
         return;
     
    decl String:Names[ Totalcount ][64];
    decl String:dump[64];
    
    RowsEnabled = 0;
        
    for(new i=0; i<= Totalcount; i++){
        if(IsColumnEnabled(i)){                       
            GetArrayString( adt_names, i , dump, sizeof(dump));
            
            Format( Names[ RowsEnabled ], 64 , "`%s`", dump);       
            RowsEnabled++;
        }
    }
    
    //If there is only 1 column enabled, it will but the ImplodeStrings function
    if(RowsEnabled == 1){     
        strcopy(SelectQuery, sizeof(SelectQuery), Names[ 0 ]) 
        return;
    }
    ImplodeStrings(Names, RowsEnabled, ",", SelectQuery, sizeof(SelectQuery));

}

stock MysqlError(){
    new String:error[255];
    SQL_GetError(db, error, sizeof(error));
    PrintToServer("Failed to query (error: %s)", error);
}

public DB_ReturnHandle(Handle:plugin,argc){
    return _:db;
}

public GetColumnSize(id){
    return GetArrayCell(adt_global, id, DB_DT_SIZE);
}

stock EnableRow(id){
    if(IsColumnEnabled(id))
         return;
    RowsEnabled++;
    SetArrayCell(adt_global, id, true, DB_DT_ENABLED);
    RemakeSelectquery();
}

stock DisableRow(id){
    if(!IsColumnEnabled(id))
         return;
    RowsEnabled--;
    SetArrayCell(adt_global, id, false, DB_DT_ENABLED);
    RemakeSelectquery();
}

stock GetColumnType(id){
    return GetArrayCell(adt_global, id, DB_DT_TYPE);
}

stock bool:IsColumnEnabled(id){
    return GetArrayCell(adt_global, id, DB_DT_ENABLED);
}

stock Handle:GetRowDataArray(id){
    return GetArrayCell(adt_global, id, DB_DT_ADRESS)
}

public OnClientAuthorized(client){        
    if(ismysql == -1){
        ResetPlayerDB(client);
        LogMessage("ATTETION! MySQL manager was unable to connect to the database, just loading zeros for player data");
        return;
    }
    
    //There is nothing to select
    if(RowsEnabled == 0)
        return;
        
    
    
    decl String:auth[32];
    
    /*#if SAVE_TYPE == 0 
        if(!GetClientAuthString(client, auth, sizeof(auth)) ) { return; }
        ReplaceString( auth, sizeof(auth), "STEAM_0:" , "" ); 
    #endif   
    
    #if SAVE_TYPE == 1 
        if(!GetClientName(client, auth, sizeof(auth)) ) { return; }
        TrimString(auth);
    #endif 
    
    #if SAVE_TYPE == 2 
        if(!GetClientIP(client, auth, sizeof(auth)) ) { return; }
        TrimString(auth);
    #endif     */
    
    if(!GetAuthString(client, auth, sizeof(auth)) ) return;
    
    SetArrayString( SteamIdColumn, client, auth);
    SetArrayCell( IdCoulmn, client, -1);
    
    decl String:buffer[511];
    
    Format(buffer, sizeof(buffer), "SELECT %s, id FROM sm_users WHERE `%s` = '%s'",SelectQuery, SaveTypeNames[SAVE_TYPE],auth);
    
    #if DEBUG == 1
        LogMessage("[MYSQLmanager] %s", buffer);    
    #endif
    
    SQL_TQuery(db, GetClientConnectInfo, buffer, client);
} 

stock GetAuthString(client, String:auth[], maxlenght){
    #if SAVE_TYPE == 0 
        if(!GetClientAuthString(client, auth, maxlenght) ) { return false; }
        ReplaceString( auth, maxlenght, "STEAM_0:" , "" ); 
    #endif   
    
    #if SAVE_TYPE == 1 
        if(!GetClientName(client, auth, maxlenght) ) { return false; }
        TrimString(auth);
    #endif 
    
    #if SAVE_TYPE == 2 
        if(!GetClientIP(client, auth, maxlenght) ) { return false; }
        TrimString(auth);
    #endif  
    
    return true;
}

public GetClientConnectInfo(Handle:owner, Handle:hndl, const String:error[], any:client)
{
    decl String:buffer[255];
 
    //Make sure the client didn't disconnect while the thread was running
    if(!IsClientConnected(client))
        return;
 
    if (hndl == INVALID_HANDLE){
        MysqlError();
        //Reset all data sinse it is not going to be over writed...
        ResetPlayerDB(client);
        return;
    } else if (SQL_GetRowCount(hndl) == 0) {
        new String:auth[32];
        
        if(GetAuthString(client, auth, sizeof(auth))){
            Format(buffer, sizeof(buffer), "INSERT INTO sm_users(%s) VALUES ('%s')", SaveTypeNames[SAVE_TYPE] ,auth);
            
            #if DEBUG == 1
                LogMessage("Insert: %s -- %s", auth, buffer);
            #endif
            
            SQL_TQuery(db, GetClientInsertId, buffer, client);
        }
        
        //Reset all data sinse it is not going to be over writed...
        ResetPlayerDB(client);
        return;
    } 
    
    //Check if we are actually able to get the answers
    if(!SQL_FetchRow(hndl))
        return;
        
    new count = 0;
    for(new i=0; i<= Totalcount; i++){
        if(!IsColumnEnabled(i))
            continue;
                
        switch( GetColumnType(i) ){
            case DB_INT: {
                SetArrayCell( GetRowDataArray(i) , client, SQL_FetchInt(hndl, count) );
            }
            case DB_FLOAT: {
                SetArrayCell( GetRowDataArray(i) , client, SQL_FetchFloat(hndl, count) );    
            }
            case DB_STRING: {
                 if(SQL_IsFieldNull(hndl, count)) {
                     SetArrayString( GetRowDataArray(i) , client, "" );
                 } else {
                    new size = SQL_FetchSize( hndl, count);
                    new String:temp[ size ];
                      
                    SQL_FetchString(hndl, count, temp, size);
                    SetArrayString( GetRowDataArray(i) , client, temp );
                }    
            }
        }
        count++;
    }
    
    SetArrayCell(IdCoulmn, client, SQL_FetchInt(hndl, count) );
    
        
    #if DEBUG == 1
        LogMessage("InsertID of client: %d", GetArrayCell(IdCoulmn, client) );
    #endif
    
    Call_StartForward(OnClientFinish);
    Call_PushCell(client);
    Call_Finish();    
}

public GetClientInsertId(Handle:owner, Handle:hndl, const String:error[], any:client){

    SetArrayCell(IdCoulmn, client, SQL_GetInsertId( owner ) );
    
    #if DEBUG == 1
        LogMessage("New user of InsertID: %d", GetArrayCell(IdCoulmn, client) );
    #endif
    
}

public ResetPlayerDB(client){
    for(new i=0; i<= Totalcount; i++){
        
        switch( GetColumnType(i) ){
            case DB_INT,DB_FLOAT: SetArrayCell( GetRowDataArray(i) , client, 0 );
            case DB_STRING: SetArrayString( GetRowDataArray(i) , client, "" );
        }
    }
}

public OnClientDisconnect_Post(client){
    UpdateClientInfo(client);
    
    //Just to make sure nobody will use his information for accident
    SetArrayString( SteamIdColumn, client, "" );
}

public UpdateClientInfo(client){
    if(RowsEnabled == 0)
         return;
         
    //Where I am going to update this to if there is not database
    if(ismysql == -1){
        LogMessage("ATTETION! MySQL manager was unable to connect to the database, no data will be saved");
        return;    
    }
    
    /*decl String:auth[32];
    GetArrayString(SteamIdColumn, client, auth, sizeof(auth));
    
    if(strlen(auth) == 0){
        if(!IsClientConnected(client)){ return; }    
        if(!GetClientAuthString(client, auth, sizeof(auth)) ) { return; }
        ReplaceString( auth, sizeof(auth), "STEAM_0:" , "" );
    }*/
     
    decl String:Names[ Totalcount + 1 ][64], String:FinalUpdate[ Totalcount * 64 ], String:buffer[512], String:ColumnName[64];
    new count = 0;
    
    for(new i=0; i<= Totalcount; i++){
        if( !IsColumnEnabled(i) )
            continue;
        
        GetArrayString( adt_names , i, ColumnName, 64);
        
        switch( GetColumnType(i) ){
            case DB_INT: Format(buffer, 128, "`%s`=%d", ColumnName, GetArrayCell( GetRowDataArray(i) , client) ); 
            case DB_FLOAT: Format(buffer, 128, "`%s`=%f", ColumnName, GetArrayCell( GetRowDataArray(i) , client) ); 
            case DB_STRING: {
                new size = GetArrayCell(adt_global, i, DB_DT_SIZE);
                new String:temp[ size + 2 ];
                GetArrayString( GetRowDataArray(i) , client, temp, size)
                Format(buffer, 512, "`%s`='%s'", ColumnName , temp );
            }
        }
        strcopy(Names[ count ], 64,  buffer);
        count++;
    }
    
    ImplodeStrings(Names, count, ",", FinalUpdate, Totalcount * 64);
    
    Format(FinalUpdate, Totalcount * 64, "UPDATE `sm_users` SET %s WHERE `id`=%d", FinalUpdate, GetArrayCell(IdCoulmn, client) );
    
    #if DEBUG == 1
        LogMessage("%s", FinalUpdate);
    #endif
    
    SQL_TQuery(db, RecieveUpdateQuery, FinalUpdate);
}


//This method is giving me lots of errors...
//Like when I call something, only half of the string is shown.
/*new const String:Queries[2][2][] = {
    {
        "CREATE TABLE IF NOT EXISTS sm_info_s(key TEXT UNIQUE,value TEXT)",
        "CREATE TABLE IF NOT EXISTS sm_info_i(key TEXT UNIQUE,value INTEGER)"    
    },
    {
        "CREATE TABLE IF NOT EXISTS `sm_info_s`(`key` VARCHAR(32) NOT NULL,`value` text NOT NULL,UNIQUE(`key`))",
        "CREATE TABLE IF NOT EXISTS `sm_info_i`(`key` varchar(32) NOT NULL,`value` int(11) NOT NULL,UNIQUE KEY `key`(`key`))"
    }
} */

new Handle:keyvalue_info;
new Handle:keyvalue_names;

#define KEY_INFO_NOTHING 0
#define KEY_INFO_UPDATE 1
#define KEY_INFO_INSERT 2

#define KEY_INFO 0
#define KEY_VALUE 1


KeyValueStart(){
    keyvalue_info = CreateArray( 2 );
    keyvalue_names = CreateArray( ByteCountToCells(64) );
}


KeyValueDataStart(){
    /*if (!SQL_FastQuery(db, Queries[ismysql][0])){
        LogMessage("[MYSQLmanager] ERROR: Could not create data string table!");
        LogMessage("[MYSQLmanager] ERROR: Could not create table!");
        return;
    }*/
    if(ismysql == 1){
        if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS `sm_info_i`(`key` varchar(32) NOT NULL,`value` int(11) NOT NULL,UNIQUE KEY `key`(`key`))")){
            LogMessage("[MYSQLmanager] ERROR: Could not create data integer table!");
            return;
        }
    } else {
        if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS sm_info_i(key TEXT UNIQUE,value INTEGER)")){
            LogMessage("[MYSQLmanager] ERROR: Could not create data integer table!");
            return;
        }
    }
    
    SQL_TQuery(db, OnKeyValueTableUpdated, "SELECT * FROM sm_info_i");
    
    LogMessage("Query executed!");
}


public OnKeyValueTableUpdated(Handle:owner, Handle:hQuery, const String:error[], any:nothing){
    if (hQuery == INVALID_HANDLE){
        LogMessage("[MYSQLmanager] %s", error);
        LogMessage("[MYSQLmanager] Fail state: Could not show coulums from sm_users");
        LogMessage("[MYSQLmanager] NO PLAYER DATA WILL BE SAVED");
        AlredyOnCahe = false;
        return;
    }
    
    LogMessage("Reading data.");
    
    ClearArray(keyvalue_info);
    ClearArray(keyvalue_names);
    
    decl String:columnname[64];
    new data[2];
    
    data[KEY_INFO] = KEY_INFO_NOTHING;
    
    while (SQL_FetchRow(hQuery)){
        SQL_FetchString(hQuery, 0, columnname, 64);        
        
        data[KEY_VALUE] = SQL_FetchInt(hQuery, 1);
        PushArrayString(keyvalue_names, columnname);
        PushArrayArray(keyvalue_info, data);    
        
        #if DEBUG == 1
            LogMessage("KeyValue got: %s = %d", columnname, SQL_FetchInt(hQuery, 1));
        #endif
    }
    
    Call_StartForward(OnKeyValueUpdated);
    Call_Finish(); 
    
    CloseHandle(hQuery);
}

SaveKeyValue(){
    #if DEBUG == 1
        LogMessage("Start saving data table");
    #endif

    new size = GetArraySize(keyvalue_names), data[2];
    decl String:key[64];
    decl String:query[256];
    
    #if DEBUG == 1
        LogMessage("Size - %d", size)
    #endif
    
    for(new i=0; i< size; i++){
        GetArrayArray( keyvalue_info, i, data);
            
        switch( data[KEY_INFO] ){
            case KEY_INFO_UPDATE:{   
                GetArrayString(keyvalue_names, i, key, sizeof(key));
                Format(query, sizeof(query), "UPDATE `sm_info_i` SET `value`=%d WHERE `key`='%s'", data[KEY_VALUE], key);      
            }
            case KEY_INFO_INSERT:{
                GetArrayString(keyvalue_names, i, key, sizeof(key));
                Format(query, sizeof(query), "INSERT INTO `sm_info_i` VALUES('%s', %d)", key, data[KEY_VALUE]);  
            }
            default:{
                continue;            
            }     
        }
        
        data[KEY_INFO] = KEY_INFO_NOTHING;
        
        SetArrayArray( keyvalue_info, i, data );        
    
        #if DEBUG == 1
            LogMessage("%s", query);
        #endif
        
        SQL_TQuery(db, RecieveUpdateQuery, query);
    }
}


KeyValueOnPluginLoad(){
    CreateNative("DB_SetGlobal", Db_SetGlobal);
    CreateNative("DB_GetGlobal", Db_GetGlobal);
}

//Key, Value
public Db_SetGlobal(Handle:plugin,argc){
    if (argc != 2){ return false; }

    decl String:key[64];
    new data[2];
    
    GetNativeString(1, key, 64);
    
    new index = FindStringInArray(keyvalue_names, key);
    if(index == -1){
        PushArrayString(keyvalue_names, key);
        
        data[KEY_INFO] = KEY_INFO_INSERT;
        data[KEY_VALUE] = GetNativeCell(2);
        
        PushArrayArray(keyvalue_info, data);
    } else { 
        GetArrayArray( keyvalue_info, index, data);
        
        if ( data[KEY_INFO] == KEY_INFO_NOTHING){
            data[KEY_INFO] = KEY_INFO_UPDATE;
        }
        
        data[KEY_VALUE] = GetNativeCell(2);
        
        SetArrayArray( keyvalue_info, index, data );
    }
    
    return  true;      
}

//Key
public Db_GetGlobal(Handle:plugin,argc){
    if (argc != 1){ return false; }

    decl String:key[64];
    GetNativeString(1, key, 64);
    
    new index = FindStringInArray(keyvalue_names, key);
    
    if(index == -1){ return 0; }
    
    return GetArrayCell(keyvalue_info, index, KEY_VALUE);
}

