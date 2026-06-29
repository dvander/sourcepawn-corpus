/******************************************************
*				L4D2: Void Darkness v1.1
*					Author: ztar
* 			Web: http://ztar.blog7.fc2.com/
*******************************************************/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1"

#define SURVIVOR 2
#define SOUND_CALL		"ambient/random_amb_sounds/randbridgegroan_03.wav"
#define MESSAGE_ALERT	"You are cursed @20sec!!\nDon't kill Witch..."

new Handle:sm_witch_darkness_enable		= INVALID_HANDLE;
new Handle:sm_witch_darkness_duration	= INVALID_HANDLE;
new Handle:sm_witch_darkness_horde		= INVALID_HANDLE;
new Handle:sm_witch_darkness_shake		= INVALID_HANDLE;
new Handle:sm_witch_darkness_onlykiller	= INVALID_HANDLE;

/* Grobal */
new visibility = 0;
new killer;

public Plugin:myinfo = 
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
public OnPluginStart()
{
	sm_witch_darkness_enable	 = CreateConVar("sm_witch_darkness_enable","1","Blind and horde when Witch dies.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_witch_darkness_duration	 = CreateConVar("sm_witch_darkness_duration","20.0","Durtion of blind effect.", FCVAR_NOTIFY);
	sm_witch_darkness_horde		 = CreateConVar("sm_witch_darkness_horde","1","Horde when Witch is killed.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_witch_darkness_shake		 = CreateConVar("sm_witch_darkness_shake","1","Enable shake effect.(0:OFF 1:ON)", FCVAR_NOTIFY);
	sm_witch_darkness_onlykiller = CreateConVar("sm_witch_darkness_onlykiller","0","Blind effect affected to only killer.(0:OFF 1:ON)", FCVAR_NOTIFY);
	
	HookEvent("witch_killed", Event_Witch_Death);
}

/******************************************************
*	Event when Witch is killed
*******************************************************/
public Action:Event_Witch_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarInt(sm_witch_darkness_enable))
		return;
	
	killer = GetClientOfUserId(GetEventInt(event, "userid"));
	new flager = GetAnyClient();
	
	if(flager != -1 && GetConVarInt(sm_witch_darkness_horde))
	{
		new flag = GetCommandFlags("director_force_panic_event");
		SetCommandFlags("director_force_panic_event", flag & ~FCVAR_CHEAT);
		FakeClientCommand(flager, "director_force_panic_event");
	}
	
	if(GetConVarInt(sm_witch_darkness_onlykiller))
	{
		if(killer > 0 && killer <= GetMaxClients())
		{
			CreateTimer(0.1, FadeoutTimer, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_witch_darkness_duration), Fadein);
			EmitSoundToClient(killer, SOUND_CALL);
			ScreenFade(killer, 200, 0, 0, 200, 100, 1);
			if(GetConVarInt(sm_witch_darkness_shake))
				ScreenShake(killer);
			PrintHintText(killer, MESSAGE_ALERT);
		}
	}
	else
	{
		CreateTimer(0.1, FadeoutTimer, _, TIMER_REPEAT);
		CreateTimer(GetConVarFloat(sm_witch_darkness_duration), Fadein);
		
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(!IsClientInGame(i) || GetClientTeam(i) != SURVIVOR)
				continue;
			EmitSoundToClient(i, SOUND_CALL);
			ScreenFade(i, 200, 0, 0, 200, 100, 1);
			if(GetConVarInt(sm_witch_darkness_shake))
				ScreenShake(i);
		}
		PrintHintTextToAll(MESSAGE_ALERT);
	}
}

/******************************************************
*	Timer functions
*******************************************************/
public Action:Fadein(Handle:Timer)
{
	CreateTimer(0.1, FadeinTimer, _, TIMER_REPEAT);
}

public Action:FadeoutTimer(Handle:Timer)
{
	visibility += 8;
	if(visibility > 240)  visibility = 240;
	
	if(GetConVarInt(sm_witch_darkness_onlykiller))
	{
		ScreenFade(killer, 0, 0, 0, visibility, 0, 0);
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) &&
				!IsFakeClient(i) &&
				GetClientTeam(i) == SURVIVOR)
			{
				ScreenFade(i, 0, 0, 0, visibility, 0, 0);
			}
		}
	}
	if(visibility >= 240)
	{
		FakeRealism(true);
		KillTimer(Timer);
	}
}

public Action:FadeinTimer(Handle:Timer)
{
	visibility -= 8;
	if(visibility < 0)  visibility = 0;
	
	if(GetConVarInt(sm_witch_darkness_onlykiller))
	{
		ScreenFade(killer, 0, 0, 0, visibility, 0, 1);
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) &&
				!IsFakeClient(i) &&
				GetClientTeam(i) == SURVIVOR)
			{
				ScreenFade(i, 0, 0, 0, visibility, 0, 1);
			}
		}
	}
	if(visibility <= 0)
	{
		FakeRealism(false);
		KillTimer(Timer);
	}
}

/******************************************************
*	Gimmick functions
*******************************************************/
public FakeRealism(bool:mode)
{
	if(mode == true)
	{
		SetConVarInt(FindConVar("sv_disable_glow_faritems"), 1, true, true);
		SetConVarInt(FindConVar("sv_disable_glow_survivors"), 1, true, true);
	}
	else
	{
		SetConVarInt(FindConVar("sv_disable_glow_faritems"), 0, true, true);
		SetConVarInt(FindConVar("sv_disable_glow_survivors"), 0, true, true);
	}
}

public ScreenFade(target, red, green, blue, alpha, duration, type)
{
	new Handle:msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
		BfWriteShort(msg, (0x0002 | 0x0008));
	else
		BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

public ScreenShake(target)
{
	new Handle:msg;
	msg = StartMessageOne("Shake", target);
	
	BfWriteByte(msg, 0);
 	BfWriteFloat(msg, 20.0);
 	BfWriteFloat(msg, 100.0);
 	BfWriteFloat(msg, 3.0);
	EndMessage();
}

GetAnyClient()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && IsClientInGame(i))
			return i;
	}
	return -1;
}

/******************************************************
*	EOF
*******************************************************/
