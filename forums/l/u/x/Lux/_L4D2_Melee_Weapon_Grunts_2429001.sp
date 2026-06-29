#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sceneprocessorMG>

#define MAX_ROCHELLESOUND      8
#define MAX_ELLISSOUND         6
#define MAX_NICKSOUND          14
#define MAX_COACHSOUND         18

#define MAX_FRANCISSOUND	   11
#define MAX_ZOEYSOUND		   9
#define MAX_LOUISSOUND		   7
#define MAX_BILLSOUND		   10

#define MAX_ELLISRESPONSE 	   9

static g_iCombatGruntChance;
static g_iEllisCommentChance;
static bool:g_bGruntCoolDown[MAXPLAYERS + 1] = false;

/* This plugin is simply a modification of Sir's  Sound manipulation plugin
* found here https://github.com/SirPlease/SirCoding 
* Credits to him! */
public Plugin:myinfo = 
{
	name = "L4D2 Melee Weapon Grunts", 
	author = "DeathChaos25 & Ludastar", 
	description = "Makes (currently L4D2 only)survivor vocalize their unused Combat Grunts when swinging a melee weapon", 
	version = "1.2", 
	url = "https://forums.alliedmods.net/showthread.php?t=259596"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead2", false))
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead 2 Only!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	HookEvent("infected_decapitated", Event_HeadShot);
	HookEvent("infected_death", Event_HeadShot2);
	HookEvent("weapon_fire", Event_WeaponFire);
	
	new Handle:CombatGruntChance = CreateConVar("combat_grunt_chance", "50", "Chance out of 100 (i.e 25 for 25% chance) that a survivor will vocalize their combat grunts when using their melee weapon", FCVAR_PLUGIN, true, 1.0, true, 100.0);
	HookConVarChange(CombatGruntChance, ConVarCombatGrunt);
	g_iCombatGruntChance = GetConVarInt(CombatGruntChance);
	
	new Handle:EllisCommentChance = CreateConVar("ellis_comment_chance", "25", "Chance out of 100 (i.e 25 for 25% chance) that a Ellis will make a comment when beheading a common infected with a melee weapon", FCVAR_PLUGIN, true, 1.0, true, 100.0);
	HookConVarChange(EllisCommentChance, ConVarEllisComment);
	g_iEllisCommentChance = GetConVarInt(EllisCommentChance);
	
	AutoExecConfig(true, "l4d2_melee_weapon_grunts");
}
new const String:sCoachSound[MAX_COACHSOUND + 1][] = 
{
	"player/survivor/voice/coach/meleeswing01.wav", 
	"player/survivor/voice/coach/meleeswing02.wav", 
	"player/survivor/voice/coach/meleeswing03.wav", 
	"player/survivor/voice/coach/meleeswing04.wav", 
	"player/survivor/voice/coach/meleeswing05.wav", 
	"player/survivor/voice/coach/meleeswing06.wav", 
	"player/survivor/voice/coach/meleeswing07.wav", 
	"player/survivor/voice/coach/meleeswing08.wav", 
	"player/survivor/voice/coach/meleeswing09.wav", 
	"player/survivor/voice/coach/meleeswing10.wav", 
	"player/survivor/voice/coach/meleeswing11.wav", 
	"player/survivor/voice/coach/meleeswing12.wav", 
	"player/survivor/voice/coach/meleeswing13.wav", 
	"player/survivor/voice/coach/meleeswing14.wav", 
	"player/survivor/voice/coach/meleeswing15.wav", 
	"player/survivor/voice/coach/meleeswing16.wav", 
	"player/survivor/voice/coach/meleeswing17.wav", 
	"player/survivor/voice/coach/meleeswing18.wav", 
	"player/survivor/voice/coach/meleeswing19.wav"
};

