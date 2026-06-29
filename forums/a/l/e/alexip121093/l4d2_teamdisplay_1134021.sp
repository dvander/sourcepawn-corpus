#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "1.5"
new Handle:cvar_Gamemode = INVALID_HANDLE;
new Handle:PanelModeCVAR = INVALID_HANDLE;
new Handle:PanelDisplayCVAR = INVALID_HANDLE;
new Handle:PanelDeadCVAR = INVALID_HANDLE;
new Handle:PanelSeCVAR = INVALID_HANDLE;
new Handle:SedCVAR = INVALID_HANDLE;
new Handle:AutoDisableCVAR = INVALID_HANDLE;
new propinfoghost;
new bool:dp[MAXPLAYERS + 1];
public Plugin:myinfo =
{
name = "L4D2 Team Displayer",
author = "hihi1210,鮑",
description = "This plug-in display a team panel.",
version = "1.5",
url = "http://kdt.poheart.com"
}

public OnPluginStart()
{
CreateConVar("l4d2_teampanel_version", PLUGIN_VERSION, " Version of L4D2 Team Viewer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
PanelModeCVAR = CreateConVar("l4d2_teampanel_mode", "2", "0: disable  ,1: 1 display without auto refresh  ,2: auto refresh", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
PanelDisplayCVAR = CreateConVar("l4d2_teampanel_display", "0", "0 : display information of both teams ,1 : just display your team", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
PanelDeadCVAR = CreateConVar("l4d2_teampanel_deadautodisplay", "1", "auto display panel to dead players", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
PanelSeCVAR = CreateConVar("l4d2_teampanel_Spectatorautodisplay", "1", "auto display panel to Spectator", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
SedCVAR = CreateConVar("l4d2_teampanel_Spectatordisplay", "1", "display Spectator in the panel", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
AutoDisableCVAR = CreateConVar("l4d2_teampanel_AutoDisable", "1", "auto disable the panel when player spawn (only work with l4d2_teampanel_mode 2)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
RegConsoleCmd("sm_showteam", Command_Say);
AutoExecConfig(true, "l4d2_teamdisplay");
cvar_Gamemode = FindConVar("mp_gamemode");
propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
}
public OnMapStart()
{
if (GetConVarInt(PanelDeadCVAR) == 1)
{
HookEvent("player_death", Event_Death);
}
if (GetConVarInt(PanelSeCVAR) == 1)
{
HookEvent("player_team", Event_Team);
}
if (GetConVarInt(AutoDisableCVAR) == 1)
{
HookEvent("player_spawn", PlayerSpawn);
}
}
public PlayerSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
if (GetConVarInt(AutoDisableCVAR) == 1)
{
decl Client;
Client = GetClientOfUserId(GetEventInt(Event, "userid"));
if (Client == 0) return;
if (IsFakeClient(Client)) return;
if (dp[Client])
{
dp[Client] = false;
}
}
}
public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
if (GetConVarInt(PanelDeadCVAR) == 1)
{
new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
if (Victim == 0) return;
if (IsFakeClient(Victim)) return;
if (GetConVarInt(PanelModeCVAR) == 2)
{
if (dp[Victim]) return;
}
FakeClientCommand(Victim, "sm_showteam");
if (GetConVarInt(PanelModeCVAR) == 1)
{
PrintToChat(Victim,"[Team Displayer] You can type !showteam to show the team panel");
}
}
}
public Action:Event_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
if (GetConVarInt(PanelSeCVAR) == 1)
{
new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
if (Victim == 0) return;
if (IsFakeClient(Victim)) return;
if (GetEventInt(event, "team") !=1) return;
if (GetConVarInt(PanelModeCVAR) == 2)
{
if (dp[Victim]) return;
}
FakeClientCommand(Victim, "sm_showteam");
if (GetConVarInt(PanelModeCVAR) == 1)
{
PrintToChat(Victim,"[Team Displayer] You can type !showteam to show the team panel");
}
}
}
public OnClientPostAdminCheck(client)
{
dp[client] = false;
}
public OnClientDisconnect(client)
{
dp[client] = false;
}

public Action:Command_Say(client, args)
{
if (GetConVarInt(PanelModeCVAR) == 1)
{
Teampanel(client);
}
else if (GetConVarInt(PanelModeCVAR) == 0)
{
return;
}
else if (GetConVarInt(PanelModeCVAR) == 2)
{
if (dp[client] == false)
{
dp[client] = true;
PrintToChat(client,"[Team Displayer] You can type !showteam to disable the panel");
PrintHintText(client,"[Team Displayer] You can type !showteam to disable the panel");
CreateTimer(1.0, PAd,client, TIMER_FLAG_NO_MAPCHANGE);
}
else
{
dp[client] = false;
return;
}
}
else
{
return;
}
}

public Action:PAd(Handle:Timer, any:client)
{
if(dp[client])
{
Teampanel(client);
CreateTimer(1.0, PAd,client, TIMER_FLAG_NO_MAPCHANGE);
return;
}
else
{
dp[client] = false;
return;
}
}
public Teampanel(client)
{
new surcount = 0;
new infcount = 0;
new sepcount = 0;
new surbotcount = 0;
new infbotcount = 0;
new String:CurrentMode[16];
GetConVarString(cvar_Gamemode, CurrentMode, sizeof(CurrentMode));
new Handle:downtownrun = FindConVar("l4d_maxplayers");
new Handle:toolzrun = FindConVar("sv_maxplayers");
new maxcl;
if (downtownrun == INVALID_HANDLE)
{
//Nothing
}
if (downtownrun != INVALID_HANDLE)
{
new downtown = GetConVarInt(FindConVar("l4d_maxplayers"));
if (downtown >= 1)
{
maxcl = (GetConVarInt(FindConVar("l4d_maxplayers")));
}
}
if (toolzrun == INVALID_HANDLE)
{
//Nothing
}
if (toolzrun != INVALID_HANDLE)
{
new toolz = GetConVarInt(FindConVar("sv_maxplayers"));
if (toolz >= 1)
{
maxcl = GetConVarInt(FindConVar("sv_maxplayers"));
}
}
if (downtownrun == INVALID_HANDLE && toolzrun == INVALID_HANDLE)
{
maxcl = (MaxClients);
}
new maxplayers = GetMaxClients();
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(GetClientTeam(i) != 2) continue;
if(!IsFakeClient(i)) continue;
surbotcount++;
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(GetClientTeam(i) != 3) continue;
if(!IsFakeClient(i)) continue;
infbotcount++;
}
if(GetClientTeam(client) == 2 || GetClientTeam(client) == 1)
{
new Handle:TeamPanel = CreatePanel();
SetPanelTitle(TeamPanel, "L4D2 Team Displayer");
DrawPanelText(TeamPanel, " \n");
DrawPanelText(TeamPanel, "Survivors:");
for (new i = 1; i <= GetMaxClients(); i++)
{
if(!IsClientInGame(i)) continue;
if(!IsPlayerAlive(i)) continue;
if(IsPlayerIncapped(i)) continue;
if(GetClientTeam(i) != 2) continue;
new String:name[64];
surcount++;
GetClientName(i, name, sizeof(name));
new hp = GetClientHealth(i);
new String:addoutput[128];
Format(addoutput, sizeof(addoutput), "%s HP:%d", name, hp);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(!IsPlayerAlive(i)) continue;
if(!IsPlayerIncapped(i)) continue;
if(GetClientTeam(i) != 2) continue;
new String:name[64];
GetClientName(i, name, sizeof(name));
new hp = GetClientHealth(i);
surcount++;
new String:addoutput[128];
Format(addoutput, sizeof(addoutput), "%s (Incapped) HP:%d", name, hp);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(IsPlayerAlive(i)) continue;
if(GetClientTeam(i) != 2) continue;
new String:name[64];
GetClientName(i, name, sizeof(name));
surcount++;
new String:addoutput[128];
Format(addoutput, sizeof(addoutput), "%s (Dead) ", name);
DrawPanelText(TeamPanel, addoutput);
}
if (GetConVarInt(PanelDisplayCVAR) == 0 || GetClientTeam(client) == 1)
{
DrawPanelText(TeamPanel, " \n");
DrawPanelText(TeamPanel, "Infected:");
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(!IsPlayerAlive(i)) continue;
if(IsPlayerSpawnGhost(i)) continue;
if(GetClientTeam(i) != 3) continue;
new String:name[64];
GetClientName(i, name, sizeof(name));
infcount++;
new String:addoutput[128];
new hp = GetClientHealth(i);
Format(addoutput, sizeof(addoutput), "%s HP:%d", name, hp);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(!IsPlayerAlive(i)) continue;
if(!IsPlayerSpawnGhost(i)) continue;
if(GetClientTeam(i) != 3) continue;
new String:name[64];
GetClientName(i, name, sizeof(name));
infcount++;
new String:addoutput[128];
Format(addoutput, sizeof(addoutput), "%s (GHOST)", name);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(IsPlayerAlive(i)) continue;
if(GetClientTeam(i) != 3) continue;
new String:name[64];
GetClientName(i, name, sizeof(name));
new String:addoutput[128];
infcount++;
Format(addoutput, sizeof(addoutput), "%s (Dead)", name);
DrawPanelText(TeamPanel, addoutput);
}
}
if (GetConVarInt(SedCVAR) == 1)
{
DrawPanelText(TeamPanel, " \n");
DrawPanelText(TeamPanel, "Spectator:");
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(GetClientTeam(i) != 1) continue;
new String:name[64];
GetClientName(i, name, sizeof(name));
sepcount++;
DrawPanelText(TeamPanel, name);
}
}
DrawPanelText(TeamPanel, " \n");
new String:addoutput1[128];
new total = surcount + infcount + sepcount;
new surreal = surcount - surbotcount;
new infreal = infcount - infbotcount;
new totalreal =  surreal + infreal + sepcount;
if (GetConVarInt(PanelDisplayCVAR) == 0 || GetClientTeam(client) == 1)
{
if (GetConVarInt(SedCVAR) == 1)
{

if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1 )
{
Format(addoutput1, sizeof(addoutput1), "Total: %d(%d)/%d Survivors: %d(%d)/%d Infected: %d(%d)/%d Spectator: %d", total, totalreal,maxcl, surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")), sepcount);
}
else
{
Format(addoutput1, sizeof(addoutput1), "Total: %d(%d) Survivors: %d(%d)/%d Infected: %d(%d) Spectator: %d", total, totalreal, surcount,surreal,maxcl, infcount,infreal, sepcount);
}
}
else
{
if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1 )
{
Format(addoutput1, sizeof(addoutput1), "Total: %d(%d)/%d Survivors: %d(%d)/%d Infected: %d(%d)/%d", total, totalreal,maxcl, surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")));
}
else
{
Format(addoutput1, sizeof(addoutput1), "Total: %d(%d) Survivors: %d(%d)/%d Infected: %d(%d)", total, totalreal, surcount,surreal, maxcl, infcount,infreal);
}
}
}
else
{
if (GetConVarInt(SedCVAR) == 1)
{
if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1 )
{
Format(addoutput1, sizeof(addoutput1), "Survivors: %d(%d)/%d Spectator: %d", surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), sepcount);
}
else
{
Format(addoutput1, sizeof(addoutput1), "Survivors: %d(%d)/%d Spectator: %d", surcount,surreal,maxcl, sepcount);
}
}
else
{
if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1 )
{
Format(addoutput1, sizeof(addoutput1), "Survivors: %d(%d)/%d", surcount,surreal,GetConVarInt(FindConVar("survivor_limit")));
}
else
{
Format(addoutput1, sizeof(addoutput1), "Survivors: %d(%d)/%d", surcount,surreal,maxcl);
}
}
}
DrawPanelText(TeamPanel, addoutput1);
SendPanelToClient(TeamPanel, client, TeamPanelHandler, 30);
CloseHandle(TeamPanel);
}
else if(GetClientTeam(client) == 3)
{
new Handle:TeamPanel = CreatePanel();
SetPanelTitle(TeamPanel, "L4D2 Team Displayer");
DrawPanelText(TeamPanel, " \n");
DrawPanelText(TeamPanel, "Infected:");
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(!IsPlayerAlive(i)) continue;
if(IsPlayerSpawnGhost(i)) continue;
if(GetClientTeam(i) != 3) continue;
new String:name[64];
infcount++;
GetClientName(i, name, sizeof(name));
new String:addoutput[128];
new hp = GetClientHealth(i);
Format(addoutput, sizeof(addoutput), "%s HP:%d", name, hp);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(!IsPlayerAlive(i)) continue;
if(!IsPlayerSpawnGhost(i)) continue;
if(GetClientTeam(i) != 3) continue;
infcount++;
new String:name[64];
GetClientName(i, name, sizeof(name));
new String:addoutput[128];
Format(addoutput, sizeof(addoutput), "%s (GHOST)", name);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(IsPlayerAlive(i)) continue;
if(GetClientTeam(i) != 3) continue;
new String:name[64];
GetClientName(i, name, sizeof(name));
new String:addoutput[128];
infcount++;
Format(addoutput, sizeof(addoutput), "%s (Dead)", name);
DrawPanelText(TeamPanel, addoutput);
}
if (GetConVarInt(PanelDisplayCVAR) == 0 || GetClientTeam(client) == 1)
{
DrawPanelText(TeamPanel, " \n");
DrawPanelText(TeamPanel, "Survivors:");

for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(!IsPlayerAlive(i)) continue;
if(IsPlayerIncapped(i)) continue;
if(GetClientTeam(i) != 2) continue;
new String:name[64];
GetClientName(i, name, sizeof(name));
new hp = GetClientHealth(i);
new String:addoutput[128];
surcount++;
Format(addoutput, sizeof(addoutput), "%s HP:%d", name, hp);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(!IsPlayerAlive(i)) continue;
if(!IsPlayerIncapped(i)) continue;
if(GetClientTeam(i) != 2) continue;
new String:name[64];
GetClientName(i, name, sizeof(name));
new hp = GetClientHealth(i);
surcount++;
new String:addoutput[128];
Format(addoutput, sizeof(addoutput), "%s (Incapped) HP:%d", name, hp);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(IsPlayerAlive(i)) continue;
if(GetClientTeam(i) != 2) continue;
new String:name[64];
GetClientName(i, name, sizeof(name));
surcount++;
new String:addoutput[128];
Format(addoutput, sizeof(addoutput), "%s (Dead) ", name);
DrawPanelText(TeamPanel, addoutput);
}
}
if (GetConVarInt(SedCVAR) == 1)
{
DrawPanelText(TeamPanel, " \n");
DrawPanelText(TeamPanel, "Spectator:");
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(GetClientTeam(i) != 1) continue;
new String:name[64];
GetClientName(i, name, sizeof(name));
sepcount++;
DrawPanelText(TeamPanel, name);
}
}
DrawPanelText(TeamPanel, " \n");
new String:addoutput1[128];
new total = surcount + infcount + sepcount;
new surreal = surcount - surbotcount;
new infreal = infcount - infbotcount;
new totalreal =  surreal + infreal + sepcount;
if (GetConVarInt(PanelDisplayCVAR) == 0 || GetClientTeam(client) == 1)
{
if (GetConVarInt(SedCVAR) == 1)
{

if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1 )
{
Format(addoutput1, sizeof(addoutput1), "Total: %d(%d)/%d Survivors: %d(%d)/%d Infected: %d(%d)/%d Spectator: %d", total, totalreal,maxcl, surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")), sepcount);
}
else
{
Format(addoutput1, sizeof(addoutput1), "Total: %d(%d) Survivors: %d(%d)/%d Infected: %d(%d) Spectator: %d", total, totalreal, surcount,surreal, maxcl, infcount,infreal, sepcount);
}
}
else
{
if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1 )
{
Format(addoutput1, sizeof(addoutput1), "Total: %d(%d)/%d Survivors: %d(%d)/%d Infected: %d(%d)/%d", total, totalreal,maxcl, surcount,surreal,GetConVarInt(FindConVar("survivor_limit")), infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")));
}
else
{
Format(addoutput1, sizeof(addoutput1), "Total: %d(%d) Survivors: %d(%d)/%d Infected: %d(%d)", total, totalreal, surcount,surreal,maxcl, infcount,infreal);
}
}
}

else
{
if (GetConVarInt(SedCVAR) == 1)
{
if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1 )
{
Format(addoutput1, sizeof(addoutput1), "Infected: %d(%d)/%d Spectator: %d", infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")), sepcount);
}
else
{
Format(addoutput1, sizeof(addoutput1), "Infected: %d(%d) Spectator: %d", infcount,infreal, sepcount);
}
}
else
{
if (StrContains(CurrentMode, "versus", false) != -1 || StrContains(CurrentMode, "scavenge", false) != -1 )
{
Format(addoutput1, sizeof(addoutput1), "Infected: %d(%d)/%d", infcount,infreal,GetConVarInt(FindConVar("z_max_player_zombies")));
}
else
{
Format(addoutput1, sizeof(addoutput1), "Infected: %d(%d)", infcount,infreal);
}
}
}
DrawPanelText(TeamPanel, addoutput1);
SendPanelToClient(TeamPanel, client, TeamPanelHandler, 30);
CloseHandle(TeamPanel);
}
}
public TeamPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

stock bool:IsPlayerIncapped(client)
{
if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
return false;
}
bool:IsPlayerSpawnGhost(client)
{
if(GetEntData(client, propinfoghost, 1)) return true;
else return false;
}
