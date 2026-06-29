/*

	Version history
	---------------
	1.0		- Initial release

*/

#include <sourcemod>
#include <sdktools>
#include <dukehacks>

#define PLUGIN_NAME					"i3D-NoBlock"
#define PLUGIN_AUTHOR				"Tony G."
#define PLUGIN_DESCRIPTION			"Manipulates players and grenades so they can't block each other"
#define PLUGIN_VERSION				"1.0"
#define PLUGIN_URL					"http://www.i3d.net/"

new g_CollisionOffset;

public Plugin:myinfo = {name = PLUGIN_NAME, author = PLUGIN_AUTHOR, description = PLUGIN_DESCRIPTION, version = PLUGIN_VERSION, url = PLUGIN_URL};

public OnPluginStart()
{

	g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
    
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	new user_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(user_id);
	
	SetEntData(client, g_CollisionOffset, 2, 1, true);

}

public ResultType:dhOnEntityCreated(edict)
{
	
	new String:classname[21];
	GetEdictClassname(edict, classname, sizeof(classname)); 

	if (StrEqual(classname, "hegrenade_projectile"))
	{
		SetEntData(edict, g_CollisionOffset, 2, 1, true);
	}
	
}