new const String:sRochelleSound[MAX_ROCHELLESOUND + 1][] = 
{
	"player/survivor/voice/producer/meleeswing01.wav", 
	"player/survivor/voice/producer/meleeswing02.wav", 
	"player/survivor/voice/producer/meleeswing03.wav", 
	"player/survivor/voice/producer/meleeswing04.wav", 
	"player/survivor/voice/producer/meleeswing05.wav", 
	"player/survivor/voice/producer/meleeswing06.wav", 
	"player/survivor/voice/producer/meleeswing07.wav", 
	"player/survivor/voice/producer/meleeswing08.wav", 
	"player/survivor/voice/producer/meleeswing09.wav"
};

new const String:sEllisSound[MAX_ELLISSOUND + 1][] = 
{
	"player/survivor/voice/mechanic/meleeswing01.wav", 
	"player/survivor/voice/mechanic/meleeswing02.wav", 
	"player/survivor/voice/mechanic/meleeswing03.wav", 
	"player/survivor/voice/mechanic/meleeswing04.wav", 
	"player/survivor/voice/mechanic/meleeswing05.wav", 
	"player/survivor/voice/mechanic/meleeswing06.wav", 
	"player/survivor/voice/mechanic/meleeswing07.wav"
};

new const String:sNickSound[MAX_NICKSOUND + 1][] = 
{
	"player/survivor/voice/gambler/meleeswing01.wav", 
	"player/survivor/voice/gambler/meleeswing02.wav", 
	"player/survivor/voice/gambler/meleeswing03.wav", 
	"player/survivor/voice/gambler/meleeswing04.wav", 
	"player/survivor/voice/gambler/meleeswing05.wav", 
	"player/survivor/voice/gambler/meleeswing06.wav", 
	"player/survivor/voice/gambler/meleeswing07.wav", 
	"player/survivor/voice/gambler/meleeswing08.wav", 
	"player/survivor/voice/gambler/meleeswing09.wav", 
	"player/survivor/voice/gambler/meleeswing10.wav", 
	"player/survivor/voice/gambler/meleeswing11.wav", 
	"player/survivor/voice/gambler/meleeswing12.wav", 
	"player/survivor/voice/gambler/meleeswing13.wav", 
	"player/survivor/voice/gambler/meleeswing14.wav", 
	"player/survivor/voice/gambler/meleeswing15.wav"
};

new const String:sFrancisSound[MAX_FRANCISSOUND + 1][] = 
{
	"player/survivor/voice/biker/hurtminor02.wav", 
	"player/survivor/voice/biker/hurtminor04.wav", 
	"player/survivor/voice/biker/hurtminor07.wav", 
	"player/survivor/voice/biker/hurtminor08.wav", 
	"player/survivor/voice/biker/positivenoise02.wav", 
	"player/survivor/voice/biker/shoved01.wav", 
	"player/survivor/voice/biker/shoved02.wav", 
	"player/survivor/voice/biker/shoved03.wav", 
	"player/survivor/voice/biker/shoved04.wav", 
	"player/survivor/voice/biker/shoved05.wav", 
	"player/survivor/voice/biker/shoved06.wav", 
	"player/survivor/voice/biker/shoved07.wav"
};

new const String:sZoeySound[MAX_ZOEYSOUND + 1][] = 
{
	"player/survivor/voice/teengirl/hordeatttack10.wav", 
	"player/survivor/voice/teengirl/hordeattack29.wav", 
	"player/survivor/voice/teengirl/hurtminor03.wav", 
	"player/survivor/voice/teengirl/shoved01.wav", 
	"player/survivor/voice/teengirl/shoved02.wav", 
	"player/survivor/voice/teengirl/shoved03.wav", 
	"player/survivor/voice/teengirl/shoved04.wav", 
	"player/survivor/voice/teengirl/shoved05.wav", 
	"player/survivor/voice/teengirl/shoved06.wav", 
	"player/survivor/voice/teengirl/shoved14.wav"
};

new const String:sLouisSound[MAX_LOUISSOUND + 1][] = 
{
	"player/survivor/voice/manager/hurtminor02.wav", 
	"player/survivor/voice/manager/hurtminor05.wav", 
	"player/survivor/voice/manager/hurtminor06.wav", 
	"player/survivor/voice/manager/shoved01.wav", 
	"player/survivor/voice/manager/shoved02.wav", 
	"player/survivor/voice/manager/shoved03.wav", 
	"player/survivor/voice/manager/shoved04.wav", 
	"player/survivor/voice/manager/shoved05.wav"
};

