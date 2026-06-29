#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#define MAX_ENTITIES 4096

new bool:NotGround[MAXPLAYERS + 1] = false;

ConVar EllisAdditionalScream;

#define PLUGIN_NAME "[L4D2] Fall Scream Fix"
#define PLUGIN_AUTHOR "Edison1318"
#define PLUGIN_DESC "Restore Zoey, Louis and Francis survivors scream fix while falling."
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL ""

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public OnPluginStart()
{
	EllisAdditionalScream = CreateConVar("l4d2_ellis_extra_scream", "1" , "Enables Ellis extra scream while falling", _, true, 0.0, true, 1.0);
	
	AddNormalSoundHook(SoundHook);
	AutoExecConfig(true, "l4d2_fall_scream_fix");
}

public OnMapStart()
{
	PrefetchSound("player/survivor/voice/mechanic/ledgehangfall02.wav");
	PrecacheSound("player/survivor/voice/mechanic/ledgehangfall02.wav", true);
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (entity <= 0 || entity > MAX_ENTITIES)
	{
		return Plugin_Continue;
	}
	
	if (EllisAdditionalScream.IntValue)
	{
		if (entity > 0 && entity <= MaxClients && StrContains(sound, "mechanic/fall0", false) > -1)
		{
			if (NotGround[entity])
			{
				new chance = GetRandomInt(1, 5);
				if (chance == 5)
				{
					Format(sound, sizeof(sound), "player/survivor/voice/mechanic/ledgehangfall02.wav");
				}
				return Plugin_Changed;
			}
		}
	}
	else if (entity > 0 && entity <= MaxClients && StrContains(sound, "teengirl/fall04", false) > -1)
	{
		if (NotGround[entity])
		{
			new random = GetRandomInt(0, 2);
			switch(random)
			{
				case 0:Format(sound, sizeof(sound), "player/survivor/voice/teengirl/fall01.wav");
				case 1:Format(sound, sizeof(sound), "player/survivor/voice/teengirl/fall02.wav");
				case 2:Format(sound, sizeof(sound), "player/survivor/voice/teengirl/fall03.wav");
			}
			return Plugin_Changed;
		}
	}
	else if (entity > 0 && entity <= MaxClients && StrContains(sound, "manager/fall04", false) > -1)
	{
		if (NotGround[entity])
		{
			new random = GetRandomInt(0, 2);
			switch(random)
			{
				case 0:Format(sound, sizeof(sound), "player/survivor/voice/manager/fall01.wav");
				case 1:Format(sound, sizeof(sound), "player/survivor/voice/manager/fall02.wav");
				case 2:Format(sound, sizeof(sound), "player/survivor/voice/manager/fall03.wav");
			}
			return Plugin_Changed;
		}
	}
	else if (entity > 0 && entity <= MaxClients && StrContains(sound, "biker/fall04", false) > -1)
	{
		if (NotGround[entity])
		{
			new random = GetRandomInt(0, 2);
			switch(random)
			{
				case 0:Format(sound, sizeof(sound), "player/survivor/voice/biker/fall01.wav");
				case 1:Format(sound, sizeof(sound), "player/survivor/voice/biker/fall02.wav");
				case 2:Format(sound, sizeof(sound), "player/survivor/voice/biker/fall03.wav");
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(int client, int &buttons)
{
	if (IsPlayerAlive(client))
	{
		if (!(GetEntityFlags(client) & FL_ONGROUND))
		{
			NotGround[client] = true;
			return Plugin_Continue;
		}
	}
	
	NotGround[client] = false;
	return Plugin_Continue;
}