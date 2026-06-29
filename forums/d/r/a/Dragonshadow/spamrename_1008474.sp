#pragma semicolon 1
#include <sourcemod>
#include <sdktools>


new String:spamnames[255][64];
new String:Path[] = "/cfg/sourcemod/spamnames.cfg";
new lines;
new Handle:spam_log = INVALID_HANDLE;
new Handle:spam_name = INVALID_HANDLE;
new String:spam_nameold[MAX_NAME_LENGTH];
new Handle:adminimmune = INVALID_HANDLE;
new Handle:logFile = INVALID_HANDLE;
new bool:EventsHooked = false;


#define PLUGIN_VERSION "1"

public Plugin:myinfo = {
    name = "Spam Name Renamer",
    author = "Fire A.K.A. Dragonshadow",
    description = "Renames players with offending names",
    version = PLUGIN_VERSION,
    url = "www.snigsclan.com"
};

public OnPluginStart()
{
    spam_name = CreateConVar("sm_srn_name", "Default", "Name to set on offending players", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
    adminimmune = CreateConVar("sm_srn_ai", "1", "Are Admins Immune?", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    spam_log = CreateConVar("sm_srn_log", "1", "Log when someone is renamed", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 1.0);
    CreateConVar("sm_srn_version", PLUGIN_VERSION, "Spam Name Renamer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    
    HookConVarChange(spam_name, cvarchanged);
    
    GetConVarString(spam_name, spam_nameold, sizeof(spam_nameold));
    
    decl String:ctime[64];
    FormatTime(ctime, 64, "logs/srn_log_%m_%d_%Y.log");
    new String:logFileName[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, logFileName, sizeof(logFileName), ctime);
    logFile = OpenFile(logFileName, "a+t");
    if (logFile == INVALID_HANDLE)
    {
        LogError("Could not open log file: %s", logFileName);
    }
}

public OnPluginEnd(){
    CloseHandle(logFile);
}

public cvarchanged(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i))
        {
            if(IsClientInGame(i))
            {
                new String:playerName[MAX_NAME_LENGTH];
                if(!GetClientName(i,playerName,sizeof(playerName)))
                {
                    return;
                }
                nameCheck(playerName,i);
            }
        }
    }
    GetConVarString(spam_name, spam_nameold, sizeof(spam_nameold));
    
} 

public OnMapStart(){
    for(new i; i < lines; i++){
        spamnames[i] = "";
    }
    lines = 0;
    //If there is something wrong with the config, don't do anything until next map
    if(ReadConfig() && !EventsHooked ){
        //Hook events
        HookEvent("player_changename", checkName);
        EventsHooked = true;
    }
}

public bool:ReadConfig()
{
    //    BuildPath("/cfg/sourcemod/", fileName, sizeof(fileName), "spamnames.ini");
    new Handle:file = OpenFile(Path, "rt");
    if (file == INVALID_HANDLE)
    {
        LogError("Could not open config file: %s, Creating...", Path);
        file = OpenFile(Path, "a");
        WriteFileLine(file, "//Spam Name Renamer Config File");
        WriteFileLine(file, "//Make Sure There Are No Empty Lines Or Spaces");
        WriteFileLine(file, "//Spaces In Player Names Will Be Ignored");
        WriteFileLine(file, "//Comment A Line With // (Like this textblock)");
        CloseHandle(file);
        return false;
    }

    while (!IsEndOfFile(file))
    {
        decl String:line[64];
        if (!ReadFileLine(file, line, sizeof(line)))
        {
            break;
        }
        
        TrimString(line);
        ReplaceString(line, 64, " ", "");
        if (strlen(line) == 0 || (line[0] == '/' && line[1] == '/'))
        {
            continue;
        }
        
        //Add the line to the list of spamnames
        strcopy(spamnames[lines], sizeof(spamnames[]), line);
        lines++;
        
    }
    
    CloseHandle(file);
    return true;
}

public OnClientPostAdminCheck(client)
{
    new String:playerName[MAX_NAME_LENGTH];
    if(!GetClientName(client,playerName,sizeof(playerName)))
    {
        return;
    }
    nameCheck(playerName,client);
}

nameCheck(String:clientName[MAX_NAME_LENGTH], player)
{
    if(GetConVarBool(adminimmune))
    {
        new AdminId:playerAdmin = GetUserAdmin(player);
        if(GetAdminFlag(playerAdmin, Admin_Generic, Access_Effective))
        {
            return;
        }
    }
    
    //Trim the spaces out
    ReplaceString(clientName, MAX_NAME_LENGTH, " ", "");
    
    new String:rename[MAX_NAME_LENGTH];
    GetConVarString(spam_name,rename,sizeof(rename));
    //Check if they have a bad phrase in their name
    for(new i = 0; i < lines; i++)
    {
        if(StrContains(clientName, spamnames[i], false) != -1 || StrContains(clientName, spam_nameold, false) != -1)
        {
            SetClientInfo(player, "name", rename);
            
            //Write to log if desired
            if(GetConVarInt(spam_log) == 1)
            {
                new String:id[64];
                GetClientAuthString(player, id, sizeof(id));
                LogToOpenFile(logFile, "%s was renamed for having %s in their name", id, spamnames[i]);
            }
        }	
    }
    return;

}


public Action:checkName(Handle:event, const String:name[], bool:dontBroadcast){
    new String:playerName[MAX_NAME_LENGTH];
    GetEventString(event, "newname", playerName, sizeof(playerName));
    nameCheck(playerName, GetClientOfUserId(GetEventInt(event, "userid")));
}
