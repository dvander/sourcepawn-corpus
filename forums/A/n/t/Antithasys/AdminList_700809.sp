#include <sourcemod>
#pragma semicolon 1

new Handle:AdminListEnabled = INVALID_HANDLE;
new Handle:AdminListMode = INVALID_HANDLE;
new Handle:AdminListMenu = INVALID_HANDLE;
new Handle:AdminListAdminFlag = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Admin List",
	author = "Fredd",
	description = "prints admins to clients",
	version = "1.3b",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("adminlist_version", "1.3b", "Admin List Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AdminListEnabled = CreateConVar("adminlist_on", "1", "turns on and off admin list, 1=on ,0=off");
	AdminListMode = CreateConVar("adminlist_mode", "1", "mode that changes how the list appears..");
	AdminListAdminFlag = CreateConVar("adminlist_adminflag", "d", "admin flag to use for list. must be in char format");
	RegConsoleCmd("sm_admins", Command_Admins, "Displays Admins to players");
	AutoExecConfig(true, "plugin.adminlist");
}
public Action:Command_Admins(client, args)
{
	if (GetConVarBool(AdminListEnabled)) {
		switch(GetConVarInt(AdminListMode)) {
			case 1:
			{
				decl String:AdminNames[MAXPLAYERS+1][MAX_NAME_LENGTH+1];
				new count = 0;
				for(new i = 1 ; i <= GetMaxClients();i++) {
					if(IsClientInGame(i) && IsAdmin(i)) {
						GetClientName(i, AdminNames[count], sizeof(AdminNames[]));
						count++;
					} 
				}
				decl String:buffer[1024];
				ImplodeStrings(AdminNames, count, ",", buffer, sizeof(buffer));
				PrintToChatAll("\x04Admins online are: %s", buffer);
			}
			case 2:
			{
				decl String:AdminName[MAX_NAME_LENGTH];
				AdminListMenu = CreateMenu(MenuListHandler);
				SetMenuTitle(AdminListMenu, "Admins Online:");							
				for(new i = 1; i <= GetMaxClients(); i++) {
					if(IsClientInGame(i) && IsAdmin(i)) {
						GetClientName(i, AdminName, sizeof(AdminName));
						AddMenuItem(AdminListMenu, AdminName, AdminName);
					} 
				}
				SetMenuExitButton(AdminListMenu, true);
				DisplayMenu(AdminListMenu, client, 15);
			}
		}
	}
	return Plugin_Handled;
}
public MenuListHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
}

stock bool:IsAdmin(client)
{
	decl String:flags[64];
	GetConVarString(AdminListAdminFlag, flags, sizeof(flags));
	new ibFlags = ReadFlagString(flags);
	if ((GetUserFlagBits(client) & ibFlags) == ibFlags)
		return true;
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		return true;
	return false;
}