/*
	SM Super Base
	
	Generates a menu from a config file - runs commands
	Use inconjunction with addons plugins to do lots of pro shiz.
	
	Commands:
		sm_super - Show the menu.
		
	Setup:
		install plugin normally.
		Put the smsuper.ini file into your configs dir
		Setup the smsuper.ini file as you wish.
		
	smsuper.ini file info:
	
		"1"
		{
			"title"			"Set Player Speed"
			"cmd"			"sm_speed #1 #2"
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
	
		title - Text to be Shown in the menu
		cmd - command to be executed (#1,#2 etc for parameters - no limit on these)
		execute - 'server' or 'player' - selects whether to execute as a clientcommand or servercommand
		1 - Information about parameter 1 (#1) - You need as many of these as you have parameters
			type - 	'teamplayer' 	- List of teams + connected player - defaults to list
					'team' 			- List of teams
					'player' 		- List of players
					'list'			- Custom Defined list of Options
			method - 'name', 'steamid', 'userid' - only needed for teamplayer/player menus - defaults to name
			title - To be shown for the parameter selection menu (optional)
			1-x	 - List parameters - only needed for 'list' type parameters
			1.-x. - Text to be shown for parameter - only needed for 'list' type parameters (optional, above will be used as text if ommited)
			
	In Above Example:
		Menu would contain an option called : "Set Player Speed"
		Selecting it would prompt another menu titled: "Player/Team to Edit" containing Team and Player Name options
		Selecting one of these would prompt a second menu titled "Speed Multiplier"
		List of options like "Normal", "80%" etc
		Example command sent (through the player using fakeclientcommand)
		sm_speed @CT 2.0
		
	View the example file to see how to set out submenus
	Both submenus and the main menu can also have custom titles but these (like most things) are optional
	and have a default setting
	
	Changelog:
	
	0.1		-	Initial Release
	0.11	-	Added BuildPath
	0.2		- 	Complete Rebuild.
*/

#define MAX_PLAYERS 32
#define NAME_LENGTH 32
#define CMD_LENGTH 255

new Handle:mainmenu
new Handle:kv

new String:command[MAX_PLAYERS][CMD_LENGTH]
new currentplace[MAX_PLAYERS][3]

new String:teamnames[3][]= {"All","Terrorists","Counter-Terrorists"}
new String:teamcmds[3][]= {"@ALL","@T","@CT"}

#define SUBMENU 0
#define ITEM 1
#define REPLACENUM 2

#define PLUGIN_VERSION "0.2"

new maxplayers

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
	RegConsoleCmd("sm_super", Command_Super)
	
	CreateConVar("sm_supermenu_version", PLUGIN_VERSION, "Super Menu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
}

public OnMapStart()
{
	mainmenu = BuildMainMenu()
	
	maxplayers=GetMaxClients()
}

Handle:BuildMainMenu()
{
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Super)
	
	new String:name[NAME_LENGTH]
	
	
	kv = CreateKeyValues("Commands")
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/smsuper.ini")
	FileToKeyValues(kv, file)
	
	if (!KvGotoFirstSubKey(kv))
	{
		return INVALID_HANDLE
	}
	
	decl String:buffer[3]
	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer))
		
		KvGetString(kv, "title", name, sizeof(name),"Missing Title")
		
		//menu,info,display
		AddMenuItem(menu, buffer, name)
		
	} while (KvGotoNextKey(kv))
	
	KvRewind(kv)
	new String:title[NAME_LENGTH]
	KvGetString(kv, "title", title, sizeof(title),"Choose a Section")
	
	/* Finally, set the title */
	SetMenuTitle(menu, title)
 
	return menu
}

public OnMapEnd()
{
	CloseHandle(kv)	
	CloseHandle(mainmenu)
}

public Action:Command_Super(client,args)
{
	if (mainmenu == INVALID_HANDLE)
	{
		PrintToConsole(client, "There was an error generating the menu. Check your smsuper.ini file")
		return Plugin_Handled
	}	
 
	DisplayMenu(mainmenu, client, MENU_TIME_FOREVER)
 
	return Plugin_Handled
}

public Menu_Super(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[3]
 
		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info))
		
		if (!found)
			return
				
		KvJumpToKey(kv, info)
		
		currentplace[param1][SUBMENU]=StringToInt(info)
		
		new Handle:itemmenu = buildsubmenu()
		DisplayMenu(itemmenu, param1, MENU_TIME_FOREVER)
		
		KvRewind(kv)
	}
}

Handle:buildsubmenu()
{
	new Handle:tempmenu = CreateMenu(Menu_Item)
	new String:buffer[3]
	new String:name[NAME_LENGTH]
	
	KvGotoFirstSubKey(kv)
	
	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer))
		KvGetString(kv, "title", name, sizeof(name),"Missing Title")

		//menu,info,display
		AddMenuItem(tempmenu, buffer, name)
		
	} while (KvGotoNextKey(kv))
	
	SetMenuTitle(tempmenu, "Choose an Item:")
	
	return tempmenu
	
	
}
public Menu_Item(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[6]

		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info))
		
		if (!found)
			return
		
		new String:buffer[6]
		Format(buffer,2,"%i",currentplace[param1][SUBMENU])
		KvJumpToKey(kv, buffer) //Jump to submenu
		KvJumpToKey(kv, info)	//Jump to item
		KvGetString(kv, "cmd", command[param1], sizeof(command[]),"")
		KvRewind(kv)
					
		currentplace[param1][ITEM]=StringToInt(info)
				
		ParamCheck(param1)
	}
	
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

