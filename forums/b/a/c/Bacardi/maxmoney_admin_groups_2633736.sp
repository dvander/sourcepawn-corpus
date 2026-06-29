

int m_iAccountMax[MAXPLAYERS+1] = {-1, ...};

char filepath[PLATFORM_MAX_PATH];
KeyValues mp_maxmoney_admin_groups;


public Plugin myinfo = 
{
	name = "Max Money admin groups",
	author = "Bacardi",
	description = "Limit player(s) max money, global and by admin group",
	version = "0.0",
	url = "https://forums.alliedmods.net/showpost.php?p=2633685&postcount=27"
};


public void OnPluginStart()
{
	BuildPath(Path_SM, filepath, sizeof(filepath), "configs/maxmoney_admin_groups.cfg");

	if(!FileExists(filepath)) SetFailState("File '%s' not exist", filepath);

	mp_maxmoney_admin_groups = new KeyValues("Groups");

	if(!mp_maxmoney_admin_groups.ImportFromFile(filepath)) SetFailState("KeyValue fail import file '%s'", filepath);


	HookEvent("player_spawn", player_spawn);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) OnClientPostAdminCheck(i);
	}
}

public void OnConfigsExecuted()
{
	delete mp_maxmoney_admin_groups;
	mp_maxmoney_admin_groups = new KeyValues("Groups");

	if(!mp_maxmoney_admin_groups.ImportFromFile(filepath)) SetFailState("KeyValue fail import file '%s'", filepath);
}


public void OnClientPostAdminCheck(int client)
{
	int maxmoneydefault = mp_maxmoney_admin_groups.GetNum("default", -1); // "default" max money value from config maxmoney_admin_groups.cfg
	m_iAccountMax[client] = maxmoneydefault;

	AdminId admin = GetUserAdmin(client);

	if(admin == INVALID_ADMIN_ID) return;

	int groupcount = admin.GroupCount;
	char groupname[MAX_NAME_LENGTH];



	for(int a = 0; a < groupcount; a++)
	{
		if(admin.GetGroup(a, groupname, sizeof(groupname)) == INVALID_GROUP_ID) continue;

		m_iAccountMax[client] = mp_maxmoney_admin_groups.GetNum(groupname, maxmoneydefault);
	}
}


public void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));


	if(m_iAccountMax[client] <= -1) return; // From config file, if default value removed or one of group values have set below 0, skip money limit.


	if(GetClientTeam(client) >= 2 && GetEntProp(client, Prop_Send, "m_iAccount") > m_iAccountMax[client])
	{
		SetEntProp(client, Prop_Send, "m_iAccount", m_iAccountMax[client]);
	}
}