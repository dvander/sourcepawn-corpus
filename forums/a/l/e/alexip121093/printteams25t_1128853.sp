#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new propinfoghost;

public Plugin:myinfo = 
{
name = "Team",
author = "hihi1210,鮑",
description = "This plug-in allows clients to build.",
version = "1.0",
url = "http://kdt.poheart.com"
}

public OnPluginStart()
{
RegConsoleCmd("sm_showteam", Command_Say);
RegConsoleCmd("sm_isalive", Command_Test);
propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
}

public Action:Command_Say(client, args)
{
Teampanel(client);
}
public Action:Command_Test(client, args)
{
if(IsPlayerAlive(client))
{
PrintToChat(client, "[SM] Is alive");
}
else if (!IsPlayerAlive(client))
{
PrintToChat(client, "[SM] Not alive");
}
}
public Teampanel(client)
{
new surcount = 0;
new infcount = 0;
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
DrawPanelText(TeamPanel, " \n");
new String:addoutput1[64];
new total = surcount + infcount;
Format(addoutput1, sizeof(addoutput1), "Total: %d Survivors: %d Infected: %d", total, surcount, infcount);
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
DrawPanelText(TeamPanel, " \n");
new String:addoutput1[64];
new total = surcount + infcount;
Format(addoutput1, sizeof(addoutput1), "Total: %d Survivors: %d Infected: %d", total, surcount, infcount);
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
