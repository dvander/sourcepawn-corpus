#include <sourcemod>
#include <cstrike>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

#define ServerTag "Server"
#define RespawnConfgig "configs/autorespawn_mapconfig.cfg"

bool SpawnkillerEnabled, RespawnOnMap, CanRespawn, SpawnKilled[MAXPLAYERS+1];
char g_Config[PLATFORM_MAX_PATH], g_CurrentMap[128], spawnkiller[4], respawntype[4], lives[4], info[128], seconds[4];
int LivesUsed[MAXPLAYERS + 1]; SpawnCheck[MAXPLAYERS+1];
Handle RespawnEndTimer;
ConVar RespawnLivesCvar, RespawnTimeCvar, RespawnMaxtimeCvar, RespawnTypeCvar;

// ====[ PLUGIN ]==============================================================
public Plugin myinfo =
{
    name = "Autorespawn system",
    author = "⸇ᴴᴱ HUИTΞƦ",
    description = "",
    version = "1.3a",
    url = "http://steamcommunity.com/profiles/76561198047681263"
};

// ====[ FUNCTIONS ]===========================================================
public void OnPluginStart()
{
    RespawnTypeCvar = CreateConVar("sm_respawn_type", "1", "Respawn type, 0-timer, 1-lives, 2 - infinite respawn", 0, true, 0.0, true, 2.0);
    RespawnTimeCvar = CreateConVar("sm_respawn_time", "2.5", "Time after death for respawn", 0, true, 0.1, false, 1.0);
    RespawnLivesCvar = CreateConVar("sm_respawn_lives", "3", "The number of lives a player has.", 0, true, 1.0, false, 1.0);
    RespawnMaxtimeCvar = CreateConVar("sm_respawn_maxtime", "60.0", "Max respawn time per round", 0, true, 0.1, false, 1.0);

    RegAdminCmd("sm_autorespawnmenu", AutoRespawnMenu, ADMFLAG_BAN);
	
    RegAdminCmd("sm_respawntype", Command_RespawnType, ADMFLAG_ROOT);
    RegAdminCmd("sm_respawnlives", Command_SetLives, ADMFLAG_ROOT);
    RegAdminCmd("sm_respawntimer", Command_SetTimer, ADMFLAG_ROOT);
    RegAdminCmd("sm_respawnsk", Command_SpawnKiller, ADMFLAG_ROOT);
    
    HookEvent("player_death", PlayerDeath);
    HookEvent("round_prestart", RoundStart);
    HookEvent("player_spawn", PlayerSpawn);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max)
{
    CreateNative("SpawnKilled", Native_Spawnkiller);
    CreateNative("RespawnOn", Native_RespawnOn);
    return APLRes_Success;
}

public int Native_Spawnkiller(Handle plugin, int argc)
{
    int client = GetNativeCell(1);
    bool value = GetNativeCell(2);
    if(RespawnOnMap){
        SpawnKilled[client] = value;
    }
}

public int Native_RespawnOn(Handle plugin, int argc)
{
    return RespawnOnMap;
}

public void OnMapStart()
{
    BuildPath(Path_SM, g_Config, sizeof(g_Config), RespawnConfgig);
    if(!FileExists(g_Config))
    {
        KeyValues generatefile = new KeyValues("respawnmaps");
        generatefile.ExportToFile(g_Config);
        delete generatefile;
    }
    ParseConfig();

	if(RespawnOnMap)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
				LivesUsed[i] = 0;
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
    if(RespawnOnMap){
        SpawnKilled[client] = false;}
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if(!RespawnOnMap)
        return Plugin_Handled;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    switch(RespawnTypeCvar.IntValue)
    {
        case 0:
        {
            int RespawnSeconds = RoundFloat(RespawnMaxtimeCvar.FloatValue);
            CanRespawn = true;
            SpawnKilled[client] = false;
            if(RespawnEndTimer != null){KillTimer(RespawnEndTimer);RespawnEndTimer = null;}
            RespawnEndTimer = CreateTimer(RespawnMaxtimeCvar.FloatValue, EndRespawn);
            CPrintToChatAll("[{lightblue}%s{default}] You can auto-respawn for the first {green}%i {default}seconds of the round.", ServerTag, RespawnSeconds);
        }
        case 1:
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
                {
                    LivesUsed[i] = 0;
                    SpawnKilled[i] = false;
                }
            }
            CPrintToChatAll("[{lightblue}%s{default}] You can auto-respawn {green}%i {default}times per round.", ServerTag, RespawnLivesCvar.IntValue);
        }
        default: if(SpawnKilled[client]){SpawnKilled[client] = false;}
    }

    return Plugin_Continue;
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (RespawnOnMap && !SpawnKilled[client])
    {
        SpawnCheck[client] = GetTime();
    }
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if(!RespawnOnMap)
        return Plugin_Handled;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    char weapon[32];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    if ((GetTime() - SpawnCheck[client]) < 2.0 && StrEqual(weapon, "trigger_hurt") && SpawnkillerEnabled)
    {
        CPrintToChat(client, "[{orange}%s{default}] Spawnkiller {green}detected{default}. Wait for the new round to use auto-respawn.", ServerTag);
        SpawnKilled[client] = true;
    }

    switch(SpawnkillerEnabled)
    {
        case true:
        {
            switch(RespawnTypeCvar.IntValue)
            {
                case 0:
                {
                    if(!SpawnKilled[client] && CanRespawn)
                    respawnplayer(client);
                }
                default: 
                {
                    if(!SpawnKilled[client])
                    respawnplayer(client);
                }
            }
        }
        case false:
        {
            switch(RespawnTypeCvar.IntValue)
            {
                case 0:
                {
                    if(!CanRespawn)
                    respawnplayer(client);
                }
                default: respawnplayer(client);
            }
        }
    }

    return Plugin_Continue;
}

