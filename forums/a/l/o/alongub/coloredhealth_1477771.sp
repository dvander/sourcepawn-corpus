#include <sourcemod>

#define PL_VERSION "1.0.1-stable"

enum LevelAttributes
{
	Float:BiggerThan,
	R,
	G,
	B,
	A
}

new Handle:g_hConfigFilePath;
new g_levelData[64][LevelAttributes];

public Plugin:myinfo =
{
    name        = "ColoredHealth",
    author      = "alongub",
    description = "Sets the color and transparency of players based on health.",
    version     = PL_VERSION,
    url         = "http://steamcommunity.com/id/alon"
};

public OnPluginStart()
{
	g_hConfigFilePath = 
		CreateConVar(
			"sm_coloredhealth_configfilepath", 
			"configs/coloredhealth.txt", 
			"Path, relative to root sourcemod directory, to colored health levels config file.", 
			_);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	AutoExecConfig();
}

public OnConfigsExecuted()
{
	new Handle:kv = CreateKeyValues("levels");	
	
	decl String:path[128];
	GetConVarString(g_hConfigFilePath, path, sizeof(path));
	
	BuildPath(Path_SM, path, sizeof(path), path);
	
	FileToKeyValues(kv, path);
		
	if (!KvGotoFirstSubKey(kv))
		return;

	decl String:sectionName[4];
	
	do
	{
		KvGetSectionName(kv, sectionName, sizeof(sectionName));
		new count = StringToInt(sectionName);
		
		new r = 255;
		new g = 255;
		new b = 255;
		new a = 255;

		g_levelData[count][BiggerThan] = KvGetFloat(kv, "biggerThan");

		KvGetColor(kv, "rgba", r, g, b, a);
		
		g_levelData[count][R] = r;
		g_levelData[count][G] = g;
		g_levelData[count][B] = b;
		g_levelData[count][A] = a;
	
	} while (KvGotoNextKey(kv));
 
	CloseHandle(kv)	
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{ 
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntityRenderMode(client, RenderMode:RENDER_GLOW);
} 

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{ 
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:health = GetEventFloat(event, "health") / GetEntProp(client, Prop_Data, "m_iMaxHealth"); 	
	
	for (new i = 0; i < sizeof(g_levelData); i++)
	{
		if (health >= g_levelData[i][BiggerThan])
		{
			SetEntityRenderColor(client, g_levelData[i][R], g_levelData[i][G], g_levelData[i][B], g_levelData[i][A]);
			return;
		}
	}
}