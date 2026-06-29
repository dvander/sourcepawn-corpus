/*
NextMap Selector by pRED*, ferret

Port of nextmap.amxx from Amx Mod X.

Creates a cvar called sm_nextmap.
At intermission checks if sm_nextmap contains a valid map name and changes to that map.
Otherwise do nothing an let default map change happen.

Allow for admins to set the cvar to the map they want next and would go well with a map chooser menu plugin (port of mapchooser.amxx?)
*/
 
#include <sourcemod>
 
#define MAXMAPS 128
#define PLUGIN_VERSION "0.5"
 
new bool:IsIntermissionCalled;
new UserMsg:VGuiMenu;
 
new Handle:g_cvar_chattime;
new Handle:g_cvar_nextmap;
new Handle:g_cvar_ff;
new Handle:g_cvar_mapcyclefile;
 
new String:g_nextMap[32];
new g_pos = -1;
 
new String:g_szMapNames[MAXMAPS][32];
new g_iMapCount;
 
public Plugin:myinfo = 
{
    name = "Nextmap",
    author = "pRED*, ferret",
    description = "SM port of nextmap.amxx",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
    VGuiMenu = GetUserMessageId("VGUIMenu");
    HookUserMessage(VGuiMenu, _VGuiMenu);
    
    g_cvar_chattime =      FindConVar("mp_chattime")
    g_cvar_ff =             FindConVar("mp_friendlyfire")
    g_cvar_mapcyclefile =   FindConVar("mapcyclefile")
    g_cvar_nextmap =        CreateConVar("sm_nextmap", "", "Sets the Next Map",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY)
    
    HookConVarChange(g_cvar_mapcyclefile, ConVarChange_mapcyclefile);
    HookConVarChange(g_cvar_nextmap, ConVarChange_nextmap);
    
    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);
    
    RegConsoleCmd("nextmap", Cmd_Nextmap);
    RegConsoleCmd("currentmap", Cmd_Currentmap);
    RegConsoleCmd("ff", Cmd_FF);
    RegConsoleCmd("listmaps", Cmd_List);
    
    LoadTranslations("plugin.nextmap.txt");
    
    decl String:szMapCycle[64];
    GetConVarString(g_cvar_mapcyclefile, szMapCycle, 64);
    LoadMaps(szMapCycle);
    
    /* Set to the current map so OnMapStart() will know what to do */
    decl String:szCurrentMap[64];
    GetCurrentMap(szCurrentMap, 64);
    SetConVarString(g_cvar_nextmap, szCurrentMap);
}
 
public OnMapStart()
{
    decl String:szLastMap[64], String:szCurrentMap[64];
    GetConVarString(g_cvar_nextmap, szLastMap, 64);
    GetCurrentMap(szCurrentMap, 64);
    
    // Why am I doing this? If we switched to a new map, but it wasn't what we expected (Due to sm_map, sm_votemap, or
    // some other plugin/command), we don't want to scramble the map cycle. Or for example, admin switches to a custom map
    // not in mapcyclefile. So we keep it set to the last expected nextmap. - ferret
    if(strcmp(szLastMap, szCurrentMap) == 0)
    {
        g_pos++;
        if(g_pos >= g_iMapCount)
            g_pos = 0;
    
        FindAndSetNextMap();
    }
}
 
public OnMapEnd()
{
    IsIntermissionCalled = false;
}
 
public ConVarChange_mapcyclefile(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(strcmp(oldValue, newValue, false) != 0)
    {
        LoadMaps(newValue);
    }
}
 
public ConVarChange_nextmap(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_nextMap, 64, newValue);
} 
 
public Action:Command_Say(client, args) {
    new String:text[30];
    GetCmdArgString(text, sizeof(text));
    new startidx = TrimQuotes(text);
 
    if (StrEqual(text[startidx], "nextmap") || StrEqual(text[startidx], "/nextmap"))
    {
        return Cmd_Nextmap(client,args)
    }
        
    if (StrEqual(text[startidx], "currentmap") || StrEqual(text[startidx], "/currentmap")) 
    {
        return Cmd_Currentmap(client,args);
 
    }
    
    if (StrEqual(text[startidx], "ff") || StrEqual(text[startidx], "/ff")) 
    {
        return Cmd_FF(client,args);
    }
    
    return Plugin_Continue;
}
 
