#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6
#define ZOMBIECLASS_TANK	8

#define LISTEN_DEFAULT      0   /**< No overwriting is done */
#define LISTEN_NO           1   /**< Disallows the client to listen to the sender */
#define LISTEN_YES          2   /**< Allows the client to listen to the sender */

#define MapCount 6
#define MaxFlagCount 6

#define MAP0 "smalltown01" 
#define MAP1 "airport01" 
#define MAP2 "c2m1_highway" 
#define MAP3 "airport05" 
#define MAP4 "c2m2_fairgrounds" 
#define MAP5 "c2m3_coaster" 

#define SOUND_BLIP		"UI/Beep07.wav"

new MapIndex;
new bool:MapOK;
new bool:Enabled;
new bool:GameStart;


new String:MapNames[MapCount][128]={MAP0, MAP1, MAP2, MAP3, MAP4, MAP5};
new FlagCount[MapCount]={3, 3, 4, 4, 3, 3};
new Float:FlagPoints[MapCount][MaxFlagCount][3]=
{
	//MAP0
	{ {-11628.453125, -14731.864257, -209.386871}, {-12269.115234, -12145.490234, -60.406021}, {-12314.117187, -10561.467773, -63.968750}, { }, { }, { } },
	//MAP1
	{ { 6528.256347, -739.510192, 798.284729 }, {4723.340820, 606.063781, 540.341796}, {3055.440185, 804.788757, 730.367919}, {0.0,0.0,0.0}, {0.0,0.0,0.0}, {0.0,0.0,0.0} },
	//MAP2
	{ {2785.028320, 4204.063964, -967.968750}, { 2970.336425, 5783.937988, -975.968750}, {1031.355712, 5704.647460, -967.968750}, { 844.451904, 3492.887939, -967.968750 }, { }, {0.0,0.0,0.0} },
	//MAP3
	{ { -6380.403808, 11860.239257, -144.035202}, {-5424.611328, 10352.963867, 60.031250 }, {-6320.660156, 9347.089843, -190.968750}, { -4103.082031, 8823.732421, -189.323852}, { 0.0, 0.0, 0.0}, {0.0,0.0,0.0} },
	//MAP4
	{ { 2034.547607, 2448.286865, 0.031250}, {2343.769042, 436.366546, 10.977792}, { 4073.619628, -1024.355834, 0.556036}, { 0.0, 0.0, 0.0}, { 0.0, 0.0, 0.0}, {0.0,0.0,0.0} },
	//MAP5
	{ { 2303.540039, 2242.629638, -11.264528}, {2167.711425, 3512.426269, -7.983049}, { 528.145507, 4538.747558, -39.968750}, { 0.0, 0.0, 0.0}, { 0.0, 0.0, 0.0}, {0.0,0.0,0.0} }
};



new PlayerDeath[MAXPLAYERS+1];
new PlayerKill[MAXPLAYERS+1];
new TeamWin[MAXPLAYERS+1];

new FlagTeam[MaxFlagCount]={-1, -1, -1, -1, -1};
static Teams[MAXPLAYERS+1];
new FlagValue[MaxFlagCount];
new SpawnDelay[MAXPLAYERS+1];
new bool:IsShowHud[MAXPLAYERS+1];
new bool:IsShowHud2[MAXPLAYERS+1];

new FlagColor[3][4]=
{
	{0,0, 255, 255},  {255, 0, 0, 255}, {128, 128, 128, 255}
};
new TeamColor[2][4]=
{
	 {255, 255, 255, 255}, {255,255,0, 255}
};

new Handle:l4d_cs_respawntime = INVALID_HANDLE;
new Handle:l4d_cs_enable = INVALID_HANDLE;
new Handle:l4d_cs_teambalance = INVALID_HANDLE;
new Handle:l4d_cs_survivorglow = INVALID_HANDLE;
new Handle:l4d_cs_noinfected= INVALID_HANDLE;
new Handle:l4d_cs_alltalk= INVALID_HANDLE;
new Handle:l4d_cs_deadalltalk= INVALID_HANDLE;

new GameMode;
new bool:L4D2Version;
new Handle:showhud_timer= INVALID_HANDLE;

new Handle:hRoundRespawn = INVALID_HANDLE;
new Handle:hGameConf = INVALID_HANDLE;
new Handle:WinTimer = INVALID_HANDLE;
new wintick;
new g_sprite;
new g_BeamSprite;
new g_HaloSprite;
new bool:LeftSafeRoom;
public Plugin:myinfo = 
{
	name = "Counter-Strike Game",
	author = "Pan Xiaohai",
	description = "Counter-Strike Game",
	version = PLUGIN_VERSION,	
}

