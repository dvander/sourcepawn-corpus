#include <sourcemod>
#include <adminmenu>
#include <sdktools>


#define STORED_ENTRIES 100
#define PLUGIN_VERSION "1.04"

public Plugin:myinfo = {
	name        = "Ban disconnected players",
	author      = "mad_hamster",
	description = "Lets you ban players that recently disconnected",
	version     = PLUGIN_VERSION,
	url         = "http://pro-css.co.il"
};


new Handle:hTopMenu = INVALID_HANDLE;

static String:disconnected_player_names  [STORED_ENTRIES][32];
static String:disconnected_player_authids[STORED_ENTRIES][32];
static disconnected_player_times         [STORED_ENTRIES];



public OnPluginStart() {
	CreateConVar("ban_disconnected_ver", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_bandisconnected", BanDisconnected, ADMFLAG_BAN);
	HookEvent("player_disconnect", OnEventPlayerDisconnect);
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
}



public Action:OnEventPlayerDisconnect(Handle:event, const String:name[], bool:dont_broadcast) {
	decl String:steam_id[32];
	GetEventString(event, "networkid", steam_id, sizeof(steam_id));

	// Ignore if authid does not start with STEAM_ (possibly bot), or is identical to the last
	// disconnected steam id, but only if it occured at the same second (duplicate event)
	// Note: We can't resolve the client index from the event's userid and check IsFakeClient(),
	//       since the client may have disconnected already under some HL2 games.
	if (   strncmp(steam_id, "STEAM_", 6) == 0
	    && (   queue_get_size() == 0
	        || (   strcmp(steam_id, disconnected_player_authids[queue_translate_pos(queue_get_size()-1)]) != 0
	            || disconnected_player_times[queue_translate_pos(queue_get_size()-1)] != GetTime())))
	{
		new pos = queue_push();
		strcopy(disconnected_player_authids[pos], sizeof(disconnected_player_authids[]), steam_id);
		GetEventString(event, "name", disconnected_player_names[pos], sizeof(disconnected_player_names[]));
		disconnected_player_times[pos] = GetTime();
	}
	return Plugin_Continue;
}



public Action:BanDisconnected(client, args) {
	if (args < 2 || args > 3)
		ReplyToCommand(client, "[SM] Usage: sm_bandisconnected <\"steamid\"> <minutes|0> [\"reason\"]");
	else {
		decl String:steamid[20], String:minutes[10], String:reason[256];
		GetCmdArg(1, steamid, sizeof(steamid));
		GetCmdArg(2, minutes, sizeof(minutes));
		GetCmdArg(3, reason,  sizeof(reason));
		CheckAndPerformBan(client, steamid, StringToInt(minutes), reason);
	}

	return Plugin_Handled;
}



CheckAndPerformBan(client, const String:steamid[], minutes, const String:reason[]) {
	new AdminId:source_aid = GetUserAdmin(client), AdminId:target_aid;
	if (   (target_aid = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid)) == INVALID_ADMIN_ID
		|| CanAdminTarget(source_aid, target_aid))
	{
		// Ugly hack: Sourcemod doesn't provide means to run a client command with elevated permissions,
		// so we briefly grant the admin the root flag
		new bool:has_root_flag = GetAdminFlag(source_aid, Admin_Root);
		SetAdminFlag(source_aid, Admin_Root, true);
		FakeClientCommand(client, "sm_addban %d \"%s\" %s", minutes, steamid, reason);
		SetAdminFlag(source_aid, Admin_Root, has_root_flag);
	}
	else ReplyToCommand(client, "[sm_bandisconnected] You can't ban an admin with higher immunity than yourself");
}



///////////////////////////////////////////////////////////////////////////////
// Menu madness
///////////////////////////////////////////////////////////////////////////////

public OnAdminMenuReady(Handle:topmenu) {
	if (topmenu != hTopMenu) {
		hTopMenu = topmenu;
		new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
		if (player_commands != INVALID_TOPMENUOBJECT)
			AddToTopMenu(hTopMenu, "sm_bandisconnected", TopMenuObject_Item, AdminMenu_Ban,
				player_commands, "sm_bandisconnected", ADMFLAG_BAN);
	}
}



public AdminMenu_Ban(Handle:topmenu,
	TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Ban disconnected player");
	else if (action == TopMenuAction_SelectOption)
		DisplayBanTargetMenu(param);
}



DisplayBanTargetMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_BanPlayerList);
	SetMenuTitle(menu, "Ban disconnected player");
	SetMenuExitBackButton(menu, true);
	for (new i=queue_get_size()-1; i>=0; --i) {
		new pos = queue_translate_pos(i);
		decl String:client_info[100];
		new delta = GetTime() - disconnected_player_times[pos];
		Format(client_info, sizeof(client_info), "%s (%s) (%dd:%02dh:%02dm:%02ds ago)",
			disconnected_player_names[pos],
			disconnected_player_authids[pos],
			(delta / (60*60*24)),
			(delta % (60*60*24)) / (60*60),
			(delta % (60*60)) / 60,
			(delta % 60));
		AddMenuItem(menu, disconnected_player_authids[pos], client_info);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}