public Action:Cmd_Nextmap(client, args) 
{
    new String:map[32];
    getNextMapName(map, 31)
    
    new maxClients = GetMaxClients();
    
    for (new i = 1; i <= maxClients; i++)
    {
        if (IsClientInGame(i))
        {
            PrintToChat(i, "%T %s","NEXT_MAP",i,map);
        }
    }
 
    return Plugin_Handled;
}
 
 
public Action:Cmd_Currentmap(client, args) 
{
    new String:map[32];
    GetCurrentMap(map,sizeof(map))
    
    new maxClients = GetMaxClients();
    
    for (new i = 1; i <= maxClients; i++)
    {
        if (IsClientInGame(i))
        {
            PrintToChat(i, "%T: %s","PLAYED_MAP",i,map);
        }
    }
 
    return Plugin_Handled;
}
 
public Action:Cmd_FF(client, args) 
{
    new maxClients = GetMaxClients();
    
    for (new i = 1; i <= maxClients; i++)
    {
        if (IsClientInGame(i))
        {
            PrintToChat(i, "%T: %s","FRIEND_FIRE",i, GetConVarInt(g_cvar_ff) ? "ON" : "OFF");
        }
    }
 
    return Plugin_Handled;
}
 
public Action:_VGuiMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
    if(IsIntermissionCalled)
    {
        return Plugin_Handled;
    }
    new String:Type[10];
    BfReadString(bf, Type, sizeof(Type));
 
    if(BfReadByte(bf) == 1 && BfReadByte(bf) == 0 && (strcmp(Type, "scores", false) == 0))
    {
        IsIntermissionCalled = true;
        
        decl String:map[32]
        new Float:chattime = GetConVarFloat(g_cvar_chattime);
        
        getNextMapName(map, 31)
        
        if (chattime<2.0)
            SetConVarFloat(g_cvar_chattime,2.0);
        
        new Handle:dp;
        CreateDataTimer(chattime-1.0, Timer_ChangeMap, dp);
        WritePackString(dp, map);
    }
    
    return Plugin_Handled;
}
 
public Action:Timer_ChangeMap(Handle:timer, Handle:dp)
{
    new String:map[32];
    
    ResetPack(dp);
    ReadPackString(dp, map, sizeof(map));
 
    InsertServerCommand("changelevel \"%s\"", map);
    ServerExecute()
    
    LogMessage("Nextmap changed map to \"%s\"", map);
    
    return Plugin_Stop;
}
 
 
stock TrimQuotes(String:text[]) {
    new startidx = 0;
    if (text[0] == '"') {
        new len = strlen(text);
        if (text[len-1] == '"') {
            startidx = 1;
            text[len-1] = '\0';
        }
    }
    return startidx;
}
 
getNextMapName(String:szArg[], iMax)
{
    GetConVarString(g_cvar_nextmap,szArg,iMax)
    
    if (IsMapValid(szArg)) return
    
    strcopy(szArg, iMax, g_nextMap)
    
    SetConVarString(g_cvar_nextmap,g_nextMap)
    
    return
}
 
public Action:Cmd_List(client, args) 
{
    PrintToConsole(client, "Map Cycle:");
    
    for (new i=0; i<g_iMapCount; i++)
    {
        PrintToConsole(client, "%s",g_szMapNames[i]);
    }
 
    return Plugin_Handled;
}
 
LoadMaps(const String:filename[])
{
    if (!FileExists(filename))
        return 0;
 
    new String:szText[32];
 
    new Handle:hMapFile = OpenFile(filename, "r");
    
    g_iMapCount = 0;
    g_pos = -1;
    
    while(g_iMapCount < MAXMAPS && !IsEndOfFile(hMapFile))
    {
        ReadFileLine(hMapFile, szText, sizeof(szText));
        TrimString(szText);
 
        if (szText[0] != ';' && strcopy(g_szMapNames[g_iMapCount], sizeof(g_szMapNames[]), szText) &&
            IsMapValid(g_szMapNames[g_iMapCount]))
        {
            ++g_iMapCount;
        }
    }
 
    return g_iMapCount;
}
 
FindAndSetNextMap()
{
    if(g_pos == -1)
    {
        decl String:szCurrent[64];
        GetCurrentMap(szCurrent, 64);

        for(new i = 0; i < g_iMapCount; i++)
        {
            if(strcmp(szCurrent, g_szMapNames[i], false) == 0)
            {
                g_pos = i;
                break;
            }
        }
        
        if(g_pos == -1)
            g_pos = 0;
    }
 
    strcopy(g_nextMap, sizeof(g_nextMap), g_szMapNames[g_pos+1]);
    SetConVarString(g_cvar_nextmap,g_nextMap);
}