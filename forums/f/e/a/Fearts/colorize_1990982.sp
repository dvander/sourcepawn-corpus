//Colorise: by Arg!

/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
new g_ColorizeTarget[MAXPLAYERS+1];

new Handle:cvar_SelfColorize;
new Handle:cvar_ColorizeDelay;

new Float:g_NextColorize[ MAXPLAYERS + 1 ] = { -1.0, ... };

/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
public SetupColorize()
{
	RegAdminCmd("sm_colorize", Command_SmColorize, ADMFLAG_SLAY, "sm_colorize <name or #userid> <color> - sets player color (normal to revert)");
	
	RegConsoleCmd("sm_colorme", Command_SmColorMe, "sm_colorme <color> - colorize yourself");
	RegConsoleCmd("sm_colorize_colors", Command_SmColorizeColors, "displays colors available to sm_colorize and sm_colorme");	
	
	cvar_SelfColorize = CreateConVar("sm_selfcolorize", "0", "Allow players to colorize themselves with sm_colorme");
	cvar_ColorizeDelay = CreateConVar( "sm_colorizedelay", "60", "The amount of time players need to wait inbetween using the colorize commands" );

}

public OnClientConnect_Colorize(client, String:rejectmsg[], maxlen)
{
	g_NextColorize[ client ] = GetGameTime();
}

/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/
public Action:Command_SmColorize(client, args)
{
	decl String:target[65];
	decl String:color[65];
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	new bool:colorFound;
	
	
	//not enough arguments, display usage
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_colorize <#userid|name> color");
		return Plugin_Handled;
	}	

	//get command arguments
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, color, sizeof(color));
	

	//get the target of this command, return error if invalid
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	//check for random color
	if(StrEqual("random", color, false))
	{
		colorFound = true;			
		
		for (new i = 0; i < target_count; i++)
		{
			PerformColorize(client, target_list[i], GetRandomInt(0,(sizeof(g_sTColors) -1 )) );
		}
	}
	else
	{	
		//iterate colors	
		for (new c = 0; c < sizeof(g_sTColors); c++) 
		{
			//if we match requested color, colorize all targets found and break
			if (StrEqual(g_sTColors[c],color,false)) 
			{
				colorFound = true;			
				
				for (new i = 0; i < target_count; i++)
				{
					PerformColorize(client, target_list[i], c);
				}			
				
				break;
			}
		}
	}
	
	//if invalid color specified, return error
	if( !colorFound )
	{
		ReplyToCommand(client, "[SM] %s", "Invalid color");
		return Plugin_Handled;
	}

	ShowActivity2(client, "[SM] ", "%t", "made the color",  target_name, color);
	
	return Plugin_Handled;
}

public Action:Command_SmColorMe(client, args)
{
	decl String:color[65];
	new bool:colorFound;
	
	if( !GetConVarInt(cvar_SelfColorize) )
	{	
		ReplyToCommand(client, "[SM] You do not have access to this command");
		return Plugin_Handled;	
	}
	
	//not enough arguments, display usage
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_colorme <color>");
		return Plugin_Handled;
	}
	
	if ( GetGameTime() < g_NextColorize[ client ] )
	{
		new Float:diff = g_NextColorize[ client ] - GetGameTime();
		
		ReplyToCommand(client, "[SM] You can't use colorme yet! You must wait %.0f seconds", diff );
		return Plugin_Handled;
	}
	
	g_NextColorize[ client ] = GetGameTime() + GetConVarFloat( cvar_ColorizeDelay );

	//get command arguments
	GetCmdArg(1, color, sizeof(color));
	
	//check for random color
	if(StrEqual("random", color, false))
	{
		colorFound = true;			
		PerformColorize(client, client, GetRandomInt(0,(sizeof(g_sTColors) -1 )) );
	}
	else
	{	
		//iterate colors	
		for (new c = 0; c < sizeof(g_sTColors); c++) 
		{
			//if we match requested color, colorize all targets found and break
			if (StrEqual(g_sTColors[c],color,false)) 
			{
				colorFound = true;			
				PerformColorize(client, client, c);
				
				break;
			}
		}
	}
	
	//if invalid color specified, return error
	if( !colorFound )
	{
		ReplyToCommand(client, "[SM] %s", "Invalid color");
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

public Action:Command_SmColorizeColors(client, args)
{
	new String:colorlist[sizeof(g_sTColors)*21];

	//iterate colors
	for (new c = 0; c < sizeof(g_sTColors); c++) 
	{
		//generate list of colors
		if( c != 0 )
		{
			Format( colorlist, sizeof(colorlist), "%s, ", colorlist);
		}
		Format( colorlist, sizeof(colorlist), "%s%s", colorlist, g_sTColors[c]);
	}
	
	//display in console
	ReplyToCommand(client, "[SM] sm_colorize accepts the following colors: random, %s", colorlist);
	
	return Plugin_Handled;
}

/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/

PerformColorize(client, target, c)
{
	//set target color and log action
	SetColor(target, c);
	
	DoRGBA(target,RENDER_NORMAL);
	
	LogAction(client, target, "\"%L\" made \"%L\" %s", client, target, g_sTColors[c]);
}

/*****************************************************************


			A D M I N   M E N U   F U N C T I O N S


*****************************************************************/
Setup_AdminMenu_Colorize_Player(TopMenuObject:parentmenu)
{
	AddToTopMenu(hTopMenu, 
		"sm_colorize",
		TopMenuObject_Item,
		AdminMenu_Colorize,
		parentmenu,
		"sm_colorize",
		ADMFLAG_SLAY);
}


public AdminMenu_Colorize(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Colorize player", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayColorizeMenu(param);
	}
}

DisplayColorizeMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Colorize);
	
	decl String:title[100];
	Format(title, sizeof(title), "%T:", "Colorize player", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, false);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}




public MenuHandler_Colorize(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			g_ColorizeTarget[param1] = userid;
			DisplayColorizeColorMenu(param1);
			return;	// Return, because we went to a new menu and don't want the re-draw to occur.
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayColorizeMenu(param1);
		}
	}
	
	return;
}

DisplayColorizeColorMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ColorizeColor);
	
	decl String:title[100];
	Format(title, sizeof(title), "%T:", "Color", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "random", "random");
	
	//iterate colors
	for (new c = 0; c < sizeof(g_sTColors); c++) 
	{
		//generate list of colors
		AddMenuItem(menu, g_sTColors[c], g_sTColors[c]);		
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public MenuHandler_ColorizeColor(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		new target;
		new String:color[16];
		
		GetMenuItem(menu, param2, color, sizeof(color));
		
		if ((target = GetClientOfUserId(g_ColorizeTarget[param1])) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			new String:name[32];
			GetClientName(target, name, sizeof(name));
			
			//check for random color
			if(StrEqual("random", color, false))
			{
				PerformColorize(param1, target, GetRandomInt(0,(sizeof(g_sTColors) -1 )) );
			}
			else
			{
				//iterate colors	
				for (new c = 0; c < sizeof(g_sTColors); c++) 
				{
					//if we match requested color, colorize all targets found and break
					if (StrEqual(g_sTColors[c],color,false)) 
					{
						PerformColorize(param1, target, c);
						break;
					}
				}
			}	

			ShowActivity2(param1, "[SM] ", "%t", "made the color",  name, color);
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayColorizeMenu(param1);
		}
	}
}