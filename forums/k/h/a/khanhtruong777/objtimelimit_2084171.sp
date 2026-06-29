#include <sourcemod>
#include <sdktools>

#define Plugin_Version "1.0.2"

new g_iTimeLeft;

new bool:g_bObjMap;
new bool:g_bSoundPlayed;
new bool:g_bPluginEnabled;

new Handle:g_hObjTimeLeft;
new Handle:g_hObjTimeWarn;
new Handle:g_hObjTimeLimit;
new Handle:g_hPluginEnabled;

public Plugin:myinfo =
{
	name = "[NMRiH] Objective Time Limiter",
	author = "Bubka3",
	description = "Encourages users to complete objectives or get slayed.",
	version = Plugin_Version,
	url = "http://www.bubka3.com/"
};

public OnPluginStart()
{
	CreateConVar("sv_objtimelimit_version", Plugin_Version, "This is the version of the Objective Time Limiter the server is running.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);

	g_hPluginEnabled = CreateConVar("sv_objtimelimit_enabled", "1", "Turns the plugin on or off. (1 = Enabled : 0 = Disabled)", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	HookConVarChange(g_hPluginEnabled, OnSettingsChange);

	g_hObjTimeLimit = CreateConVar("sv_objtimelimit", "300", "Sets the timelimit on each objective.", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0);

	g_hObjTimeWarn = CreateConVar("sv_objtimelimit_warn", "120", "Sets the amount of time between chat warnings.", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0);

	g_bPluginEnabled = GetConVarBool(g_hPluginEnabled);

	if(g_bPluginEnabled)
	{
		HookEvent("nmrih_round_begin", Event_RoundStart, EventHookMode_Pre); //Temporary event until obj_begin is working.
		//HookEvent("objective_begin", Event_ObjectiveBegin, EventHookMode_Pre); // Begin event never fires, so we must use round start and resetup on round end.
		HookEvent("objective_complete", Event_ObjectiveComplete, EventHookMode_Pre);
		HookEvent("nmrih_reset_map", Event_RoundEnd, EventHookMode_Pre);
	}

	RegAdminCmd("sm_objtimeleft", Command_ObjTimeChng, ADMFLAG_SLAY, "sm_objtimeleft - <timeleft> [-1 will cancel timer]");
	RegAdminCmd("sm_objtime", Command_ObjTimeLeft, 0, "Simple chat trigger to display how much time is left for this objective.");
	AutoExecConfig(true, "objtimelimit");
}

public OnMapStart()
{
	new String:sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));
	if (StrContains(sMapName, "nmo_") != -1) 
		g_bObjMap = true;
	else
		g_bObjMap = false;

	//Ideally I'd like to use IsSoundPrecached but it always returns true.
	if(g_bObjMap)
	{
		PrecacheSound("survival/survival_ng/extraction01.wav", true);
		PrecacheSound("survival/survival_ng/extraction02.wav", true);
		PrecacheSound("survival/survival_ng/extraction03.wav", true);
		PrecacheSound("survival/survival_ng/extraction04.wav", true);
		PrecacheSound("survival/survival_ng/extraction05.wav", true);
		PrecacheSound("survival/survival_ng/extraction06.wav", true);
		PrecacheSound("survival/survival_ng/survivalbegin01.wav", true);
		PrecacheSound("survival/survival_ng/survivalbegin02.wav", true);
		PrecacheSound("survival/survival_ng/survivalbegin03.wav", true);
	}
}

public OnMapEnd()
{
	if(g_bObjMap)
	RemoveOldObjective();
}

public OnSettingsChange(Handle:hConvar, const String:sOldValue[], const String:sNewValue[])
{
	if (hConvar == g_hPluginEnabled) g_bPluginEnabled = bool:StringToInt(sNewValue);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bObjMap)
		SetupNewObjective();
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bObjMap)
		RemoveOldObjective();

	if(g_bSoundPlayed)
		g_bSoundPlayed = false;
}

/*public Action:Event_ObjectiveBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iTimeLeft = GetConVarInt(g_hObjTimeLimit);
	g_hObjTimeLeft = CreateTimer(1.0, Timer_TimeLeft, _, TIMER_REPEAT);
	PrintToChatAll("[SM] You have %d minutes and %d seconds to complete this objective before you are overrun!", g_iTimeLeft/60, g_iTimeLeft%60)
}*/

public Action:Event_ObjectiveComplete(Handle:event, const String:name[], bool:dontBroadcast)
{
	RemoveOldObjective();
	PrintToChatAll("[SM] Objective complete!");

	if(g_bSoundPlayed)
	{
		g_bSoundPlayed = false;
		new iSound = GetRandomInt(1,3);
		switch(iSound)
		{
			case 1:
				EmitSoundToAll("survival/survival_ng/survivalbegin01.wav");
				
			case 2:
				EmitSoundToAll("survival/survival_ng/survivalbegin02.wav");

			case 3:
				EmitSoundToAll("survival/survival_ng/survivalbegin03.wav");
		}
	}

	SetupNewObjective();
}

