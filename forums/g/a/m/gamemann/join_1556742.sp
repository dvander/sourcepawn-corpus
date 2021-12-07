#include<sourcemod>
#include<sdktools>
#include<colors>

public Plugin:myinfo = {
	name = "JOIN",
	author = "gamemann",
	description = "!join sign",
	version = "1",
	url = "http://games223.com/"
};

new Handle:Flag = INVALID_HANDLE;
new Handle:Group = INVALID_HANDLE;
/*
new Handle:Group1 = INVALID_HANDLE;
new Handle:Group2 = INVALID_HANDLE;
new Handle:Group3 = INVALID_HANDLE;
*/
new Handle:GroupName = INVALID_HANDLE;

public OnPluginStart()
{
	Flag = CreateConVar("sm_join_flag", "99:@mem", "The groups name to put in admin simple.ini, USAGE: <immunity>:@<groupname>");
	Group = CreateConVar("sm_join_group", "MEM", "The group name to check to see if hes in that group or not(prevents flooding the admim_simple.ini and should be same group as sm_join_flag group is set to ");
	CreateConVar("sm_join_version", "1", "Plugin's version");
	/* 
	Currently Unavailable 
	Group1 = CreateConVar("sm_join_group_2", "", "The group of the member added 2");
	Group2 = CreateConVar("sm_join_group_3", "", "The group of the member added 3");
	Group3 = CreateConVar("sm_join_group_4", "", "The group of the member added 4");
	*/
	GroupName = CreateConVar("sm_join_group_name", "", "Groups name of the group");
	RegConsoleCmd("sm_join", CmdJoin);
	AutoExecConfig(true, "sm_join");

}

public Action:CmdJoin(client, args)
{
	//new string
	new String:groupName[64];
	GetConVarString(Group, groupName, sizeof(groupName));
	if(Client_IsInAdminGroup(client, groupName, false))
	{
		PrintToChat(client, "\x02 Your already a member");
	}
	else
	{
		new String:groupN[64];
		GetConVarString(GroupName, groupN, sizeof(groupN));
		CPrintToChat(client, "{green}Your a member of %s now! Please rejoin and get everything!", groupN);
		decl String:user[64];
		GetClientName(client, user, sizeof(user));
		decl String:buffer[256];
		GetClientAuthString(client, buffer, sizeof(buffer));
		new String:szFile[256];
		BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins_simple.ini");

		new Handle:hFile = OpenFile(szFile, "at");

		//get flag name
		//new string
		new String:groupFlag[64];
		GetConVarString(Flag, groupFlag, sizeof(groupFlag));
		//write the lines
		// username
		WriteFileLine(hFile, "//%s", user);
		//id and flag
		WriteFileLine(hFile, "\"%s\" \"%s\"", buffer, groupFlag);

		CloseHandle(hFile);
		ServerCommand("sm_reloadadmins");
	}
	return Plugin_Handled;
}

//stock clients group
stock bool:Client_IsInAdminGroup(client, const String:groupName[], bool:caseSensitive=true)
{
	new AdminId:adminId = GetUserAdmin(client);

	// Validate id.
	if (adminId == INVALID_ADMIN_ID) {
		return false;
	}

	// Get number of groups.
	new count = GetAdminGroupCount(adminId);

	// Validate number of groups.
	if (count == 0) {
		return false;
	}

	decl String:groupname[64];

	// Loop through each group.
	for (new i = 0; i < count; i++) {
		// Get group name.
		GetAdminGroup(adminId, i, groupname, sizeof(groupname));
		
		// Compare names.
		if (StrEqual(groupName, groupname, caseSensitive)) {
			return true;
		}
	}

	// No match.
	return false;
}