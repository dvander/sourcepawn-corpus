#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>


#define VERSION    "1.0"
#define SPEC        1
#define TEAM1        2
#define TEAM2        3

new g_VipStatus[MAXPLAYERS+1] = 0;
new Handle:g_Health;
new Handle:g_Armor;

public Plugin:myinfo =
{
    name = "VIP Plugin",
    author = "Hk",
    description = "",
    version = "",
    url = ""
}

public OnPluginStart()
{
    HookEvent("player_spawn", PlayerSpawn);
    CreateConVar("sm_vip_version", VERSION, "VIP Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_Health = CreateConVar("sm_vip_health", "100", "HP On Spawn");
    g_Armor = CreateConVar("sm_vip_armor", "100", "Armor On Spawn");
    RegConsoleCmd("sm_vip", VIP);
    
    AutoExecConfig(true, "sm_vip");
}

public OnClientDisconnect(client)
{
    g_VipStatus[client] = 0;
}

public Action:VIP(client, args)
{
    if (IsClientInGame(i))
    {
        new Handle:VMenu = CreateMenu(VipMenu);
        SetMenuTitle(VMenu, "\n.::VIP MENU::.");
        AddMenuItem(VMenu, "AK47", "AK47+Deagle");
        AddMenuItem(VMenu, "M4A4", "M4A4_Deagle");
        AddMenuItem(VMenu, "M4A1", "M4A1+Deagle");
        AddMenuItem(VMenu, "FAMAS", "Famas+Deagle+zeus+Medishot");
        AddMenuItem(VMenu, "GALIL", "Galil+Deagle+zeus+Medishot");
        AddMenuItem(VMenu, "SG556", "SG556+Deagle+zeus+Medishot");
		AddMenuItem(VMenu, "AUG", "AUG+Deagle+zeus+Medishot");
		AddMenuItem(VMenu, "SCOUT", "Scout+Deagle+zeus+Medishot");
		AddMenuItem(VMenu, "AWP", "Awp+Deagle+zeus+Medishot");
		AddMenuItem(VMenu, "WALLHACK", "Wallhack_Grenade");
        SetMenuExitButton(VMenu, true);
        DisplayMenu(VMenu, client, 0);
			}
			if (IsVIP(i))
			{
        
        return Plugin_Handled;
    }
    else
    {
        PrintToChat(client, "\x04[ IRG ]\x01 You Are Not \x03VIP\x01.");
        return Plugin_Handled;
    }
}

public VipMenu(Handle:VMenu, MenuAction:action, client, position)
{
    if(action == MenuAction_Select)
    {
        decl String:item[20];
        GetMenuItem(VMenu, position, item, sizeof(item));
        
        if(StrEqual(item, "AK47"))
        {
            GivePlayerItem(client, "weapon_ak47");
            GivePlayerItem(client, "weapon_deagle");
            return;
        }    
        if(StrEqual(item, "M4A4"))
        {
            GivePlayerItem(client, "weapon_m4a1");
            GivePlayerItem(client, "weapon_deagle");
            return;
        }
        if(StrEqual(item, "M4A1"))
        {
            GivePlayerItem(client, "weapon_m4a1_silencer");
            GivePlayerItem(client, "weapon_deagle");
            return;
        }
        if(StrEqual(item, "FAMAS"))
        {
			if (!IsVIP(client))
			{
				PrintToChat(param1, "\x03Error: You are not VIP to get this item.");
				CloseHandle(menu);
				return 0;
			}
            GivePlayerItem(client, "weapon_famas");
            GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_taser");
			GivePlayerItem(client, "weapon_healthshot");
            return;
        }
        if(StrEqual(item, "GALIL"))
        {
			if (!IsVIP(client))
			{
				PrintToChat(param1, "\x03Error: You are not VIP to get this item.");
				CloseHandle(menu);
				return 0;
			}
            GivePlayerItem(client, "weapon_galilar");
            GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_taser");
			GivePlayerItem(client, "weapon_healthshot");
            return;
        }
        if(StrEqual(item, "SG556"))
        {
			if (!IsVIP(client))
			{
				PrintToChat(param1, "\x03Error: You are not VIP to get this item.");
				CloseHandle(menu);
				return 0;
			}
            GivePlayerItem(client, "weapon_sg556");
            GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_taser");
			GivePlayerItem(client, "weapon_healthshot");
            return;
        }
        if(StrEqual(item, "AUG"))
        {
			if (!IsVIP(client))
			{
				PrintToChat(param1, "\x03Error: You are not VIP to get this item.");
				CloseHandle(menu);
				return 0;
			}
            GivePlayerItem(client, "weapon_aug");
            GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_taser");
			GivePlayerItem(client, "weapon_healthshot");
            return;
        }
        if(StrEqual(item, "SCOUT"))
        {
			if (!IsVIP(client))
			{
				PrintToChat(param1, "\x03Error: You are not VIP to get this item.");
				CloseHandle(menu);
				return 0;
			}
            GivePlayerItem(client, "weapon_ssg08");
            GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_taser");
			GivePlayerItem(client, "weapon_healthshot");
            return;
        }
        if(StrEqual(item, "AWP"))
        {
			if (!IsVIP(client))
			{
				PrintToChat(param1, "\x03Error: You are not VIP to get this item.");
				CloseHandle(menu);
				return 0;
			}
            GivePlayerItem(client, "weapon_awp");
            GivePlayerItem(client, "weapon_deagle");
			GivePlayerItem(client, "weapon_taser");
			GivePlayerItem(client, "weapon_healthshot");
            return;
        }
        if(StrEqual(item, "WALLHACK"))
        {
			if (!IsVIP(client))
			{
				PrintToChat(param1, "\x03Error: You are not VIP to get this item.");
				CloseHandle(menu);
				return 0;
			}
            GivePlayerItem(client, "weapon_tagrenade");
            return;
            }    
        }
    else if(action == MenuAction_End)
    {
        CloseHandle(VMenu)
    }
}
new g_PlayerRespawn[MAXPLAYERS+1];

public bool:OnClientConnect(client, String:Reject[], Len)
{
    
    if (IsClientInGame(i))
        g_PlayerRespawn[client] = 3
    else 
    g_PlayerRespawn[client] = 0;
    
}  

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(client) > CS_TEAM_SPECTATOR && IsClientInGame(i))
	{
		if(GameRules_GetProp("m_totalRoundsPlayed") >= 3) 
		{
			VIP(client, 0); // Use console command callback
		}

		SetEntProp(client, Prop_Data, "m_iHealth", GetConVarInt(g_Health));
		SetEntProp(client, Prop_Send, "m_ArmorValue", GetConVarInt(g_Armor));
	}
	return Plugin_Handled;
}