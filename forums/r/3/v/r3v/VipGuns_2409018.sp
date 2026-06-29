#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>


#define VERSION    "1.0"
#define SPEC        1
#define TEAM1        2
#define TEAM2        3

new g_VipStatus[MAXPLAYERS+1] = 0;

public Plugin:myinfo =
{
    name = "VIP Plugin",
    author = "ITGurra",
    description = "Vip Plugin that gives access to gravity and respawn!",
    version = "2.0",
    url = "http://mywebsite.nothing"
}

public OnPluginStart()
{
    CreateConVar("sm_vipguns_version", VERSION, "VIP Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    RegConsoleCmd("sm_vipguns", VIP);
}

public OnClientDisconnect(client)
{
    g_VipStatus[client] = 0;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(client) > CS_TEAM_SPECTATOR && IsPlayerGenericAdmin(client))
	{
		if(GameRules_GetProp("m_totalRoundsPlayed") == 3) // show menu on third round ?
		{
			VIP(client, 0); // Use console command callback
		}
	}
	return Plugin_Handled;
}

public Action:VIP(client, args)
{
    if (IsPlayerGenericAdmin(client))
    {
        new Handle:VMenu = CreateMenu(VipMenu);
        SetMenuTitle(VMenu, ".:GUNS MENU:.");
        AddMenuItem(VMenu, "M4", "M4A1 + DGL");
        AddMenuItem(VMenu, "AK47", "AK47 + DGL");
        AddMenuItem(VMenu, "AWP", "AWP + DGL");
        SetMenuExitButton(VMenu, true);
        DisplayMenu(VMenu, client, 0);
        
        return Plugin_Handled;
    }
    else
    {
        PrintToChat(client, "\x04[ WARNING ]\x01 You don't have a \x03VIP\x01.");
        return Plugin_Handled;
    }
}

public VipMenu(Handle:VMenu, MenuAction:action, client, position)
{
    if(action == MenuAction_Select)
    {
        decl String:item[20];
        GetMenuItem(VMenu, position, item, sizeof(item));
        
if(StrEqual(item, "M4"))
        {
            GivePlayerItem(client, "weapon_m4a1");
            GivePlayerItem(client, "weapon_deagle");
            return;
        }    
        if(StrEqual(item, "AK47"))
        {
            GivePlayerItem(client, "weapon_ak47");
            GivePlayerItem(client, "weapon_deagle");
            return;
        }
        if(StrEqual(item, "AWP"))
        {
            GivePlayerItem(client, "weapon_awp");
            GivePlayerItem(client, "weapon_deagle");
            return;
            }       
        }
    else if(action == MenuAction_End)
    {
        CloseHandle(VMenu)
    }
} 

bool:IsPlayerGenericAdmin(client)
{
    return CheckCommandAccess(client, "generic_admin", ADMFLAG_RESERVATION, false);
} 