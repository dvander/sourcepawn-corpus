//Thanks to McFlurry for his Zed Time plugin, thats where i got my inspiration and some code...

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"
//McFlurry's SpaceSaving® Definitions
#define ATTACKER new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
#define CLIENT new client = GetClientOfUserId(GetEventInt(event, "userid"));
#define ACHECK2 if(attacker > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2)

new CURRENTKILLS[MAXPLAYERS] = 0;
new READYTOMATRIX[MAXPLAYERS] = 0;
new bool:MatrixOn = false;
new Handle:kte,Handle:ts,Handle:timer2,Handle:aa,Handle:rer,Handle:colorvar,Handle:glowon,Handle:GlowLoopHand;

public Plugin:myinfo = 
{
	name = "[L4D2] Matrix Time",
	author = "Caps Lock Fuck Yeah",
	description = "After a specified number of kills, matrix time can be enabled",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.com"
}

public OnPluginStart()
{
	kte	= CreateConVar("l4d2_mt_killsneeded", "50", "Kills needed to enable matrix time");
	CreateConVar("matrixtime_version",PLUGIN_VERSION, "Current version of Matrix Time", FCVAR_NOTIFY);
	ts	= CreateConVar("l4d2_mt_multiplier","0.35", "Matrix timescale multiplier");
	timer2	= CreateConVar("l4d2_mt_duration","17", "Matrix time duration, multiplied by resulting timescale modification");
	aa	= CreateConVar("l4d2_mt_adminannounce","0", "Should a message be announced when you activate slowdown?");
	rer	= CreateConVar("l4d2_mt_resetonend","0","Reset the players killcount at round end?");
	colorvar	= CreateConVar("l4d2_mt_glowcolor","255255","Zombie glow color");
	glowon	= CreateConVar("l4d2_mt_glowenabled","1","Should infected glow during matrix time?");
	
	RegConsoleCmd("sm_matrixkills", Callback_AnnounceKills, "Announce how many kills a player has towards matrix time");
	RegAdminCmd("sm_forcematrix", Callback_AdminMatrix, ADMFLAG_GENERIC, "Enable the slowdown effect for a specified time");
	RegAdminCmd("sm_glowzombies", AdmGlowInfected, ADMFLAG_GENERIC, "Force all zombies to glow");
	RegAdminCmd("sm_stopglow", AdmRemoveGlow, ADMFLAG_GENERIC, "Stop zombie glow");

	HookEvent("player_death", Event_Death);
	HookEvent("infected_death", Event_Kill);
	HookEvent("round_end", Event_REnd);
	LoadTranslations("common.phrases");
	AutoExecConfig(true, "l4d2_matrix_time");
}

public TriggerMatrix()
{
	MatrixOn = true;
	new String:time[32];
	GetConVarString(ts, time, sizeof(time))
	decl i_Ent, Handle:h_pack;
	i_Ent = CreateEntityByName("func_timescale");
	DispatchKeyValue(i_Ent, "desiredTimescale", time);
	DispatchKeyValue(i_Ent, "acceleration", "1.0");
	DispatchKeyValue(i_Ent, "minBlendRate", "0.1");
	DispatchKeyValue(i_Ent, "blendDeltaMultiplier", "1.0");
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "Start");
	h_pack = CreateDataPack();
	WritePackCell(h_pack, i_Ent);
	CreateTimer(GetConVarFloat(timer2), RestoreTime, h_pack);
}

public Action:Callback_AdminMatrix(client, args)
{
	new String:arg[32],String:time[32],Float:timerout;
	GetCmdArg(1, arg, sizeof(arg));
	timerout = StringToFloat(arg);
	GetConVarString(ts,time,sizeof(time));
	MatrixOn = true;
	new Float:ptime,Float:qtime,Float:cocaine;
	qtime = GetConVarFloat(ts);
	ptime = 1 / qtime;
	cocaine = ptime * timerout;
	if(GetConVarInt(aa))
	{
		PrintToChatAll("\x05 Matrix time has been activated for %f seconds",cocaine);
	}
	if(GetConVarInt(glowon))
	{
		GlowInfected();
	}
	decl i_Ent, Handle:h_pack;
	i_Ent = CreateEntityByName("func_timescale");
	DispatchKeyValue(i_Ent, "desiredTimescale", time );
	DispatchKeyValue(i_Ent, "acceleration", "1.0");
	DispatchKeyValue(i_Ent, "minBlendRate", "0.1");
	DispatchKeyValue(i_Ent, "blendDeltaMultiplier", "1.0");
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "Start");
	h_pack = CreateDataPack();
	WritePackCell(h_pack, i_Ent);
	CreateTimer(StringToFloat(arg), RestoreTime, h_pack);
}
public Action:Callback_AnnounceKills(client, args)
{
	if(args == 0)
	{
		PrintHintText(client,"You have : %d kills out of %d towards matrix time",CURRENTKILLS[client],GetConVarInt(kte));
	}
}
public Action:RestoreTime(Handle:Timer, Handle:h_pack)
{
	if(MatrixOn)
	{
		decl i_Ent;
		ResetPack(h_pack, false);
		i_Ent = ReadPackCell(h_pack);
		CloseHandle(h_pack);
		if(IsValidEdict(i_Ent))
		{
			AcceptEntityInput(i_Ent, "Stop");
			MatrixOn = false;
			if(GetConVarInt(glowon))
			{
				RemoveGlow();
			}
		}
		else
		{
			PrintToServer("[SM] i_Ent is not a valid edict!");
			MatrixOn = false;
			if(GetConVarInt(glowon))
			{
				RemoveGlow();
			}
		}
	}
	else
	{
		PrintToServer("Restore time was triggered, but MatrixOn returned false");	//Probably never gonna happen, but you never know
	}
}

