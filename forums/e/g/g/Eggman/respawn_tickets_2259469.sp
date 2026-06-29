#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#tryinclude "freak_fortress_2"
//#tryinclude "demo_pirate"

#define PLUGIN_VERSION "1.0"

new Handle:ticketHUD;
new Handle:ticketHUD2;


new Handle:cvarMinCount;
new Handle:cvarCount;
new Handle:cvarCoolDown;
new Handle:cvarCoolDownInc;
new Handle:cvarHPmp;
new Handle:cvarOnResp;
new TFTeam:BossTeam=TFTeam_Unassigned;

new MinCount;
new Float:Count;
new CoolDown;
new CoolDownInc;
new Float:HPmp;
new bool:OnResp;

new initCount;
new currentCount;

new bool:bDead[MAXPLAYERS+1];
new cooldown[MAXPLAYERS+1];
new respawn_uses[MAXPLAYERS+1];

new bool:overhealth[MAXPLAYERS+1];

new String:respawn_responses[10][3][55]=
{
	{"","",""},
	{"vo/scout_mvm_resurrect02.wav", "vo/scout_mvm_resurrect03.wav", "vo/scout_mvm_resurrect07.wav"},
	{"vo/sniper_mvm_resurrect01.wav", "vo/sniper_mvm_resurrect02.wav", "vo/sniper_mvm_loot_rare01.wav"},
	{"vo/soldier_mvm_resurrect03.wav", "vo/soldier_mvm_resurrect05.wav", "vo/soldier_mvm_resurrect06.wav"},
	{"vo/demoman_mvm_resurrect03.wav", "vo/demoman_mvm_resurrect01.wav", "vo/demoman_mvm_resurrect06.wav"},
	{"vo/medic_mvm_resurrect01.wav", "vo/medic_mvm_resurrect02.wav", "vo/medic_mvm_say_ready02.wav"},
	{"vo/heavy_mvm_resurrect01.wav", "vo/heavy_mvm_resurrect04.wav", "vo/heavy_positivevocalization03.wav"},
	{"vo/pyro_laugh_addl04.wav", "vo/pyro_paincrticialdeath02.wav", "vo/pyro_needteleporter01.wav"},
	{"vo/spy_mvm_resurrect01.wav", "vo/spy_mvm_resurrect06.wav", "vo/spy_mvm_resurrect08.wav"},
	{"vo/engineer_mvm_resurrect02.wav", "vo/engineer_mvm_resurrect03.wav", "vo/engineer_mvm_say_ready02.wav"}
};
//new String:respawn_responses_pirate[3][] = {"custom/vo/pirate_resurrect01.mp3", "custom/vo/pirate_resurrect02.mp3", "custom/vo/pirate_resurrect03.mp3"};

//new String:buyback[PLATFORM_MAX_PATH] = "buyback.mp3";
new String:buyback[PLATFORM_MAX_PATH] = "ui/trade_ready.wav";

public Plugin:myinfo=
{
	name="Freak Fortress 2: Respawn Tickets",
	author="DaNetNavern0 aka Eggman",
	description="FF2: Respawn Tickets",
	version=PLUGIN_VERSION,
};