public OnPluginStart()
{
	new bool:error=false;
	hGameConf = LoadGameConfigFile("l4dcs");
	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if (hRoundRespawn == INVALID_HANDLE) 
		{
			error=true;
			SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
		}
  	}
	else
	{
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/l4dcs.txt , you FAILED AT INSTALLING");
		error=true;
	}
 	if(error)return;
	GameCheck();
		
	l4d_cs_enable = CreateConVar("l4d_cs_enable", "0", "cs mode 0:disable, 1:enable ", FCVAR_PLUGIN);
	l4d_cs_respawntime = CreateConVar("l4d_cs_respawntime", "10", "", FCVAR_PLUGIN);
	l4d_cs_teambalance = CreateConVar("l4d_cs_teambalance", "1", "auto team balance  0:disable, 1:enable ", FCVAR_PLUGIN);
	l4d_cs_survivorglow = CreateConVar("l4d_cs_survivorglow", "0", "surivor glow  0:disable, 1:enable ", FCVAR_PLUGIN);
	l4d_cs_noinfected = CreateConVar("l4d_cs_noinfected", "1", "no infected 0:disable, 1:enable ", FCVAR_PLUGIN);	
	l4d_cs_alltalk = CreateConVar("l4d_cs_alltalk", "0", "voice communication between two team 0:disable, 1:enable ", FCVAR_PLUGIN);
	l4d_cs_deadalltalk = CreateConVar("l4d_cs_deadalltalk", "1", "dead all talk 0:disable, 1:enable ", FCVAR_PLUGIN);		
	
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("round_start", RoundStart);
	HookEvent("player_death", evtPlayerDeath);
	//HookEvent("player_left_start_area", player_left_start_area);	
	//HookEvent("door_open", player_left_start_area);	
	
	RegAdminCmd("sm_pos", sm_pos, ADMFLAG_KICK);
	RegAdminCmd("sm_switchteam",sm_switchteam,ADMFLAG_RCON);
	RegConsoleCmd("sm_betray",sm_betray);
	RegConsoleCmd("sm_join",sm_join);
	RegAdminCmd("sm_restart",sm_restart,ADMFLAG_RCON);
	AutoExecConfig(true, "l4d_cs");
	
	HookConVarChange(l4d_cs_enable, ConVarChange);
	HookConVarChange(l4d_cs_survivorglow, ConVarChange);
	HookConVarChange(l4d_cs_noinfected, ConVarChange);

	Enabled=GetConVarInt(l4d_cs_enable )>0;
	ConVarSet();
	
}
GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version=true;
	}	
	else
	{
		L4D2Version=false;
	}

}

MapCheck()
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	MapIndex=-1;
	MapOK=false;
	for(new i=0; i<MapCount; i++)
	{
		if(StrContains(mapname, MapNames[i], false)>=0)
		{
			MapIndex=i;
			MapOK=true;
		}
	}
}
public OnMapStart()
{
	MapCheck();
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
		g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
		g_HaloSprite = PrecacheModel("materials/dev/halo_add_to_screen.vmt");			
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
		g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
		g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");	
	}
	PrecacheSound(SOUND_BLIP, true);
}
ConVarSet()
{
	if(!MapOK)return;
	Enabled=GetConVarInt(l4d_cs_enable )>0;
	if(GetConVarInt(l4d_cs_noinfected)>0 && Enabled)
	{
		
		SetConVarInt(FindConVar("director_no_bosses"), 1);
		SetConVarInt(FindConVar("director_no_specials"), 1);
		SetConVarInt(FindConVar("director_no_mobs"), 1); 
		//StripAndExecuteServerCommand("director_stop"); //why do not work?
	}
	else
	{
		SetConVarInt(FindConVar("director_no_death_check"), 0);
		SetConVarInt(FindConVar("director_no_bosses"), 0);
		SetConVarInt(FindConVar("director_no_specials"), 0);
		SetConVarInt(FindConVar("director_no_mobs"), 0); 
		//StripAndExecuteServerCommand("director_start");
	
	}
	new bool:show=GetConVarInt(l4d_cs_survivorglow)==1;
	if( Enabled)
	{
		for (new i=1;i<=MaxClients;i++)
		{
			if (IsClientInGame(i))
			{
				GlowSet(i, show);
			}
		}
	}
	else
	{
		GameStart=false;
		for (new i=1;i<=MaxClients;i++)
		{
			if (IsClientInGame(i))
			{
				GlowSet(i, true);
				if(GetClientTeam(i)==2)
				{
					for (new j=1;j<=MaxClients;j++)
					{
						if (IsClientInGame(j) && GetClientTeam(j)==2)
						{
							SetClientListening(i,j, LISTEN_YES);
							SetClientListening(j,i, LISTEN_YES);
						}
					}
				}
			}
		}	
		SetConVarInt(FindConVar("director_no_death_check"), 0);
	}
}
public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ConVarSet();
}
GetTeamNumber(team)
{
	new count=0;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i)==2 && Teams[i]==team)
		{
			count++;
		}
	}
	return count;
}
FindRandomFlag(team)
{
	decl flag[10];
	new index=0;
	for(new i=0; i<FlagCount[MapIndex]; i++)
	{
		if(FlagTeam[i]==team)
		{
			flag[index++]=i;
		}
	}
	if(index>0)
	{
		return flag[GetRandomInt(0, index-1)];
	}
	else return -1;
}

