/**
	Version 0.1
	|23.6.2011
	- Released

	Version 0.2
	|23.6.2011
	- Update to new flashtool
	http://forums.alliedmods.net/showthread.php?t=159876
*/

#include <sourcemod>
#include <sdktools>
#include <flashtools>

new Handle:gh_range_max = INVALID_HANDLE;
new Float:gf_range_max;

new Handle:gh_range_min = INVALID_HANDLE;
new Float:gf_range_min;

new Handle:gh_fade = INVALID_HANDLE;
new Float:gf_fade;

new Handle:gh_beep = INVALID_HANDLE;
new bool:gb_beep;

public Plugin:myinfo =
{
	name = "[Css] Flashbang muffle",
	author = "Bacardi",
	description = "Remove/change flashbang default deafness",
	version = "0.2",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	gh_range_max = CreateConVar("sm_fbmuffle_range_max", "0.0", "Maximum range when flashbang start muffle environment (1000.0 is best)\n 0.0 = Use game default deaf durations", FCVAR_NONE, true, 0.0, true, 1500.0);
	gf_range_max = GetConVarFloat(gh_range_max);
	HookConVarChange(gh_range_max, ConVarChanged);

	gh_range_min = CreateConVar("sm_fbmuffle_range_min", "600.0", "Minimum range when muffle environment for 2 seconds", FCVAR_NONE, true, 0.0, true, 1500.0);
	gf_range_min = GetConVarFloat(gh_range_min);
	HookConVarChange(gh_range_min, ConVarChanged);

	gh_fade = CreateConVar("sm_fbmuffle_fadepercent", "100.0", "How much environment is muffled\n0.0 = Disable muffle/deafness", FCVAR_NONE, true, 0.0, true, 100.0);
	gf_fade = GetConVarFloat(gh_fade);
	HookConVarChange(gh_fade, ConVarChanged);

	gh_beep = CreateConVar("sm_fbmuffle_tinnitus", "0.0", "Leave flashbang tinnitus", FCVAR_NONE, true, 0.0, true, 1.0);
	gb_beep = GetConVarBool(gh_beep);
	HookConVarChange(gh_beep, ConVarChanged);

}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	gf_range_max = GetConVarFloat(gh_range_max);
	gf_range_min = GetConVarFloat(gh_range_min);
	gf_fade = GetConVarFloat(gh_fade);
	gb_beep = GetConVarBool(gh_beep);	
}

public Action:OnDeafen(client, &Float:distance)
{
	if(gf_fade != 0.0)
	{
		decl Float:holdtime;
		holdtime = 0.0;

		if(gf_range_max == 0.0 && distance <= 1000.0) // Game default deafnes dsp_preset.txt
		{
			if(distance <= 600.0)
			{
			// *** FLASHBANG MUFFLE LONG ***
				holdtime = 1.6;
			}
			else if(distance <= 800.0)
			{
			// *** FLASHBANG MUFFLE MEDIUM ***
				holdtime = 0.2;
			}
			else
			{
			// *** FLASHBANG MUFFLE SHORT ***
				holdtime = 0.1;
			}
		}
		else if(gf_range_max != 0.0 && distance < gf_range_max) // Custom settings
		{
			if(distance < gf_range_min)
			{
				holdtime = 2.0;	
			}
			else
			{
				// stupid calculation...
				// Minus Max and min range divided holdtime 2 seconds,
				// Min range minus current "distance" divided by previous calc, then plus again hold time 2 seconds
				// More close flashbang goes max range, less holdtime. Vice versa, more flashbang close min range, bigger holdtime. Of cource below 2 seconds :P
				holdtime = (gf_range_min - distance)/((gf_range_max - gf_range_min)/2.0) + 2.0;
			}
		}
		holdtime > 0.05 ? FadeClientVolume(client, gf_fade, 1.0, holdtime, 0.1):0;
	}

	return gb_beep ? Plugin_Continue:Plugin_Handled;
}