#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_functions>

ConVar g_hBodyTime;

public Plugin myinfo =
{
	name = "[L4D2]body color",
	author = "King",
	description = "",
	version = "3.0.0",
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
    g_hBodyTime = CreateConVar("body_time", "5.0", "time for aura rainbow change");

    RegConsoleCmd("sm_body", BODY, "body color for survivors");
	
	AutoExecConfig(true, "L4D2_body");
}

public Action BODY(client, args)
{
	VipBody(client);
	return Plugin_Handled;
}

public Action VipBody(clientId)
{
	new Handle:menu = CreateMenu(VipBodyMenuHandler);
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
	AddMenuItem(menu, "option15", "* Black*");
	AddMenuItem(menu, "option16", "* Rainbow*");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
	//return Plugin_Handled;
}

public VipBodyMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{  
		switch (itemNum)
		{
		    case 0: // Vip default
			{
                SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 255, 255, 255, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
		    case 1: // Vip color 1
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 0, 255, 0, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 2: // Vip color 2
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 7, 19, 250, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 3: // Vip color 3
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 249, 19, 250, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
            case 4: // Vip color 4
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 66, 250, 250, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 5: // Vip color 5
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 249, 155, 84, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 6: // Vip color 6
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 255, 0, 0, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 7: // Vip color 7
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 50, 50, 50, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 8: // Vip color 8
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 255, 255, 0, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 9: // Vip color 9
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 128, 255, 0, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 10: // Vip color 10
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 128, 0, 0, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 11: // Vip color 11
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 0, 128, 128, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 12: // Vip color 12
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 255, 0, 150, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 13: // Vip color 13
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 155, 0, 255, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 14: // Vip color 14
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 255, 215, 0, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 15: // Vip color 15
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			    SetEntityRenderColor(client, 0, 0, 0, 255);
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
			}
			case 16: // Vip Random color
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
	
	float flBody = g_hBodyTime.FloatValue;

    int color[3];
    color[0] = RoundToNearest(Cosine((GetGameTime() * flBody) + client + 0) * 127.5 + 127.5);
    color[1] = RoundToNearest(Cosine((GetGameTime() * flBody) + client + 2) * 127.5 + 127.5);
    color[2] = RoundToNearest(Cosine((GetGameTime() * flBody) + client + 4) * 127.5 + 127.5);
    SetEntityRenderColor(client, color[0], color[1], color[2], 255);
} 