FindRandomPlayer(team, bool:alive=true)
{
	decl player[MAXPLAYERS+1];
	new index=0;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i)==2 && Teams[i]==team)
		{
			if(alive)
			{
				if(IsPlayerAlive(i))
				{
					player[index++]=i;
				}
			}
			else 
			{
				player[index++]=i;
			}
		}
	}
	if(index>0)
	{
		return player[GetRandomInt(0, index-1)];
	}
	else return -1;
}
SwitchTeam(client)
{
	if(!IsClientInGame(client))return;
	new t0=GetTeamNumber(0);
	new t1=GetTeamNumber(1);	
	new bool:full=false;
	if(Teams[client]==0)
	{
		if(t1>t0)full=true;
	}
	if(Teams[client]==1)
	{
		if(t0>t1)full=true;
	}
	if(full)
	{
		PrintCenterText(client, "team is full");
	}
	else
	{
		if(IsPlayerAlive(client))ForcePlayerSuicide(client);
		PlayerDeath[client]=PlayerKill[client]=0;
		Teams[client]=(Teams[client]+1)%2;
		SpawnDelay[client]=GetConVarInt(l4d_cs_respawntime);
	}
}
ResetFlag()
{
	for(new i=0; i<FlagCount[MapIndex]; i++)
	{
		FlagTeam[i]=-1;
		FlagValue[i]=0;
	}
}
RoundRestart(bool:swtichteam=true)
{
	ResetFlag();
	ConVarSet(); 
	SetConVarInt(FindConVar("director_no_death_check"), 1);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) ==2 )
		{

			PlayerDeath[i]=PlayerKill[i]=0;		
			if(swtichteam) Teams[i]=(Teams[i]+1)%2;
			SpawnDelay[i]=2*GetConVarInt(l4d_cs_respawntime);
			if(!IsPlayerAlive(i))
			{
				//ForcePlayerSuicide(i);
				SDKCall(hRoundRespawn, i);
			}
		
			if(Teams[i]==0)	TeleportEntity(i, FlagPoints[MapIndex][0], NULL_VECTOR, NULL_VECTOR);
			if(Teams[i]==1)	TeleportEntity(i, FlagPoints[MapIndex][FlagCount[MapIndex]-1], NULL_VECTOR, NULL_VECTOR);
			PlayerSpawnSet(i);
		}
	}

	
}
ResetVoice()
{
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientTeam(i)==2)
			{
				for (new j=1;j<=MaxClients;j++)
				{
					if (IsClientInGame(j) && GetClientTeam(j)==2)
					{
						SetClientListening(i,j, LISTEN_YES);
						SetClientListening(j,i, LISTEN_YES);
					}
				}
			}
		}
	}		
	
}

