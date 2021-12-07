/* put the line below after all of the includes!
#pragma newdecls required
*/

#include <sourcemod>
#include <adminmenu>
#include <sdktools>


#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <updater>  // Comment out this line to remove updater support by force.
#tryinclude <sourcebanspp>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

#define UPDATE_URL    "https://raw.githubusercontent.com/eyal282/AlliedmodsUpdater/master/y/updatefile.txt"

#pragma newdecls required

char PLUGIN_VERSION[] = "1.0";

// Heavy edit from mad_hamster's plugin
public Plugin myinfo =
{
	name = "Ban disconnected players",
	author = "Eyal282, based on mad_hamster's plugin",
	description = "Allows you to ban players that have disconnected from the server.",
	version = PLUGIN_VERSION,
	url = ""
};

enum struct Entry
{
	char AuthId[35];
	int AccountId;
	char Name[64];
	int timestamp;
	
	void init(char AuthId[35], int AccountId, char Name[64], int timestamp)
	{
		this.AuthId = AuthId;
		this.AccountId = AccountId;
		this.Name = Name;
		this.timestamp = timestamp;
	}
}


ArrayList Array_Reasons;
ArrayList Array_Bans;

Handle hcv_MaxSave = INVALID_HANDLE;
Handle hTopMenu = INVALID_HANDLE;

bool SBPP_Loaded = false;

public void OnPluginStart()
{
	Array_Reasons = new ArrayList(128);
	Array_Bans = new ArrayList(sizeof(Entry));
	
	hcv_MaxSave = CreateConVar("ban_disconnected_max_save", "100", "Maximum amount of disconnected players to store.");
	
	ReadBanReasons();
	
	CreateConVar("ban_disconnected_version", PLUGIN_VERSION, _, FCVAR_NOTIFY);
	
	RegAdminCmd("sm_bandisconnected", BanDisconnected, ADMFLAG_BAN);
	
	Handle topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
		
	#if defined _updater_included
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
	
	SBPP_Loaded = false;
	#if defined _sourcebanspp_included
	if (LibraryExists("sourcebans++"))
	{
		SBPP_Loaded = true;
	}
	#endif
}


#if defined _updater_included
public int Updater_OnPluginUpdated()
{
	ServerCommand("sm_reload_translations");
	
	ReloadPlugin(INVALID_HANDLE);
}
#endif
public void OnLibraryAdded(const char[] name)
{
	#if defined _updater_included
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
	
	#if defined _sourcebanspp_included
	if (StrEqual(name, "sourcebans++"))
	{
		SBPP_Loaded = true;
	}
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _sourcebanspp_included
	if (StrEqual(name, "sourcebans++"))
	{
		SBPP_Loaded = false;
	}
	#endif
}

void ReadBanReasons()
{
	char Path[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, Path, sizeof(Path), "configs/banreasons.txt");
	
	Handle keyValues = CreateKeyValues("banreasons");
	
	if(!FileToKeyValues(keyValues, Path))
	{
		SetFailState("Couldn't read %s", Path);
		return;
	}
	
	else if(!KvGotoFirstSubKey(keyValues, false))
	{
		SetFailState("%s is an invalid keyvalues file.", Path);
		return;
	}

	do
	{
		char Reason[128];
		KvGetSectionName(keyValues, Reason, sizeof(Reason));
		
		Array_Reasons.PushString(Reason);
	}
	while(KvGotoNextKey(keyValues, false))
	
	CloseHandle(keyValues);
}

public void OnClientDisconnect(int client)
{
	char AuthId[35], Name[64];
	
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	GetClientName(client, Name, sizeof(Name));
	
	int timestamp = GetTime();
	
	int AccountId = GetSteamAccountID(client);
	
	if(AccountId == 0)
		return;
		
	Entry entry;
	entry.init(AuthId, AccountId, Name, timestamp);
	
	if(Array_Bans.Length > 0)
	{
		Array_Bans.ShiftUp(0);
	
		Array_Bans.SetArray(0, entry);
	}
	else
	{
		Array_Bans.PushArray(entry);
	}
		
	
	int MaxSave = GetConVarInt(hcv_MaxSave);
	
	while(Array_Bans.Length > MaxSave)
		Array_Bans.Erase(MaxSave);
}
public Action BanDisconnected(int client, int args) {
	if(args < 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_bandisconnected <steamid> <minutes|0> <reason>");
		
		return Plugin_Handled;
	}
	
	char AuthId[35], Duration[11], Reason[256];
	
	GetCmdArg(1, AuthId, sizeof(AuthId));
	GetCmdArg(2, Duration, sizeof(Duration));
	GetCmdArg(3, Reason, sizeof(Reason));

	CheckAndPerformBan(client, AuthId, "", StringToInt(Duration), Reason);

	return Plugin_Handled;
}

void CheckAndPerformBan(int client, const char[] steamid, const char[] name, int minutes, const char[] reason)
{
	AdminId source_aid = GetUserAdmin(client), target_aid;
	
	if((target_aid = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid)) == INVALID_ADMIN_ID 
	|| CanAdminTarget(source_aid, target_aid))
	{
		// Ugly hack: Sourcemod doesn't provide means to run a client command with elevated permissions,
		// so we briefly grant the admin the root flag
		bool has_root_flag = GetAdminFlag(source_aid, Admin_Root);
		SetAdminFlag(source_aid, Admin_Root, true);
		
		if(SBPP_Loaded)
		{
			char FinalName[64];
			FormatEx(FinalName, sizeof(FinalName), name);
			
			int AccountId = 0;
			
			int size = Array_Bans.Length;
			
			for(int i=0;i < size;i++)
			{
				Entry entry;
		
				GetArrayArray(Array_Bans, i, entry);
		
				if(StrEqual(entry.AuthId, steamid))
				{
					if(FinalName[0] == EOS)
						FormatEx(FinalName, sizeof(FinalName), entry.Name);
						
					AccountId = entry.AccountId;
					break;
				}
			}
			SBPP_BanAccountId(AccountId, client, minutes, reason, _, FinalName)
		}
		else
			FakeClientCommand(client, "sm_addban %d \"%s\" %s", minutes, steamid, reason);
		
		//FakeClientCommand(client, "sm_addban %d \"%s\" %s", minutes, steamid, reason);
		SetAdminFlag(source_aid, Admin_Root, has_root_flag);
	}
	else ReplyToCommand(client, "[sm_bandisconnected] You can't ban an admin with higher immunity than yourself");
}

