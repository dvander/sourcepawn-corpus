#include <sourcemod>
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[L4D] Silencer Weapon.",
	author = "Figa edited by [†×Ą]AYA SUPAY[Ļ×Ø]",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/AyaSupay/"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_silenceron", EnableAllSilencerOn, "enable silencer");
    RegConsoleCmd("sm_silenceroff", EnableAllSilencerOff, "disable silencer");
}
public Action EnableAllSilencerOn(int client, int args)
{
    for(int i=1; i<=MaxClients; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
        SetEntProp(i, Prop_Send, "m_upgradeBitVec", 262144, 4);
    }
}	
public Action EnableAllSilencerOff(int client, int args)
{
    for(int i=1; i<=MaxClients; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
        SetEntProp(i, Prop_Send, "m_upgradeBitVec", 0, 4);
    }
}