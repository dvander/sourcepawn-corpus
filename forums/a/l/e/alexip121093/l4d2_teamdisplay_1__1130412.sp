#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "1.2"
new Handle:PanelModeCVAR = INVALID_HANDLE;
new Handle:PanelDisplayCVAR = INVALID_HANDLE;
new Handle:PanelDeadCVAR = INVALID_HANDLE;
new Handle:PanelSeCVAR = INVALID_HANDLE;
new Handle:SedCVAR = INVALID_HANDLE;

new propinfoghost;
new bool:dp[MAXPLAYERS + 1];
public Plugin:myinfo = 
{
name = "L4D2 Team Displayer",
author = "hihi1210,鮑",
description = "This plug-in display a team panel.",
version = "1.0",
url = "http://kdt.poheart.com"
}

public OnPluginStart()
{
decl String:game_name[64];
GetGameFolderName(game_name, sizeof(game_name));
if (!StrEqual(game_name, "left4dead2", false))
{
SetFailState("L4D2 Team Displayer supports Left 4 Dead 2 only.");
}
CreateConVar("l4d2_teampanel_version", PLUGIN_VERSION, " Version of L4D2 Team Viewer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
PanelModeCVAR = CreateConVar("l4d2_teampanel_mode", "2", "0: disable  ,1: 1 display without auto refresh  ,2: auto refresh", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
PanelDisplayCVAR = CreateConVar("l4d2_teampanel_display", "0", "0 : display information of both teams ,1 : just display your team", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
PanelDeadCVAR = CreateConVar("l4d2_teampanel_deadautodisplay", "1", "auto display panel to dead players", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
PanelSeCVAR = CreateConVar("l4d2_teampanel_Spectatorautodisplay", "1", "auto display panel to Spectator", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
SedCVAR = CreateConVar("l4d2_teampanel_Spectatordisplay", "1", "display Spectator in the panel", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
RegConsoleCmd("sm_showteam", Command_Say);
AutoExecConfig(true, "l4d2_teamdisplay");
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
if (GetConVarInt(PanelModeCVAR) == 2)
{
PrintToChat(Victim,"[Team Displayer] You can type !showteam to disable the panel");
}
else
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
if (GetConVarInt(PanelModeCVAR) == 2)
{
PrintToChat(Victim,"[Team Displayer] You can type !showteam to disable the panel");
}
else
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
if(GetClientTeam(client) == 2 || GetClientTeam(client) == 1)
{
new Handle:TeamPanel = CreatePanel();
SetPanelTitle(TeamPanel, "L4D2 Team Displayer");
DrawPanelText(TeamPanel, " \n");
DrawPanelText(TeamPanel, "Survivors:");
new maxplayers = GetMaxClients();
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(!IsPlayerAlive(i)) continue;
if(IsPlayerIncapped(i)) continue;
if(GetClientTeam(i) != 2) continue; 
new String:name[32];
surcount++;
GetClientName(i, name, 32);
new hp = GetClientHealth(i);
new String:addoutput[32];
Format(addoutput, sizeof(addoutput), "%s HP:%d", name, hp);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(!IsPlayerAlive(i)) continue;
if(!IsPlayerIncapped(i)) continue;
if(GetClientTeam(i) != 2) continue; 
new String:name[32];
GetClientName(i, name, 32);
new hp = GetClientHealth(i);
surcount++;
new String:addoutput[32];
Format(addoutput, sizeof(addoutput), "%s (Incapped) HP:%d", name, hp);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(IsPlayerAlive(i)) continue;
if(GetClientTeam(i) != 2) continue; 
new String:name[32];
GetClientName(i, name, 32);
surcount++;
new String:addoutput[32];
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
new String:name[32];
GetClientName(i, name, 32);
infcount++;
new String:addoutput[32];
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
new String:name[32];
GetClientName(i, name, 32);
infcount++;
new String:addoutput[32];
Format(addoutput, sizeof(addoutput), "%s (GHOST)", name);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(IsPlayerAlive(i)) continue;
if(GetClientTeam(i) != 3) continue; 
new String:name[32];
GetClientName(i, name, 32);
new String:addoutput[32];
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
new String:name[32];
GetClientName(i, name, 32);
sepcount++;
DrawPanelText(TeamPanel, name);
}
}
DrawPanelText(TeamPanel, " \n");
new String:addoutput1[64];
new total = surcount + infcount + sepcount;
if (GetConVarInt(PanelDisplayCVAR) == 0 || GetClientTeam(client) == 1)
{
if (GetConVarInt(SedCVAR) == 1)
{
Format(addoutput1, sizeof(addoutput1), "Total: %d Survivors: %d Infected: %d Spectator: %d", total, surcount, infcount, sepcount);
}
else
{
Format(addoutput1, sizeof(addoutput1), "Total: %d Survivors: %d Infected: %d", total, surcount, infcount);
}
}
else
{
if (GetConVarInt(SedCVAR) == 1)
{
Format(addoutput1, sizeof(addoutput1), "Survivors: %d Spectator: %d", surcount, sepcount);
}
else
{
Format(addoutput1, sizeof(addoutput1), "Survivors: %d", surcount);
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
new maxplayers = GetMaxClients();
DrawPanelText(TeamPanel, " \n");
DrawPanelText(TeamPanel, "Infected:");
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(!IsPlayerAlive(i)) continue;
if(IsPlayerSpawnGhost(i)) continue;
if(GetClientTeam(i) != 3) continue; 
new String:name[32];
infcount++;
GetClientName(i, name, 32);
new String:addoutput[32];
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
new String:name[32];
GetClientName(i, name, 32);
new String:addoutput[32];
Format(addoutput, sizeof(addoutput), "%s (GHOST)", name);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(IsPlayerAlive(i)) continue;
if(GetClientTeam(i) != 3) continue; 
new String:name[32];
GetClientName(i, name, 32);
new String:addoutput[32];
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
new String:name[32];
GetClientName(i, name, 32);
new hp = GetClientHealth(i);
new String:addoutput[32];
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
new String:name[32];
GetClientName(i, name, 32);
new hp = GetClientHealth(i);
surcount++;
new String:addoutput[32];
Format(addoutput, sizeof(addoutput), "%s (Incapped) HP:%d", name, hp);
DrawPanelText(TeamPanel, addoutput);
}
for (new i = 1; i <= maxplayers; i++)
{
if(!IsClientInGame(i)) continue;
if(IsPlayerAlive(i)) continue;
if(GetClientTeam(i) != 2) continue; 
new String:name[32];
GetClientName(i, name, 32);
surcount++;
new String:addoutput[32];
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
new String:name[32];
GetClientName(i, name, 32);
sepcount++;
DrawPanelText(TeamPanel, name);
}
}
DrawPanelText(TeamPanel, " \n");
new String:addoutput1[64];
new total = surcount + infcount + sepcount;
if (GetConVarInt(PanelDisplayCVAR) == 0 || GetClientTeam(client) == 1)
{
if (GetConVarInt(SedCVAR) == 1)
{
Format(addoutput1, sizeof(addoutput1), "Total: %d Survivors: %d Infected: %d Spectator: %d", total, surcount, infcount, sepcount);
}
else
{
Format(addoutput1, sizeof(addoutput1), "Total: %d Survivors: %d Infected: %d", total, surcount, infcount);
}
}
else
{
if (GetConVarInt(SedCVAR) == 1)
{
Format(addoutput1, sizeof(addoutput1), "Infected: %d Spectator: %d", infcount, sepcount);
}
else
{
Format(addoutput1, sizeof(addoutput1), "Infected: %d", infcount);
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
