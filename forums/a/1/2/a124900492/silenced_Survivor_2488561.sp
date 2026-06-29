/*======================================================================================
	Plugin Info:

*	Name	:	[L4D / L4D2] Silenced Infected
*	Version	:	1.0
*	Author	:	SilverShot
*	Desc	:	Disable Survivor, special, tank and witch sounds.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=137397

========================================================================================
	Change Log:

*	1.0
	- Initial release.

======================================================================================*/

#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new const String:g_Survivor[1][] =
{
	"player/survivor/voice/"
};

new i_Survivor;
new Handle:h_Enable = INVALID_HANDLE;
new Handle:h_Survivor = INVALID_HANDLE;



/*======================================================================================
#####################			P L U G I N   I N F O				####################
======================================================================================*/
public Plugin:myinfo =
{
	name = "[L4D & L4D2] Silenced Infected",
	author = "SilverShot",
	description = "Disable Survivor, special, tank and witch sounds.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=137397"
}


/*======================================================================================
#####################			P L U G I N   S T A R T				####################
======================================================================================*/
public OnPluginStart()
{
	// Game check.
	decl String:s_GameName[128];
	GetGameFolderName(s_GameName, sizeof(s_GameName));
	if (StrContains(s_GameName, "left4dead") < 0) SetFailState("This plugin only supports Left4Dead");

	// Cvars
	h_Enable = CreateConVar("l4d_silenced_survivor_enable", "1", "0=Disables plugin, 1=Enables plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	h_Survivor = CreateConVar("l4d_silenced_Survivor", "1", "0=Enables sounds, 1=Disables Survivor infected sounds.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d_silenced_survivor");

	HookConVarChange(h_Enable, ConVarChanged_Enable);
	HookConVarChange(h_Survivor, ConVarChanged_Infected);

	i_Survivor = GetConVarInt(h_Survivor);
	HookEvents();
}


/*======================================================================================
############			C V A R   C H A N G E   A N D   H O O K S			############
======================================================================================*/
public ConVarChanged_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) > 0) {
		HookEvents();
	}else{
		UnhookEvents();
	}
}


public ConVarChanged_Infected(Handle:convar, const String:oldValue[], const String:newValue[])
{
	i_Survivor = GetConVarInt(h_Survivor);
}


HookEvents()
	AddNormalSoundHook(NormalSHook:SoundHook);

UnhookEvents()
	RemoveNormalSoundHook(NormalSHook:SoundHook);


/*======================================================================================
#####################				S O U N D   H O O K				####################
======================================================================================*/
public Action:SoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) 
{ 
	if (i_Survivor == 1) { // Survivor sounds
		for (new i = 0; i < sizeof(g_Survivor); i++) {
			if (StrContains(sample, g_Survivor[i], false) > -1) {
				volume = 0.0;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}