#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define PLUGIN_VERSION "1.0"

new Handle:sm_donateinfo_enabled = INVALID_HANDLE;
new Handle:sm_donateinfo_descmode = INVALID_HANDLE;
new String:donatepath[PLATFORM_MAX_PATH];
new Item = 0;

public Plugin:myinfo = 
{
	name = "Server Donation Info",
	author = "ReFlexPoison",
	description = "Show Information About Server Donations in Menu",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	BuildPath(Path_SM, donatepath, sizeof(donatepath), "configs/donateinfo.cfg");
	
	CreateConVar("sm_donateinfo_version", PLUGIN_VERSION, "Server Donation Info Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	sm_donateinfo_enabled = CreateConVar("sm_donateinfo_enabled", "1", "Enabled Server Donation Info\n1=Enabled\n0=Disabled.");
	sm_donateinfo_descmode = CreateConVar("sm_donateinfo_descmode", "1", "Enable Selection of Description in Menu for More Info\n1=Enabled\n0=Disabled.");
	
	RegConsoleCmd("sm_donateinfo", DonateMenu_Function);
	RegConsoleCmd("sm_dinfo", DonateMenu_Function);
	//RegConsoleCmd("sm_donate", DonateMenu_Function);
	
	AutoExecConfig(true, "plugin.donateinfo");
}

public Action:DonateMenu_Function(client, args)
{
	if (GetConVarInt(sm_donateinfo_enabled) == 1)
	{
		CreateDonateMenu(client, 0);
	}
	return Plugin_Handled;
}

public Action:CreateDonateMenu(client, item)
{
	new Handle:DonateMenu = CreateMenu(DonateMenuHandler);
	SetMenuTitle(DonateMenu, "Donation Info");
	
	new Handle:kv = CreateKeyValues("Info");
	FileToKeyValues(kv, donatepath);
	
	decl String:DonateNumber[512];
	decl String:DonateName[512];
	
	if (!KvGotoFirstSubKey(kv))
	{
		return Plugin_Continue;
	}
	do
	{
		KvGetSectionName(kv, DonateNumber, sizeof(DonateNumber));	
		KvGetString(kv, "name", DonateName, sizeof(DonateName));
		AddMenuItem(DonateMenu, DonateNumber, DonateName);	
	}
	while (KvGotoNextKey(kv));
	{
		CloseHandle(kv);  
		DisplayMenuAtItem(DonateMenu, client, item, 15);
	}
	return Plugin_Handled;  
}

public HandlerBackToMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		CreateDonateMenu(param1, Item);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public DonateMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{			 
		new Handle:kv = CreateKeyValues("Info");   
		FileToKeyValues(kv, donatepath);
		
		if (!KvGotoFirstSubKey(kv))
		{
			CloseHandle(menu);
		}		

		decl String:buffer[255];
		decl String:choice[255];
		GetMenuItem(menu, param2, choice, sizeof(choice));	 
		do
		{   
			KvGetSectionName(kv, buffer, sizeof(buffer));
			if (StrEqual(buffer, choice))
			{
				decl String:DonateName[255];
				decl String:DonateDescription[255];
				KvGetString(kv, "name", DonateName, sizeof(DonateName));
				KvGetString(kv, "description", DonateDescription, sizeof(DonateDescription));
				decl String:Donate[255];
				decl String:Desc[255];
				Format(Donate, sizeof(Donate), "%s", DonateName);
				Format(Desc, sizeof(Desc), "%s", DonateDescription); 
				Item = GetMenuSelectionPosition();		
				if(GetConVarInt(sm_donateinfo_descmode) == 1)
				{
					new Handle:DescriptionPanel = CreatePanel(); 
					SetPanelTitle(DescriptionPanel, Donate);
					DrawPanelText(DescriptionPanel, " ");
					DrawPanelText(DescriptionPanel, Desc);
					DrawPanelText(DescriptionPanel, " ");
					DrawPanelItem(DescriptionPanel, "Back");				 
					SendPanelToClient(DescriptionPanel, param1, HandlerBackToMenu, 15);	
				}
			}
		} 
		while (KvGotoNextKey(kv));
		{
			CloseHandle(kv);
		}
	}
	else if (action == MenuAction_End)
	{
			CloseHandle(menu);
	}
}

public ShowDonateHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:UserId[64];
		GetMenuItem(menu, param2, UserId, sizeof(UserId));
		new i_UserId = StringToInt(UserId);
		new client = GetClientOfUserId(i_UserId);
		CreateDonateMenu(client, 1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}   
}
