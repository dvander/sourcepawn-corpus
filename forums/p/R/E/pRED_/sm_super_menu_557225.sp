/*
	SM Super Menu
	
	Generates a menu from a config file - runs commands
	Use in conjunction with addons plugins to do lots of pro shiz.
	
	Commands:
		None.
		
	Setup:
		install plugin normally.
		Put the smsuper.ini file into your configs dir
		Setup the smsuper.ini file as you wish.
		
	smsuper.ini file info:
	
		"Set Player Speed"
		{
			"cmd"			"sm_speed #1 @2"
			"admin"			"sm_kick"
			"execute"	"player"
			"1"
			{
				"type" 		"teamplayer"
				"method"	"name"
				"title"		"Player/Team to Edit"

			}
			"2"
			{
				"type" 		"list"
				"title"		"Speed Multiplier"
				"1"		"1.0"
				"1."		"Normal"
				"2"		"0.8"
				"2."		"80%"
				"3"		"0.5"
				"3."		"Half"
				"4"		"1.5"
				"4."		"50% Boost"
				"5"		"2.0"
				"5."		"Double"
			}

		}
		
	Example Set out for a Command:
	
		cmd - command to be executed (#1,#2 etc for parameters - no limit on these) Use @num to not quote the parameter
		admin - admin level required to access the command - see admin level section
		execute - 'server' or 'player' - selects whether to execute as a clientcommand or servercommand
		1 - Information about parameter 1 (#1) - You need as many of these as you have parameters
			type - 	'teamplayer' 	- List of teams + connected player - defaults to list
					'team' 			- List of teams
					'player' 		- List of players
					'list'			- Custom Defined list of Options
					'mapcycle'		- Auto filled with the contents of your mapcycle file
			path - Only required for type mapcycle. Path (including file name and extension) to the file containing maplist
			method - 'name', 'steamid', 'userid' - only needed for teamplayer/player menus - defaults to name
			title - To be shown for the parameter selection menu (optional)
			1-x	 - List parameters - only needed for 'list' type parameters
			1.-x. - Text to be shown for parameter - only needed for 'list' type parameters (optional, above will be used as text if ommited)
			1* - x* - Admin level required to see this option (same as the rest of the admin types)
			
	In Above Example:
		Menu would contain an option called : "Set Player Speed"
		Selecting it would prompt another menu titled: "Player/Team to Edit" containing Team and Player Name options
		Selecting one of these would prompt a second menu titled "Speed Multiplier"
		List of options like "Normal", "80%" etc
		Example command sent (through the player using fakeclientcommand)
		sm_speed @CT 2.0
		
	Admin Levels:
	
	Admin levels has been given a massive rewrite for this latest version.
	
	All 'admin' types now require a string command name. This command can be already existing (sm_ban) or completely imaginary (reallyweirdcommandnamethatdoesntexist).
	
	If the command exists that section (or list option) will require the exact same access level as that command (including any overrides you have specified).
	Eg you use sm_ban as the admin level for a submenu. Admins will require the 'ban' flag to access this. However you have overrided sm_ban in one of your lower groups ("override" "allow" - in admin_groups.cfg). This group will also have access.
	
	If the command doesn't exist you will need to add it to your overrides sections as if it was a normal command. This can be done in admin_overrides.cfg (to assign flag letters to this command),
	and/or in admin_groups.cfg (to give access to the command to a specified group or remove it from a group even though they have the flag)
	
	View the example file to see how to set out submenus
	Both submenus and the main menu can also have custom titles but these (like most things) are optional
	and have a default setting
	The submenus can also be given an 'admin' parameter to stop people from being able to even read the commands in it.
	
	Categories:
	
		Default Sourcemod Categories:
				PlayerCommands
				ServerCommands
				VotingCommands
	
	Changelog:
	
	0.1		-	Initial Release
	0.11	-	Added BuildPath
	0.2		- 	Complete Rebuild.
	0.3		-	Fixed a few bugs
			- 	Added admin levels
			- 	Added 'mapcycle' type of menu
			- 	Added option for @num (unquoted) as well as #num
	0.31	- 	Fixed @num and mapcycle types
	0.4		-	Mapcycle type now also needs a 'path' setting (relative to base mod dir)
			-	Rewrote to use supermenu include file
			-	Fixed stupid admin auth bug
			-	Added admins levels for lists
			-	Rewrote admin system
			-	Base menu is now created on view (only shows needed entries)
			-	Another large admin system change - Recommendation by Bail
	0.5		-	Large re-write to use sm_admin menu. Should be more efficient
			
	Credits:
	
		Thanks to Recon for spotting a dumb mistake. XD
	
	
	Need:
	
	Range/FRange - Max, min, increment
	Input
	Vote menu
	Map.
	1/0 On/Off
*/