new const String:sBillSound[MAX_BILLSOUND + 1][] = 
{
	"player/survivor/voice/namvet/hurtminor02.wav", 
	"player/survivor/voice/namvet/hurtminor05.wav", 
	"player/survivor/voice/namvet/hurtminor07.wav", 
	"player/survivor/voice/namvet/hurtminor08.wav", 
	"player/survivor/voice/namvet/shoved01.wav", 
	"player/survivor/voice/namvet/shoved02.wav", 
	"player/survivor/voice/namvet/shoved03.wav", 
	"player/survivor/voice/namvet/shoved04.wav", 
	"player/survivor/voice/namvet/shoved05.wav", 
	"player/survivor/voice/namvet/positivenoise03.wav", 
	"player/survivor/voice/namvet/reactionstartled01.wav"
};

new const String:sEllisResponse[MAX_ELLISRESPONSE + 1][] = 
{
	"player/survivor/voice/mechanic/meleeresponse01.wav", 
	"player/survivor/voice/mechanic/meleeresponse02.wav", 
	"player/survivor/voice/mechanic/meleeresponse03.wav", 
	"player/survivor/voice/mechanic/meleeresponse04.wav", 
	"player/survivor/voice/mechanic/meleeresponse05.wav", 
	"player/survivor/voice/mechanic/meleeresponse06.wav", 
	"player/survivor/voice/mechanic/meleeresponse07.wav", 
	"player/survivor/voice/mechanic/meleeresponse08.wav", 
	"player/survivor/voice/mechanic/meleeresponse09.wav", 
	"player/survivor/voice/mechanic/meleeresponse10.wav"
};

new const String:sEllisScenes[MAX_ELLISRESPONSE + 1][] = 
{
	"scenes/mechanic/meleeresponse01.vcd", 
	"scenes/mechanic/meleeresponse02.vcd", 
	"scenes/mechanic/meleeresponse03.vcd", 
	"scenes/mechanic/meleeresponse04.vcd", 
	"scenes/mechanic/meleeresponse05.vcd", 
	"scenes/mechanic/meleeresponse06.vcd", 
	"scenes/mechanic/meleeresponse07.vcd", 
	"scenes/mechanic/meleeresponse08.vcd", 
	"scenes/mechanic/meleeresponse09.vcd", 
	"scenes/mechanic/meleeresponse10.vcd"
};

