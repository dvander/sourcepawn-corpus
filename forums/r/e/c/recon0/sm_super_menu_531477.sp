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
			"cmd"			"sm_speed #1 @2"
			"admin"			"kick"
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
		cmd - command to be executed (#1,#2 etc for parameters - no limit on these) Use @num to not quote the parameter
		admin - admin level required to access the command (list supplied below)
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
			
	In Above Example:
		Menu would contain an option called : "Set Player Speed"
		Selecting it would prompt another menu titled: "Player/Team to Edit" containing Team and Player Name options
		Selecting one of these would prompt a second menu titled "Speed Multiplier"
		List of options like "Normal", "80%" etc
		Example command sent (through the player using fakeclientcommand)
		sm_speed @CT 2.0
		
	Admin Levels:
		reservation
		generic
		kick
		ban
		unban
		slay
		changemap
		cvars
		config
		chat
		vote
		password
		rcon
		cheats
		custom1
		custom2
		custom3
		custom4
		custom5
		custom6
		root
		
	View the example file to see how to set out submenus
	Both submenus and the main menu can also have custom titles but these (like most things) are optional
	and have a default setting
	The submenus can also be given an 'admin' parameter to stop people from being able to even read the commands in it.
	
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
	
	
	Need:
	
	Range/FRange - Max, min, increment
	Input
	Vote menu
	Map.
	1/0 On/Off
*/

#include <sourcemod>
#include <supermenu>

#define NAME_LENGTH 32
#define CMD_LENGTH 255

new Handle:mainmenu
new Handle:kv

new String:command[MAXPLAYERS+1][CMD_LENGTH]
new currentplace[MAXPLAYERS+1][3]

#define SUBMENU 0
#define ITEM 1
#define REPLACENUM 2

#define PLUGIN_VERSION "0.4"

new Mod:mod

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
	RegAdminCmd("sm_super", Command_Super,ADMFLAG_GENERIC)
	
	LoadTranslations("core.phrases")
	
	CreateConVar("sm_supermenu_version", PLUGIN_VERSION, "Super Menu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	new String:modname[30]
	GetGameFolderName(modname, sizeof(modname));
	if (StrEqual(modname,"cstrike",false)) mod = MOD_CSTRIKE
	else if (StrEqual(modname,"dod",false)) mod = MOD_DODS
	else if (StrEqual(modname,"hl2mp",false)) mod = MOD_HL2MP
	else if (StrEqual(modname,"Insurgency",false)) mod = MOD_INS
}

public OnMapStart()
{
	mainmenu = BuildMainMenu()
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
	decl String:admin[10]
	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer))
		
		KvGetString(kv, "title", name, sizeof(name),"Missing Title")

		KvGetString(kv, "admin", admin, sizeof(admin),"")
		KvSetNum(kv, "admin", GetAdminLevel(admin))
		
		//menu,info,display
		AddMenuItem(menu, buffer, name)
		
		KvGotoFirstSubKey(kv)
		do
		{
			KvGetString(kv, "admin", admin, sizeof(admin),"")
			KvSetNum(kv, "admin", GetAdminLevel(admin))
		} while (KvGotoNextKey(kv))
		
		KvGoBack(kv)
		
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
		
		new AdminFlag:flag
		
		if (!BitToFlag(KvGetNum(kv,"admin"), flag))
		{
			new String:temp[30]
			KvGetString(kv,"title",temp,sizeof(temp))
			LogMessage("Invalid Admin Type for section: %s",temp)	
		}
		
		new AdminId:aid = GetUserAdmin(param1)
		
		if (!GetAdminFlag(aid, flag, Access_Effective) && !GetAdminFlag(aid, Admin_Root, Access_Effective))
		{
			PrintToChat(param1,"[SM] %t","No Access")
			return	
		}

		
		currentplace[param1][SUBMENU]=StringToInt(info)
		
		new Handle:itemmenu = buildsubmenu(param1)
		DisplayMenu(itemmenu, param1, MENU_TIME_FOREVER)
		
		KvRewind(kv)
	}
}