// ====[ COMMANDS ]============================================================
public Action AutoRespawnMenu(int client, int args)
{
    Respawn(client, args);
}

public Action Command_RespawnType(int client, int args)
{
    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
    BuildPath(Path_SM, g_Config, sizeof(g_Config), RespawnConfgig);

    KeyValues ResType = new KeyValues("respawnmaps");
    ResType.ImportFromFile(g_Config);
    GetCmdArgString(respawntype, sizeof(respawntype));

    if (KvJumpToKey(ResType, g_CurrentMap))
    {
         if(StrEqual(respawntype, "0", false))
         {
             Format(respawntype, sizeof(respawntype), "0");
             CReplyToCommand(client, "[{orange}%s{default}] Autorespawn will use a {red}timer{default}.", g_CurrentMap);

         }
         else if(StrEqual(respawntype, "1", false))
         {
             Format(respawntype, sizeof(respawntype), "1");
             CReplyToCommand(client, "[{orange}%s{default}] Autorespawn will use a {red}live system{default}.", g_CurrentMap);
         }
         else if(StrEqual(respawntype, "2", false))
         {
             Format(respawntype, sizeof(respawntype), "2");
             CReplyToCommand(client, "[{orange}%s{default}] Players will respawn {red}infinite {default}times.", g_CurrentMap);
         }
         else
         {
             CReplyToCommand(client, "[{red}SM{default}] Usage: {green}sm_respawntype {default}<{lightgreen}0{default}-Timer{red}/{lightgreen}1{default}-Lives system{red}/{lightgreen}2{default}-Infinite Respawn>");
             delete ResType;
             return Plugin_Handled;
         }

         if(RespawnEndTimer != null){KillTimer(RespawnEndTimer);RespawnEndTimer = null;}
         ResType.SetString("type", respawntype);
         ResType.Rewind();
         ResType.ExportToFile(g_Config);
         delete ResType;
         ParseConfig();
    }
    else
    {
         delete ResType;
         CReplyToCommand(client,"[{orange}%s{default}] This map doesn't have autorespawn enabled. Enable it with {green}!addrespawn{default}.", g_CurrentMap);
    }

    return Plugin_Continue;
}

public Action Command_SpawnKiller(int client, int args)
{
    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
    BuildPath(Path_SM, g_Config, sizeof(g_Config), RespawnConfgig);

    KeyValues SpawnKillCheck = new KeyValues("respawnmaps");
    SpawnKillCheck.ImportFromFile(g_Config);
    GetCmdArgString(spawnkiller, sizeof(spawnkiller));

    if (KvJumpToKey(SpawnKillCheck, g_CurrentMap))
    {
         if(StrEqual(spawnkiller, "1", false))
         {
             Format(spawnkiller, sizeof(spawnkiller), "1");
             CReplyToCommand(client, "[{orange}%s{default}] Spawnkiller is now {green}enabled{default}.", g_CurrentMap);
         }
         else if(StrEqual(spawnkiller, "0", false))
         {
             Format(spawnkiller, sizeof(spawnkiller), "0");
             CReplyToCommand(client, "[{orange}%s{default}] Spawnkiller is now {red}disabled{default}.", g_CurrentMap);
         }
         else
         {
             delete SpawnKillCheck;
             CReplyToCommand(client, "[{red}SM{default}] Usage: {green}sm_respawnsk {default}<{lightgreen}0{default} - Off{red} | {lightgreen}1{default} - On>");
             return Plugin_Handled;
         }

         SpawnKillCheck.SetString("spawnkiller", spawnkiller);
         SpawnKillCheck.Rewind();
         SpawnKillCheck.ExportToFile(g_Config);
         delete SpawnKillCheck;
         ParseConfig();
    }
    else
    {
         delete SpawnKillCheck;
         CReplyToCommand(client,"[{orange}%s{default}] This map doesn't have autorespawn enabled. Enable it with {green}!addrespawn{default}.", g_CurrentMap);
    }

    return Plugin_Continue;
}

