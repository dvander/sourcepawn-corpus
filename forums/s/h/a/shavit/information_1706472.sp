#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <basecomm>

#undef REQUIRE_EXTENSIONS
#include <geoip>

#define PLUGIN_VERSION "3.6"
#define PREFIX "\x04[SM]\x01"

#pragma semicolon 1

new Handle:gH_Enabled = INVALID_HANDLE,
	Handle:gH_Menu = INVALID_HANDLE,
	Handle:gH_Targets = INVALID_HANDLE;

new bool:gB_Enabled,
	bool:gB_Menu,
	bool:gB_Targets;

new bool:gB_Basecomm,
	bool:gB_GeoIP;/*,
* 	bool:gB_ExtendedComm;                    ***** FUTURE USE ***** */

new String:Commands[][] = {"info", "myinfo", "information"};

public Plugin:myinfo = 
{
	name = "Information",
	author = "ml/shavit",
	description = "Showing your own/players information via the command \"sm_info\", \"sm_myinfo\", \"sm_information\".",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	new Handle:Version = CreateConVar("sm_information_version", PLUGIN_VERSION, "Information version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PLUGIN);
	SetConVarString(Version, PLUGIN_VERSION, _, true);
	
	gH_Enabled = CreateConVar("sm_information_enabled", "1", "Plugin's enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Menu = CreateConVar("sm_information_menu", "1", "Information printing will be on menu or chat? [0 - Chat] [1 - Menu]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Targets = CreateConVar("sm_information_targets", "1", "Allow admins to see other players information?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	gB_Enabled = GetConVarBool(gH_Enabled);
	gB_Menu = GetConVarBool(gH_Menu);
	gB_Targets = GetConVarBool(gH_Targets);
	
	HookConVarChange(gH_Enabled, ConVarChanged);
	HookConVarChange(gH_Menu, ConVarChanged);
	HookConVarChange(gH_Targets, ConVarChanged);
	
	LoadTranslations("common.phrases");
	
	AutoExecConfig();
	
	for(new i; i < sizeof(Commands); i++)
	{
		new String:Command[32];
		Format(Command, 32, "sm_%s", Commands[i]);
		RegConsoleCmd(Command, Command_Info, "Show your information, for targeting use !info <target>");
	}
	
	gB_Basecomm = LibraryExists("basecomm");
	gB_GeoIP = LibraryExists("GeoIP");
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "basecomm"))
	{
		gB_Basecomm = true;
	}
	
	else if(StrEqual(name, "GeoIP"))
	{
		gB_GeoIP = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name, "basecomm"))
	{
		gB_Basecomm = false;
	}
	
	else if(StrEqual(name, "GeoIP"))
	{
		gB_GeoIP = false;
	}
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Enabled)
	{
		gB_Enabled = StringToInt(newVal)? true:false;
	}
	
	else if(cvar == gH_Menu)
	{
		gB_Menu = StringToInt(newVal)? true:false;
	}
	
	else if(cvar == gH_Targets)
	{
		gB_Targets = StringToInt(newVal)? true:false;
	}
}

public Action:Command_Info(client, args)
{
	if(!gB_Enabled)
	{
		ReplyToCommand(client, "%s This plugin is disabled.", PREFIX);
		
		return Plugin_Handled;
	}
	
	decl String:arg1[MAX_TARGET_LENGTH];
	
	GetCmdArg(1, arg1, MAX_TARGET_LENGTH);
	
	new target = client;
	
	if(args == 1 && gB_Targets && CheckCommandAccess(client, "target_info", ADMFLAG_GENERIC))
	{
		target = FindTarget(client, arg1);
		
		if(target == -1)
		{
			return Plugin_Handled;
		}
	}
	
	new String:Name[MAX_NAME_LENGTH+10],
		String:IP[32],
		String:Muted[128],
		String:Gagged[128],
		String:UserID[16],
		String:Connected[32],
		String:Country[64];
	
	decl String:SteamID[32];
	
	GetClientIP(target, IP, 32);
	Format(IP, 32, "IP Address: %s.", IP);
	GetClientAuthString(target, SteamID, 32);
	Format(SteamID, 32, "SteamID: %s.", SteamID);
	
	if(gB_Basecomm)
	{
		Format(Muted, 128, "Muted: %s.", BaseComm_IsClientMuted(target)? "Yes":"No");
		Format(Gagged, 128, "Gagged: %s.", BaseComm_IsClientGagged(target)? "Yes":"No");
	}
	
	Format(UserID, 16, "UserID: #%d.", GetClientUserId(target));
	Format(Name, MAX_NAME_LENGTH+6, "Name: %N.", target);
	Format(Connected, 32, "Connected: %d minutes.", RoundToFloor(GetClientTime(target) / 60));
	
	if(gB_GeoIP)
	{
		GetClientIP(target, Country, 45);
		GeoipCountry(Country, Country, 45);
		Format(Country, 64, "Country: %s", Country);
	}
	
	if(gB_Menu)
	{
		new Handle:menu = CreateMenu(MenuHandler_menu);
		SetMenuTitle(menu, "%N's information", target);
		AddMenuItem(menu, "Name", Name);
		AddMenuItem(menu, "SteamID", SteamID);
		AddMenuItem(menu, "IP", IP);
		
		if(gB_Basecomm)
		{
			AddMenuItem(menu, "Muted", Muted);
			AddMenuItem(menu, "Gagged", Gagged);
		}
		
		AddMenuItem(menu, "UserID", UserID);
		AddMenuItem(menu, "Connected", Connected);
		
		if(gB_GeoIP)
		{
			AddMenuItem(menu, "Country", Country);
		}
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	}
	
	else
	{
		ReplyToCommand(client, "%s %snformation", PREFIX, target != client? "%N's i":"I", target);
		ReplyToCommand(client, "%s %s", PREFIX, Name);
		ReplyToCommand(client, "%s %s", PREFIX, SteamID);
		ReplyToCommand(client, "%s %s", PREFIX, IP);
		
		if(gB_Basecomm)
		{
			ReplyToCommand(client, "%s %s", PREFIX, Muted);
			ReplyToCommand(client, "%s %s", PREFIX, Gagged);
		}
		
		if(gB_GeoIP)
		{
			ReplyToCommand(client, "%s %s", PREFIX, Country);
		}
		
		ReplyToCommand(client, "%s %s", PREFIX, UserID);
		ReplyToCommand(client, "%s %s", PREFIX, Connected);
	}
	
	return Plugin_Handled;
}

public MenuHandler_menu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}