public ParamCheck(client)
{
	new String:buffer[6]
	
	Format(buffer,2,"%i",currentplace[client][SUBMENU])
	KvJumpToKey(kv, buffer) //Jump to submenu
	
	Format(buffer,2,"%i",currentplace[client][ITEM])
	KvJumpToKey(kv, buffer)	//Jump to item
	
	
	new String:type[NAME_LENGTH]
		
	if (currentplace[client][REPLACENUM]<1)
		currentplace[client][REPLACENUM]=1
	
	Format(buffer,5,"#%i",currentplace[client][REPLACENUM])
	
	if (StrContains(command[client], buffer) != -1)
	{
		//user has a parameter to fill. lets do it.	
		Format(buffer,5,"%i",currentplace[client][REPLACENUM])
		KvJumpToKey(kv, buffer) // Jump to current param
		KvGetString(kv, "type", type, sizeof(type),"list")
		
		new Handle:itemmenu = CreateMenu(Menu_Selection)
		new String:title[NAME_LENGTH]
		
		new bool:team=false
		
		if (strncmp(type,"team",4)==0)
		{
			//team or teamplayer
			//add team options then check to see if player is going in as well
			//@Ct/@T/@ALL as info, teamname as text
			AddMenuItem(itemmenu, teamcmds[0], teamnames[0])
			AddMenuItem(itemmenu, teamcmds[1], teamnames[1])
			AddMenuItem(itemmenu, teamcmds[2], teamnames[2])
			team=true
		}
		

		if (strncmp(type,"mapcycle",4)==0)
		{
			new Handle:hFile = OpenFile("mapcycle.txt", "rt");
			new String:szReadData[128];
			if(hFile == INVALID_HANDLE)
			{
				return;
			}
			while(!IsEndOfFile(hFile) && ReadFileLine(hFile, szReadData, sizeof(szReadData)))
			{
				AddMenuItem(itemmenu, szReadData, szReadData)
			}
		}

		if (StrContains(type,"player")!=-1)
		{
			//player menu!
			//may have already had the team options added
			//just append the player list
			new String:method[NAME_LENGTH]
			KvGetString(kv, "method", method, sizeof(method),"name")
			
			new String:name[NAME_LENGTH]
			new String:info[NAME_LENGTH]
			new String:temp[4]
			KvGetString(kv, "title", title, sizeof(title),"Choose a Player")
			
			//loop through players. Add name as text and name/userid/steamid as info
			for (new i=1; i<=maxplayers; i++)
			{
				if (IsClientInGame(i))
				{
					Format(temp,3,"%i",i)
					GetClientName(i, name, 31);

					if (method[0]=='u') //userid
					{
						Format(info,sizeof(info),"#%i",i)
						AddMenuItem(itemmenu, info, name)
					}
					else if (method[0]=='s') //steamid
					{
						GetClientAuthString(i, info, sizeof(info))
						AddMenuItem(itemmenu, info, name)
					}
					else //name
					{
						AddMenuItem(itemmenu, name, name)
					}
				}
			}
		}
		else if (!team)
		{
			//list menu

			new String:temp[6]
			new String:value[NAME_LENGTH]
			new String:text[NAME_LENGTH]
			new i=1
			new bool:more = true
			
			do
			{
				// load the i and i. options from kv and make a menu from them
				Format(temp,3,"%i",i)
				KvGetString(kv, temp, value, sizeof(value), "")
				Format(temp,5,"%i.",i)
				KvGetString(kv, temp, text, sizeof(text), value)
				if (value[0]=='\0')
					more=false
				else
					AddMenuItem(itemmenu, value, text)
				i++
				
			} while (more)
		
			KvGetString(kv, "title", title, sizeof(title), "Choose an Option")
		}
		
		SetMenuTitle(itemmenu, title)
		DisplayMenu(itemmenu, client, MENU_TIME_FOREVER)	
	}
	else
	{	
		//nothing else need to be done. Run teh command.
		new String:execute[7]
		KvGetString(kv, "execute", execute, sizeof(execute), "player")
		if (execute[0]=='p')
			FakeClientCommand(client, command[client])
		else
		{
			InsertServerCommand(command[client])
			ServerExecute()
		}
		command[client][0]='\0'
		currentplace[client][REPLACENUM]=1
		
		KvGoBack(kv)
		new Handle:itemmenu = buildsubmenu()
		DisplayMenu(itemmenu, client, MENU_TIME_FOREVER)
	}
	
	KvRewind(kv)
}

public Menu_Selection(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[NAME_LENGTH]
 
		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info))
		
		if (!found)
			return
		
		new String:buffer[5]
		Format(buffer,4,"#%i",currentplace[param1][REPLACENUM])
		ReplaceString(command[param1], sizeof(command[]), buffer, info)
		//replace #num with the selected player name (might id num etc later)
		currentplace[param1][REPLACENUM]++
		
		ParamCheck(param1)
	}
	
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		//client exited we should go back to submenu i thin
		new String:buffer[3]
		Format(buffer,sizeof(buffer),"%i",currentplace[param1][SUBMENU])
		KvJumpToKey(kv, buffer) //Jump to submenu
		
		new Handle:itemmenu = buildsubmenu()
		DisplayMenu(itemmenu, param1, MENU_TIME_FOREVER)
		
		KvRewind(kv)
		
	}
	
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}