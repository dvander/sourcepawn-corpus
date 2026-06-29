 #pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2"

new Handle:Game_Mode_name;
new String:GMName[254];

//variables needed by includes here

public Plugin:myinfo= 
{
	name="Game Name Changer",
	author="FrozDark",
	description="This plugin will change your game name.",
	version=PLUGIN_VERSION,
	url="http://mega-friends.ucoz.kz/"
};

public OnPluginStart()
{
	CreateConVar("gnc_version", PLUGIN_VERSION, "Version of plugin", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	Game_Mode_name = CreateConVar("gnc_name","Counter-Strike:Source","Game Mode Name",FCVAR_PLUGIN);
	
	AutoExecConfig(true, "game_name_changer");
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	GetConVarString(Game_Mode_name, GMName, sizeof(GMName));
	Format(gameDesc,64,"%s", GMName);
	return Plugin_Changed;
}
