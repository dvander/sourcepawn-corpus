#pragma semicolon 1

#include <sourcemod>
#include <console>
#include <events>
#include <entity>
#include <string>
#include <clients>

#define TEXTMSG_PRINTNOTIFY		1
#define TEXTMSG_PRINTCONSOLE	2
#define TEXTMSG_PRINTTALK		3
#define TEXTMSG_PRINTCENTER		4


public Plugin:myinfo = 
{
	name = "C4 Countdown Timer",
	author = "sslice",
	description = "Small plugin that gives a countdown for the C4 explosion in Counter-Strike Source. Timer length is specified by sm_c4timer",
	version = "1.0.0.0",
	url = "http://www.gameconnect.info/"
};


new Handle:sm_c4timer;
new Handle:mp_c4timer;

new g_explosionTime;
new g_lastCountdown;

// so we can unhook events when sm_c4timer is zero (disabled)
new bool:g_isHooked;

// Stock written by jopmako
stock SendMsg_TextMsg(client, type, const String:szMsg[], any:...)
{
   if (strlen(szMsg) > 191){
      LogError("Disallow string len(%d) > 191", strlen(szMsg));
      return;
   }

   decl String:buffer[192];
   VFormat(buffer, sizeof(buffer), szMsg, 4);

   new Handle:hBf;
   if (!client)
      hBf = StartMessageAll("TextMsg");
   else hBf = StartMessageOne("TextMsg", client);

   if (hBf != INVALID_HANDLE)
   {
      BfWriteByte(hBf, type);
      BfWriteString(hBf, buffer);
      EndMessage();
   }
}


public OnPluginStart()
{
	mp_c4timer = FindConVar("mp_c4timer");
	if (mp_c4timer == INVALID_HANDLE)
	{
		g_isHooked = false;
		PrintToServer("* FATAL ERROR: Failed to find ConVar 'mp_c4timer'");
	}
	else
	{
		g_isHooked = true;
		HookEvent("bomb_planted", OnBombPlanted, EventHookMode_Post);
		HookEvent("bomb_beep", OnBombBeep, EventHookMode_Post);
	
		sm_c4timer = CreateConVar("sm_c4timer", "5", "Time that a countdown is given for the bomb; disable with value of 0", FCVAR_PLUGIN, true, 0.0, true, 30.0);
		HookConVarChange(sm_c4timer, OnC4TimerChange);
	}
}

public OnPluginEnd()
{
	if (g_isHooked == true)
	{
		UnhookEvent("bomb_planted", OnBombPlanted, EventHookMode_Post);
		UnhookEvent("bomb_beep", OnBombBeep, EventHookMode_Post);
	}
	
	UnhookConVarChange(sm_c4timer, OnC4TimerChange);
}

// This way we can remove the event hooks when sm_c4timer is 0 (disabled)
public OnC4TimerChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new timer = StringToInt(newValue);
	if (timer == 0)
	{
		if (g_isHooked == true)
		{
			g_isHooked = false;
			
			UnhookEvent("bomb_planted", OnBombPlanted, EventHookMode_Post);
			UnhookEvent("bomb_beep", OnBombBeep, EventHookMode_Post);
		}
	}
	else if (g_isHooked == false)
	{
		g_isHooked = true;
		
		HookEvent("bomb_planted", OnBombPlanted, EventHookMode_Post);
		HookEvent("bomb_beep", OnBombBeep, EventHookMode_Post);
	}
}


public OnBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_explosionTime = GetTime() + GetConVarInt(mp_c4timer);
}

public OnBombBeep(Handle:event, const String:name[], bool:dontBroadcast)
{
	new now = GetTime();
	new timer = GetConVarInt(sm_c4timer);
	new diff = g_explosionTime - now;
	if (diff <= timer && g_lastCountdown != now && diff >= 0)
	{
		SendMsg_TextMsg(0, TEXTMSG_PRINTTALK, "\x03-=[ \x01%d \x04Seconds \x03]=-", diff);
		g_lastCountdown = GetTime();
	}
}
