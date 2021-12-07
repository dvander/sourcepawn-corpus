
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>


#define PLUGIN_VERSION "1.2.0"

public Plugin:myinfo = {
	name = "Concussion Grenade",
	author = "CrancK",
	description = "gives specified classes the concussion grenade from other tf's",
	version = PLUGIN_VERSION,
	url = ""
};

#define DMG_GENERIC			0
#define DMG_CRUSH			(1 << 0)
#define DMG_BULLET			(1 << 1)
#define DMG_SLASH			(1 << 2)
#define DMG_BURN			(1 << 3)
#define DMG_VEHICLE			(1 << 4)
#define DMG_FALL			(1 << 5)
#define DMG_BLAST			(1 << 6)
#define DMG_CLUB			(1 << 7)
#define DMG_SHOCK			(1 << 8)
#define DMG_SONIC			(1 << 9)
#define DMG_ENERGYBEAM			(1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE	(1 << 11)
#define DMG_NEVERGIB			(1 << 12)
#define DMG_ALWAYSGIB			(1 << 13)
#define DMG_DROWN			(1 << 14)
#define DMG_TIMEBASED			(DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE			(1 << 15)
#define DMG_NERVEGAS			(1 << 16)
#define DMG_POISON			(1 << 17)
#define DMG_RADIATION			(1 << 18)
#define DMG_DROWNRECOVER		(1 << 19)
#define DMG_ACID			(1 << 20)
#define DMG_SLOWBURN			(1 << 21)
#define DMG_REMOVENORAGDOLL		(1 << 22)
#define DMG_PHYSGUN			(1 << 23)
#define DMG_PLASMA			(1 << 24)
#define DMG_AIRBOAT			(1 << 25)
#define DMG_DISSOLVE			(1 << 26)
#define DMG_BLAST_SURFACE		(1 << 27)
#define DMG_DIRECT			(1 << 28)
#define DMG_BUCKSHOT			(1 << 29)

#define SND_NADE_CONC "weapons/explode5.wav"
#define SND_THROWNADE "weapons/grenade_throw.wav"
#define SND_NADE_CONC_TIMER "weapons/det_pack_timer.wav"
//#define MDL_CONC "models/weapons/nades/duke1/w_grenade_conc.mdl"
#define MDL_CONC "models/conc/w_grenade_conc.mdl"

new Handle:cvConcEnabled = INVALID_HANDLE;
new Handle:cvConcClass = INVALID_HANDLE;
new Handle:cvConcRadius = INVALID_HANDLE;
new Handle:cvConcMax = INVALID_HANDLE;
new Handle:cvConcDelay = INVALID_HANDLE;
new Handle:cvConcTimer = INVALID_HANDLE;
new Handle:cvConcPhysics = INVALID_HANDLE;
new Handle:cvConcDifGrav = INVALID_HANDLE;
new Handle:cvConcTrail = INVALID_HANDLE;
new Handle:cvConcSoundMode = INVALID_HANDLE;
new Handle:cvConcThrowSpeed = INVALID_HANDLE;
new Handle:cvConcThrowAngle = INVALID_HANDLE;
new Handle:cvConcIgnore = INVALID_HANDLE;
new Handle:cvConcNoOtherPush = INVALID_HANDLE;
new Handle:cvConcRings = INVALID_HANDLE;
new Handle:cvConcBaseHeight = INVALID_HANDLE;
new Handle:cvConcBaseSpeed = INVALID_HANDLE;
new Handle:cvConcIcon = INVALID_HANDLE;
new Handle:cvConcHHHeight = INVALID_HANDLE;
new Handle:cvConcHHDisDecrease = INVALID_HANDLE;
new Handle:cvBlastDistanceMin = INVALID_HANDLE;
new Handle:cvConcBounce = INVALID_HANDLE;
new Handle:cvConcWaitPeriod = INVALID_HANDLE;
new gRingModel;	
new bool:holding[MAXPLAYERS][50];
new nadesUsed[MAXPLAYERS];
new concToUse[MAXPLAYERS];
new nadeId[MAXPLAYERS][50];
new nadeTime[MAXPLAYERS][50];
new bool:nadeDelay[MAXPLAYERS];
new bool:buttonDown[MAXPLAYERS];
new bool:concHelp[MAXPLAYERS];
new Float:PlayersInRange[MAXPLAYERS];
new bool:canThrow = false;
new bool:waitOver = false;
new realStart = 0;
new Handle:HudMsg;
new Handle:timeTimer[MAXPLAYERS];
new Float:holdingArea[3] = { -10000.0, -10000.0, -10000.0 };