///////////////////////////////////////////////////////////////////////////////
// Menu madness
///////////////////////////////////////////////////////////////////////////////

public void OnAdminMenuReady(Handle topmenu) {
	if(topmenu != hTopMenu) {
		hTopMenu = topmenu;
		TopMenuObject player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
		
		if(player_commands != INVALID_TOPMENUOBJECT)
			AddToTopMenu(hTopMenu, "sm_bandisconnected", TopMenuObject_Item, AdminMenu_Ban, 
			player_commands, "sm_bandisconnected", ADMFLAG_BAN);
	}
}


public void AdminMenu_Ban(Handle topmenu,
	TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if(action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Ban disconnected player");
		
	else if(action == TopMenuAction_SelectOption)
	{
		DisplayBanTargetMenu(param);
	}
}



void DisplayBanTargetMenu(int client)
{
	int size = Array_Bans.Length;
	
	if(size == 0)
	{
		PrintToChat(client, "[SM] There aren't any stored disconnected players yet.");
		
		return;
	}
	
	Handle menu = CreateMenu(MenuHandler_BanPlayerList);
	SetMenuTitle(menu, "Ban disconnected player");
	SetMenuExitBackButton(menu, true);
	
	char TempFormat[128], Info[128];
	
	for(int i=0;i < size;i++)
	{
		Entry entry;
		
		GetArrayArray(Array_Bans, i, entry);
		
		FormatEx(TempFormat, sizeof(TempFormat), "%s (%s)", entry.Name, entry.AuthId);
		
		FormatEx(Info, sizeof(Info), "%s\n%s", entry.AuthId, entry.Name);
		AddMenuItem(menu, Info, TempFormat);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}



public int MenuHandler_BanPlayerList(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
		
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if(action == MenuAction_Select)
	{
		char state_[128];
		GetMenuItem(menu, param2, state_, sizeof(state_));
		DisplayBanTimeMenu(param1, state_);
	}
}



void AddMenuItemWithState(Handle menu, const char[] state_, const char[] addstate, const char[] display) {
	char newstate[128];
	Format(newstate, sizeof(newstate), "%s\n%s", state_, addstate);
	AddMenuItem(menu, newstate, display);
}




void DisplayBanTimeMenu(int client, const char[] state_) {
	Handle menu = CreateMenu(MenuHandler_BanTimeList);
	SetMenuTitle(menu, "Ban disconnected player");
	SetMenuExitBackButton(menu, true);
	AddMenuItemWithState(menu, state_, "0", "Permanent");
	AddMenuItemWithState(menu, state_, "10", "10 Minutes");
	AddMenuItemWithState(menu, state_, "30", "30 Minutes");
	AddMenuItemWithState(menu, state_, "60", "1 Hour");
	AddMenuItemWithState(menu, state_, "120", "2 Hours");
	AddMenuItemWithState(menu, state_, "180", "3 Hours");
	AddMenuItemWithState(menu, state_, "240", "4 Hours");
	AddMenuItemWithState(menu, state_, "480", "8 Hours");
	AddMenuItemWithState(menu, state_, "720", "12 Hours");
	AddMenuItemWithState(menu, state_, "1440", "1 Day");
	AddMenuItemWithState(menu, state_, "4320", "3 Days");
	AddMenuItemWithState(menu, state_, "10080", "1 Week");
	AddMenuItemWithState(menu, state_, "20160", "2 Weeks");
	AddMenuItemWithState(menu, state_, "30240", "3 Weeks");
	AddMenuItemWithState(menu, state_, "43200", "1 Month");
	AddMenuItemWithState(menu, state_, "129600", "3 Months");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}



public int MenuHandler_BanTimeList(Handle menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if(action == MenuAction_Select) {
		char state_[128];
		GetMenuItem(menu, param2, state_, sizeof(state_));
		DisplayBanReasonMenu(param1, state_);
	}
}



void DisplayBanReasonMenu(int client, const char[] state_)
{
	Handle menu = CreateMenu(MenuHandler_BanReasonList);
	SetMenuTitle(menu, "Ban reason");
	SetMenuExitBackButton(menu, true);
	
	int size = GetArraySize(Array_Reasons);
	
	for(int i=0;i < size;i++)
	{
		char Reason[128];
		Array_Reasons.GetString(i, Reason, sizeof(Reason));
		
		AddMenuItemWithState(menu, state_, Reason, Reason);
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}



public int MenuHandler_BanReasonList(Handle menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if(action == MenuAction_Select) {
		char state_[128], state_parts[4][32];
		GetMenuItem(menu, param2, state_, sizeof(state_));
		if(ExplodeString(state_, "\n", state_parts, sizeof(state_parts), sizeof(state_parts[])) != 4)
			SetFailState("Bug in menu handlers");

		else
			CheckAndPerformBan(param1, state_parts[0], state_parts[1], StringToInt(state_parts[2]), state_parts[3]);
	}
}