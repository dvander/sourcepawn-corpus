#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <clientprefs>

#include <scp>
#include <multicolors>
#define VERSION "0.5"
#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientInGame(%1))
 
native Store_GetClientCredits(client);
native Store_SetClientCredits(client, credits);
 
new TotalTime[MAXPLAYERS+1];
new iTeam[MAXPLAYERS+1];
 
new bool:bCountSpec;
new bool:bCountCT;
new bool:bCountT;

#pragma tabsize 0
#define MAXTAGS 40
enum Tags
{
    String:Tag[32],
    String:Color[10],
    PlayTimeNeeded,
    AdminFlags,
    CreditsReward,
    String:Benefit[32]
}
new TagHandler[MAXTAGS+1][Tags];
new TagCount;
 
new Handle:c_GameTime = INVALID_HANDLE;
 
new Handle:CountSpecs = INVALID_HANDLE;
new Handle:AllowCT = INVALID_HANDLE;
new Handle:AllowT = INVALID_HANDLE;

 
public Plugin:myinfo =
{
    name = "Play Time Ranking Advanced",
    author = "Mitch, Eyal, Shitler",
    description = "Play Tag Ranks with Progression",
    version = VERSION,
    url = "http://snbx.info/"
}
 
public OnPluginStart()
{
    c_GameTime =    RegClientCookie("PlayTime",     "PlayTime", CookieAccess_Private);
    CreateTimer(1.0, CheckTime, _, TIMER_REPEAT);
    LoadConfig();
    CountSpecs = CreateConVar("sm_playtime_countspec", "0", "Addtime if the players are in spec?");
    AllowT = CreateConVar("sm_playtime_count2", "1", "Addtime if the players are in Terrorist/Red?");
    AllowCT = CreateConVar("sm_playtime_count3", "1", "Addtime if the players are in Counter-Terrorist/blue?");
    AutoExecConfig(true, "playtime");
    bCountSpec = GetConVarBool(CountSpecs);
    bCountT = GetConVarBool(AllowT);
    bCountCT = GetConVarBool(AllowCT); 
    HookConVarChange(CountSpecs,    CvarUpdated);
    HookConVarChange(AllowT,        CvarUpdated);
    HookConVarChange(AllowCT,       CvarUpdated);
   
    RegConsoleCmd("sm_nextlvl", Command_PlayTime, "Shows your play time and play time for next level.");
    RegConsoleCmd("sm_levels", Command_Levels, "Shows what you get per level");
	
	ServerCommand("sm_reloadadmins");
   
	AddCommandListener(ReloadAdmins, "sm_reloadadmins");
	 
	HookEvent("player_team", Event_Team);
	HookEvent("player_spawn", Event_Spawn);
	
	CreateConVar("playtime_version", VERSION, "Tag Ranking Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);   
	for(new client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            iTeam[client] = GetClientTeam(client);
            if(AreClientCookiesCached(client))
            {
                OnClientCookiesCached(client);
            }
           
            OnClientPostAdminCheck(client);
        }
        else
        {
            iTeam[client] = 0;
        }
    }
}
 
public OnMapStart()
{
    AddFileToDownloadsTable("sound/ui/xp_levelup.wav");
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new CurrentLevel = -1;
    for(new X = TagCount-1; X >= 0; X--)
    {
        if(((TagHandler[X][PlayTimeNeeded])*60) <= TotalTime[client])
            CurrentLevel = X;
			CS_SetClientClanTag(client, TagHandler[CurrentLevel][Tag])
    }
}

public Action:Command_Levels(client, args)
{
    new Handle:hMenu = CreateMenu(LevelsMenu_Handler);
   
    new CurrentLevel = -1;
   
    new String:TempFormat[100];
    for(new X = TagCount-1; X >= 0; X--)
    {
        if(!StrEqual(TagHandler[X][Benefit], ""))
        {  
            Format(TempFormat, sizeof(TempFormat), "%s - %s", TagHandler[X][Tag], TagHandler[X][Benefit]);
           
            if((TagHandler[X][PlayTimeNeeded])*60 >= TotalTime[client])
                AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DISABLED);
               
            else
                AddMenuItem(hMenu, "", TempFormat, ITEMDRAW_DEFAULT);
        }
       
        if(((TagHandler[X][PlayTimeNeeded])*60) <= TotalTime[client])
            CurrentLevel = X;
    }
   
    new Float:fTime = float(TotalTime[client]), iDays, Float:fHours;
 
    iDays = RoundToFloor(fTime / 86400.0)
   
    fHours = ((fTime - float(iDays*86400)) / 3600.0);
   
    SetMenuTitle(hMenu, "Play Time: %i days, %.1f hours.\n%s -> !nextlvl for lvl up time", iDays, fHours, TagHandler[CurrentLevel][Tag]);
    DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
   
}
 