public Action:RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	LeftSafeRoom=false;	

	if(!MapOK)return Plugin_Continue;
	if(GameMode==2 || GetConVarInt(l4d_cs_enable)==0) return Plugin_Continue; 
	ConVarSet();
	ResetVoice();
	GameStart=true;
	if(showhud_timer == INVALID_HANDLE )
	{
 		showhud_timer=CreateTimer(1.0, ShowHud, 0, TIMER_REPEAT);
 	}
	GameStart=true;
  	return Plugin_Continue;
}
public Action:sm_restart(client, args)
{
	if(!MapOK)return Plugin_Continue;
	if(GameMode==2 || GetConVarInt(l4d_cs_enable)==0) return Plugin_Continue; 
	GameStart=true;

	if(LeftSafeRoom)
	{
		GameStart=false;
		SetConVarInt(FindConVar("director_no_death_check"), 0);
		for(new client=1;client<=MaxClients; client++)
		{
			if (IsClientInGame(client) && GetClientTeam(client)==2 && IsPlayerAlive(client))
			{
				ForcePlayerSuicide(client);
			}
		}
		PrintHintTextToAll("CS game restart");
	}
	else
	{
		PrintHintText(client, "please left start area first");
	}
	if(showhud_timer == INVALID_HANDLE )
	{
 		showhud_timer=CreateTimer(1.0, ShowHud, 0, TIMER_REPEAT);
 	}
	return Plugin_Continue;
}
public Action:Event_Player_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(!MapOK || !GameStart)return Plugin_Continue;
	if(GameMode==2 || GetConVarInt(l4d_cs_enable)==0) return Plugin_Continue; 
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	PlayerSpawnSet(client);
  	return Plugin_Continue;
}
public Action:evtPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!MapOK || !GameStart)return Plugin_Continue;
 	if(GameMode==2 || GetConVarInt(l4d_cs_enable)==0) return Plugin_Continue; 
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	PlayerDeathSet(client,attacker );

	return Plugin_Continue;
}
bool:IsLeftStartAreaArea()
{
	new ent = -1, maxents = GetMaxEntities();
	for (new i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			decl String:netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		new offset = FindSendPropInfo("CTerrorPlayerResource", "m_hasAnySurvivorLeftSafeArea");
		if (offset > 0)
		{
			if (GetEntData(ent, offset))
			{
				if (GetEntData(ent, offset) == 1) return true;
			}
		}
	}
	return false;
}
PlayerDeathSet(client, attacker)
{
	new alltalk=LISTEN_NO;
	if(GetConVarInt(l4d_cs_alltalk)>0)
	{
		alltalk=LISTEN_YES;
		GlowSet(client, true);
	}	
	new deadalltalk=LISTEN_NO;
	if(GetConVarInt(l4d_cs_deadalltalk)>0)
	{
		deadalltalk=LISTEN_YES;
	}		
		
	if(client>0 && IsClientInGame(client) && GetClientTeam(client)==2)
	{
		SpawnDelay[client]=GetConVarInt(l4d_cs_respawntime);
		if(client!=attacker)PlayerDeath[client]++;
		
		if(Teams[client]==Teams[attacker])
		{
			if(client !=attacker )PlayerKill[attacker]--;
		}
		else
		{
			PlayerKill[attacker]++;
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			if(Teams[client]==Teams[i])
			{
				if (IsClientInGame(i) && GetClientTeam(i) ==2 )
				{
					if(IsPlayerAlive(i))
					{
						SetClientListening(client, i, LISTEN_YES);
						SetClientListening(i, client,alltalk);
					}
					else
					{
						SetClientListening(client, i, LISTEN_YES);
						SetClientListening(i, client, LISTEN_YES);					
					}
				}		
			}
			else
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2 )
				{
					if(IsPlayerAlive(i))
					{
						SetClientListening(client, i, alltalk);
						SetClientListening(i, client, alltalk);
					}
					else
					{
						SetClientListening(client, i, alltalk || deadalltalk );
						SetClientListening(i, client, alltalk || deadalltalk );						
					}
				}
			}

		}
		
	}
}
PlayerSpawnSet(client)
{
	new alltalk=LISTEN_NO;
	if(GetConVarInt(l4d_cs_alltalk)>0)
	{
		alltalk=LISTEN_YES;
	}
	if(client>0 && IsClientInGame(client) && GetClientTeam(client)==2)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if(Teams[client]==Teams[i])
			{
				if (IsClientInGame(i) && GetClientTeam(i) ==2 )
				{
					if(IsPlayerAlive(i))
					{
						SetClientListening(client, i, LISTEN_YES);
						SetClientListening(i, client, LISTEN_YES);
					}
					else
					{
						SetClientListening(client, i, alltalk);
						SetClientListening(i, client, LISTEN_YES);					
					}
				}		
			}
			else
			{
				if (IsClientInGame(i) && GetClientTeam(i) ==2 )
				{

					SetClientListening(client, i, alltalk);
					SetClientListening(i, client, alltalk);
				}
			}

		}
		SetEntityRenderMode(client, RenderMode:3);
		SetEntityRenderColor(client, TeamColor[Teams[client]][0],  TeamColor[Teams[client]][1], TeamColor[Teams[client]][2], TeamColor[Teams[client]][3]);
		//PrintToChatAll("%N respawn", client);
		
		GlowSet(client, GetConVarInt(l4d_cs_survivorglow)==1);
		
	}
}


