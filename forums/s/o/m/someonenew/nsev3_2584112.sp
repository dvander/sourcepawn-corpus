#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VMT_PATH "materials/blutak/blutakk.vmt"
#define VTF_PATH "materials/blutak/blutakk.vtf"

stock bool:IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
  name = "NoScope Express",
  author = "SomeoneNew",
  description= "The Noscope Express! Choo Choo!",
  version = "1.2",
  url = ""
}

public void OnPluginStart()
{
    AddCommandListener(OnSay, "say");
    AddCommandListener(OnSay, "say_team");
	
    RegConsoleCmd("sm_nse", Command_Toggle, "Toggle NSE On");
    RegConsoleCmd("sm_nseoff", Command_Remove, "Toggle NSE Off");
	
	InitPrecache();
}
public void InitPrecache()
{
	AddFileToDownloadsTable(VMT_PATH);
	AddFileToDownloadsTable(VTF_PATH);
	PrecacheModel("materials/blutak/blutakk.vtf");
}

public Action Command_Toggle(int client, int args)
{
	CreateOverlayRepeat(client);
    PrintToChat(client, "[SM] \x02 All aboard the NoScope Express! Choo Choo!");
}	
public Action Command_Remove(int client, int args)
{
	CreateOverlayRemove(client);
	PrintToChat(client, "[SM] \x02 NoScopeExpress has been removed, This makes me sad.");
}
public void CreateOverlayRepeat(int client)
{
	CreateTimer(0.1, OverlayOn, client, TIMER_REPEAT);	
}
public void CreateOverlayRemove(int client)
{
	CreateTimer(0.0, OverlayOff, client, TIMER_REPEAT);	
}
public Action OverlayOn(Handle timer, any client)
{
	SetClientOverlay(client, "blutak/blutakk");
	return Plugin_Handled;
}
public Action OverlayOff(Handle timer, any client)
{
	SetClientOverlay(client, "");
}

bool SetClientOverlay(int client, char[] strOverlay)
{
    if(IsValidClient(client))
    {
        ClientCommand(client, "r_screenoverlay \"%s\"", strOverlay);
        return true;
    }
	return false;
}
public Action OnSay(int client, const char[] command, int args)
{
    char messageText[32];
    GetCmdArgString(messageText, sizeof(messageText));
   
    if(strcmp(messageText, "\"!nseoff\"", false) == 0)
    {
        return Plugin_Handled;
    }
	if(strcmp(messageText, "\"!nse\"", false) == 0)
	{
	return Plugin_Handled;
    }
	return Plugin_Continue;
}