public Action:Command_PlayTime(client, args)
{
    new Float:fTime = float(TotalTime[client]), iDays, Float:fHours;
 
    iDays = RoundToFloor(fTime / 86400.0)
   
    fHours = ((fTime - float(iDays*86400)) / 3600.0);
   
    new TagNext = -1;
    if(TagCount > 0)
    {
        for(new X = 0; X < TagCount; X++)
        {
            if(((TagHandler[X][PlayTimeNeeded])*60) <= TotalTime[client])
            {
                TagNext = X-1; // X-1 = Next level
                break;
            }
        }
    }
    if(TagNext == -1)
    {
        return Plugin_Handled;
    }
   
    new Float:fNextTime = float(TagHandler[TagNext][PlayTimeNeeded]*60), iNextDays, Float:fNextHours;
 
    iNextDays = RoundToFloor(fNextTime / 86400.0)
   
    fNextHours = ((fNextTime - float(iNextDays*86400)) / 3600.0);
   
    CPrintToChat(client, "{orange}Play Time: {yellow}%i days, %.1f hours. {orange}For next level: {yellow}%i days, %.1f hours", iDays, fHours, iNextDays - iDays, fNextHours - fHours);
 
    return Plugin_Handled;
}
public LevelsMenu_Handler(Handle:hMenu, MenuAction:action, client, item)
{
    if(action == MenuAction_End)
        CloseHandle(hMenu);
       
    else if(action == MenuAction_Select)
        Command_Levels(client, 0);
}
 
public Action:ReloadAdmins(client, const String:Arg[], argc)
{
    for(new i=1;i <= MaxClients;i++)
    {
        if(!IsClientInGame(i))
            continue;
       
        else if(IsFakeClient(i))
            continue;
           
        else if(!AreClientCookiesCached(i))
            continue;
           
        new UserId = GetClientUserId(i);
        CreateTimer(0.0, GiveFlags, UserId);
        CreateTimer(2.0, GiveFlags, UserId);
    }
}
 
public OnClientPostAdminCheck(client)
{
    if(IsFakeClient(client))
        return;
       
    new UserId = GetClientUserId(client);
    CreateTimer(0.0, GiveFlags, UserId);
    CreateTimer(2.0, GiveFlags, UserId);
}
 
public Action:GiveFlags(Handle:hTimer, UserId)
{
    new client = GetClientOfUserId(UserId);
   
    if(client == 0)
        return Plugin_Continue;
       
    new flags = 0;
    for(new X = 0; X < TagCount; X++)
    {
        if(((TagHandler[X][PlayTimeNeeded])*60) <= TotalTime[client])
        {
            flags |= TagHandler[X][AdminFlags];
        }
    }
   
    if(flags != 0)
        SetUserFlagBits(client, GetUserFlagBits(client) | flags);
       
    return Plugin_Continue;
}


public CvarUpdated(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(convar == CountSpecs)
    {
        bCountSpec = GetConVarBool(CountSpecs);
    }
    else if(convar == AllowT)
    {
        bCountT = GetConVarBool(AllowT);
    }
    else if(convar == AllowCT)
    {
        bCountCT = GetConVarBool(AllowCT);
    }
}
public OnPluginEnd()
{
    for(new client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            OnClientDisconnect(client);
        }
    }
}
 
public Action:Event_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    iTeam[client] = GetEventInt(event, "team"); //GetClientTeam(client);
	
	new CurrentLevel = -1;
    for(new X = TagCount-1; X >= 0; X--)
    {
        if(((TagHandler[X][PlayTimeNeeded])*60) <= TotalTime[client])
            CurrentLevel = X;
			CS_SetClientClanTag(client, TagHandler[CurrentLevel][Tag])
    }
    //PrintToChat(client, "Team: %i", iTeam[client]);
}