public Action Command_SetLives(int client, int args)
{
    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
    BuildPath(Path_SM, g_Config, sizeof(g_Config), RespawnConfgig);

    KeyValues AddLives = new KeyValues("respawnmaps");
    AddLives.ImportFromFile(g_Config);
    GetCmdArgString(lives, sizeof(lives));
    int livesint = StringToInt(lives);

    if (args < 1)
    {
        CReplyToCommand(client, "[{red}SM{default}] Usage: {green}sm_respawnlives {default}|>=1|");
        return Plugin_Handled;
    }

    if (KvJumpToKey(AddLives, g_CurrentMap))
    {
         AddLives.SetString("lives", lives);
         AddLives.Rewind();
         AddLives.ExportToFile(g_Config);
         delete AddLives;
         ParseConfig();
         CReplyToCommand(client,"[{orange}%s{default}] Players can now respawn up to {lightgreen}%i {default}time(s).", g_CurrentMap, livesint);
    }
    else
    {
         delete AddLives;
         CReplyToCommand(client,"[{orange}%s{default}] This map doesn't have autorespawn enabled. Enable it with {green}!addrespawn{default}.", g_CurrentMap);
    }
    
    return Plugin_Continue;
}

public Action Command_SetTimer(int client, int args)
{
    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
    BuildPath(Path_SM, g_Config, sizeof(g_Config), RespawnConfgig);

    KeyValues AddLives = new KeyValues("respawnmaps");
    AddLives.ImportFromFile(g_Config);
    GetCmdArgString(seconds, sizeof(seconds));
    int secondsint = StringToInt(seconds);

    if (args < 1)
    {
        CReplyToCommand(client, "[{red}SM{default}] Usage: {green}sm_respawntimer {default}|>=1|");
        return Plugin_Handled;
    }

    if (KvJumpToKey(AddLives, g_CurrentMap))
    {
         AddLives.SetString("maxtime", seconds);
         AddLives.Rewind();
         AddLives.ExportToFile(g_Config);
         delete AddLives;
         ParseConfig();
         CReplyToCommand(client,"[{orange}%s{default}] Player can now respawn for {lightgreen}%i {default}seconds.", g_CurrentMap, secondsint);
    }
    else
    {
         delete AddLives;
         CReplyToCommand(client,"[{orange}%s{default}] This map doesn't have autorespawn enabled. Enable it with {green}!addrespawn{default}.", g_CurrentMap);
    }
    
    return Plugin_Continue;
}

// ====[ RESPAWN MENU ]=========================================================
public void Respawn(int client, int args)
{
    Menu RespawnMenu = new Menu(Respawn_Menu);
    RespawnMenu.SetTitle("Autorespawn system ADMIN MENU");
    RespawnMenu.AddItem("AddCurrent", "Enable autorespawn on current map ");
    RespawnMenu.AddItem("RemoveCurrent", "Remove autorespawn from current map");
    RespawnMenu.ExitButton = true;
    RespawnMenu.Display(client, 15);
}

public int Respawn_Menu(Menu menu, MenuAction action, int client, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            menu.GetItem(param2, info, sizeof(info));

            if (StrEqual(info, "AddCurrent"))
            {
                GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
                BuildPath(Path_SM, g_Config, sizeof(g_Config), RespawnConfgig);

                KeyValues RespawnMaps = new KeyValues("respawnmaps");
                RespawnMaps.ImportFromFile(g_Config);

                if (KvJumpToKey(RespawnMaps, g_CurrentMap))
                {
                    delete RespawnMaps;
                    CReplyToCommand(client,"[{orange}%s{default}] This map already has autorespawn {green}enabled{default}.", g_CurrentMap);
                }
                else
                {
                    RespawnMaps.JumpToKey(g_CurrentMap, true);
                    RespawnMaps.SetString("type", "1");
                    RespawnMaps.SetString("maxtime", "60");
                    RespawnMaps.SetString("lives", "3");
                    RespawnMaps.SetString("spawnkiller", "1");
                    RespawnMaps.Rewind();
                    RespawnMaps.ExportToFile(g_Config);
                    delete RespawnMaps;
                    ParseConfig();
                    CReplyToCommand(client,"[{orange}%s{default}] Autorespawn {green}added{default}.", g_CurrentMap);
                }
            }
            else if (StrEqual(info, "RemoveCurrent"))
            {
                GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
                BuildPath(Path_SM, g_Config, sizeof(g_Config), RespawnConfgig);

                KeyValues RemoveRespawn = new KeyValues("respawnmaps");
                RemoveRespawn.ImportFromFile(g_Config);

                if (!KvJumpToKey(RemoveRespawn, g_CurrentMap))
                {
                    delete RemoveRespawn;
                    CReplyToCommand(client,"[{orange}%s{default}] This map doesn't have autorespawn enabled, therefore it can't be removed.", g_CurrentMap);
                }
                else
                {
                    RemoveRespawn.DeleteThis();
                    RemoveRespawn.Rewind();
                    RemoveRespawn.ExportToFile(g_Config);
                    delete RemoveRespawn;
                    ParseConfig();
                    CReplyToCommand(client,"[{orange}%s{default}] Autorespawn {lightred}removed{default}.", g_CurrentMap);
                }

            }
        }
        case MenuAction_End:{delete menu;}
    }    

    return 0;
}

