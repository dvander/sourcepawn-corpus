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
#define ZOMBIECLASS_WITCH	7
#define ZOMBIECLASS_TANK	8


#define M_hunter "models/infected/hunter.mdl" 
#define M_smoker "models/infected/smoker.mdl" 
#define M_boomer1 "models/infected/boomer.mdl" 
#define M_boomer2 "models/infected/boomette.mdl" 
#define M_boomer3 "models/infected/limbs/exploded_boomer.mdl" 
#define M_jockey "models/infected/jockey.mdl" 
#define M_spitter "models/infected/spitter.mdl" 
#define M_charger "models/infected/charger.mdl" 
#define M_tank "models/infected/hulk.mdl" 
#define M_witch "models/infected/witch.mdl" 

#define M_fireman "models/infected/common_male_ceda.mdl" 

#define M_noooo "" 
 

new String:Ms[9][9][100]=
{
					{M_noooo, M_noooo, M_noooo, M_noooo, M_noooo, M_noooo, M_noooo, M_noooo, M_noooo},
	/* smoker  */ {M_tank, M_boomer1, M_witch, /*l4d2*/ M_boomer2, M_jockey,M_spitter,M_charger,M_noooo, M_noooo},
	/* boomer  */ {M_tank, M_boomer3, M_witch, /*l4d2*/ M_spitter,M_charger,M_fireman,M_noooo,M_noooo, M_noooo},
	/* hunter  */ {M_tank, M_boomer1, M_witch, /*l4d2*/ M_boomer2, M_boomer3, M_smoker, M_jockey,M_spitter,M_charger},	
	
	/* spitter */ {M_tank,M_boomer2, M_boomer1, M_boomer3, M_jockey, M_charger,M_fireman, M_noooo, M_noooo},
	/* jockey  */ {M_tank,M_witch, M_boomer2, M_boomer3,M_spitter,M_charger, M_noooo, M_noooo, M_noooo },
	/* charger */ {M_tank,M_witch, M_boomer2,M_spitter, M_noooo, M_noooo, M_noooo, M_noooo, M_noooo},
	/* witch   */ {M_tank, M_boomer1, M_boomer3, /*l4d2*/ M_boomer2, M_jockey, M_spitter, M_charger, M_noooo, M_noooo},
	/* tank    */ {M_tank, M_noooo, M_noooo, M_noooo, M_noooo, M_noooo, M_noooo, M_noooo, M_noooo}
};
new Count[9][2]=
{
	{0, 0},
	/* smoker  */ {3, 7},
	/* boomer  */ {3, 6},
	/* hunter  */ {3, 9},
	
	/* spitter */ {0, 7},
	/* jockey  */ {0, 6},
	/* charger */ {0, 4},
	/* witch   */ {3, 7},
	/* tank    */ {1, 1}
};
new gColor[9][3]=
{
	{0, 0, 0},
	/* smoker  */ {0,0, 255},
	/* boomer  */ {255,84,  52},
	/* hunter  */ {98, 128, 122},

	/* spitter */ {0, 255, 0},	
	/* jockey  */ {255,255,0},
	/* charger */ {255, 255, 255},
	/* witch   */ {255, 0, 0},
	/* tank    */ {255, 0, 0}
};

new Handle:l4d_disguise_probability[9];
new Handle:l4d_disguise_enable= INVALID_HANDLE;
new Handle:l4d_disguise_colored= INVALID_HANDLE;
new Handle:l4d_disguise_colored_witch= INVALID_HANDLE;
new GameMode;
new bool:L4D2Version;
public Plugin:myinfo = 
{
	name = "disguise",
	author = "Pan Xiaohai",
	description = "disguise",
	version = PLUGIN_VERSION,	
}