#pragma semicolon 1

#define PLUGIN_VERSION "0.5"

#define BENCHMARK

#include <sourcemod>
#include <supermenu>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hTopMenu = INVALID_HANDLE;

#define NAME_LENGTH 32
#define CMD_LENGTH 255

new Handle:kv;

enum Places
{
	Place_Category,
	Place_Item,
	Place_ReplaceNum	
};

new String:command[MAXPLAYERS+1][CMD_LENGTH];
new currentplace[MAXPLAYERS+1][Places];


new Mod:g_currentMod;

public Plugin:myinfo = 
{
	name = "SM Super Menu",
	author = "pRED*",
	description = "Extendable Menu",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{	
	LoadTranslations("core.phrases");
	
	CreateConVar("sm_supermenu_version", PLUGIN_VERSION, "Super Menu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	new String:modname[30];
	GetGameFolderName(modname, sizeof(modname));
	if (StrEqual(modname,"cstrike",false))
	{
		g_currentMod = MOD_CSTRIKE;
	}
	else if (StrEqual(modname,"tf",false)) 
	{
		g_currentMod = MOD_TF2;
	}
	else if (StrEqual(modname,"dod",false)) 
	{
		g_currentMod = MOD_DODS;
	}
	else if (StrEqual(modname,"hl2mp",false)) 
	{
		g_currentMod = MOD_HL2MP;
	}
	else if (StrEqual(modname,"Insurgency",false)) 
	{
		g_currentMod = MOD_INS;
	}
	
	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
#if defined BENCHMARK
	new startTime = GetSysTickCount();
#endif
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Loop through the kv and find everything */
	
	if (kv != INVALID_HANDLE)
	{
		CloseHandle(kv);	
	}
	
	kv = CreateKeyValues("Commands");
	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/smsuper.ini");
	FileToKeyValues(kv, file);
	
	new String:name[NAME_LENGTH];
	new String:buffer[NAME_LENGTH];
	
	
	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}
	
	decl String:admin[30];
	
	new TopMenuObject:categoryId;
	
	new catId;
	new id;
	
	do
	{		
		KvGetSectionName(kv, buffer, sizeof(buffer));

		KvGetString(kv, "admin", admin, sizeof(admin),"sm_admin");
				
		if ((categoryId =FindTopMenuCategory(hTopMenu, name)) == INVALID_TOPMENUOBJECT)
		{
			categoryId = AddToTopMenu(hTopMenu,
							buffer,
							TopMenuObject_Category,
							CategoryHandler,
							INVALID_TOPMENUOBJECT,
							admin,
							ADMFLAG_GENERIC,
							name);
					
			LogMessage("Added Topmenu Category: \"%s\" (%i) with admin \"%s\"", buffer, categoryId, admin);
		}
		
		if (!KvGetSectionSymbol(kv, catId))
		{
			LogError("Key Id not found for section: %s", buffer);
			break;
		}
		
		LogMessage("Key Id for current category: %i", catId);
		
		if (!KvGotoFirstSubKey(kv))
		{
			return;
		}
		
		do
		{		
			KvGetSectionName(kv, buffer, sizeof(buffer));

			KvGetString(kv, "admin", admin, sizeof(admin),"sm_admin");	
							  
			if (!KvGetSectionSymbol(kv, id))
			{
				LogError("Key Id not found for section: %s");
				break;
			}
			
			LogMessage("Key Id for current item: %i", id);
			
			new String:keyId[64];
			
			Format(keyId, sizeof(keyId), "%i %i", catId, id);
		
			AddToTopMenu(hTopMenu,
							buffer,
							TopMenuObject_Item,
							ItemHandler,
  							categoryId,
  							admin,
  							ADMFLAG_GENERIC,
  							keyId);
  							
  			LogMessage("Added Topmenu Item: \"%s\" with admin \"%s\"", buffer, admin);
			
		} while (KvGotoNextKey(kv));
		
		KvGoBack(kv);
		
	} while (KvGotoNextKey(kv));
	
	KvRewind(kv);
	
#if defined BENCHMARK
	LogMessage("Spent %i ms processing smsuper.ini", GetSysTickCount() - startTime);
#endif
}

public CategoryHandler(Handle:topmenu, 
						TopMenuAction:action,
						TopMenuObject:object_id,
						param,
						String:buffer[],
						maxlength)
{
	if ((action == TopMenuAction_DisplayTitle) || (action == TopMenuAction_DisplayOption))
	{
		GetTopMenuObjName(topmenu, object_id, buffer, maxlength);
	}
}

public ItemHandler(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		GetTopMenuObjName(topmenu, object_id, buffer, maxlength);
	}
	else if (action == TopMenuAction_SelectOption)
	{
#if defined BENCHMARK
		new startTime = GetSysTickCount();
#endif
		
		new String:keyId[64];
		new String:catId[64];
		GetTopMenuInfoString(topmenu, object_id, keyId, sizeof(keyId));
		
		new start = BreakString(keyId, catId, sizeof(catId));
		
		new id = StringToInt(keyId[start]);
		new category = StringToInt(catId);
		
		new bool:jump1 = KvJumpToKeySymbol(kv, category);
		new bool:jump2 = KvJumpToKeySymbol(kv, id);
		
		KvGetString(kv, "cmd", command[param], sizeof(command[]),"");
		KvRewind(kv);
		
		LogMessage("Item %i selected. Found string \"%s\" and converted to %i, %i. Jumps were: %i %i. Found Command \"%s\"", object_id, keyId, category, id, jump1, jump2, command);
					
		currentplace[param][Place_Category] = category;
		currentplace[param][Place_Item] = id;
		
		ParamCheck(param);
		
#if defined BENCHMARK
		LogMessage("Spent %i ms processing an item", GetSysTickCount() - startTime);
#endif
	}
}