public OnPluginStart()
{
	cvarCount = CreateConVar("ff2_tickets_count_multiplier", "1.3", "Tickets per player", FCVAR_PLUGIN);
	cvarMinCount = CreateConVar("ff2_tickets_count_min", "5", "Min count of respawn tickets", FCVAR_PLUGIN);
	cvarCoolDown = CreateConVar("ff2_tickets_countdown", "10", "Initial respawn countdown", FCVAR_PLUGIN);
	cvarCoolDownInc = CreateConVar("ff2_tickets_countdown_increase", "10", "Countdown personally increase per death", FCVAR_PLUGIN);
	cvarHPmp = CreateConVar("ff2_tickets_hp_multiplier", "0.07", "Boss' health increase per ticket", FCVAR_PLUGIN);
	cvarOnResp = CreateConVar("ff2_tickets_onrespawn", "1", "1 - Player respawns in respawn room. 0 - Player respawns in spectating player.", FCVAR_PLUGIN);
	
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
	PrecacheSound("ui/vote_success.wav");
	//decl String:s[PLATFORM_MAX_PATH];
	//Format(s,PLATFORM_MAX_PATH,"sound/%s",buyback);
	//AddFileToDownloadsTable(s);
	PrecacheSound(buyback);
	for(new i=1;i<10;i++)
		for(new j=0;j<3;j++)
			PrecacheSound(respawn_responses[i][j]);
	/*#if defined _demo_pirate_included
	decl String:s[PLATFORM_MAX_PATH];
	for(new j=0;j<3;j++)
	{
		PrecacheSound(respawn_responses_pirate[j]);
		Format(s,PLATFORM_MAX_PATH,"sound/%s",respawn_responses_pirate[j]);
		AddFileToDownloadsTable(s);
	}
	#endif*/
	event_round_start(INVALID_HANDLE,"",false);
}

public OnMapStart()
{
	CreateTimer(1.0, Timer_Down_CoolDown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	ticketHUD = CreateHudSynchronizer();
	ticketHUD2 = CreateHudSynchronizer();
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	MinCount = GetConVarInt(cvarMinCount);
	Count = GetConVarFloat(cvarCount);
	HPmp = GetConVarFloat(cvarHPmp);
	CoolDown = GetConVarInt(cvarCoolDown);
	CoolDownInc = GetConVarInt(cvarCoolDownInc);
	OnResp = GetConVarBool(cvarOnResp);
	
	//CreateTimer(9.0, MaxHPTimer);
	CreateTimer(12.0, MaxHPTimer);
	#if defined _FF2_included
		CreateTimer(0.3, Timer_GetBossTeam);
		for(new client=0; client<=MaxClients; client++)
			overhealth[client]=false;
	#endif
}

public OnClientPutInServer(client)
{
	bDead[client] = true;
	cooldown[client] = 0;
}

public Action:Timer_Down_CoolDown(Handle:hTimer)
{
	SetHudTextParams(0.95, 0.03, 4.0, 255, 255, 255, 255);
	for(new client=1;client<=MaxClients;client++)
		if (IsValidClient(client))
		{
			ShowSyncHudText(client, ticketHUD2, "%i/%i",currentCount,initCount);
		}
	SetHudTextParams(-1.0, 0.65, 1.2, 255, 255, 255, 255);
	for(new client=1;client<=MaxClients;client++)
	{
		if (currentCount>0 && bDead[client] && IsValidClient(client))
		{
			if (cooldown[client]>0)
			{
				ShowSyncHudText(client, ticketHUD, "%i seconds until you can respawn", cooldown[client]);
				cooldown[client]--;
			}
			else
				ShowSyncHudText(client, ticketHUD, "Press Reload to use respawn ticket");
		}
	}
}

#if defined _FF2_included
public Action:Timer_GetBossTeam(Handle:hTimer)
{
	BossTeam=TFTeam:FF2_GetBossTeam();
	return Plugin_Continue;
}
#endif

public Action:MaxHPTimer(Handle:hTimer)
{
	new playing=0;
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && GetClientTeam(client)>_:TFTeam_Spectator)
			playing++;
		respawn_uses[client]=0;
	}
	currentCount = RoundFloat(playing*Count);
	if (currentCount<MinCount)
		currentCount=MinCount;
	initCount = currentCount;
	
	#if defined _FF2_included
	decl index;
	new String:s[256]="Max Health of Bosses increased to ";
	new lives=0;
	for(new client=1;client<=MaxClients;client++)
	{
		index = FF2_GetBossIndex(client);
		if (index!=-1)
		{
			if (!overhealth[index])
			{
				lives = FF2_GetBossMaxLives(index);
				new health = RoundFloat(FF2_GetBossMaxHealth(index)*(1.0+(currentCount*HPmp)/lives));
				Format(s,256,"%s %i\n",s,RoundFloat(FF2_GetBossMaxHealth(index)*(1.0+(currentCount*HPmp)/lives)));
				overhealth[index]=true;
				FF2_SetBossMaxHealth(index, health);
				FF2_SetBossHealth(index, health*lives);
			}
		}
	}
	if (lives)
	{
		SetHudTextParams(-1.0, 0.3, 10.0, 255, 255, 255, 255);
		for(new player=1;player<=MaxClients;player++)
			if (IsValidClient(player))
				ShowHudText(player, -1, s);
	}
	#endif
}