public OnPluginStart()
{
	
	GameCheck(); 	
 
	l4d_disguise_enable = CreateConVar("l4d_disguise_enable", "1", "SI disguise 0:disable, 1:eanble ", FCVAR_PLUGIN);

 	l4d_disguise_probability[ZOMBIECLASS_HUNTER]  = CreateConVar("l4d_disguise_probability_hunter",  "50", "probalility of a hunter become a disguised hunter[0.0-100.0]", FCVAR_PLUGIN);
 	l4d_disguise_probability[ZOMBIECLASS_SMOKER]  = CreateConVar("l4d_disguise_probability_smoker",  "20", "", FCVAR_PLUGIN);	
 	l4d_disguise_probability[ZOMBIECLASS_BOOMER]  = CreateConVar("l4d_disguise_probability_boomer",  "20", "", FCVAR_PLUGIN);
 	l4d_disguise_probability[ZOMBIECLASS_JOCKEY]  = CreateConVar("l4d_disguise_probability_jockey",  "20", "", FCVAR_PLUGIN);
 	l4d_disguise_probability[ZOMBIECLASS_SPITTER] = CreateConVar("l4d_disguise_probability_spitter", "30", "", FCVAR_PLUGIN);	
	l4d_disguise_probability[ZOMBIECLASS_CHARGER] = CreateConVar("l4d_disguise_probability_charger", "10", "", FCVAR_PLUGIN);
  	l4d_disguise_probability[ZOMBIECLASS_WITCH]   = CreateConVar("l4d_disguise_probability_witch",   "60",  "", FCVAR_PLUGIN);
	l4d_disguise_probability[ZOMBIECLASS_TANK] =    CreateConVar("l4d_disguise_probability_tank",    "0",  "", FCVAR_PLUGIN);
	
	l4d_disguise_colored=    						CreateConVar("l4d_disguise_colored",    "50",  "probalility of a disguised SI change its color[0.0-100.0]", FCVAR_PLUGIN);
	l4d_disguise_colored_witch=     				CreateConVar("l4d_disguise_colored_witch",    "10",  "probalility of a disguised witch change its color[0.0-100.0]", FCVAR_PLUGIN);  
	
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("witch_spawn", Event_Witch_Spawn);
	AutoExecConfig(true, "l4d_disguise_en");
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
public OnMapStart()
{

	PrecacheModel( M_hunter , true );
	PrecacheModel( M_smoker , true );
	PrecacheModel( M_boomer1 , true );
	PrecacheModel( M_tank , true );
	PrecacheModel( M_witch , true );	
	PrecacheModel( M_boomer3 , true );
	if(L4D2Version)
	{
		PrecacheModel( M_jockey , true );
		PrecacheModel( M_spitter , true );
		PrecacheModel( M_charger , true );
		PrecacheModel( M_boomer2 , true );
			
		PrecacheModel( M_fireman , true );
 	}
 }
public Action:Event_Player_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GameMode==2 || GetConVarInt(l4d_disguise_enable)==0) return Plugin_Continue; 
	new client  = GetClientOfUserId(GetEventInt(event, "userid"));
  	if(GetClientTeam(client) == 3)
	{
	 	new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if(!L4D2Version && class==5)class=ZOMBIECLASS_TANK;
 		new Float:p=GetConVarFloat(l4d_disguise_probability[class]);
		new Float:r=GetRandomFloat(0.0, 100.0);
		if(r<p)	CreateTimer(1.0, CreateDisguiseBoss, client);
	}
  	return Plugin_Continue;
}
public Action:Event_Witch_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{ 
	if(GameMode==2 || GetConVarInt(l4d_disguise_enable)==0) return Plugin_Continue; 
	new witchid  = GetEventInt(event, "witchid");	
	new class = ZOMBIECLASS_WITCH;
	new count=Count[class][L4D2Version];
	new Float:p=GetConVarFloat(l4d_disguise_probability[class]);
	new Float:r=GetRandomFloat(0.0, 100.0);
	if(r<p)	
	{
		SetEntityModel(witchid, Ms[class][GetRandomInt(0, count-1)]);
		r=GetRandomFloat(0.0, 100.0);
		if(r<GetConVarFloat(l4d_disguise_colored_witch))
		{
			SetEntityRenderMode(witchid, RenderMode:0);
			SetEntityRenderColor(witchid,  gColor[class][0], gColor[class][1], gColor[class][2], 255);
		}
	}
  	return Plugin_Continue;
}
public Action:CreateDisguiseBoss(Handle:timer, any:client)
{
	if ( IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
	 	
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if(!L4D2Version && class==5)class=ZOMBIECLASS_TANK;
 
		new count=Count[class][L4D2Version];
		if(count>0)	SetEntityModel(client, Ms[class][GetRandomInt(0, count-1)]);

		new Float:r=GetRandomFloat(0.0, 100.0);
		if(r<GetConVarFloat(l4d_disguise_colored))
		{
			SetEntityRenderMode(client, RenderMode:0);
			SetEntityRenderColor(client, gColor[class][0], gColor[class][1], gColor[class][2], 255);	
		}
 	}
	return;
}