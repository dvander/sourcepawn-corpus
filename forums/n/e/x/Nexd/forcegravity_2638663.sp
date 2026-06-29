#include <sourcemod>

#define PLUGIN_NEV	"Forcegravity"
#define PLUGIN_LERIAS	"https://forums.alliedmods.net/showthread.php?t=314196"
#define PLUGIN_AUTHOR	"Nexd"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_URL	"steelclouds.clans.hu"

Handle gh_Gravity = INVALID_HANDLE;
ConVar forcegravity;

public Plugin myinfo = 
{
	name = PLUGIN_NEV,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_LERIAS,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	forcegravity = CreateConVar("sm_forcegravity", "300");
	gh_Gravity = FindConVar("sv_gravity");

	AutoExecConfig(true, "plugin_forcegravity");
	HookConVarChange(gh_Gravity, GravityChanged);
}

public GravityChanged(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
    GetConVarInt(gh_Gravity);
    if (gh_Gravity != forcegravity) {
    	SetConVarInt(gh_Gravity, GetConVarInt(forcegravity), true);
    }
}