

char filepath[PLATFORM_MAX_PATH];
KeyValues mp_maxmoney_admin_groups;


public Plugin myinfo = 
{
	name = "Max Money admin groups",
	author = "Bacardi",
	description = "Limit player(s) max money, global and by admin group",
	version = "0.2",
	url = "https://forums.alliedmods.net/showthread.php?t=313419"
};


public void OnPluginStart()
{
	BuildPath(Path_SM, filepath, sizeof(filepath), "configs/maxmoney_admin_groups.cfg");

	if(!FileExists(filepath)) SetFailState("File '%s' not exist", filepath);

	mp_maxmoney_admin_groups = new KeyValues("Groups");

	if(!mp_maxmoney_admin_groups.ImportFromFile(filepath)) SetFailState("KeyValue fail import file '%s'", filepath);


	HookEvent("player_spawn", player_spawn);

}

public void OnConfigsExecuted()
{
	delete mp_maxmoney_admin_groups;
	mp_maxmoney_admin_groups = new KeyValues("Groups");

	if(!mp_maxmoney_admin_groups.ImportFromFile(filepath)) SetFailState("KeyValue fail import file '%s'", filepath);
}


public void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));


	if(GetClientTeam(client) <= 1 ) return; // not in team


	int maxmoneydefault = mp_maxmoney_admin_groups.GetNum("default", -1); // "default" max money value from config maxmoney_admin_groups.cfg
	int m_iAccountMax = maxmoneydefault;

	AdminId admin = GetUserAdmin(client);

	if(admin != INVALID_ADMIN_ID)
	{

		int groupcount = admin.GroupCount;
		char groupname[MAX_NAME_LENGTH];



		for(int a = 0; a < groupcount; a++)
		{
			if(admin.GetGroup(a, groupname, sizeof(groupname)) == INVALID_GROUP_ID) continue;

			m_iAccountMax = mp_maxmoney_admin_groups.GetNum(groupname, maxmoneydefault);
		}
	}

	//PrintToServer("m_iAccountMax %i", m_iAccountMax);
	if(m_iAccountMax <= -1) return; // No max. money limit



	if(GetEntProp(client, Prop_Send, "m_iAccount") > m_iAccountMax)
	{
		SetEntProp(client, Prop_Send, "m_iAccount", m_iAccountMax);
	}
}