public Action:Event_Kill(Handle:event, const String:name[], bool:dontBroadcast)
{
	new args;
	ATTACKER
	ACHECK2
	{
		CURRENTKILLS[attacker]++;
		if(CURRENTKILLS[attacker] == GetConVarInt(kte))
		{
			CURRENTKILLS[attacker] -= GetConVarInt(kte);
			READYTOMATRIX[attacker] = 1;
			MatrixMessage(attacker, args);
		}
	}	
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new args;
	ATTACKER
	CLIENT
	if(attacker > 0 && client > 0 && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2)
	{
		CURRENTKILLS[attacker]++;
		if(CURRENTKILLS[attacker] == GetConVarInt(kte))
		{
			CURRENTKILLS[attacker] -= GetConVarInt(kte);
			READYTOMATRIX[attacker] = 1;
			MatrixMessage(attacker, args);
		}	
	}	
}

public Action:MatrixMessage(client, args)
{
	PrintToChat(client,"\x05 Matrix time is ready. Crouch and press E to activate it");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new args;
	if((buttons & IN_DUCK) == IN_DUCK && (buttons & IN_USE) == IN_USE && !MatrixOn && !IsFakeClient(client) && READYTOMATRIX[client])
    {
		DoMatrix(client, args);
	}
	else if((buttons & IN_DUCK) == IN_DUCK && (buttons & IN_USE) == IN_USE && MatrixOn && READYTOMATRIX[client])
	{
		PrintToChat(client,"\x05 Matrix time is currently activated, Please wait");
	}
}

public Action:DoMatrix(client, args)
{
	new Float:ptime,Float:qtime,String:name[32],Float:timerout,Float:cocaine;
	qtime = GetConVarFloat(ts);
	ptime = 1 / qtime;
	timerout = GetConVarFloat(timer2);
	cocaine = ptime * timerout;
	GetClientName(client,name,sizeof(name));
	if(READYTOMATRIX[client])
	{
		PrintToChatAll( "\x05 %s has activated Matrix Time for %f seconds",name,cocaine);
		TriggerMatrix();
		if(glowon)
		{
			GlowInfected();
		}
		READYTOMATRIX[client] = 0;
	}
}

public Action:Event_REnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GetConVarInt(rer))
	{
		for (new i=1; i<=MaxClients; i++)
		{
			CURRENTKILLS[i] = 0;
		}    
	}
}

public OnClientDisconnect(client)
{
      if (IsClientInGame(client))
      {
            CURRENTKILLS[client] = 0;
      }
}

public Action:GlowInfected()
{
	GlowLoopHand = CreateTimer(0.1, GlowInfectedFunc, _, TIMER_REPEAT)
}

public Action:AdmGlowInfected(client,args)
{
	if(GetConVarInt(aa))
	{
		PrintToChatAll("\x05 Zombie glow has been enabled by an admin");
	}
	GlowInfected();
}

public Action:AdmRemoveGlow(client,args)
{
	if(GetConVarInt(aa))
	{
		PrintToChatAll("\x05 Zombie glow has been disabled");
	}
	RemoveGlow();
}

public Action:GlowInfectedFunc(Handle:timer)
{
	new c2;
	c2 = GetConVarInt(colorvar);
	new iMaxEntities = GetMaxEntities();
	for (new iEntity = MaxClients + 1; iEntity < iMaxEntities; iEntity++)
    {
        if (IsCommonInfected(iEntity))
        {
			SetEntProp(iEntity, Prop_Send, "m_iGlowType", 3, 1);
			SetEntProp(iEntity,Prop_Send,"m_glowColorOverride", c2, 1);
        }
    }
}

public Action:RemoveGlow()
{
	KillTimer(GlowLoopHand);
	new iMaxEntities = GetMaxEntities();
	for (new iEntity = MaxClients + 1; iEntity < iMaxEntities; iEntity++)
    {
        if (IsCommonInfected(iEntity))
        {
			SetEntProp(iEntity, Prop_Send, "m_iGlowType", 0, 1);
			SetEntProp(iEntity,Prop_Send,"m_glowColorOverride", 0, 1);
        }
    }
}

stock bool:IsCommonInfected(iEntity)
{
    if (iEntity && IsValidEntity(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "infected");
    }
    return false;
}  