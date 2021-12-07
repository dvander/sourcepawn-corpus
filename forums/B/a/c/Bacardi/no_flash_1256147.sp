/*
*	30.7.2010
*
*	No Flash
*	-Prevent blindness from flashbang grenade
*	cvar: sm_noflash_enable 1/0 (Default: 0)
*
*	This have duplicate from plugin "Sunglasses Version 0.1 by SAMURAI"
*	http://forums.alliedmods.net/showthread.php?t=69452
*
*	Code strips taken from:
*	TeamBets 2.5 (Mani Conversion) http://forums.alliedmods.net/showthread.php?t=85914
*	Flesh'n'Scream v1.1c http://forums.alliedmods.net/showthread.php?t=93272
*	and from other plugins what I can't remember
*
*/

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
	name = "No Flash",
	author = "Bacardi - Original by SAMURAI",
	description = "Prevent blindness from flashbang grenade",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showpost.php?p=1256147&postcount=8"
};



new enabled = false;
new hooked = false;

new g_iFlashAlpha = -1;
new Handle:cvarEnable = INVALID_HANDLE;






public OnPluginStart()
{
	//Offset
	g_iFlashAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	if (g_iFlashAlpha == -1)
	{
		hooked = false;
		PrintToServer("[NO FLash] - Unable to start, cannot find necessary send prop offsets.");
		return;
	}




	//Cvar
	cvarEnable = CreateConVar("sm_noflash_enable", "0", "Disable = 0, Enable = 1 plugin (Default: 0)");
	enabled = false;
	HookConVarChange(cvarEnable, ConVarChange_cvarEnable);

	//Event
	//HookEvent("player_blind",Event_Flashed);
	//hooked = true;
}




public Action:Event_Flashed(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));

    if (g_iFlashAlpha != -1)
    {
		SetEntDataFloat(client,g_iFlashAlpha,0.5);
    }
}




public ConVarChange_cvarEnable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iNewVal = StringToInt(newValue);

	if (enabled && iNewVal != 1)
	{
		if (hooked)
		{
			UnhookEvent("player_blind",Event_Flashed);

			hooked = false;
		}

		enabled = false;
	}
	else if (!enabled && iNewVal == 1)
	{
		if (!hooked)
		{
			HookEvent("player_blind",Event_Flashed);

			hooked = true;
		}

		enabled = true;
	}
}