public event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client>0 && client<=MaxClients)
		bDead[client] = false;
}

public event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client>0 && client<=MaxClients)
		{
			cooldown[client]=CoolDown+CoolDownInc*respawn_uses[client];
			bDead[client] = true;
		}	
		for(new client2=1;client2<=MaxClients;client2++)
		{
			if (cooldown[client2]>0)
			{
				cooldown[client2]-=3;
				SetHudTextParams(-1.0, 0.7, 1.2, 255, 0, 0, 255);
				ShowHudText(client2, -1, "-1 sec");
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:velocity[3], Float:angles[3], &weapon)
{
	if (currentCount>0)
	{
		if ((BossTeam==TFTeam_Unassigned) || (BossTeam==TFTeam_Blue && TFTeam:GetClientTeam(client)==TFTeam_Red) || (BossTeam==TFTeam_Red && TFTeam:GetClientTeam(client)==TFTeam_Blue))
		{
			if ((buttons & IN_RELOAD) && bDead[client] && cooldown[client]<=0)
			{
				TF2_RespawnPlayer(client);
				if (!OnResp)
				{
					decl Float:pos[3];
					new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
					if (IsValidClient(target))
					{
						GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
						new Handle:data;
						CreateDataTimer(0.01, Timer_Teleport, data);		
						WritePackFloat(data, pos[0]);
						WritePackFloat(data, pos[1]);
						WritePackFloat(data, pos[2]);
						WritePackCell(data, GetClientUserId(client));
						ResetPack(data);
					}
				}
				
				EmitSoundToAll(buyback);
				currentCount--;
				respawn_uses[client]++;
				
				SetHudTextParams(0.95, 0.06, 1.0, 255, 64, 64, 255);
				for(new inforer=1;inforer<=MaxClients;inforer++)
					if (IsValidClient(inforer))
						ShowHudText(inforer, -1, "-1");
				CreateTimer(1.0,Timer_RespawnResponse,GetClientUserId(client));
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_RespawnResponse(Handle:hTimer,any:clientid)
{
	new client = GetClientOfUserId(clientid);
	new class = _:TF2_GetPlayerClass(client);
	new num = GetRandomInt(0,2);
	EmitSoundToAll(respawn_responses[class][num]);
	//EmitSoundToAll(respawn_responses[class][num]);
	/*new bool:see = true;
	#if defined _demo_pirate_included
		see=!Pirate_IsPirate(client);
	#endif
	
	if (see)
	{	
		EmitSoundToAll(respawn_responses[class][num]);
		EmitSoundToAll(respawn_responses[class][num]);
	}
	else
	{
		EmitSoundToAll(respawn_responses_pirate[num]);
		EmitSoundToAll(respawn_responses_pirate[num]);
	}*/
}

public Action:Timer_Teleport(Handle:hTimer,Handle:data)
{
	new Float:pos[3];
	pos[0] = ReadPackFloat(data);
	pos[1] = ReadPackFloat(data);
	pos[2] = ReadPackFloat(data);
	new client=GetClientOfUserId(ReadPackCell(data));
	if (IsValidClient(client))
		SetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
}

stock bool:IsValidClient(client, bool:replaycheck=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}