public Action:sm_pos(client, args)
{
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	PrintToChatAll("pos %f, %f, %f", pos[0], pos[1], pos[2]);
}
public Action:sm_switchteam(client, args)
{
	if(!MapOK || !GameStart)return Plugin_Continue;
	if(GameMode==2 || GetConVarInt(l4d_cs_enable)==0) return Plugin_Continue; 
 	new String:arg[8];
	GetCmdArg(1,arg,8);
 	new Input=StringToInt(arg[0]);
	new c=GetClientOfUserId(Input);
	SwitchTeam(c);
	return Plugin_Continue;
}
public Action:sm_betray(client, args)
{
	if(!MapOK || !GameStart)return Plugin_Continue;
	if(GameMode==2 || GetConVarInt(l4d_cs_enable)==0) return Plugin_Continue; 
	ChangeClientTeam(client, 2);
	SwitchTeam(client);
	return Plugin_Continue;
}
public Action:sm_join(client, args)
{
	if(!MapOK || !GameStart)return Plugin_Continue;
	if(GameMode==2 || GetConVarInt(l4d_cs_enable)==0) return Plugin_Continue; 
	ChangeClientTeam(client, 2);
	SpawnDelay[client]=GetConVarInt(l4d_cs_respawntime);
	return Plugin_Continue;
}

