#include <sourcemod>
#include <tf2>
#define REQUIRE_EXTENSIONS
#include <tf2items>
#define PLUGIN_VERSION "1"

public Plugin:myinfo =
{
    name = "[TF2Items] Steak Fix",
    author = "DarthNinja",
    description = "-",
    version = PLUGIN_VERSION,
    url = "DarthNinja.com"
};


public OnPluginStart ()
{
	CreateConVar ("sm_SteakFix_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	LoadTranslations("common.phrases");
}

public Action:TF2Items_OnGiveNamedItem(client, String:strClassName[], iItemDefinitionIndex, &Handle:hItemOverride)
{	
	if (iItemDefinitionIndex == 311)
	{
		PrintToChat(client, "\x05Sorry! You cannot use The Buffalo Steak Sandvich at this time.")
		return Plugin_Handled;
	}
	return Plugin_Continue;
}