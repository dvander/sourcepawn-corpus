public Plugin myinfo =  {

	name = "[CS:GO] Map Enforcer",
	author = "noBrain",
	description = "this set server map to one map only",
	version = "1.0.2",

};
ConVar i_bMapName = null;
ConVar s_pEnable = null;
Handle b_gLevel = INVALID_HANDLE;
public void OnPluginStart()
{
	s_pEnable = CreateConVar("sm_plugin_enable", "1");
	i_bMapName = CreateConVar("sm_map_name", "de_dust2");
	b_gLevel = FindConVar("nextlevel");
	HookEvent("cs_win_panel_match", CS_EndMatch, EventHookMode_PostNoCopy); 
}
public void OnMapStart()
{
	if(GetConVarBool(s_pEnable))
	{
		char MapName[32], EnfMap[32];
		GetCurrentMap(MapName, sizeof(MapName));
		GetConVarString(i_bMapName, EnfMap, sizeof(EnfMap));
		if(!StrEqual(MapName, EnfMap, false))
		{
			ServerCommand("map %s", EnfMap);
		}
	}
}
public CS_EndMatch(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarBool(s_pEnable))
	{
		SetConVarString(b_gLevel, "de_dust2");
	}
}