Handle:buildsubmenu(client)
{
	new Handle:tempmenu = CreateMenu(Menu_Item)
	new String:buffer[3]
	new String:name[NAME_LENGTH]
	
	new AdminFlag:flag
	new AdminId:aid = GetUserAdmin(client)
	
	KvGotoFirstSubKey(kv)
	
	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer))
		KvGetString(kv, "title", name, sizeof(name),"Missing Title")
		
		if (!BitToFlag(KvGetNum(kv,"admin"), flag))
		{
			LogMessage("Invalid Admin Type for section: %s",name)	
		}
		
		if (!GetAdminFlag(aid, flag, Access_Effective) && !GetAdminFlag(aid, Admin_Root, Access_Effective))
		{
			AddMenuItem(tempmenu, buffer, name,ITEMDRAW_DISABLED)
		}
		else
		{
			//menu,info,display
			AddMenuItem(tempmenu, buffer, name)
		}
		
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
	new String:buffer2[6]
	
	Format(buffer,2,"%i",currentplace[client][SUBMENU])
	KvJumpToKey(kv, buffer) //Jump to submenu
	
	Format(buffer,2,"%i",currentplace[client][ITEM])
	KvJumpToKey(kv, buffer)	//Jump to item
	
	
	new String:type[NAME_LENGTH]
		
	if (currentplace[client][REPLACENUM]<1)
		currentplace[client][REPLACENUM]=1
	
	Format(buffer,5,"#%i",currentplace[client][REPLACENUM])
	Format(buffer2,5,"@%i",currentplace[client][REPLACENUM])
	
	if (StrContains(command[client], buffer) != -1 || StrContains(command[client], buffer2) != -1)
	{
		//user has a parameter to fill. lets do it.	
		Format(buffer,5,"%i",currentplace[client][REPLACENUM])
		KvJumpToKey(kv, buffer) // Jump to current param
		KvGetString(kv, "type", type, sizeof(type),"list")
		
		new Handle:itemmenu
		
		new String:title[NAME_LENGTH]
		new String:path[200] = "mapcycle.txt"
		
		new MenuType:Type
		new PlayerMethod:playermethod
		
		if (strncmp(type,"team",4)==0)
		{
			if (StrContains(type,"player")!=-1)
			{
				Type = Player_Team
			}
			else
			{
				Type = Team
			}
		}
		else if (strncmp(type,"mapcycle",8)==0)
		{
			KvGetString(kv, "path", path, sizeof(path),"mapcycle.txt")
		
			Type = MapCycle

		}
		else if (strncmp(type,"player",6)==0)
		{
			Type = PlayerList		
		}		
		else
		{
			//list menu
			
			Type = List
			
			itemmenu = CreateMenu(Menu_Selection)

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
		
		}
		
		KvGetString(kv, "title", title, sizeof(title),"Choose an Option")
		
		
		if (Type == Player_Team || Type == PlayerList)
		{
			new String:method[NAME_LENGTH]			
			KvGetString(kv, "method", method, sizeof(method),"name")
			if (strncmp(method,"name",4)==0)
			{
				playermethod = Name
			}
			else if (strncmp(method,"steamid",6)==0)
			{
				playermethod = SteamId
			}
			else if (strncmp(method,"userid",6)==0)
			{
				playermethod = UserId	
			}
			else
			{
				playermethod = ClientId	
			}
		}
		
		if (Type != List)
			itemmenu = GenerateAutoMenu(Type,Menu_Selection,mod,title,playermethod,path)
		
		SetMenuTitle(itemmenu, title)
		DisplayMenu(itemmenu, client, MENU_TIME_FOREVER)	
	}
	else
	{	
		//nothing else need to be done. Run teh command.
		new String:execute[7]
		KvGetString(kv, "execute", execute, sizeof(execute), "player")
		
		KvGoBack(kv)
		new Handle:itemmenu = buildsubmenu(client)
		DisplayMenu(itemmenu, client, MENU_TIME_FOREVER)
		
		if (execute[0]=='p')
		{
			LogMessage("%L sent command \"%s\" to client console",client,command[client])
			FakeClientCommand(client, command[client])
		}
		else
		{
			LogMessage("%L sent command \"%s\" to server console",client,command[client])
			InsertServerCommand(command[client])
			ServerExecute()
		}

		command[client][0]='\0'
		currentplace[client][REPLACENUM]=1
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
		new String:infobuffer[NAME_LENGTH+2]
		Format(infobuffer,sizeof(infobuffer),"\"%s\"",info)
		
		Format(buffer,4,"#%i",currentplace[param1][REPLACENUM])
		ReplaceString(command[param1], sizeof(command[]), buffer, infobuffer)
		//replace #num with the selected option (quoted)
		
		Format(buffer,4,"@%i",currentplace[param1][REPLACENUM])
		ReplaceString(command[param1], sizeof(command[]), buffer, info)
		//replace @num with the selected option (unquoted)
		
		currentplace[param1][REPLACENUM]++
		
		ParamCheck(param1)
	}
	
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		//client exited we should go back to submenu i thin
		new String:buffer[3]
		Format(buffer,sizeof(buffer),"%i",currentplace[param1][SUBMENU])
		KvJumpToKey(kv, buffer) //Jump to submenu
		
		new Handle:itemmenu = buildsubmenu(param1)
		DisplayMenu(itemmenu, param1, MENU_TIME_FOREVER)
		
		KvRewind(kv)
		
	}
	
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

stock GetAdminLevel(String:key[])
{
		if (key[0] == 'r' && key[1] == 'e')
		{
			return ADMFLAG_RESERVATION
		} else if (key[0] == 'k') {
			return ADMFLAG_KICK
		} else if (key[0] == 'g') {
			return ADMFLAG_GENERIC
		} else if (key[0] == 'b') {
			return ADMFLAG_BAN
		} else if (key[0] == 'u') {
			return ADMFLAG_UNBAN
		} else if (key[0] == 's') {
			return ADMFLAG_SLAY
		} else if (key[0] == 'c' && key[1] == 'h' && key[3] == 'n') {
			return ADMFLAG_CHANGEMAP
		} else if (key[0] == 'c' && key[1] == 'v') {
			return ADMFLAG_CONVARS
		} else if (key[0] == 'c' && key[1] == 'o') {
			return ADMFLAG_CONFIG
		} else if (key[0] == 'c' && key[1] == 'h' && key[2]== 'a') {
			return ADMFLAG_CHAT
		} else if (key[0] == 'v') {
			return ADMFLAG_VOTE
		} else if (key[0] == 'p') {
			return ADMFLAG_PASSWORD
		} else if (key[0] == 'r' && key[1] == 'c') {
			return ADMFLAG_RCON
		} else if (key[0] == 'c') {
			return ADMFLAG_CHEATS
		} else if (key[0] == 'r') {
			return ADMFLAG_ROOT
		} else if (key[6] == '1') {
			return ADMFLAG_CUSTOM1
		} else if (key[6] == '2') {
			return ADMFLAG_CUSTOM2
		} else if (key[6] == '3') {
			return ADMFLAG_CUSTOM3
		} else if (key[6] == '4') {
			return ADMFLAG_CUSTOM4
		} else if (key[6] == '5') {
			return ADMFLAG_CUSTOM5
		} else if (key[6] == '6') {
			return ADMFLAG_CUSTOM6
		} else {
			return -1
		}
}