LoadConfig() {
   
    for(new X = 0; X < MAXTAGS; X++)
    {
        strcopy(TagHandler[X][Tag], 32, "");
        strcopy(TagHandler[X][Color], 10, "");
        TagHandler[X][PlayTimeNeeded] = 0;
    }
    new Handle:kvs = CreateKeyValues("TagConfig");
    decl String:sPaths[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPaths, sizeof(sPaths),"configs/ranktime.cfg");
    if(FileToKeyValues(kvs, sPaths))
    {
        if (KvGotoFirstSubKey(kvs))
        {
            TagCount = 0;
            do
            {
                KvGetSectionName(kvs, TagHandler[TagCount][Tag], 32);
                KvGetString(kvs, "color", TagHandler[TagCount][Color], 10);
                TagHandler[TagCount][PlayTimeNeeded] = KvGetNum(kvs, "playtime", 0);
                new String:sAdminFlags[26];
                KvGetString(kvs, "adminflags", sAdminFlags, sizeof(sAdminFlags));
               
 
                TagHandler[TagCount][AdminFlags] = ReadFlagString(sAdminFlags);
               
                TagHandler[TagCount][CreditsReward] = KvGetNum(kvs, "creditsreward");
               
                KvGetString(kvs, "benefit", TagHandler[TagCount][Benefit], 32);
                ReplaceString(TagHandler[TagCount][Color], 32, "#", "");
                //PrintToServer("Tag: %s\n  Color: %s\n  Time: %i", TagHandler[TagCount][Tag], TagHandler[TagCount][Color], TagHandler[TagCount][PlayTimeNeeded]);
                TagCount++;
            } while (KvGotoNextKey(kvs));
        }
    }
    CloseHandle(kvs);
}
 
public Action:CheckTime(Handle:timer)
{
    for(new client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            if(((iTeam[client] > 2) && bCountSpec) || ((iTeam[client] == 2) && bCountT) || ((iTeam[client] == 3) && bCountCT))
            {
                TotalTime[client]++;
               
                for(new X = 0; X < TagCount; X++)
                {
                    if(((TagHandler[X][PlayTimeNeeded])*60) == TotalTime[client])
                    {
                        CPrintToChat(client, "{yellow}You have reached {orange}%s {yellow}and earned {orange}%i {yellow}credits! {yellow}Type {orange}!levels {yellow}to learn more.", TagHandler[X][Tag], TagHandler[X][CreditsReward]);
                        ClientCommand(client, "play ui/xp_levelup.wav");
						CS_SetClientClanTag(client, TagHandler[X][Tag])
                        Store_GiveClientCredits(client, TagHandler[X][CreditsReward]);
                        OnClientPostAdminCheck(client);
                       
                        break;
                    }
                }
                //PrintToChat(client, "Total Time: %i", TotalTime[client]);
            }
        }
    }
    return Plugin_Continue;
}
public OnClientCookiesCached(client)
{
    new String:TimeString[12]; //Big number, i know this is just incase people play for a year total.
    GetClientCookie(client, c_GameTime, TimeString, sizeof(TimeString));
    TotalTime[client]  = StringToInt(TimeString);
}
public OnClientDisconnect(client)
{
    if(AreClientCookiesCached(client))
    {
        new String:TimeString[12];
        Format(TimeString, sizeof(TimeString), "%i", TotalTime[client]);
        SetClientCookie(client, c_GameTime, TimeString);
    }
}
//Message Config, and Message Handling
 
public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[]) {
    new TagNum = -1;
    if(TagCount > 0)
    {
        for(new X = 0; X < TagCount; X++)
        {	
            if(((TagHandler[X][PlayTimeNeeded])*60) <= TotalTime[author])
            {
                TagNum = X;
                break;
            }
        }
    }
    if(TagNum == -1)
    {
        return Plugin_Continue;
    }
    //This is pretty much Dr.McKay's Customchat color code, just replaced variables.
    if(strlen(TagHandler[TagNum][Tag]) > 0)
    {
        if(StrEqual(TagHandler[TagNum][Color], "T", false))
        {
            Format(name, MAXLENGTH_NAME, "\x03%s %s", TagHandler[TagNum][Tag], name);
        }
        else if(StrEqual(TagHandler[TagNum][Color], "G", false))
        {
            Format(name, MAXLENGTH_NAME, "\x04%s \x03%s", TagHandler[TagNum][Tag], name);
        }
        else if(StrEqual(TagHandler[TagNum][Color], "O", false))
        {
            Format(name, MAXLENGTH_NAME, "\x05%s \x03%s", TagHandler[TagNum][Tag], name);
        }
        else if(strlen(TagHandler[TagNum][Color]) == 6)
        {
            Format(name, MAXLENGTH_NAME, "\x07%s%s \x03%s", TagHandler[TagNum][Color], TagHandler[TagNum][Tag], name);
        }
        else if(strlen(TagHandler[TagNum][Color]) == 8)
        {
            Format(name, MAXLENGTH_NAME, "\x08%s%s \x03%s", TagHandler[TagNum][Color], TagHandler[TagNum][Tag], name);
        }
        else
        {
            Format(name, MAXLENGTH_NAME, "\x01%s \x03%s", TagHandler[TagNum][Tag], name);
        }
    }
    return Plugin_Changed;
}
 
stock Store_GiveClientCredits(client, credits)
{
    Store_SetClientCredits(client, Store_GetClientCredits(client) + credits);
}