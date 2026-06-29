#include <sourcemod>
#include <sdktools>
#pragma  semicolon 1

new propinfoghost;
public OnPluginStart()
{
propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
}
 
public Action:OnPlayerRunCmd(client, &buttons)
{
 
//ingame?
if (!IsClientInGame(client)) return;
 
//human?
if (IsFakeClient(client)) return;
 
 
//infected?
if (GetClientTeam(client) != 3) return;
 
if (!IsPlayerAlive(client)) return;
 
if(IsPlayerSpawnGhost(client)) return;
 
//boomer (class = 2) spitter (class = 4) smoker (class = 1)
if (GetEntProp(client, Prop_Send,  "m_zombieClass") != 2) return;
 
//reload button?
if  (!(buttons & IN_RELOAD)) return;
 
//kill boomer
ForcePlayerSuicide(client);
}  
 
bool:IsPlayerSpawnGhost(client)
{
 if(GetEntData(client, propinfoghost, 1)) return true;
 else return false;
}