public OnPluginStart() 
{
	CreateConVar("sm_conc_version", PLUGIN_VERSION, "Conc Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvConcEnabled = CreateConVar("sm_conc_enabled", "1", "Enables the plugin", FCVAR_PLUGIN);
	cvConcWaitPeriod = CreateConVar("sm_conc_waitperiod", "0", "Reccomended if you have setuptime");
	cvConcClass = CreateConVar("sm_conc_class", "scout,medic", "Which classes are able to use the conc command", FCVAR_PLUGIN);
	cvConcRadius = CreateConVar("sm_conc_radius", "288.0", "Radius of conc blast", FCVAR_PLUGIN);
	cvConcMax = CreateConVar("sm_conc_max", "3", "How many concs a player can have spawned at the same time", FCVAR_PLUGIN);
	cvConcDelay = CreateConVar("sm_conc_delay", "0.25", "How long a player has to wait before throwing another conc", FCVAR_PLUGIN);
	cvConcTimer = CreateConVar("sm_conc_timer", "3", "How many second to wait until conc explodes", FCVAR_PLUGIN);
	cvConcPhysics = CreateConVar("sm_conc_physics", "0", "Throwing physics, 0 = sm_conc_throwspeed, 1 = sm_conc_throwspeed+ownspeed, 2 = mix", FCVAR_PLUGIN);
	cvConcDifGrav = CreateConVar("sm_conc_difgrav", "1.75", "Since prop_physics don't use the same physics as a player, this is needed to give it the same terminal velocity", FCVAR_PLUGIN);
	cvConcTrail = CreateConVar("sm_conc_trail", "1", "Enables a trail following the conc", FCVAR_PLUGIN);
	cvConcSoundMode = CreateConVar("sm_conc_sounds", "1", "0 = sounds only for client throwing them, 1 = sounds audible for everyone", FCVAR_PLUGIN);
	cvConcThrowSpeed = CreateConVar("sm_conc_throwspeed", "850.0", "Speed at which concs are thrown", FCVAR_PLUGIN);
	cvConcThrowAngle = CreateConVar("sm_conc_throwangle", "0.4", "Positive aims higher then crosshair, negative lower", FCVAR_PLUGIN);
	cvConcIgnore = CreateConVar("sm_conc_ignorewalls", "1", "Enables the conc's explosion to push people through walls", FCVAR_PLUGIN);
	cvConcNoOtherPush = CreateConVar("sm_conc_ignoreothers", "1", "Enables the conc's to only push the person that threw it", FCVAR_PLUGIN);
	cvConcRings = CreateConVar("sm_conc_rings", "10.0", "Sets how many rings the conc explosion has", FCVAR_PLUGIN);
	cvConcBaseHeight = CreateConVar("sm_conc_baseheight", "48.0", "Correction for how high the player is when exploding, for making sure it pushes ppl off ground", FCVAR_PLUGIN);
	cvConcBaseSpeed = CreateConVar("sm_conc_basespeed", "650.0", "Base value for conc speed calculations", FCVAR_PLUGIN);
	cvConcIcon = CreateConVar("sm_conc_killicon", "tf_projectile_rocket", "kill icon for concs", FCVAR_PLUGIN);
	cvConcHHHeight = CreateConVar("sm_conc_hhheight", "24.0", "How high a nade should be spawned relative to feet on a handheld(feet = 0.0)", FCVAR_PLUGIN);
	cvConcHHDisDecrease = CreateConVar("sm_conc_hhdisdec", "0.1", "This value*playerspeed = distance from you and nade on a handheld", FCVAR_PLUGIN);
	cvConcBounce = CreateConVar("sm_conc_bounce", "1", "Insures a conc has the power to push someone back up, no matter how fast he's falling", FCVAR_PLUGIN);
	cvBlastDistanceMin = CreateConVar("sm_conc_blastdistmin", "0.25", "...");
	RegConsoleCmd("+conc", Command_Conc);
	RegConsoleCmd("-conc", Command_UnConc);
	RegConsoleCmd("sm_conchelp", Command_ConcHelp);
	HookEvent("teamplay_restart_round", EventRestartRound);
	HookEvent("player_death",EventPlayerDeath, EventHookMode_Pre);
	HookEvent("teamplay_round_start", MainEvents);
	HookEvent("teamplay_round_active", MainEvents);
	HookEvent("teamplay_round_stalemate", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_game_over", RoundEnd, EventHookMode_PostNoCopy);
	HudMsg = CreateHudSynchronizer();
}

public OnMapStart()
{
	
	/*AddFileToDownloadsTable("models/weapons/nades/duke1/w_grenade_conc.vvd");
	AddFileToDownloadsTable("models/weapons/nades/duke1/w_grenade_conc.sw.vtx");
	AddFileToDownloadsTable("models/weapons/nades/duke1/w_grenade_conc.phy");
	AddFileToDownloadsTable("models/weapons/nades/duke1/w_grenade_conc.mdl");
	AddFileToDownloadsTable("models/weapons/nades/duke1/w_grenade_conc.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/nades/duke1/w_grenade_conc.dx80.vtx");
	AddFileToDownloadsTable("materials/models/weapons/nades/duke1/w_grenade_conc_blu.vmt");
	AddFileToDownloadsTable("materials/models/weapons/nades/duke1/w_grenade_conc_red.vmt");
	AddFileToDownloadsTable("materials/models/weapons/nades/duke1/w_grenade_conc_blu.vtf");
	AddFileToDownloadsTable("materials/models/weapons/nades/duke1/w_grenade_conc_red.vtf");*/
	gRingModel = PrecacheModel("sprites/laser.vmt", true);
	PrecacheSound(SND_THROWNADE, true);
	PrecacheSound(SND_NADE_CONC, true);
	PrecacheSound(SND_NADE_CONC_TIMER, true);
	PrecacheModel(MDL_CONC, true);
	//AddFolderToDownloadTable("models/weapons/nades/duke1");
	//AddFolderToDownloadTable("materials/models/weapons/nades/duke1");
	AddFolderToDownloadTable("models/conc");
	AddFolderToDownloadTable("materials/conc");
	canThrow = false;
	waitOver = false;
	for(new i=0;i<MAXPLAYERS;i++)
	{
		
		nadesUsed[i] = 0;
		concToUse[i] = -1;
		nadeDelay[i] = false;
		buttonDown[i] = false;
		concHelp[i] = false;
		timeTimer[i] = INVALID_HANDLE;
		for(new j=0;j<50;j++)
		{
			nadeId[i][j] = -1;
			nadeTime[i][j] = -1;
			holding[i][j] = false;
		}
	}
	
	
}

public OnMapEnd()
{
	canThrow = false;
	waitOver = false;
	for(new i=0;i<MAXPLAYERS;i++)
	{
		nadesUsed[i] = 0;
		concToUse[i] = -1;
		nadeDelay[i] = false;
		buttonDown[i] = false;
		concHelp[i] = false;
		for(new j=0;j<50;j++)
		{
			nadeId[i][j] = -1;
			nadeTime[i][j] = -1;
			holding[i][j] = false;
		}
	}
}

public OnClientPostAdminCheck(client)
{
	for(new i=0;i<GetConVarInt(cvConcMax);i++)
	{
		if(nadeId[client][i] != -1 && IsValidEntity(nadeId[client][i])) { RemoveEdict(nadeId[client][i]); nadeId[client][i] = -1; }
		nadeTime[client][i] = -1;
		holding[client][i] = false;
	}
	if(timeTimer[client]!=INVALID_HANDLE)
	{
		CloseHandle(timeTimer[client]); timeTimer[client] = INVALID_HANDLE;
	}
	nadeDelay[client] = false;
	buttonDown[client] = false;
	concHelp[client] = false;
	concToUse[client] = -1;
	nadesUsed[client] = 0; //
}

public OnClientDisconnect(client) 
{
	for(new i=0;i<GetConVarInt(cvConcMax);i++)
	{
		if(nadeId[client][i] != -1 && IsValidEntity(nadeId[client][i])) { RemoveEdict(nadeId[client][i]); nadeId[client][i] = -1; }
		nadeTime[client][i] = -1;
		holding[client][i] = false;
	}
	if(timeTimer[client]!=INVALID_HANDLE)
	{
		CloseHandle(timeTimer[client]); timeTimer[client] = INVALID_HANDLE;
	}
	nadeDelay[client] = false;
	buttonDown[client] = false;
	concHelp[client] = false;
	concToUse[client] = -1;
	nadesUsed[client] = 0; //
}

public Action:EventRestartRound(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(GetConVarInt(cvConcEnabled)==1 && GetConVarInt(cvConcWaitPeriod)==1)
	{
		waitOver = true;
		//PrintToChatAll("EventRestartRound");
		//PrintToServer("EventRestartRound");
	}
}

public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client, nr;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	while(!holding[client][nr] && nr<GetConVarInt(cvConcMax))
	{
		nr++;
	}
	if(nr < GetConVarInt(cvConcMax))
	{
		ThrowConc(client, false);
	}
}

public Action:MainEvents(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (waitOver && realStart%2 == 1 && GetConVarInt(cvConcWaitPeriod)==1)
	{
		if (StrEqual(name, "teamplay_round_start"))
		{
			//PrintToChatAll("teamplay_round_start && waitover");
			//PrintToServer("teamplay_round_start && waitover");
			canThrow = false;
		}
		else if (StrEqual(name, "teamplay_round_active"))
		{
			//PrintToChatAll("teamplay_round_active && waitover");
			//PrintToServer("teamplay_round_active && waitover");
			realStart++;
			canThrow = true;
		}
	}
	else if(GetConVarInt(cvConcWaitPeriod)==1)
	{
		if (StrEqual(name, "teamplay_round_start"))
		{
			//PrintToChatAll("teamplay_round_start && !waitover");
			//PrintToServer("teamplay_round_start && !waitover");
			canThrow = false;
		}
		else if (StrEqual(name, "teamplay_round_active"))
		{
			//PrintToChatAll("teamplay_round_active && !waitover");
			//PrintToServer("teamplay_round_active && !waitover");
			canThrow = false;
			realStart++;
		}
	}
	else
	{
		canThrow = true;
		waitOver = true;
	}
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("EventRoundEnd");
	//PrintToServer("EventRoundEnd");
	if (StrEqual(name, "teamplay_game_over"))
	{
		waitOver = false;
		realStart = 0;
		canThrow = false;
	}
	canThrow = false;
	realStart = 1;
	//waitOver = false;
}

public Action:Command_Conc(client, args)
{
	if(GetConVarInt(cvConcEnabled)==1 && canThrow)
	{
		new tClass = int:TF2_GetPlayerClass(client);
		new String:classString[16];
		switch(tClass)
		{
			case 1:	{ Format(classString, sizeof(classString), "scout"); }
			case 2: { Format(classString, sizeof(classString), "sniper"); }
			case 3: { Format(classString, sizeof(classString), "soldier"); }
			case 4: { Format(classString, sizeof(classString), "demoman"); }
			case 5: { Format(classString, sizeof(classString), "medic"); }
			case 6: { Format(classString, sizeof(classString), "heavy"); }
			case 7: { Format(classString, sizeof(classString), "pyro"); }
			case 8: { Format(classString, sizeof(classString), "spy"); }
			case 9: { Format(classString, sizeof(classString), "engineer"); }
		}
		if(!IsPlayerAlive(client) || IsFakeClient(client) || IsClientObserver(client) || nadeDelay[client] || !IsClassAllowed(classString) || buttonDown[client])
		{
			return Plugin_Handled;
		}
		for(new i=0;i<GetConVarInt(cvConcMax);i++)
		{
			if(holding[client][i] == true) { return Plugin_Handled; }
		}
		if(nadesUsed[client] < GetConVarInt(cvConcMax))
		{
			MakeConc(client);
			holding[client][concToUse[client]] = true;
			nadeDelay[client] = true;
			buttonDown[client] = true;
			nadesUsed[client]++;
			PrintToChat(client, "Nades in use %i of max %i", nadesUsed[client], GetConVarInt(cvConcMax));
			nadeTime[client][concToUse[client]] = -1;
			CreateTimer(1.0, beepTimer, nadeId[client][concToUse[client]]);
			CreateTimer(GetConVarFloat(cvConcDelay), delayTimer, client);
			if(concHelp[client])
			{
				if(timeTimer[client]==INVALID_HANDLE)
				{
					timeTimer[client] = CreateTimer(0.1, disTimer, nadeId[client][concToUse[client]], TIMER_REPEAT);
				}
			}
			if(GetConVarInt(cvConcSoundMode)==0)
			{
				EmitSoundToClient(client, SND_NADE_CONC_TIMER);
			}
			else
			{
				EmitSoundToAll(SND_NADE_CONC_TIMER, client);
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_UnConc(client, args)
{
	if(GetConVarInt(cvConcEnabled)==1)
	{
		buttonDown[client] = false;
		new iHold = 0;
		for(new i = 0;i<GetConVarInt(cvConcMax);i++)
		{
			if(!holding[client][i])
			{
				iHold++;
			}
		}
		if(iHold==GetConVarInt(cvConcMax)) { return Plugin_Handled; }
		ThrowConc(client);
	}
	return Plugin_Handled;
}

public Action:Command_ConcHelp(client, args)
{
	if(concHelp[client])
	{
		concHelp[client] = false;
		ReplyToCommand(client, "Distance meter off");
	}
	else
	{
		concHelp[client] = true;
		ReplyToCommand(client, "Distance meter on");
	}
	return Plugin_Handled;
}

MakeConc(client)
{
	new number = 0;
	while(nadeId[client][number] != -1 && number < GetConVarInt(cvConcMax))
	{
		number++;
	}
	if(number < GetConVarInt(cvConcMax))
	{
		nadeId[client][number] = CreateEntityByName("prop_physics");
		if (IsValidEntity(nadeId[client][number]))
		{
			SetEntPropEnt(nadeId[client][number], Prop_Data, "m_hOwnerEntity", client);
			new String:gnModel[255];
			strcopy(gnModel, sizeof(gnModel), MDL_CONC);
			SetEntityModel(nadeId[client][number], gnModel);
			new String:gnSkin[8];
			Format(gnSkin, sizeof(gnSkin), "%d", GetClientTeam(client)-2);
			DispatchKeyValue(nadeId[client][number], "skin", gnSkin);
			//SetEntityMoveType(Nade, MOVETYPE_VPHYSICS);
			SetEntityMoveType(nadeId[client][number], MOVETYPE_FLYGRAVITY);
			SetEntProp(nadeId[client][number], Prop_Data, "m_CollisionGroup", 1);
			SetEntProp(nadeId[client][number], Prop_Data, "m_usSolidFlags", 16);
			//http://forums.alliedmods.net/showthread.php?p=644652#post644652
			concToUse[client] = number;
			//SDKHook(nadeId[client][number], SDKHook_PreThink, OnPreThink);
			//SDKHook(nadeId[client][number], SDKHook_Think, OnThink);
			DispatchSpawn(nadeId[client][number]);
			new String:tName[32];
			Format(tName, sizeof(tName), "tf2nade%d", client);
			DispatchKeyValue(nadeId[client][number], "targetname", tName);
			AcceptEntityInput(nadeId[client][number], "DisableDamageForces");
			//SetEntPropString(gNade[client][i], Prop_Data, "m_iName", "tf2nade%d", gNade[client][i]);
			TeleportEntity(nadeId[client][number], holdingArea, NULL_VECTOR, NULL_VECTOR);
			return true;
		}
	}
	return false;
}

ThrowConc(client, bool:thrown = true)
{
	if(IsValidEntity(nadeId[client][concToUse[client]]))
	{
		// get position and angles
		new Float:startpt[3];
		GetClientEyePosition(client, startpt);
		new Float:angle[3];
		new Float:speed[3];
		new Float:playerspeed[3];
		
		angle[0] = GetRandomFloat(-180.0, 180.0);
		angle[1] = GetRandomFloat(-180.0, 180.0);
		angle[2] = GetRandomFloat(-180.0, 180.0);
		
		if(thrown)
		{
			holding[client][concToUse[client]] = false;
			GetClientEyeAngles(client, angle);
			GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
			speed[2]+=GetConVarFloat(cvConcThrowAngle);
			//speed[0]*=GetConVarFloat(cvConcThrowSpeed); speed[1]*=GetConVarFloat(cvConcThrowSpeed); speed[2]*=GetConVarFloat(cvConcThrowSpeed);
			ScaleVector(speed, GetConVarFloat(cvConcThrowSpeed));
			if(GetConVarInt(cvConcPhysics)>0)
			{
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
				if(GetConVarInt(cvConcPhysics)==1)
				{
					for(new i=0;i<2;i++)
					{
						if(playerspeed[i] >= 0.0 && speed[i] < 0.0)
						{
							playerspeed[i] = 0.0;
						}
						else if(playerspeed[i] < 0.0 && speed[i] >= 0.0)
						{
							playerspeed[i] = 0.0;
						}
					}
					if(playerspeed[2] < 0.0 )
					{
						playerspeed[2] = 0.0;
					}
				}
				AddVectors(speed, playerspeed, speed);
			}
			TeleportEntity(nadeId[client][concToUse[client]], startpt, angle, speed);
		}
		else
		{
			new Float:altstartpt[3];
			GetClientAbsOrigin(client, altstartpt);
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
			ScaleVector(playerspeed, GetConVarFloat(cvConcHHDisDecrease));
			SubtractVectors(altstartpt, playerspeed, altstartpt);
			altstartpt[2] += GetConVarFloat(cvConcHHHeight);
			TeleportEntity(nadeId[client][concToUse[client]], altstartpt, angle, NULL_VECTOR);
		}
		if(GetConVarFloat(cvConcDifGrav)!=1.0)
		{
			SetEntityGravity(nadeId[client][concToUse[client]], GetConVarFloat(cvConcDifGrav));
		}
		
		if(GetConVarInt(cvConcTrail)==1)
		{
			new color[4];
			if(GetClientTeam(client)==2) //red
			{
				color = { 255, 50, 50, 255 };
			}
			else if(GetClientTeam(client)==3)
			{
				color = { 50, 50, 255, 255 };
			}
			else
			{
				color = { 50, 255, 50, 255 };
			}
			ShowTrail(nadeId[client][concToUse[client]], color);
		}
		EmitSoundToAll(SND_THROWNADE, client);
	}
}

public Action:beepTimer(Handle:timer, any:concId)
{
	new client = FindConcOwner(concId);
	if(client != -1)
	{
		new number = FindNr(client, concId);
		if(nadeTime[client][number] < GetConVarInt(cvConcTimer)-2)
		{
			if(holding[client][number])
			{
				if(GetConVarInt(cvConcSoundMode)==0)
				{
					EmitSoundToClient(client, SND_NADE_CONC_TIMER);
				}
				else
				{
					EmitSoundToAll(SND_NADE_CONC_TIMER, client);
				}
			}
			else
			{
				if(GetConVarInt(cvConcSoundMode)==0)
				{
					EmitSoundToClient(client, SND_NADE_CONC_TIMER);
				}
				else
				{
					EmitSoundToAll(SND_NADE_CONC_TIMER, concId);
				}
			}
			nadeTime[client][number] += 1;
			CreateTimer(1.0, beepTimer, concId);
		}
		else
		{
			if(holding[client][number])
			{
				ThrowConc(client, false);
				holding[client][number] = false;
				ConcExplode(client, concId, true);
			}
			else
			{
				ConcExplode(client, concId);
			}
			//CreateTimer(1.0, ExplodeTimer, 
		}
	}
	return Plugin_Handled;
}

public Action:delayTimer(Handle:timer, any:client)
{
	nadeDelay[client] = false;
	return Plugin_Handled;
}

public Action:disTimer(Handle:timer, any:concId)
{
	new client = FindConcOwner(concId);
	if(client > 0 && client < GetMaxClients())
	{
		new Float:center[3], Float:pos[3], Float:distance, Float:pointDist, iDist, String:sDist[32], ln = 0;
		GetClientAbsOrigin(client, pos);
		GetEntPropVector(concId, Prop_Send, "m_vecOrigin", center);
		distance = GetVectorDistance(center, pos);
		pointDist = FloatDiv(distance, GetConVarFloat(cvConcRadius));
		iDist = RoundFloat(pointDist*10.0);
		if(iDist > 30) { iDist = 30; }
		for(new i=0;i<iDist;i++)
		{
			ln += Format(sDist[ln], 31-ln, "I");
		}
		if(pointDist==1.0)
		{
			SetHudTextParams(0.04, 0.83, 1.0, 50, 255, 255, 255);
		}
		else
		{
			SetHudTextParams(0.04, 0.83, 1.0, 255, 50, 50, 255);
		}
		ShowSyncHudText(client, HudMsg, "%s", sDist);
	}
	else
	{
		PrintToServer("client = %i, concId = %i", client, concId);
	}
}

ConcExplode(client, concId, bool:handHeld = false)
{
	new Float:radius = GetConVarFloat(cvConcRadius);
	new Float:center[3];
	nadesUsed[client]--;
	//new oteam;
	//if(GetClientTeam(client)==3) {oteam=2;} else {oteam=3;}
	GetEntPropVector(concId, Prop_Send, "m_vecOrigin", center);
	SetupConcBeams(center, radius);
	EmitSoundToAll(SND_NADE_CONC, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, center, NULL_VECTOR, false, 0.0);
	if(GetConVarInt(cvConcIgnore) == 1) { FindPlayersInRange(center, radius, 0, client, false, -1); }
	else { FindPlayersInRange(center, radius, 0, client, true, -1); }
	new damage = 1;
	for (new j=1;j<=GetMaxClients();j++)
	{
		if(PlayersInRange[j]>0.0)
		{
			if(j==client || GetConVarInt(cvConcNoOtherPush)==0)
			{
				ConcPlayer(j, center, radius, client, handHeld);
				new String:tempString[32]; GetConVarString(cvConcIcon, tempString, sizeof(tempString));
				DealDamage(j, damage, center, client, DMG_CRUSH, tempString);
			}
		}
	}
	new number = FindNr(client, concId);
	nadeId[client][number] = -1;
	if(timeTimer[client] != INVALID_HANDLE) { CloseHandle(timeTimer[client]); timeTimer[client] = INVALID_HANDLE; }
	TeleportEntity(concId, holdingArea, NULL_VECTOR, NULL_VECTOR);
	RemoveEdict(concId);
}

ConcPlayer(victim, Float:center[3], Float:radius, attacker, bool:hh)
{
	new Float:pSpd[3], Float:cPush[3], Float:pPos[3], Float:distance, Float:pointDist, Float:calcSpd, Float:baseSpd;
	GetClientAbsOrigin(victim, pPos); pPos[2] += GetConVarFloat(cvConcBaseHeight);
	GetEntPropVector(victim, Prop_Data, "m_vecVelocity", pSpd);
	distance = GetVectorDistance(pPos, center);
	SubtractVectors(pPos, center, cPush);
	NormalizeVector(cPush, cPush);
	pointDist = FloatDiv(distance, radius);
	//if(concHelp[attacker] && attacker == victim) { PrintToChat(attacker, "Distance %f of 1.0", pointDist); }
	baseSpd = GetConVarFloat(cvConcBaseSpeed);
	if(GetConVarFloat(cvBlastDistanceMin) > pointDist) { pointDist = GetConVarFloat(cvBlastDistanceMin); }
	calcSpd = baseSpd*pointDist;
	//PrintToChat(victim, "Dist %f, calcSpd %f, pointDist %f", distance, calcSpd, pointDist);
	calcSpd = -1.0*Cosine( (calcSpd / baseSpd) * 3.141592 ) * ( baseSpd - (800.0 / 3.0) ) + ( baseSpd + (800.0 / 3.0) );
	//PrintToChat(victim, "calcSpd after %f", calcSpd);
	ScaleVector(cPush, calcSpd);
	new bool:OnGround; if(GetEntityFlags(victim) & FL_ONGROUND){ OnGround = true; } else { OnGround = false; }
	if((hh && victim != attacker) || !hh)
	{
		if(pSpd[2] < 0.0 && cPush[2] > 0.0 && GetConVarInt(cvConcBounce)==1) { pSpd[2] = 0.0; }
	}
	//if(concHelp[attacker] && attacker == victim) { PrintToChat(attacker, "Spd[2] %f, push %f, %f, %f", pSpd[2], cPush[0], cPush[1], cPush[2]); }
	AddVectors(pSpd, cPush, pSpd);
	if(OnGround) { if(pSpd[2] < 800.0/3.0) { pSpd[2] = 800.0/3.0; } }
	//PrintToChat(victim, "Final: x %f, y %f, z %f", pSpd[0], pSpd[1], pSpd[2]);
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, pSpd);
	/*
	new Float:play[3], Float:pointDist, Float:speed, Float:tempspeed[2], Float:playerspeed[3], Float:distance;
	GetClientAbsOrigin(victim, play);
	GetEntPropVector(victim, Prop_Data, "m_vecVelocity", playerspeed);
	play[2] += GetConVarFloat(cvConcBaseHeight);
	distance = GetVectorDistance(play, center);
	SubtractVectors(play, center, play);
	NormalizeVector(play, play);
	if (distance<GetConVarFloat(cvBlastDistanceMin)*radius) { distance = GetConVarFloat(cvBlastDistanceMin)*radius; }
	pointDist = FloatDiv(distance, radius);
	speed = GetVectorLength(playerspeed);
	new Float:baseSpd = GetConVarFloat(cvConcBaseSpeed);

	
	if(hh && victim==attacker) 
	{ 
		//tempspeed[0] = -Pow(speed-400.0, 2.0)/2000000.0 + (GetConVarFloat(cvConcHHincrement)-0.75);
		//tempspeed[1] = -Pow(speed-400.0, 2.0)/2000000.0 + (GetConVarFloat(cvConcHHincrement));
		tempspeed[0] = ConvertSpeed(600.0, 6700.0, baseSpd, speed);
		tempspeed[1] = tempspeed[0]; // * 1.2;
		if(tempspeed[0] < baseSpd/2.0) { tempspeed[0] = baseSpd/2.0; }
		if(tempspeed[1] < baseSpd/2.0) { tempspeed[1] = baseSpd/2.0; }
		play[0] *= tempspeed[0]; play[1] *= tempspeed[0]; play[2] *= tempspeed[1];
		if(playerspeed[2] < 0.0 && play[2] > 0.0 && GetConVarInt(cvConcBounce)==1) { playerspeed[2] = 0.0; }
		AddVectors(play, playerspeed, play);
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, play);
	}
	else
	{
		//tempspeed[0] = -Pow(speed-800.0, 2.0)/6000.0+GetConVarFloat(cvConcBaseSpeed);
		//tempspeed[1] = -Pow(speed-800.0, 2.0)/6000.0+(GetConVarFloat(cvConcBaseSpeed)*1.2);
		if(speed < 1200.0)
		{
			tempspeed[0] = ConvertSpeed(600.0, 800.0, baseSpd, speed);
			tempspeed[1] = tempspeed[0]; // * 1.2;
		}
		else
		{
			tempspeed[0] = Pow(speed-3500.0, 2.0)/8000.0;
			tempspeed[1] = tempspeed[0]; // * 1.2;
		}
		tempspeed[0] *= pointDist; tempspeed[1] *= pointDist;
		if(tempspeed[0] < baseSpd/2.0) { tempspeed[0] = baseSpd/2.0; }
		if(tempspeed[1] < baseSpd/2.0) { tempspeed[1] = baseSpd/2.0; }
		play[0] *= tempspeed[0]; play[1] *= tempspeed[0]; play[2] *= tempspeed[1];
		if(playerspeed[2] < 0.0 && play[2] > 0.0 && GetConVarInt(cvConcBounce)==1) { playerspeed[2] = 0.0; }
		new bool:OnGround; if(GetEntityFlags(victim) & FL_ONGROUND){ OnGround = true; } else { OnGround = false; }
		if(OnGround) { if(playerspeed[2] < 800.0/3.0) { playerspeed[2] = 800.0/3.0; } }
		AddVectors(play, playerspeed, play);
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, play);
	}
	*/
}

FindConcOwner(id)
{
	new nr = 0;
	new client = 1;
	while(nadeId[client][nr] != id && client < GetMaxClients() && nr < GetConVarInt(cvConcMax))
	{
		if(nr+1 == GetConVarInt(cvConcMax))
		{
			client+=1;
			nr=0;
		}
		else
		{
			nr+=1;
		}
	}
	if(client < GetMaxClients() && nr < GetConVarInt(cvConcMax))
	{
		return client;
	}
	return -1;
}

FindNr(client, id)
{
	new nr = 0;
	while(nadeId[client][nr] != id && nr < GetConVarInt(cvConcMax))
	{
		nr++;
	}
	return nr;
}

IsClassAllowed(String:playerClass[16])
{
	if(GetConVarInt(cvConcEnabled)==1)
	{
		new String:sKeywords[64];
		GetConVarString(cvConcClass, sKeywords, 64);
		// = "jump_,rj_,quad_,conc_,cp_,ctf_";
		new String:sKeyword[16][32];
		new iKeywords = ExplodeString(sKeywords, ",", sKeyword, 16, 16);
		for(new i = 0; i < iKeywords; i++)
		{
			if(StrContains(playerClass, sKeyword[i], false) > -1)
			{ return true; }
		}
	}
	return false;
}

SetupConcBeams(Float:center[3], Float:radius)
{
	new beamcolor[4] = { 255, 255, 255, 255 };
	new Float:beamcenter[3]; beamcenter = center;
	new Float:height = (radius/2.0)/GetConVarFloat(cvConcRings);
	for(new f=0;f<GetConVarInt(cvConcRings);f++)
	{
		TE_SetupBeamRingPoint(beamcenter,2.0,radius,gRingModel,gRingModel,0,1,0.35,6.0,0.0,beamcolor,0,FBEAM_FADEOUT);
		TE_SendToAll(0.0);
		beamcenter[2] += height;
	}
}

ShowTrail(nade, color[4])
{
	TE_SetupBeamFollow(nade, gRingModel, 0, Float:1.0, Float:10.0, Float:10.0, 5, color);
	TE_SendToAll();
}

DealDamage(victim, damage, Float:loc[3],attacker=0,dmg_type=DMG_GENERIC,String:weapon[]="")
{
	if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
	{
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		//PrintToChat(victim, "victim %i is valid and hit by attacker %i", victim, attacker);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			//new Float:vicOri[3];
			//GetClientAbsOrigin(victim, vicOri);
			TeleportEntity(pointHurt, loc, NULL_VECTOR, NULL_VECTOR);
			//Format(tName, sizeof(tName), "hurtme%d", victim);
			DispatchKeyValue(victim,"targetname","hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				//PrintToChat(victim, "weaponname = %s", weapon);
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			//Format(tName, sizeof(tName), "donthurtme%d", victim);
			DispatchKeyValue(victim,"targetname","donthurtme");
			//TeleportEntity(pointHurt[victim], gHoldingArea, NULL_VECTOR, NULL_VECTOR);
			//CreateTimer(0.01, TPHurt, victim);
			RemoveEdict(pointHurt);
		}
	}
}

AddFolderToDownloadTable(const String:Directory[], bool:recursive=false) 
{
	decl String:FileName[64], String:Path[512];
	new Handle:Dir = OpenDirectory(Directory), FileType:Type;
	while(ReadDirEntry(Dir, FileName, sizeof(FileName), Type))     
	{
		if(Type == FileType_Directory && recursive)         
		{           
			FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
			AddFolderToDownloadTable(FileName);
			continue;
			
		}                 
		if (Type != FileType_File) continue;
		FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
		AddFileToDownloadsTable(Path);
	}
	return;	
}

FindPlayersInRange(Float:location[3], Float:radius, team, self, bool:trace, donthit)
{
	new Float:rsquare = radius*radius;
	new Float:orig[3];
	new Float:distance;
	new Handle:tr;
	new j;
	new maxplayers = GetMaxClients();
	//if(GetConVarInt(ff)==1){ team = 0; }
	for (j=1;j<=maxplayers;j++)
	{
		PlayersInRange[j] = 0.0;
		if (IsClientInGame(j))
		{
			if (IsPlayerAlive(j))
			{
				if ( (team>1 && GetClientTeam(j)==team) || team==0 || j==self)
				{
					GetClientAbsOrigin(j, orig);
					orig[0]-=location[0];
					orig[1]-=location[1];
					orig[2]-=location[2];
					orig[0]*=orig[0];
					orig[1]*=orig[1];
					orig[2]*=orig[2];
					distance = orig[0]+orig[1]+orig[2];
					if (distance < rsquare)
					{
						if (trace)
						{
							GetClientEyePosition(j, orig);
							tr = TR_TraceRayFilterEx(location, orig, MASK_SOLID, RayType_EndPoint, TraceRayHitPlayers, donthit);
							if (tr!=INVALID_HANDLE)
							{
								if (TR_GetFraction(tr)>0.98)
								{
									PlayersInRange[j] = SquareRoot(distance)/radius;
								}
								CloseHandle(tr);
							}
							
						}
						else
						{
							PlayersInRange[j] = SquareRoot(distance)/radius;
						}
					}
				}
			}
		}
	}
}

public bool:TraceRayHitPlayers(entity, mask, any:startent)
{
	if (entity <= GetMaxClients() && entity > 0)
	{
		return true;
	}
	return false; 
}