#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

float gF_FullPress = 450.0;

public Plugin myinfo =
{
	name = "Analog Keyboard Fix",
	author = "shavit",
	description = "Patches analog keyboards by rounding wish velocities.",
	version = PLUGIN_VERSION,
	url = "https://github.com/shavitush"
};

public void OnPluginStart()
{
	CreateConVar("analogboard_version", PLUGIN_VERSION, "Plugin version.", (FCVAR_NOTIFY | FCVAR_DONTRECORD));

	// cl_forwardspeed's and cl_sidespeed's default setting.
	// might be different with other games
	if(GetEngineVersion() == Engine_CSS)
	{
		gF_FullPress = 400.0;
	}

	else
	{
		gF_FullPress = 450.0;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsPlayerAlive(client) || IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	if((buttons & IN_BACK) == 0 && (buttons & IN_FORWARD) > 0)
	{
		vel[0] = gF_FullPress;
	}

	else if((buttons & IN_FORWARD) == 0 && (buttons & IN_BACK) > 0)
	{
		vel[0] = -gF_FullPress;
	}

	if((buttons & IN_MOVERIGHT) == 0 && (buttons & IN_MOVELEFT) > 0)
	{
		vel[1] = -gF_FullPress;
	}

	else if((buttons & IN_MOVELEFT) == 0 && (buttons & IN_MOVERIGHT) > 0)
	{
		vel[1] = gF_FullPress;
	}

	vel[0] = RoundToNearestPress(vel[0]);

	if(vel[0] == gF_FullPress)
	{
		buttons |= IN_FORWARD;
	}

	else if(vel[0] == -gF_FullPress)
	{
		buttons |= IN_BACK;
	}

	vel[1] = RoundToNearestPress(vel[1]);

	if(vel[1] == -gF_FullPress)
	{
		buttons |= IN_MOVELEFT;
	}

	else if(vel[1] == gF_FullPress)
	{
		buttons |= IN_MOVERIGHT;
	}

	return Plugin_Changed;
}

float RoundToNearestPress(float wishspeed)
{
	if(wishspeed == 0.0 || FloatAbs(wishspeed) == gF_FullPress)
	{
		return wishspeed;
	}

	float fNearest = 0.0;

	float fPossibleWishSpeeds[9];
	fPossibleWishSpeeds[0] = -(gF_FullPress);
	fPossibleWishSpeeds[1] = -(gF_FullPress * 0.75);
	fPossibleWishSpeeds[2] = -(gF_FullPress * 0.50);
	fPossibleWishSpeeds[3] = -(gF_FullPress * 0.25);
	fPossibleWishSpeeds[4] = 0.0;
	fPossibleWishSpeeds[5] = gF_FullPress * 0.25;
	fPossibleWishSpeeds[6] = gF_FullPress * 0.50;
	fPossibleWishSpeeds[7] = gF_FullPress * 0.75;
	fPossibleWishSpeeds[8] = gF_FullPress;

	for(int i = 0; i < sizeof(fPossibleWishSpeeds); i++)
	{
		if(FloatAbs(wishspeed - fPossibleWishSpeeds[i]) < FloatAbs(wishspeed - fNearest))
		{
			fNearest = fPossibleWishSpeeds[i];
		}
	}

	return fNearest;
}