new Handle:pInfHUD 		= INVALID_HANDLE;	
public Menu_InfHUDPanel(Handle:menu, MenuAction:action, param1, param2) { return; }
public Action:ShowHud(Handle:timer, any:data)
{
	if(!MapOK || !GameStart)return Plugin_Continue;
	if(GameMode==2 || GetConVarInt(l4d_cs_enable)==0) return Plugin_Continue ; 
	if(!LeftSafeRoom)
	{
		LeftSafeRoom=IsLeftStartAreaArea();
		//PrintToChatAll("check");
		if(LeftSafeRoom)
		{
			PrintHintTextToAll("CS game begin...");
			RoundRestart();
		}
		return Plugin_Continue;
	}
	
	decl String:iStatus[100];
	
	pInfHUD = CreatePanel(GetMenuStyleHandle(MenuStyle_Default));

	SetPanelTitle(pInfHUD, "scores:");

	DrawPanelItem(pInfHUD, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
 
	new respawn=0;
	new button;
	new Float:dis;
	decl Float:pos[3];
	 
	new goodteam=0;
	new badteam=0;
	new goodteam2=0;
	new badteam2=0;
	Format(iStatus, sizeof(iStatus), "good (%d)", TeamWin[0]);
	DrawPanelText(pInfHUD, iStatus);

	new i;
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) != 2)continue;
		if(Teams[i]!=0)continue;
		
		if (IsPlayerAlive(i))
		{
			goodteam++;

			Format(iStatus, sizeof(iStatus), " (%d/%d)", PlayerKill[i], PlayerDeath[i]);
			button=GetClientButtons(i);
			if(button & IN_SCORE)IsShowHud[i]=!IsShowHud[i];
			if(button & IN_USE)IsShowHud2[i]=true;
			else IsShowHud2[i]=false;
			if(button & IN_DUCK)
			{
				GetClientAbsOrigin(i, pos);
				for(new j=0; j<FlagCount[MapIndex]; j++)
				{
					if(FlagTeam[j]!=Teams[i])
					{
						dis=GetVectorDistance(pos, FlagPoints[MapIndex][j]);
						if(dis<60.0)
						{
							FlagValue[j]+=Teams[i]==0?1:-1;
							if(FlagValue[j]>=5 )
							{
								FlagValue[j]=5;
								if(FlagTeam[j]!=Teams[i])
								{
									PrintToChatAll("good team win flag %s", 'A'+j);
									EmitSoundToAll(SOUND_BLIP, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, FlagPoints[MapIndex][j], NULL_VECTOR, false, 0.0);
								}
								FlagTeam[j]=Teams[i];
							}
							else 
							{
								if(FlagValue[j]==-4 )
								{
									PrintToChatAll("bad team lost flag %s", 'A'+j);
								}
								FlagTeam[j]=-1;
								EmitSoundToAll(SOUND_BLIP, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, FlagPoints[MapIndex][j], NULL_VECTOR, false, 0.0);
							}
							PrintHintText(i, "flag %s", 'A'+j);
						}
					}
				}
				
			}
		}
		else
		{
			if (SpawnDelay[i] >0)
			{
				Format(iStatus, sizeof(iStatus), "  (%d/%d) - dead", PlayerKill[i], PlayerDeath[i]);
				SpawnDelay[i]--;
			} 
			else 
			{
				Format(iStatus, sizeof(iStatus), "  wait");
				respawn=i;
			}
			IsShowHud2[i]=true;
		}
 
		Format(iStatus, sizeof(iStatus), "%N  %s", i, iStatus);
		DrawPanelItem  (pInfHUD, iStatus);
		goodteam2++;
	}
	 
	DrawPanelText(pInfHUD, " ");
	Format(iStatus, sizeof(iStatus), "bad  (%d)", TeamWin[1]);
	DrawPanelText(pInfHUD, iStatus);
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) != 2)continue;
		if(Teams[i]!=1)continue;
		
		if (IsPlayerAlive(i))
		{
			badteam++;

			Format(iStatus, sizeof(iStatus), "  (%d/%d)", PlayerKill[i], PlayerDeath[i]);
			button=GetClientButtons(i);
			if(button & IN_SCORE)IsShowHud[i]=!IsShowHud[i];
			if(button & IN_USE)IsShowHud2[i]=true;
			else IsShowHud2[i]=false;
			if(button & IN_DUCK)
			{
				GetClientAbsOrigin(i, pos);
				for(new j=0; j<FlagCount[MapIndex]; j++)
				{
					if(FlagTeam[j]!=Teams[i])
					{
						dis=GetVectorDistance(pos, FlagPoints[MapIndex][j]);
						if(dis<60.0)
						{
							FlagValue[j]+=Teams[i]==0?1:-1;
							if(FlagValue[j]<=-5)
							{
								FlagValue[j]=-5;
								if(FlagTeam[j]!=Teams[i])
								{
									PrintToChatAll("bad team win flag %s", 'A'+j);
									EmitSoundToAll(SOUND_BLIP, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, FlagPoints[MapIndex][j], NULL_VECTOR, false, 0.0);
									
								}
								FlagTeam[j]=Teams[i];
							}							
							else 
							{
								if(FlagValue[j]==4)
								{
									PrintToChatAll("good team lost flag %s", 'A'+j);
								}
								FlagTeam[j]=-1;
								EmitSoundToAll(SOUND_BLIP, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, FlagPoints[MapIndex][j], NULL_VECTOR, false, 0.0);
							}
							PrintHintText(i, "flag %s", 'A'+j);
						}
					}
				}
				
			}
		}
		else
		{
			if (SpawnDelay[i] >0)
			{
				Format(iStatus, sizeof(iStatus), "  (%d/%d) - dead", PlayerKill[i], PlayerDeath[i]);
				SpawnDelay[i]--;
			} 
			else 
			{
				Format(iStatus, sizeof(iStatus), "  wait");
				respawn=i;
			}
			IsShowHud2[i]=true;
		}
 
		Format(iStatus, sizeof(iStatus), "%N-%s", i, iStatus);
		DrawPanelItem  (pInfHUD, iStatus);
		badteam2++;
	}
	 
	DrawPanelText(pInfHUD, " ");
	DrawPanelText(pInfHUD, "flags:");
	Format(iStatus, sizeof(iStatus), "good : ");
	for(i=0; i<FlagCount[MapIndex]; i++)
	{
		if(FlagTeam[i]==0)
		{
			Format(iStatus, sizeof(iStatus), "%s %s", iStatus, 'A'+i);
		}
	}
	DrawPanelText(pInfHUD, iStatus);
	Format(iStatus, sizeof(iStatus), "bad  : ");
	for(i=0; i<FlagCount[MapIndex]; i++)
	{
		if(FlagTeam[i]==1)
		{
			Format(iStatus, sizeof(iStatus), "%s %s", iStatus, 'A'+i);
		}
	}

	DrawPanelText(pInfHUD, iStatus);
	Format(iStatus, sizeof(iStatus), "neutrality : ");
	for(i=0; i<FlagCount[MapIndex]; i++)
	{
		if(FlagTeam[i]==-1)
		{
			Format(iStatus, sizeof(iStatus), "%s %s", iStatus, 'A'+i);
		}
	}
	DrawPanelText(pInfHUD, iStatus);

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if ((GetClientTeam(i) == 2) && (GetClientMenu(i) == MenuSource_RawPanel || GetClientMenu(i) == MenuSource_None))
			{	
				if(IsShowHud[i] || IsShowHud2[i])SendPanelToClient(pInfHUD, i, Menu_InfHUDPanel, 5);
			}
			if ((GetClientTeam(i) == 1) && (GetClientMenu(i) == MenuSource_RawPanel || GetClientMenu(i) == MenuSource_None))
			{	
				SendPanelToClient(pInfHUD, i, Menu_InfHUDPanel, 5);
			}	
		}
	}
	decl Float:pos2[3];
	new goodflag=0;
	new badflag=0;
	for(new j=0; j<FlagCount[MapIndex]; j++)
	{
		pos[0]=FlagPoints[MapIndex][j][0];
		pos[1]=FlagPoints[MapIndex][j][1];
		pos[2]=FlagPoints[MapIndex][j][2];	
		pos2[0]=FlagPoints[MapIndex][j][0];
		pos2[1]=FlagPoints[MapIndex][j][1];	
		if( FlagValue[j]>0)
		{
			pos2[2]=FlagPoints[MapIndex][j][2]+FlagValue[j]*40.0;
			if(FlagTeam[j]==-1)	TE_SetupBeamPoints(pos, pos2, g_sprite, 0, 0, 0, 1.0, 10.0, 10.0, 1, 0.0, FlagColor[2], 0);
			else TE_SetupBeamPoints(pos, pos2, g_sprite, 0, 0, 0, 1.0, 10.0, 10.0, 1, 0.0, FlagColor[0], 0);
			TE_SendToAll();
		}
		if( FlagValue[j]<0)
		{
		

			pos2[2]=FlagPoints[MapIndex][j][2]-FlagValue[j]*40.0;
			if(FlagTeam[j]==-1)	TE_SetupBeamPoints(pos, pos2, g_sprite, 0, 0, 0, 1.0, 10.0, 10.0, 1, 0.0, FlagColor[2], 0);
			else TE_SetupBeamPoints(pos, pos2, g_sprite, 0, 0, 0, 1.0, 10.0, 10.0, 1, 0.0, FlagColor[1], 0);
			TE_SendToAll();			
		}
		if(FlagTeam[j]==-1)
		{
			new Float:width=5.0;
			if(L4D2Version)width = 1.0;
			pos[0]=FlagPoints[MapIndex][j][0];
			pos[1]=FlagPoints[MapIndex][j][1];
			pos[2]=FlagPoints[MapIndex][j][2]+10.0;	
			TE_SetupBeamRingPoint(pos, 10.0, 200.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, width, 0.5, FlagColor[2], 10, 0);
			TE_SendToAll();
		}
		if(FlagTeam[j]==0)goodflag++;
		if(FlagTeam[j]==1)badflag++;
	}
	if(goodflag==FlagCount[MapIndex])// && badteam==0)
	{
		
		wintick=15;
		TeamWin[0]++;
		GameStart=false;	
		WinTimer=CreateTimer(1.0, Win, 0, TIMER_REPEAT);
		ResetVoice();
		
	}
	if(badflag==FlagCount[MapIndex])// && goodteam==1)
	{
		TeamWin[1]++;
		wintick=15;
		GameStart=false;
		ResetVoice();
		WinTimer=CreateTimer(1.0, Win, 1, TIMER_REPEAT);
		
	}
 
	CloseHandle(pInfHUD);

	if(respawn>0)
	{
		CreateTimer(0.1, RespawnPlayer, respawn, TIMER_FLAG_NO_MAPCHANGE);
	}
 
	if( goodteam2-badteam2>2 && GetConVarInt(l4d_cs_teambalance)>0)
	{
		CreateTimer(0.5, TeamBalance, 0);
		PrintCenterTextAll("auto team banlance");
		
	}
	if( badteam2-goodteam2>2 && GetConVarInt(l4d_cs_teambalance)>0)
	{
		CreateTimer(0.5, TeamBalance, 1);
		PrintCenterTextAll("auto team banlance");
	}
}
public Action:TeamBalance(Handle:Timer, any:team)
{
	new c=FindRandomPlayer(team, false);
	if(c>0)
	{
		if(IsPlayerAlive(c))ForcePlayerSuicide(c);
		SDKCall(hRoundRespawn, c);
		Teams[c]=Teams[c]==0?1:0;
		if(Teams[c]==0)	TeleportEntity(c, FlagPoints[MapIndex][0], NULL_VECTOR, NULL_VECTOR);
		if(Teams[c]==1)	TeleportEntity(c, FlagPoints[MapIndex][FlagCount[MapIndex]-1], NULL_VECTOR, NULL_VECTOR);
		SetEntityRenderMode(c, RenderMode:3);
		SetEntityRenderColor(c, TeamColor[Teams[c]][0],  TeamColor[Teams[c]][1], TeamColor[Teams[c]][2], TeamColor[Teams[c]][3]);

	}	
}
public Action:Win(Handle:Timer, any:team)
{
	if(wintick>0)
	{
		wintick--;
		if(team==0)	PrintHintTextToAll("good team win,  round will be started after %d seconds", wintick);
		if(team==1)	PrintHintTextToAll("bad team win,  round will be started after %d seconds", wintick);
		return Plugin_Continue;
	}
	else
	{
		WinTimer=INVALID_HANDLE;
		wintick=0;
		SetConVarInt(FindConVar("director_no_death_check"), 0);
		
		for(new client=1;client<=MaxClients; client++)
		{
			if (IsClientInGame(client) && GetClientTeam(client)==2 && IsPlayerAlive(client))
			{
				ForcePlayerSuicide(client);
			}
		}
		return Plugin_Stop;
	}
	
}
public Action:RespawnPlayer(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && GetClientTeam(client)==2 && !IsPlayerAlive(client) && SpawnDelay[client]==0)
	{
		
		new f=FindRandomPlayer(Teams[client]);
		if(f>0)
		{
			SDKCall(hRoundRespawn, client);
			decl Float:pos[3];
			GetClientAbsOrigin(f, pos);
			pos[2]+=50.0;
			TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
			//PrintToChatAll("find %N", f);
		}
		else 
		{
			f=FindRandomFlag(Teams[client]);
			if(f!=-1)
			{
				SDKCall(hRoundRespawn, client);
				TeleportEntity(client, FlagPoints[MapIndex][f], NULL_VECTOR, NULL_VECTOR);
				//PrintToChatAll("find %d", f);
			}
			else 
			{
				f=FindRandomFlag(-1);
				if(f!=-1)
				{
					SDKCall(hRoundRespawn, client);
					TeleportEntity(client, FlagPoints[MapIndex][f], NULL_VECTOR, NULL_VECTOR);
					//PrintToChatAll("find2 %d", f);
				}
			}
		}
		
	}
}

