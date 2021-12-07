/******************************************************
*				L4D2: Void Darkness v1.1
*					Author: ztar
* 			Web: http://ztar.blog7.fc2.com/
*******************************************************/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

#define CVAR_FLAGS FCVAR_NOTIFY

#define SOUND_CALL		"ambient/random_amb_sounds/randbridgegroan_03.wav"
#define MESSAGE_ALERT	"You are cursed @20sec!!\nDon't kill Witch..."

ConVar sm_witch_darkness_enable, sm_witch_darkness_duration, sm_witch_darkness_horde, sm_witch_darkness_shake, sm_witch_darkness_onlykiller;
ConVar disable_glow_faritems, disable_glow_survivors; 
/* Grobal */
int visibility = 0, killer;

public Plugin myinfo = 
{
	name = "[L4D2] Void Darkness",
	author = "ztar",
	description = "When Witch is killed, It will darken and panic event occur.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

/******************************************************
*	When plugin started
*******************************************************/
public void OnPluginStart()
{
	sm_witch_darkness_enable	 = CreateConVar("sm_witch_darkness_enable", "1", "Blind and horde when Witch dies.(0:OFF 1:ON)", CVAR_FLAGS);
	sm_witch_darkness_duration	 = CreateConVar("sm_witch_darkness_duration", "2.0", "Durtion of blind effect.", CVAR_FLAGS);
	sm_witch_darkness_horde		 = CreateConVar("sm_witch_darkness_horde", "1", "Horde when Witch is killed.(0:OFF 1:ON)", CVAR_FLAGS);
	sm_witch_darkness_shake		 = CreateConVar("sm_witch_darkness_shake", "1", "Enable shake effect.(0:OFF 1:ON)", CVAR_FLAGS);
	sm_witch_darkness_onlykiller = CreateConVar("sm_witch_darkness_onlykiller", "1", "Blind effect affected to only killer.(0:OFF 1:ON)", CVAR_FLAGS);

	disable_glow_faritems = FindConVar("sv_disable_glow_faritems");
	disable_glow_survivors = FindConVar("sv_disable_glow_survivors");
		
	HookEvent("witch_killed", Event_Witch_Death);
}

/******************************************************
*	Event when Witch is killed
*******************************************************/
public Action Event_Witch_Death(Event event, const char[] name, bool dontBroadcast)
{
	if(!sm_witch_darkness_enable.BoolValue) return;

	killer = GetClientOfUserId(event.GetInt("userid"));
	int flager = GetAnyClient();

	if(flager != -1 && sm_witch_darkness_horde.BoolValue)
	{
		int flag = GetCommandFlags("director_force_panic_event");
		SetCommandFlags("director_force_panic_event", flag & ~FCVAR_CHEAT);
		FakeClientCommand(flager, "director_force_panic_event");
		SetCommandFlags("director_force_panic_event", flag | FCVAR_CHEAT);
	}

	if(sm_witch_darkness_onlykiller.BoolValue)
	{
		if(killer > 0 && killer <= MaxClients)
		{
			CreateTimer(0.1, FadeoutTimer, _, TIMER_REPEAT);
			CreateTimer(sm_witch_darkness_duration.FloatValue, Fadein);
			EmitSoundToClient(killer, SOUND_CALL);
			ScreenFade(killer, 200, 0, 0, 200, 100, 1);
			if(sm_witch_darkness_shake.BoolValue) ScreenShake(killer);
			PrintHintText(killer, MESSAGE_ALERT);
		}
	}
	else
	{
		CreateTimer(0.1, FadeoutTimer, _, TIMER_REPEAT);
		CreateTimer(sm_witch_darkness_duration.FloatValue, Fadein);

		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || GetClientTeam(i) != 2)
				continue;

			EmitSoundToClient(i, SOUND_CALL);
			ScreenFade(i, 200, 0, 0, 200, 100, 1);
			if(sm_witch_darkness_shake.BoolValue) ScreenShake(i);
		}
		PrintHintTextToAll(MESSAGE_ALERT);
	}
}

/******************************************************
*	Timer functions
*******************************************************/
public Action Fadein(Handle Timer)
{
	CreateTimer(0.1, FadeinTimer, _, TIMER_REPEAT);
}

public Action FadeoutTimer(Handle Timer)
{
	visibility += 8;
	if(visibility > 240)  visibility = 240;

	if(sm_witch_darkness_onlykiller.BoolValue)
	{
		ScreenFade(killer, 0, 0, 0, visibility, 0, 0);
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidSurvivor(i))
			{
				ScreenFade(i, 0, 0, 0, visibility, 0, 0);
			}
		}
	}

	if(visibility >= 240)
	{
		FakeRealism(true);
		Timer = null;
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}

public Action FadeinTimer(Handle Timer)
{
	visibility -= 8;
	if(visibility < 0)  visibility = 0;

	if(sm_witch_darkness_onlykiller.BoolValue)
	{
		ScreenFade(killer, 0, 0, 0, visibility, 0, 1);
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidSurvivor(i))
			{
				ScreenFade(i, 0, 0, 0, visibility, 0, 1);
			}
		}
	}

	if(visibility <= 0)
	{
		FakeRealism(false);
		Timer = null;
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}

/******************************************************
*	Gimmick functions
*******************************************************/
public void FakeRealism(bool mode)
{
	if(mode == true)
	{
		disable_glow_faritems.SetInt(1);
		disable_glow_survivors.SetInt(1);
	}
	else
	{
		disable_glow_faritems.SetInt(0);
		disable_glow_survivors.SetInt(0);
	}
}

public void ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	if(target > 0)
	{
		Handle msg = StartMessageOne("Fade", target);
		BfWriteShort(msg, 500);
		BfWriteShort(msg, duration);
		if (type == 0) BfWriteShort(msg, (0x0002 | 0x0008));
		else BfWriteShort(msg, (0x0001 | 0x0010));
		BfWriteByte(msg, red);
		BfWriteByte(msg, green);
		BfWriteByte(msg, blue);
		BfWriteByte(msg, alpha);
		EndMessage();
	}
}

public void ScreenShake(int target)
{
	if(target > 0)
	{
		Handle msg = StartMessageOne("Shake", target);
		BfWriteByte(msg, 0);
		BfWriteFloat(msg, 20.0);
		BfWriteFloat(msg, 100.0);
		BfWriteFloat(msg, 3.0);
		EndMessage();
	}
}

stock int GetAnyClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && IsClientInGame(i))
		{
			return i;
		}
	}
	return -1;
}

stock bool IsValidSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2;
}

/******************************************************
*	EOF
*******************************************************/