public OnMapEnd()
{
	CloseHandle(kv);
}

public ParamCheck(client)
{
	new String:buffer[6];
	new String:buffer2[6];

	KvJumpToKeySymbol(kv, currentplace[client][Place_Category]);
	KvJumpToKeySymbol(kv, currentplace[client][Place_Item]);
	
	new String:type[NAME_LENGTH];
		
	if (currentplace[client][Place_ReplaceNum] < 1)
	{
		currentplace[client][Place_ReplaceNum] = 1;
	}
	
	Format(buffer,5,"#%i",currentplace[client][Place_ReplaceNum]);
	Format(buffer2,5,"@%i",currentplace[client][Place_ReplaceNum]);
	
	if (StrContains(command[client], buffer) != -1 || StrContains(command[client], buffer2) != -1)
	{
		//user has a parameter to fill. lets do it.	
		Format(buffer,5,"%i",currentplace[client][Place_ReplaceNum]);
		KvJumpToKey(kv, buffer); // Jump to current param
		KvGetString(kv, "type", type, sizeof(type),"list");
		
		new Handle:itemmenu;
		
		new String:title[NAME_LENGTH];
		new String:path[200] = "mapcycle.txt";
		
		new MenuType:Type;
		new PlayerMethod:playermethod;
		
		if (strncmp(type,"team",4)==0)
		{
			if (StrContains(type,"player")!=-1)
			{
				Type = Player_Team;
			}
			else
			{
				Type = Team;
			}
		}
		else if (strncmp(type,"mapcycle",8)==0)
		{
			KvGetString(kv, "path", path, sizeof(path),"mapcycle.txt");
		
			Type = MapCycle;

		}
		else if (strncmp(type,"player",6)==0)
		{
			Type = PlayerList;	
		}		
		else
		{
			//list menu
			
			Type = List;
			
			itemmenu = CreateMenu(Menu_Selection);

			new String:temp[6];
			new String:value[NAME_LENGTH];
			new String:text[NAME_LENGTH];
			new i=1;
			new bool:more = true;
					
			new String:admin[NAME_LENGTH];
				
			do
			{
				// load the i and i. options from kv and make a menu from them (i* = required admin level to view)
				Format(temp,3,"%i",i);
				KvGetString(kv, temp, value, sizeof(value), "");
				
				Format(temp,5,"%i.",i);
				KvGetString(kv, temp, text, sizeof(text), value);
				
				Format(temp,5,"%i*",i);
				KvGetString(kv, temp, admin, sizeof(admin),"");	
				
				if (value[0]=='\0')
				{
					more = false;
				}
				else if (CheckCommandAccess(client, admin, 0))
				{
					AddMenuItem(itemmenu, value, text);
				}
				
				i++;
				
			} while (more);
		
		}
		
		KvGetString(kv, "title", title, sizeof(title),"Choose an Option");
		
		
		if (Type == Player_Team || Type == PlayerList)
		{
			new String:method[NAME_LENGTH];	
			KvGetString(kv, "method", method, sizeof(method),"name");
			if (strncmp(method,"clientid",8)==0)
			{
				playermethod = ClientId;
			}
			else if (strncmp(method,"steamid",7)==0)
			{
				playermethod = SteamId;
			}
			else if (strncmp(method,"userid",6)==0)
			{
				playermethod = UserId;
			}
			else
			{
				playermethod = Name;
			}
		}
		
		if (Type != List)
		{
			itemmenu = GenerateAutoMenu(Type, Menu_Selection, g_currentMod, title, playermethod, path);
		}
		
		SetMenuTitle(itemmenu, title);
		DisplayMenu(itemmenu, client, MENU_TIME_FOREVER);
	}
	else
	{	
		//nothing else need to be done. Run teh command.
		new String:execute[7];
		KvGetString(kv, "execute", execute, sizeof(execute), "player");
		
		KvGoBack(kv);
		
		DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
		
		if (execute[0]=='p')
		{
			LogMessage("%L sent command \"%s\" to client console",client,command[client]);
			FakeClientCommand(client, command[client]);
		}
		else
		{
			LogMessage("%L sent command \"%s\" to server console",client,command[client]);
			InsertServerCommand(command[client]);
			ServerExecute();
		}

		command[client][0] = '\0';
		currentplace[client][Place_ReplaceNum] = 1;
	}
	
	KvRewind(kv);
}

public Menu_Selection(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	if (action == MenuAction_Select)
	{
#if defined BENCHMARK
		new startTime = GetSysTickCount();
#endif		

		new String:info[NAME_LENGTH];
 
		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		
		if (!found)
		{
			return;
		}
		
		new String:buffer[5];
		new String:infobuffer[NAME_LENGTH+2];
		Format(infobuffer, sizeof(infobuffer), "\"%s\"", info);
		
		Format(buffer, 4, "#%i", currentplace[param1][Place_ReplaceNum]);
		ReplaceString(command[param1], sizeof(command[]), buffer, infobuffer);
		//replace #num with the selected option (quoted)
		
		Format(buffer, 4, "@%i", currentplace[param1][Place_ReplaceNum]);
		ReplaceString(command[param1], sizeof(command[]), buffer, info);
		//replace @num with the selected option (unquoted)
		
		currentplace[param1][Place_ReplaceNum]++;
		
		ParamCheck(param1);
		
#if defined BENCHMARK
		LogMessage("Spent %i ms processing a parameter", GetSysTickCount() - startTime);
#endif
	}
	
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		//client exited we should go back to submenu i think
		DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
}