GlowSet(client, bool:show)
{
	if(client<=0)return;
	if(!IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}
	if(!show)
	{
			ClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_r 0.0");
			
	}
	else
	{
		
			ClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.4");
			ClientCommand(client, "cl_glow_survivor_hurt_r 1.0");
		 
	}
	if(!show)
	{
			ClientCommand(client, "cl_glow_survivor_vomit_b 0.0");
			ClientCommand(client, "cl_glow_survivor_vomit_g 0.0");
			ClientCommand(client, "cl_glow_survivor_vomit_r 0.0");
	}
	else
	{
		
			ClientCommand(client, "cl_glow_survivor_vomit_b 0.0");
			ClientCommand(client, "cl_glow_survivor_vomit_g 0.4");
			ClientCommand(client, "cl_glow_survivor_vomit_r 1.0");

	}
	if(!show)
	{

			
			ClientCommand(client, "cl_glow_survivor_b 0.0");
			ClientCommand(client, "cl_glow_survivor_g 0.0");
			ClientCommand(client, "cl_glow_survivor_r 0.0");
	}
	else
	{

			
			ClientCommand(client, "cl_glow_survivor_b 1.0");
			ClientCommand(client, "cl_glow_survivor_g 0.4");
			ClientCommand(client, "cl_glow_survivor_r 0.3");
	}
 
 
	return;
}
public GlowSetInL4D2(bool:mode)
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
 StripAndExecuteServerCommand(String:command[] ) {
        new flags = GetCommandFlags(command);
        SetCommandFlags(command, flags & ~FCVAR_CHEAT);
        ServerCommand(command);
        SetCommandFlags(command, flags);
}