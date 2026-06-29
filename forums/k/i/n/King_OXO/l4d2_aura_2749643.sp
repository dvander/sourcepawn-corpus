#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_functions>

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
    RegConsoleCmd("sm_aura", Aura, "aura for players");
}

public OnMapStart()
{
    Ghost();
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
	AddMenuItem(menu, "option0", "* Green*");
	AddMenuItem(menu, "option1", "* Blue*");
	AddMenuItem(menu, "option2", "* Violet*");
	AddMenuItem(menu, "option3", "* Cyan*");
	AddMenuItem(menu, "option4", "* Orange*");
	AddMenuItem(menu, "option5", "* Red*");
	AddMenuItem(menu, "option6", "* Gray*");
	AddMenuItem(menu, "option7", "* Yellow*");
	AddMenuItem(menu, "option8", "* Lime*");
	AddMenuItem(menu, "option9", "* Maroon*");
	AddMenuItem(menu, "option10", "* Teal*");
	AddMenuItem(menu, "option11", "* Pink*");
	AddMenuItem(menu, "option12", "* Purple*");
	AddMenuItem(menu, "option13", "* White*");
	AddMenuItem(menu, "option14", "* Golden*");
	AddMenuItem(menu, "option15", "* Golden*");
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
		    case 0: // Vip aura 1
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 + (255 * 256) + (0 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}
			case 1: // Vip aura 2
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 7 + (19 * 256) + (250 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}
            case 2: // Vip aura 3
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 249 + (19 * 256) + (250 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);	
			}
            case 3: // Vip aura 4
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 66 + (250 * 256) + (250 * 65536));
		        SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}
			case 4: // Vip aura 5
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 249 + (155 * 256) + (84 * 65536));
		        SetEntProp(client, Prop_Send, "m_iGlowType", 3);
		        SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}
			case 5: // Vip aura 6
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (0 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}
			case 6: // Vip aura 7
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 50 + (50 * 256) + (50 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}
			case 7: // Vip aura 8
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (255 * 256) + (0 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}
            case 8: // Vip aura 9
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 128 + (255 * 256) + (0 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}
            case 9: // Vip aura 10
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 128 + (0 * 256) + (0 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}	
            case 10: // Vip aura 11
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 + (128 * 256) + (128 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}
            case 11: // Vip aura 12
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (150 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}
            case 12: // Vip aura 13
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 155 + (0 * 256) + (255 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}		
            case 13: // Vip aura 14
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", -1 + (-1 * 256) + (-1 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}
            case 14: // Vip aura 15
			{

				SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (155 * 256) + (0 * 65536));
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
				SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
			}				
		}
	}	
}