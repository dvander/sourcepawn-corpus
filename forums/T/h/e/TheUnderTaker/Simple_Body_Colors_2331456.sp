#include <sourcemod>

#pragma semicolon 1
#pragma tabsize 0

public Plugin myinfo = {
	name        = "Simple Body Colors",
	author      = "TheUnderTaker",
	description = "Allow you to color yourself by a command.",
	version     = "1.0",
	url         = "http://steamcommunity.com/id/theundertaker007/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_bodycolor", Colors);
	RegConsoleCmd("sm_bodycolors", Colors);
}

public Action:Colors(client, args)
{
	new Handle:colors = CreateMenu(ColorCallback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	SetMenuTitle(colors, "Color Body Menu");
	AddMenuItem(colors, "x", "------------------", ITEMDRAW_DISABLED);
	AddMenuItem(colors, "RC", "Remove Color");
	AddMenuItem(colors, "GREEN", "Green");
	AddMenuItem(colors, "RED", "Red");
	AddMenuItem(colors, "BLUE", "Blue");
	AddMenuItem(colors, "GOLD", "Gold");
	AddMenuItem(colors, "BLACK", "Black");
	AddMenuItem(colors, "CYAN", "Cyan");
	AddMenuItem(colors, "TURQUOISE", "Turquoise");
	AddMenuItem(colors, "SKYBLUE", "Sky as Blue");
	AddMenuItem(colors, "DODGER", "Dodger Blue");
	AddMenuItem(colors, "YELLOW", "Yellow");
	AddMenuItem(colors, "PINK", "Pink");
	AddMenuItem(colors, "PURPLE", "Purple");
	AddMenuItem(colors, "GRAY", "Gray");
	DisplayMenu(colors, client, MENU_TIME_FOREVER);
}

public ColorCallback(Handle:menu, MenuAction:action, client, item)
{
	switch(action)
	{
		case MenuAction_Select:
    		{
						decl String:item_name[64];
						GetMenuItem(menu, item, item_name, sizeof(item_name));
    					if(StrEqual(item_name, "RC"))
    					{
						SetEntityRenderColor(client, 255, 255, 255, 255);
						PrintToChat(client, "You removed your color successfully.");
    					}
                        else if(StrEqual(item_name, "GREEN"))
                        {
                        SetEntityRenderColor(client, 0, 255, 0, 255);
                       	PrintToChat(client, "You changed your color to Green.");
                        }
                        else if(StrEqual(item_name, "RED"))
                        {
                        SetEntityRenderColor(client, 255, 0, 0, 255);
                       	PrintToChat(client, "You changed your color to Red.");
                        }
						else if(StrEqual(item_name, "BLUE"))
						{
						SetEntityRenderColor(client, 0, 0, 255, 255);
                       	PrintToChat(client, "You changed your color to Blue.");
						}
						else if(StrEqual(item_name, "GOLD"))
						{
						SetEntityRenderColor(client, 255, 215, 0, 255);
                       	PrintToChat(client, "You changed your color to Gold.");
						}
						else if(StrEqual(item_name, "BLACK"))
						{
						SetEntityRenderColor(client, 0, 0, 0, 255);
                       	PrintToChat(client, "You changed your color to Black.");
						}
						else if(StrEqual(item_name, "CYAN"))
						{
						SetEntityRenderColor(client, 0, 255, 255, 255);
                       	PrintToChat(client, "You changed your color to Cyan.");
						}
						else if(StrEqual(item_name, "TURQUOISE"))
						{
						SetEntityRenderColor(client, 64, 224, 208, 255);
                       	PrintToChat(client, "You changed your color to Turquoise.");
						}
						else if(StrEqual(item_name, "SKYBLUE"))
						{
						SetEntityRenderColor(client, 0, 191, 255, 255);
                       	PrintToChat(client, "You changed your color to Sky as Blue.");
						}
						else if(StrEqual(item_name, "DODGER"))
						{
						SetEntityRenderColor(client, 30, 144, 255, 255);
                       	PrintToChat(client, "You changed your color to Dodger Blue.");
						}
						else if(StrEqual(item_name, "YELLOW"))
						{
						SetEntityRenderColor(client, 255, 255, 0, 255);
                       	PrintToChat(client, "You changed your color to Yellow.");
						}
						else if(StrEqual(item_name, "PINK"))
						{
						SetEntityRenderColor(client, 255, 105, 180, 255);
                       	PrintToChat(client, "You changed your color to Pink.");
						}
						else if(StrEqual(item_name, "PURPLE"))
						{
						SetEntityRenderColor(client, 128, 0, 128, 255);
                       	PrintToChat(client, "You changed your color to Purple.");
						}
						else if(StrEqual(item_name, "GRAY"))
						{
						SetEntityRenderColor(client, 128, 128, 128, 255);
                       	PrintToChat(client, "You changed your color to Gray.");
						}
                	
                }
                case MenuAction_End:
                {
                        CloseHandle(menu);
                }
    }
}