// ====[ TIMERS]===============================================================
public Action EndRespawn(Handle timer)
{
    CanRespawn = false;
    CPrintToChatAll("[{lightgreen}Info{default}] Autorespawn is now {lightred}disabled{default}. Wait for the new round.");
    KillTimer(RespawnEndTimer);
    RespawnEndTimer = null;
    return Plugin_Continue;
}

// ====[ MISC ]================================================================
void respawnplayer(int client)
{
    if(!RespawnOnMap || IsPlayerAlive(client))
        return;

    switch(RespawnTypeCvar.IntValue)
    {
        case 0:{
            CPrintToChat(client, "[{lightblue}%s{default}] Respawning in {green}%.1f{default} seconds. ", ServerTag, RespawnTimeCvar.FloatValue);
            CreateTimer(RespawnTimeCvar.FloatValue, respawntheplayer, GetClientUserId(client));
        }
        case 1:
        {
            if(++LivesUsed[client] > RespawnLivesCvar.IntValue){
                CPrintToChat(client, "[{lightblue}%s{default}] You have no more lives left, wait for the new round.", ServerTag);}
            else if(++LivesUsed[client] == RespawnLivesCvar.IntValue){
                CPrintToChat(client, "[{lightblue}%s{default}] Respawning in {green}%.1f{default} seconds. This is your {green}last{default} live.", ServerTag, RespawnTimeCvar.FloatValue);
                CreateTimer(RespawnTimeCvar.FloatValue, respawntheplayer, GetClientUserId(client));
            }
            else{
                if(IsClientConnected(client) && !IsFakeClient(client)){
                    CPrintToChat(client, "[{lightblue}%s{default}] Respawning in {green}%.1f{default} seconds. Lives remaining: {green}%i{default}.", ServerTag, RespawnTimeCvar.FloatValue, RespawnLivesCvar.IntValue - LivesUsed[client]);
                    CreateTimer(RespawnTimeCvar.FloatValue, respawntheplayer, GetClientUserId(client));}
                  }
        }
        case 2:{
            CPrintToChat(client, "[{lightblue}%s{default}] Respawning in {green}%.1f{default} seconds. ", ServerTag, RespawnTimeCvar.FloatValue);
            CreateTimer(RespawnTimeCvar.FloatValue, respawntheplayer, GetClientUserId(client));
        }
  
    }
}

public Action respawntheplayer(Handle timer, int userid)
{
   int client = GetClientOfUserId(userid);
   if(client == 0) return;

   if(IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) > 1)
      CS_RespawnPlayer(client);
}

// ====[ PARSE MAP ]============================================================
void ParseConfig()
{
    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
    BuildPath(Path_SM, g_Config, sizeof(g_Config), RespawnConfgig);

    KeyValues respawncheck = new KeyValues("respawnmaps");

    if (FileToKeyValues(respawncheck, g_Config))
    {
        if (KvJumpToKey(respawncheck, g_CurrentMap))
        {
            Handle res = FindConVar("sm_respawn_lives");
            Handle typeres = FindConVar("sm_respawn_type");
            Handle timetores = FindConVar("sm_respawn_maxtime");

            int spawnkill = KvGetNum(respawncheck, "spawnkiller");
            int numoflives = KvGetNum(respawncheck, "lives");
            int typeofres = KvGetNum(respawncheck, "type");
            int timetorespawn = KvGetNum(respawncheck, "maxtime");

            if(spawnkill){
                SpawnkillerEnabled = true;
            }
            else{
                SpawnkillerEnabled = false;
            }

            float RespawnSeconds = float(timetorespawn);
            SetConVarFloat(timetores, RespawnSeconds, true, false);
            SetConVarInt(typeres, typeofres, true, false);
            SetConVarInt(res, numoflives, true, false);
            RespawnOnMap = true;
            delete res;
            delete typeres;
            delete timetores;
        }
        else
        {
            RespawnOnMap = false;
            SpawnkillerEnabled = false;
        }
    }
    delete respawncheck;
}