public MenuHandler_BanPlayerList(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select) {
		decl String:state_[128];
		GetMenuItem(menu, param2, state_, sizeof(state_));
		DisplayBanTimeMenu(param1, state_);
	}
}



AddMenuItemWithState(Handle:menu, const String:state_[], const String:addstate[], const String:display[]) {
	decl String:newstate[128];
	Format(newstate, sizeof(newstate), "%s\n%s", state_, addstate);
	AddMenuItem(menu, newstate, display);
}




DisplayBanTimeMenu(client, const String:state_[]) {
	new Handle:menu = CreateMenu(MenuHandler_BanTimeList);
	SetMenuTitle(menu, "Ban disconnected player");
	SetMenuExitBackButton(menu, true);
	AddMenuItemWithState(menu, state_, "0", "Permanent");
	AddMenuItemWithState(menu, state_, "10", "10 Minutes");
	AddMenuItemWithState(menu, state_, "30", "30 Minutes");
	AddMenuItemWithState(menu, state_, "60", "1 Hour");
	AddMenuItemWithState(menu, state_, "240", "4 Hours");
	AddMenuItemWithState(menu, state_, "1440", "1 Day");
	AddMenuItemWithState(menu, state_, "10080", "1 Week");
	AddMenuItemWithState(menu, state_, "20160", "2 Weeks");
	AddMenuItemWithState(menu, state_, "30240", "3 Weeks");
	AddMenuItemWithState(menu, state_, "43200", "1 Month");
	AddMenuItemWithState(menu, state_, "129600", "3 Months");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}



public MenuHandler_BanTimeList(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select) {
		decl String:state_[128];
		GetMenuItem(menu, param2, state_, sizeof(state_));
		DisplayBanReasonMenu(param1, state_);
	}
}



DisplayBanReasonMenu(client, const String:state_[]) {
	new Handle:menu = CreateMenu(MenuHandler_BanReasonList);
	SetMenuTitle(menu, "Ban reason");
	SetMenuExitBackButton(menu, true);
	AddMenuItemWithState(menu, state_, "Abusive", "Abusive");
	AddMenuItemWithState(menu, state_, "Racism", "Racism");
	AddMenuItemWithState(menu, state_, "General cheating/exploits", "General cheating/exploits");
	AddMenuItemWithState(menu, state_, "Wallhack", "Wallhack");
	AddMenuItemWithState(menu, state_, "Aimbot", "Aimbot");
	AddMenuItemWithState(menu, state_, "Speedhacking", "Speedhacking");
	AddMenuItemWithState(menu, state_, "Mic spamming", "Mic spamming");
	AddMenuItemWithState(menu, state_, "Admin disrepect", "Admin disrepect");
	AddMenuItemWithState(menu, state_, "Camping", "Camping");
	AddMenuItemWithState(menu, state_, "Team killing", "Team killing");
	AddMenuItemWithState(menu, state_, "Unacceptable Spray", "Unacceptable Spray");
	AddMenuItemWithState(menu, state_, "Breaking Server Rules", "Breaking Server Rules");
	AddMenuItemWithState(menu, state_, "Other", "Other");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}



public MenuHandler_BanReasonList(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select) {
		decl String:state_[128], String:state_parts[4][32];
		GetMenuItem(menu, param2, state_, sizeof(state_));
		if (ExplodeString(state_, "\n", state_parts, sizeof(state_parts), sizeof(state_parts[])) != 3)
			SetFailState("Bug in menu handlers");
		else CheckAndPerformBan(param1, state_parts[0], StringToInt(state_parts[1]), state_parts[2]);
	}
}



///////////////////////////////////////////////////////////////////////////////
// A very simple fixed-size queue yielding offsets into cyclic array(s)
///////////////////////////////////////////////////////////////////////////////

static queue_max_size = STORED_ENTRIES;
static queue_size     = 0;
static queue_start    = 0;


queue_get_size()   { return queue_size; }
//queue_is_full()    { return queue_size == queue_max_size; }
//queue_is_empty()   { return queue_size == 0; }
//queue_space_left() { return queue_max_size - queue_size; }



// Given a logical position within the queue between 0 (queue front; oldest item)
// and queue_size-1 (queue back; newest item), returns the translated position
// in the cyclic array.

queue_translate_pos(pos) {
	pos += queue_start;
	if (pos >= queue_max_size)
		return pos - queue_max_size;
	else return pos;
}


// Adds an item to the queue, possibly popping the oldest item to make room if
// the queue is full. Returns the translated position of the new item in the
// cyclic array.

queue_push() {
	if (queue_size == queue_max_size)
		queue_pop();
	return queue_translate_pos(queue_size++);
}


// Removes an item from the queue, assuming it is non-empty. If it is empty, it
// will stop the plugin execution!

queue_pop() {
	if (queue_size == 0) {
		SetFailState("Can't pop from an empty queue!");
		return -1;
	}
	else {
		new pos = queue_start;
		queue_start = queue_translate_pos(1);
		--queue_size;
		return pos;
	}
}

