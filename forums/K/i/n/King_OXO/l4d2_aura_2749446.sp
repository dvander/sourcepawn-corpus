#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_functions>

ConVar g_hAuratime;

public Plugin myinfo =
{
	name = "[L4D2] aura",
	author = "King",
	description = "",
	version = "3.0.0",
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
    g_hAuratime = CreateConVar("aura_time", "5.0", "time for aura rainbow change");

    RegConsoleCmd("sm_aura", Aura, "aura for players");

    AutoExecConfig(true, "L4D2_aura");
}

public Action Aura(client, args)
{
    if(IsPlayerAlive(client))
	{
	    VipAura(client);
	    return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action VipAura(clientId)
{
	new Handle:menu = CreateMenu(VipAuraMenuHandler);
	SetMenuTitle(menu, " |★| Aura menu |★| ");
	AddMenuItem(menu, "option0", "* Default*");
	AddMenuItem(menu, "option1", "* Green*");
	AddMenuItem(menu, "option2", "* Blue*");
	AddMenuItem(menu, "option3", "* Violet*");
	AddMenuItem(menu, "option4", "* Cyan*");
	AddMenuItem(menu, "option5", "* Orange*");
	AddMenuItem(menu, "option6", "* Red*");
	AddMenuItem(menu, "option7", "* Gray*");
	AddMenuItem(menu, "option8", "* Yellow*");
	AddMenuItem(menu, "option9", "* Lime*");
	AddMenuItem(menu, "option10", "* Maroon*");
	AddMenuItem(menu, "option11", "* Teal*");
	AddMenuItem(menu, "option12", "* Pink*");
	AddMenuItem(menu, "option13", "* Purple*");
	AddMenuItem(menu, "option14", "* White*");
	AddMenuItem(menu, "option15", "* Golden*");
	AddMenuItem(menu, "option16", "* Rainbow*");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
	//return Plugin_Handled;
}

public VipAuraMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{  
		switch (itemNum)
		{
		    case 0: // Vip Default
			{
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
				SetEntProp(client, Prop_Send, "m_iGlowType", 0);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
		    case 1: // Vip aura 1
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 + (255 * 256) + (0 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 2: // Vip aura 2
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 7 + (19 * 256) + (250 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 3: // Vip aura 3
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 249 + (19 * 256) + (250 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
                SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);				
			}
            case 4: // Vip aura 4
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 66 + (250 * 256) + (250 * 65536));
		        SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 5: // Vip aura 5
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 249 + (155 * 256) + (84 * 65536));
		        SetEntProp(client, Prop_Send, "m_iGlowType", 3);
		        SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 6: // Vip aura 6
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (0 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 7: // Vip aura 7
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 50 + (50 * 256) + (50 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 8: // Vip aura 8
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (255 * 256) + (0 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 9: // Vip aura 9
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 128 + (255 * 256) + (0 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 10: // Vip aura 10
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 128 + (0 * 256) + (0 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}	
            case 11: // Vip aura 11
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 + (128 * 256) + (128 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 12: // Vip aura 12
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (150 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 13: // Vip aura 13
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 155 + (0 * 256) + (255 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}		
            case 14: // Vip aura 14
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", -1 + (-1 * 256) + (-1 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 15: // Vip aura 15
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (155 * 256) + (0 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}				
			case 16: // Vip rainbow
			{
			    SDKHook(client, SDKHook_PreThink, OnPlayerThink);
			}
		}
	}	
}

public void OnPlayerThink(int client)
{
    if (!(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)))
    {
        SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);

        return;
    }
	
	float flAura = g_hAuratime.FloatValue;

    int color[3];
    color[0] = RoundToNearest(Cosine((GetGameTime() * flAura) + client + 0) * 127.5 + 127.5);
    color[1] = RoundToNearest(Cosine((GetGameTime() * flAura) + client + 2) * 127.5 + 127.5);
    color[2] = RoundToNearest(Cosine((GetGameTime() * flAura) + client + 4) * 127.5 + 127.5);
    SetEntProp(client, Prop_Send, "m_glowColorOverride", color[0] + (color[1] * 256) + (color[2] * 65536));
    SetEntProp(client, Prop_Send, "m_iGlowType", 3);
    SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
    SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
}