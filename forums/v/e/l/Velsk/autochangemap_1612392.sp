#pragma semicolon 1
#include <sourcemod>

new Handle:timer = INVALID_HANDLE; 
new Handle:new_map;
new Handle:map_idle_time;
new Handle:Timelimit_H;
new Handle:Command_S;
new Handle:PlayersC;
new Handle:SameMapChange;
new status;

public Plugin:myinfo =
{
    name = "Auto change map",
    author = "Mleczam, modified by Velsk",
    description = "Change the map if there are no players on the server for a defined time",
    version = "1.3.1.1",
    url = "http://www.sect-of-death.com.pl/"
}

public OnPluginStart()
{
    Command_S = CreateConVar("sm_cm_command","sm_setnextmap","When mp_timelimit is not 0 uses this command - use ma_setnextmap for MAP or sm_setnextmap for sourcemod", FCVAR_PLUGIN);
    map_idle_time = CreateConVar("sm_cm_idlechange","5","When no players after this time server changes the map", FCVAR_PLUGIN);
    new_map = CreateConVar("sm_cm_nextmap","de_dust2","Name of the map for change without .bsp", FCVAR_PLUGIN);
    PlayersC = CreateConVar("sm_cm_players","0","How many players should by to change the map", FCVAR_PLUGIN);
    SameMapChange = CreateConVar("sm_cm_samemapchange", "1", "Should the next map be set to sm_cm_nextmap when that is already the current map being played", FCVAR_PLUGIN); 
    Timelimit_H = FindConVar("mp_timelimit");
    AutoExecConfig(true, "autochangemap");
    status = 0;
}

public OnMapStart()
{
    new String:mapname[128];
    new String:newMap[128];
    GetCurrentMap(mapname,sizeof(mapname));
    GetConVarString(new_map, newMap, sizeof(newMap));
    if(GetConVarInt(SameMapChange))
    {
        timer = CreateTimer(60.0, sprawdz ,0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        if( strcmp(mapname, newMap, false) )
        {
            // Only create timer if current map and sm_cm_nextmap are different 
            timer = CreateTimer(60.0, sprawdz ,0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    status = 0;
}

public Action:sprawdz(Handle:Timer)
{
    new ccount;
    new NOfClients = GetClientCount(true);
    for (new i = 1; i <= NOfClients ; i++)
    if (IsClientInGame(i) && !IsFakeClient(i))
    {
        ccount++;
    }
    if( ccount > GetConVarFloat(PlayersC) || status) 
    return Plugin_Handled;

    KillTimer(timer); 
    timer = INVALID_HANDLE;
    timer = CreateTimer(GetConVarFloat(map_idle_time)*60, sprawdz2);
    return Plugin_Handled;
}

public Action:sprawdz2(Handle:Timer)
{
    new String:str[128];
    new String:mapname[128];
    new String:command_s[64];
    new ccount = GetRealClientCount(true);
    //new NOfClients = GetRealClientCount(true);
    KillTimer(timer);
    /*for (new i = 1; i <= NOfClients; i++)
    if (IsClientInGame(i) && !IsFakeClient(i))
    {
        ccount++;
    }*/

    if( ccount > GetConVarFloat(PlayersC) )
    {
        timer = INVALID_HANDLE;
        timer = CreateTimer(60.0, sprawdz ,0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        return Plugin_Handled;
    }
    else
    {
        GetCurrentMap(mapname,sizeof(mapname));
        GetConVarString(new_map, str, sizeof(str));
        if( strcmp(mapname, str, false) )
        { 
            if( IsMapValid(str) ) ServerCommand("changelevel %s",str);
            return Plugin_Handled;
        }
        else if(GetConVarFloat(Timelimit_H))
        {
            GetConVarString(Command_S,command_s,sizeof(command_s));
            ServerCommand("%s %s",command_s,str);
            status = 1;
        }
    }
    return Plugin_Handled;
}
// Thanks to GottZ for this function
// http://docs.sourcemod.net/api/index.php?fastload=show&id=165
public GetRealClientCount( bool:inGameOnly)
{
    new clients = 0;
    for(new i = 1; i <= GetMaxClients(); ++i)
    {
        if( ( (inGameOnly) ? IsClientInGame(i) : IsClientConnected( i ) ) && !IsFakeClient( i ))
        {
            ++clients;
        }
    }
    return clients;
}
