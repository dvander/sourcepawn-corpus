#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_functions>

ConVar g_hRainbowTime;

public Plugin myinfo =
{
	name = "[L4D2]color and aura menu",
	author = "King",
	description = "",
	version = "2.0.0",
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
    g_hRainbowTime = CreateConVar("rainbow_time", "5.0", "time for aura and body change");

    RegConsoleCmd("sm_color", BODY, "color for survivors");
	
	AutoExecConfig(true, "L4D2_pack");
}

public Action BODY(client, args)
{
	Body(client);
	return Plugin_Handled;
}

public Action Body(clientId)
{
	new Handle:menu = CreateMenu(BodyMenuHandler);
	SetMenuTitle(menu, "|★|Color menu|★| ");
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
	AddMenuItem(menu, "option14", "* Golden*");
	AddMenuItem(menu, "option15", "* White aura and black body*");
	AddMenuItem(menu, "option16", "* Rainbow*");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
	//return Plugin_Handled;
}

public BodyMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{  
		switch (itemNum)
		{
		    case 0: // Vip color 0
			{
               	SetEntityRenderColor(client, 255, 255, 255, 255);
	            SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
	            SetEntProp(client, Prop_Send, "m_iGlowType", 0);
	            SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
                SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
		    case 1: // Vip color 1
			{
                SetEntityRenderColor(client, 0, 255, 0, 255);
                SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 + (255 * 256) + (0 * 65536));
                SetEntProp(client, Prop_Send, "m_iGlowType", 3);
                SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
                SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 2: // Vip color 2
			{
				SetEntityRenderColor(client, 7, 19, 250, 255);
                SetEntProp(client, Prop_Send, "m_glowColorOverride", 7 + (19 * 256) + (250 * 65536));
                SetEntProp(client, Prop_Send, "m_iGlowType", 3);
                SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
                SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 3: // Vip color 3
			{
    		    SetEntityRenderColor(client, 249, 19, 250, 255);
                SetEntProp(client, Prop_Send, "m_glowColorOverride", 249 + (19 * 256) + (250 * 65536));
                SetEntProp(client, Prop_Send, "m_iGlowType", 3);
                SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);	
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 4: // Vip color 4
			{
    			SetEntityRenderColor(client, 66, 250, 250, 255);
    			SetEntProp(client, Prop_Send, "m_glowColorOverride", 66 + (250 * 256) + (250 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
    			SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
    			SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 5: // Vip color 5
			{
			    SetEntityRenderColor(client, 249, 155, 84, 255);
                SetEntProp(client, Prop_Send, "m_glowColorOverride", 249 + (155 * 256) + (84 * 65536));
	            SetEntProp(client, Prop_Send, "m_iGlowType", 3);
	            SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
                SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 6: // Vip color 6
			{
			    SetEntityRenderColor(client, 255, 0, 0, 255);
                SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (0 * 65536));
                SetEntProp(client, Prop_Send, "m_iGlowType", 3);
                SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
                SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 7: // Vip color 7
			{
			    SetEntityRenderColor(client, 50, 50, 50, 255);
    			SetEntProp(client, Prop_Send, "m_glowColorOverride", 50 + (50 * 256) + (50 * 65536));
    			SetEntProp(client, Prop_Send, "m_iGlowType", 3);
    			SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
    			SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 8: // Vip color 8
			{
			    SetEntityRenderColor(client, 255, 255, 0, 255);
                SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (255 * 256) + (0 * 65536));
                SetEntProp(client, Prop_Send, "m_iGlowType", 3);
                SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
                SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 9: // Vip color 9
			{
			    SetEntityRenderColor(client, 128, 255, 0, 255);
                SetEntProp(client, Prop_Send, "m_glowColorOverride", 128 + (255 * 256) + (0 * 65536));
                SetEntProp(client, Prop_Send, "m_iGlowType", 3);
                SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
                SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 10: // Vip color 10
			{
			    SetEntityRenderColor(client, 128, 0, 0, 255);
                SetEntProp(client, Prop_Send, "m_glowColorOverride", 128 + (0 * 256) + (0 * 65536));
                SetEntProp(client, Prop_Send, "m_iGlowType", 3);
                SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
                SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 11: // Vip color 11
			{
			    SetEntityRenderColor(client, 0, 128, 128, 255);
                SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 + (128 * 256) + (128 * 65536));
                SetEntProp(client, Prop_Send, "m_iGlowType", 3);
                SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
                SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 12: // Vip color 12
			{
    			SetEntityRenderColor(client, 255, 0, 150, 255);
                SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (255 * 65536));
                SetEntProp(client, Prop_Send, "m_iGlowType", 3);
                SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
                SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 13: // Vip color 13
			{
    			SetEntityRenderColor(client, 155, 0, 255, 255);
    			SetEntProp(client, Prop_Send, "m_glowColorOverride", 155 + (0 * 256) + (255 * 65536));
   				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
    			SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
    			SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
				
			}
            case 14: // Vip color 14
			{
				SetEntityRenderColor(client, 255, 215, 0, 255);
                SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (215 * 256) + (0 * 65536));
                SetEntProp(client, Prop_Send, "m_iGlowType", 3);
                SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
                SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 15: // Vip color 15
			{
		        SetEntityRenderColor(client, 0, 0, 0, 255);
    			SetEntProp(client, Prop_Send, "m_glowColorOverride", -1 + (-1 * 256) + (-1 * 65536));
    			SetEntProp(client, Prop_Send, "m_iGlowType", 3);
    			SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
    			SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 16: // Vip color 16
			{
		        SDKHook(client, SDKHook_PreThink, OnPlayerThink);
			}	
		}
	}	
}

public void OnPlayerThink(client)
{
    if (!(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)))
    {
        SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);

        return;
    }
	
	float flRainbow = g_hRainbowTime.FloatValue;

    int color[3];
    color[0] = RoundToNearest(Cosine((GetGameTime() * flRainbow) + client + 0) * 127.5 + 127.5);
    color[1] = RoundToNearest(Cosine((GetGameTime() * flRainbow) + client + 2) * 127.5 + 127.5);
    color[2] = RoundToNearest(Cosine((GetGameTime() * flRainbow) + client + 4) * 127.5 + 127.5);
	SetEntityRenderColor(client, color[0], color[1], color[2], 255);
    SetEntProp(client, Prop_Send, "m_glowColorOverride", color[0] + (color[1] * 256) + (color[2] * 65536));
    SetEntProp(client, Prop_Send, "m_iGlowType", 3);
    SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
    SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
} 
