#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define SOUND_HEART "player/heartbeatloop.wav"
#define SOUND_INCAP "music/terror/puddleofyou.wav"


public Plugin myinfo =
{
	name = "[L4D2] Health Giver",
	author = "Tonton Zen",
	description = "Give specific amount of health to players",
	version = "2.1",
	url = "N/A"
};


public void OnPluginStart()
{
    new String:GameFolder[50];
    GetGameFolderName(GameFolder, sizeof(GameFolder));
    if(!StrEqual(GameFolder, "left4dead2", false))
        SetFailState("Health Giver supports Left 4 Dead 2 only");

    RegAdminCmd("sm_health", Command_Health, ADMFLAG_KICK, "sm_health <#userid|name> [+]<hp> [P]");

}

public void OnMapStart()
{
    PrecacheSound(SOUND_HEART, true);
    PrecacheSound(SOUND_INCAP, true);
}

// Validate that the HP parameter is numeric with optional "+" prefix
public bool ValidateHp(char [] hps)
{
	int i, ilen;

	ilen = strlen(hps);

	for (i = 1; i < ilen; i++)
	{
		if ( IsCharNumeric(hps[i]) == false)
			return false;
	}

	if ( IsCharNumeric(hps[0]) == true || hps[0] == '+')
		return true;

	return false;
}

// Return actual full health of a survivor, results are > zero
public GetSurvivorPermanentHealth(client)
{
	int hp = GetEntProp(client, Prop_Send, "m_iHealth");
	return hp < 0 ? 0 : hp;
}

// Return temporary health of a survivor, results are > zero
public GetSurvivorTempHealth(client)
{
	new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	return temphp > 0 ? temphp : 0;
}

// Set a survivor's temp health
public SetSurvivorTempHealth(client, hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	float newOverheal = hp * 1.0;
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal);
}

// Set survivor permanent health
public SetSurvivorPermanentHealth(client, hp)
{

	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", "give", "health");
	SetCommandFlags("give", flags);
	SetUserFlagBits(client, userFlags);

	SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
	SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
	UnloopAnnoyingMusic(client, SOUND_HEART);
	UnloopAnnoyingMusic(client, SOUND_INCAP);
	SetEntProp(client, Prop_Send, "m_iHealth", hp);
}

void UnloopAnnoyingMusic(int client, const char[] sGivenSound)
{
	StopSound(client, SNDCHAN_REPLACE, sGivenSound);
	StopSound(client, SNDCHAN_AUTO, sGivenSound);
	StopSound(client, SNDCHAN_BODY, sGivenSound);
	StopSound(client, SNDCHAN_STREAM, sGivenSound);
	StopSound(client, SNDCHAN_STATIC, sGivenSound);
	StopSound(client, SNDCHAN_USER_BASE, sGivenSound);
}

public Action Command_Health(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_health <#userid|name> [+]<hp>|RND [P]\n+ to add (else replace), RND = random between 60-90.\nP for permanent health.");
		return Plugin_Handled;
	}

	bool bPermHP;

	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	char hps[65];
	GetCmdArg(2, hps, sizeof(hps));
	
	char argperm[10];
	
	if (args > 2)
	{
		GetCmdArg(3, argperm, sizeof(argperm));
		bPermHP = (strcmp(argperm, "p", false) == 0) ? true : false;
	}
	else
	{
		bPermHP = false;
	}
	
	if (strcmp(hps, "rnd", false) == 0)
	{
		float hpr;

		hpr = GetURandomFloat();
		hpr = hpr * 30 + 60;
		Format(hps, sizeof(hps), "%.0f", hpr);
	}

	if (ValidateHp(hps) == false)
	{
		ReplyToCommand(client, "Health point parameter must be numeric or RND!");
		return Plugin_Handled;
	}

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS + 1], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int hpi;

	hpi = StringToInt(hps);
	if (hpi > 100) hpi = 100;
	if (hpi < 1) hpi = 1;

	int iCurrentPermHealth, iCurrentTempHealth, iNewHealth;

	for (new i = 0; i < target_count; i++)
	{
	        if(!IsClientConnected(target_list[i]))
        	    continue;
	        if(!IsClientInGame(target_list[i]))
        	    continue;
	        if(GetClientTeam(target_list[i]) != 2)
        	    continue;

		iCurrentPermHealth = GetSurvivorPermanentHealth(target_list[i]);
		iCurrentTempHealth = GetSurvivorTempHealth(target_list[i]);

		if (hps[0] == '+')
		{
			iNewHealth = iCurrentPermHealth + iCurrentTempHealth + hpi;
		}
		else
		{
			iNewHealth = hpi;
		}
	
		if ( iNewHealth > 100 ) iNewHealth = 100;
	
		if (bPermHP)
		{
			SetSurvivorPermanentHealth(target_list[i], iNewHealth);
			SetSurvivorTempHealth(target_list[i], 0);			
		}
		else
		{
			SetSurvivorTempHealth(target_list[i], iNewHealth - iCurrentPermHealth);
		}
	}

	return Plugin_Handled;
}