public Action:Command_ObjTimeChng(iClient, sArgs)
{
	if (sArgs < 1)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_objtimeleft - <timeleft> [-1 will cancel timer]");
		return Plugin_Handled;
	}

	if(!g_bObjMap)
	{
		ReplyToCommand(iClient, "[SM] This is not an objective map!");
		return Plugin_Handled;
	}

	new String:sArg1[8];
	GetCmdArg(1, sArg1, sizeof(sArg1));

	if(g_iTimeLeft == -1)
	{
		g_iTimeLeft = StringToInt(sArg1);

		if(g_hObjTimeLeft != INVALID_HANDLE)
			g_hObjTimeLeft = INVALID_HANDLE;


		g_hObjTimeLeft = CreateTimer(1.0, Timer_TimeLeft, _, TIMER_REPEAT);
	}
	else if(g_iTimeLeft <= 30)
	{
		g_bSoundPlayed = false;
		g_iTimeLeft = StringToInt(sArg1);
	}
	else
		g_iTimeLeft = StringToInt(sArg1);

	if(g_iTimeLeft != -1)
	{
		ShowActivity2(iClient, "[SM] ", "Changed objective time left to %d minutes and %d seconds.", g_iTimeLeft/60, g_iTimeLeft%60);
		LogAction(iClient, -1, "\"%L\" changed objective time left to %d minutes and %d seconds.", iClient, g_iTimeLeft/60, g_iTimeLeft%60);
		PrintTimeLeft();
	}
	else
	{
		ShowActivity2(iClient, "[SM] ", "Disabled the objective time left.");
		LogAction(iClient, -1, "\"%L\" disabled the objective time left.", iClient);
	}

	return Plugin_Handled;
}

public Action:Command_ObjTimeLeft(iClient, sArgs)
{
	if(!g_bObjMap)
	{
		ReplyToCommand(iClient, "[SM] This is not an objective map!");
		return Plugin_Handled;
	}

	if(g_iTimeLeft != -1)
	{
		if(g_iTimeLeft/60 == 0 && g_iTimeLeft != 0)
			PrintToChat(iClient, "[SM] You have %d seconds to complete this objective before the National Guard abandon you!", g_iTimeLeft%60);
		else if(g_iTimeLeft%60 == 0 && g_iTimeLeft != 0)
		{
			if(g_iTimeLeft/60 == 1)
				PrintToChat(iClient, "[SM] You have 1 minute to complete this objective before the National Guard abandon you!");
			else
				PrintToChat(iClient, "[SM] You have %d minutes to complete this objective before the National Guard abandon you!", g_iTimeLeft/60);
		}	
		else if(g_iTimeLeft != 0)
			PrintToChat(iClient, "[SM] You have %d minutes and %d seconds to complete this objective before the National Guard abandon you!", g_iTimeLeft/60, g_iTimeLeft%60)
	}
	else
		PrintToChat(iClient, "[SM] The National Guard has removed the time limit to complete this objective!");

	return Plugin_Handled;
}

public Action:Timer_TimeLeft(Handle:timer)
{
	if(g_iTimeLeft == 0)
	{
		PrintToChatAll("[SM] You have run out of time and the zombies have overrun the area!");
		KillAlivePlayers();
		return Plugin_Stop;
	}

	else if(g_iTimeLeft == -1)
	{
		PrintToChatAll("[SM] The National Guard has removed the time limit to complete this objective!");
		return Plugin_Stop;
	}

	else
	{
		g_iTimeLeft--;

		if((float(g_iTimeLeft)/GetConVarInt(g_hObjTimeWarn)) == RoundFloat(float(g_iTimeLeft)/GetConVarInt(g_hObjTimeWarn)))
		{
			PrintTimeLeft();
		}
		
		if(g_iTimeLeft == 30)
		{
			new iSound = GetRandomInt(1,3);
			switch(iSound)
			{
				case 1:
					EmitSoundToAll("survival/survival_ng/extraction01.wav");
					
				case 2:
					EmitSoundToAll("survival/survival_ng/extraction02.wav");

				case 3:
					EmitSoundToAll("survival/survival_ng/extraction03.wav");

				case 4:
					EmitSoundToAll("survival/survival_ng/extraction04.wav");
					
				case 5:
					EmitSoundToAll("survival/survival_ng/extraction05.wav");

				case 6:
					EmitSoundToAll("survival/survival_ng/extraction06.wav");
			}
			g_bSoundPlayed = true;
		}
		return Plugin_Continue;
	}
}

public Action:SetupNewObjective()
{
	g_iTimeLeft = GetConVarInt(g_hObjTimeLimit);
	g_hObjTimeLeft = CreateTimer(1.0, Timer_TimeLeft, _, TIMER_REPEAT);
	PrintTimeLeft();
}

public Action:RemoveOldObjective()
{
	if(g_hObjTimeLeft != INVALID_HANDLE)
	{
		CloseHandle(g_hObjTimeLeft);
		g_hObjTimeLeft = INVALID_HANDLE;
	}
}

public Action:PrintTimeLeft()
{
	if(g_iTimeLeft/60 == 0 && g_iTimeLeft != 0)
		PrintToChatAll("[SM] You have %d seconds to complete this objective before the National Guard abandon you!", g_iTimeLeft%60);
	else if(g_iTimeLeft%60 == 0 && g_iTimeLeft != 0)
	{
		if(g_iTimeLeft/60 == 1)
			PrintToChatAll("[SM] You have 1 minute to complete this objective before the National Guard abandon you!");
		else
			PrintToChatAll("[SM] You have %d minutes to complete this objective before the National Guard abandon you!", g_iTimeLeft/60);
	}	
	else if(g_iTimeLeft != 0)
		PrintToChatAll("[SM] You have %d minutes and %d seconds to complete this objective before the National Guard abandon you!", g_iTimeLeft/60, g_iTimeLeft%60)
}

//Thanks to the original Objective Time Limiter for these:
public Action:KillAlivePlayers()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		 if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
			ForcePlayerSuicide(i);
	}
}