public OnMapStart()
{
	for (new i = 0; i <= MAX_ROCHELLESOUND; i++)
	{
		PrecacheSound(sRochelleSound[i], true);
	}
	
	for (new i = 0; i <= MAX_NICKSOUND; i++)
	{
		PrecacheSound(sNickSound[i], true);
	}
	
	for (new i = 0; i <= MAX_ELLISSOUND; i++)
	{
		PrecacheSound(sEllisSound[i], true);
	}
	
	for (new i = 0; i <= MAX_COACHSOUND; i++)
	{
		PrecacheSound(sCoachSound[i], true);
	}
	
	for (new i = 0; i <= MAX_FRANCISSOUND; i++)
	{
		PrecacheSound(sFrancisSound[i], true);
	}
	
	for (new i = 0; i <= MAX_LOUISSOUND; i++)
	{
		PrecacheSound(sLouisSound[i], true);
	}
	
	for (new i = 0; i <= MAX_ZOEYSOUND; i++)
	{
		PrecacheSound(sZoeySound[i], true);
	}
	
	for (new i = 0; i <= MAX_BILLSOUND; i++)
	{
		PrecacheSound(sBillSound[i], true);
	}
	
	for (new i = 0; i <= MAX_ELLISRESPONSE; i++)
	{
		PrecacheSound(sEllisResponse[i], true);
	}
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapon[6];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if(weapon[0] != 'm' || !StrEqual(weapon, "melee"))
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_bGruntCoolDown[client] || !IsPlayerAlive(client) || GetClientTeam(client) != 2 || IsActorBusy(client))
		return;
	
	new i_GruntChance = GetRandomInt(1, 100);
	if (i_GruntChance > g_iCombatGruntChance)
		return;
	
	g_bGruntCoolDown[client] = true;
	CreateTimer(0.5, GruntCoolDown, client);// cooldown to prevent soundspamm from trying to melee while stumbled
	
	decl String:sModel[31];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	switch(sModel[29])
	{
		case 'b'://nick
		{
			new rndPick = GetRandomInt(0, MAX_NICKSOUND);
			EmitSoundToAll(sNickSound[rndPick], client, SNDCHAN_VOICE);
		}
		case 'd'://rochelle
		{
			new rndPick = GetRandomInt(0, MAX_ROCHELLESOUND);
			EmitSoundToAll(sRochelleSound[rndPick], client, SNDCHAN_VOICE);
		}
		case 'c'://coach
		{
			new rndPick = GetRandomInt(0, MAX_COACHSOUND);
			EmitSoundToAll(sCoachSound[rndPick], client, SNDCHAN_VOICE);
		}
		case 'h'://ellis
		{
			new rndPick = GetRandomInt(0, MAX_ELLISSOUND);
			EmitSoundToAll(sEllisSound[rndPick], client, SNDCHAN_VOICE);
		}
		case 'v'://bill
		{
			new rndPick = GetRandomInt(0, MAX_BILLSOUND);
			EmitSoundToAll(sBillSound[rndPick], client, SNDCHAN_VOICE);
		}
		case 'n'://zoey
		{
			new rndPick = GetRandomInt(0, MAX_ZOEYSOUND);
			EmitSoundToAll(sZoeySound[rndPick], client, SNDCHAN_VOICE);
		}
		case 'e'://francis
		{
			new rndPick = GetRandomInt(0, MAX_FRANCISSOUND);
			EmitSoundToAll(sFrancisSound[rndPick], client, SNDCHAN_VOICE);
		}
		case 'a'://louis
		{
			new rndPick = GetRandomInt(0, MAX_LOUISSOUND);
			EmitSoundToAll(sLouisSound[rndPick], client, SNDCHAN_VOICE);
		}
	}
}

public Event_HeadShot(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client < 1 || client > MaxClients) 
		return;
	
	if (!IsClientInGame(client) || GetClientTeam(client) != 2)
		return;
	
	decl String:sModel[31];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	switch(sModel[29]) 
	{
		case 'h': //ellis
		{
			new i_CommentChance, i;	
			i_CommentChance = GetRandomInt(1, 100);
			if (i_CommentChance > g_iEllisCommentChance || IsActorBusy(client)) 
				return;
			
			i = GetRandomInt(0, MAX_ELLISRESPONSE);
			PerformSceneEx(client, "", sEllisScenes[i], 0.0, _, SCENE_INITIATOR_WORLD);
			EmitSoundToAll(sEllisResponse[i], client, SNDCHAN_VOICE);
		}
	}
}

public Event_HeadShot2(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetEventBool(event, "headshot"))
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (client < 1 || client > MaxClients) 
		return;
	
	if (!IsClientInGame(client) || GetClientTeam(client) != 2)
		return;
	
	decl String:sModel[31];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	switch(sModel[29])
	{
		case 'h': //ellis
		{
			new i_CommentChance, i;
			i_CommentChance = GetRandomInt(1, 100);
			if (i_CommentChance > g_iEllisCommentChance || IsActorBusy(client)) 
				return;
			
			i = GetRandomInt(0, MAX_ELLISRESPONSE);
			PerformSceneEx(client, "", sEllisScenes[i], 0.0, _, SCENE_INITIATOR_WORLD);
			EmitSoundToAll(sEllisResponse[i], client, SNDCHAN_VOICE);
		}
	}
	
}
public ConVarCombatGrunt(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iCombatGruntChance = GetConVarInt(convar);
}

public ConVarEllisComment(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iEllisCommentChance = GetConVarInt(convar);
}

public Action:GruntCoolDown(Handle:hTimer, any:client)
{
	g_bGruntCoolDown[client] = false;
}