#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

#define PL_VERSION "1.32"
#define HITSOUND "weapons/fist_hit_world2.wav"
//#define MISSSOUND "ui/duel_score_behind.wav"

new const String:g_Taunts[][] = { "taunt_highFiveSuccessFull", "taunt_hifiveSuccessFull" };	//{ "taunt_highFiveFail", "taunt_highFiveFailFull", "taunt_highFiveSuccess", "taunt_highFiveSuccessFull", "taunt_hifiveFail", "taunt_hifiveFailFull", "taunt_hifiveSuccess", "taunt_hifiveSuccessFull"  };
new const Float:g_TauntTimes[] = { 0.0, 4.2, 3.8, 4.2, 4.2, 4.0, 4.2, 4.2, 4.3, 4.3 };
//	{ 0.0, 0.0, 0.0, 0.0 } /* Unknown */,
//	{ 4.2, 4.2, 4.2, 4.2 } /* Scout */,
//	{ 4.0, 4.0, 4.0, 3.8 } /* Sniper */, 	
//	{ 4.2, 4.2, 4.2, 4.2 } /* Soldier */,
//	{ 4.2, 4.2, 4.2, 4.2 } /* Demoman */,
//	{ 4.2, 4.2, 4.0, 4.0 } /* Medic */, 
//	{ 4.7, 4.6, 3.8, 4.2 } /* Heavy */,	
//	{ 4.0, 4.0, 4.2, 4.2 } /* Pyro */,
//	{ 4.0, 4.0, 4.0, 4.3 } /* Spy */,
//	{ 0.0, 0.0, 0.0, 0.0 } /* Engineer */
//};

new bool:g_Taunting[MAXPLAYERS+1] = false;
new g_ClientTauntEntity[MAXPLAYERS+1] = 0;
new Handle:g_CVarCooldownTime;
new Handle:g_CVarAllowEnemy;
//new Handle:g_CVarMissSound;

public Plugin:myinfo = 
{
	name = "[TF2] High-Five",
	author = "Geit (modified by FlaminSarge)",
	description = "Allows players to High-Five Teammates.",
	version = PL_VERSION,
	url = "http://gamingmasters.co.uk"
};

public OnPluginStart()
{
	CreateConVar("sm_high_five_version", PL_VERSION, "[TF2] High-Five Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CVarCooldownTime = CreateConVar("sm_high_five_cooldown", "3.0", "Cooldown time for high-five taunts.", _, true, 0.0);
	g_CVarAllowEnemy = CreateConVar("sm_high_five_enemy", "0", "Allow people to high-five enemies.", _, true, 0.0, true, 1.0);
//	g_CVarMissSound =  CreateConVar("sm_high_five_miss_sound", "1", "Play the miss sound if the player's high-five is unsuccessful.", _, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_highfive", Command_HighFive, "High-Five another player.");
	
	HookEvent("player_death", Event_PlayerDeath);
}

public OnClientDisconnect(client)
{
	g_Taunting[client] = false;
}

public OnMapStart()
{
	PrecacheSound(HITSOUND);
//	PrecacheSound(MISSSOUND); 
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_Taunting[client] && g_ClientTauntEntity[client] > 0 && IsValidEdict(g_ClientTauntEntity[client]))
	{
		AcceptEntityInput(g_ClientTauntEntity[client], "Kill");
	}
	return Plugin_Continue;
}

public Action:Command_HighFive(client, args)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new client2 = GetClientAimTarget(client, true);
		if(client2 > 0 && IsPlayerAlive(client2) && IsClientInGame(client2))
		{
			new clientCondFlags = TF2_GetPlayerConditionFlags(client);
			new client2CondFlags = TF2_GetPlayerConditionFlags(client2);
			if (g_Taunting[client] || g_Taunting[client2] || 
				clientCondFlags & TF_CONDFLAG_TAUNTING ||  
				client2CondFlags & TF_CONDFLAG_TAUNTING ||
				clientCondFlags & TF_CONDFLAG_ZOOMED ||  
				client2CondFlags & TF_CONDFLAG_ZOOMED ||
				clientCondFlags & TF_CONDFLAG_SLOWED ||  
				client2CondFlags & TF_CONDFLAG_SLOWED ||
				clientCondFlags & TF_CONDFLAG_CLOAKED ||  
				client2CondFlags & TF_CONDFLAG_CLOAKED ||
				clientCondFlags & TF_CONDFLAG_UBERCHARGED ||  
				client2CondFlags & TF_CONDFLAG_UBERCHARGED ||
				clientCondFlags & TF_CONDFLAG_DAZED ||  
				client2CondFlags & TF_CONDFLAG_DAZED ||
				clientCondFlags & TF_CONDFLAG_CHARGING ||  
				client2CondFlags & TF_CONDFLAG_CHARGING)
			{
				return Plugin_Handled;
			}
			if (GetClientTeam(client) != GetClientTeam(client2) && !GetConVarBool(g_CVarAllowEnemy))
			{
				PrintToChat(client, "[SM] Target must be on your team");
				return Plugin_Handled;
			}
			if (GetClientAimTarget(client2, true) != client)
			{
				PrintToChat(client, "[SM] Target must be looking at you");
				return Plugin_Handled;
			}
			new Float:clientPos[3], Float:client2Pos[3];
			GetClientEyePosition(client, clientPos);
			GetClientEyePosition(client2, client2Pos);
			if (clientPos[2] - client2Pos[2] > 10 || clientPos[2] - client2Pos[2] < -10)
			{
				PrintToChat(client, "[SM] Target must be level with you");
				return Plugin_Handled;
			}
			new Float:DistanceApart = GetVectorDistance(clientPos, client2Pos, false);
			if (DistanceApart < 50 || DistanceApart > 78)
			{
				PrintToChat(client, "[SM] Target get is too close or too far away (%f)", DistanceApart);
				return Plugin_Handled;
			}
/*			if (TF2_GetPlayerClass(client) == TFClass_Engineer || TF2_GetPlayerClass(client2) == TFClass_Engineer )
			{
				PrintToChat(client, "[SM] You may not do this as an Engineer");
				return Plugin_Handled;
			}*/
			

			SetAlpha(client, 0);
			SetAlpha(client2, 0);
			TF2_StunPlayer(client, g_TauntTimes[TF2_GetPlayerClass(client)], 1.0, TF_STUNFLAGS_LOSERSTATE);
			TF2_StunPlayer(client2, g_TauntTimes[TF2_GetPlayerClass(client2)], 1.0, TF_STUNFLAGS_LOSERSTATE);
			AttachNewPlayerModel(client, 1);
			AttachNewPlayerModel(client2, 1);
			CreateTimer(g_TauntTimes[TF2_GetPlayerClass(client)], Timer_HighFive, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(g_TauntTimes[TF2_GetPlayerClass(client2)], Timer_HighFive, GetClientUserId(client2), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(2.0, Timer_HighFiveSuccessSound, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);	
			return Plugin_Handled;
		}
		else
		{
			PrintToChat(client, "[SM] Invalid Target");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public AttachNewPlayerModel(client, TauntToUse)
{	
	g_Taunting[client] = true;
	decl String:ClientModel[256];
	GetClientModel(client, ClientModel, sizeof(ClientModel)); 
	if (StrContains(ClientModel, "pyro", false) != -1 || StrContains(ClientModel, "soldier", false) != -1 || StrContains(ClientModel, "scout", false) != -1 || StrContains(ClientModel, "medic", false) != -1) 
	{	// new: taunt_hifiveSuccessFull: spy, sniper, heavy, demo, engineer
		// taunt_highFiveSuccessFull: pyro, soldier, scout, medic
		TauntToUse = 0;
	}
	new Model = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(Model))
	{
		new Float:pos[3], Float:angles[3];
		decl String:Skin[2];
		
//		GetClientModel(client, ClientModel, sizeof(ClientModel));
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(Model, pos, NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		angles[2] = 0.0;
		IntToString(GetClientTeam(client)-2, Skin, sizeof(Skin));
		
		DispatchKeyValue(Model, "skin", Skin);
		DispatchKeyValue(Model, "model", ClientModel);
		DispatchKeyValue(Model, "DefaultAnim", g_Taunts[TauntToUse]);	
		DispatchKeyValueVector(Model, "angles", angles);
		
		DispatchSpawn(Model);
		SetVariantString(g_Taunts[TauntToUse]);
		AcceptEntityInput(Model, "SetAnimation");
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(Model, "AddOutput");
		CreateTimer(5.0, Timer_KillModel, EntIndexToEntRef(Model), TIMER_FLAG_NO_MAPCHANGE);
		g_ClientTauntEntity[client] = Model;
	}
}

stock SetAlpha (target, alpha)
{
	SetWeaponsAlpha(target,alpha);
	SetWearablesAlpha(target, alpha);
	SetEntityRenderMode(target, RENDER_TRANSCOLOR);
	SetEntityRenderColor(target, 255, 255, 255, alpha);
}

stock SetWeaponsAlpha (target, alpha){
	decl String:classname[64];
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
	for(new i = 0, weapon; i < 189; i += 4)
	{
		weapon = GetEntDataEnt2(target, m_hMyWeapons + i);
		if(weapon > -1 && IsValidEdict(weapon))
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
			if(StrContains(classname, "tf_weapon", false) != -1 || StrContains(classname, "tf_wearable", false) != -1)
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, alpha);
			}
		}
	}
}

stock SetWearablesAlpha (target, alpha){
	if(IsPlayerAlive(target))
	{
		new Float:pos[3], Float:wearablepos[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
		new wearable= -1;
		while ((wearable= FindEntityByClassname2(wearable, "tf_wearable")) != -1)
		{
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos); // Thanks to Psychonic! :D
			if (GetVectorDistance(pos, wearablepos, true) < 2)
			{
				SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wearable, 255, 255, 255, alpha);
			}
		}
		while ((wearable= FindEntityByClassname2(wearable, "tf_wearable_demoshield")) != -1)
		{
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos); // Thanks to Psychonic! :D
			if (GetVectorDistance(pos, wearablepos, true) < 2)
			{
				SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wearable, 255, 255, 255, alpha);
			}
		}
	}
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
public Action:Timer_HighFive(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0 &&IsClientInGame(client))
	{
		
		SetAlpha(client, 255);
		CreateTimer(GetConVarFloat(g_CVarCooldownTime), Timer_HighFiveCooldown, userid, TIMER_FLAG_NO_MAPCHANGE);
		if (IsPlayerAlive(client))
			SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

public Action:Timer_HighFiveCooldown(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0 &&IsClientInGame(client))
	{
		g_Taunting[client]=false;
	}
}

public Action:Timer_HighFiveSuccessSound(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:clientPos[3];
		GetClientEyePosition(client, clientPos);
		EmitSoundToAll(HITSOUND, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL,-1 , clientPos, NULL_VECTOR);
	}
	//TO-DO: Add Positive voice lines appropriate the the client's class here. (KV File)
}

/*public Action:Timer_HighFiveMissSound(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:clientPos[3];
		GetClientEyePosition(client, clientPos);
		EmitSoundToAll(MISSSOUND, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL,-1 , clientPos, NULL_VECTOR);
	}
	//TO-DO: Add Negative voice lines appropriate the the client's class here.
}*/

public Action:Timer_KillModel(Handle:timer, any:entref)
{
	new Model = EntRefToEntIndex(entref);
	if (IsValidEntity(Model))
	{
		AcceptEntityInput(Model, "KillHierarchy");
	}
}


/* MISC DEVELOPMENT INFORMATION
	
	TAUNT FRAMES
	Class	 - taunt_highFiveFail - taunt_highFiveFailFull - taunt_highFiveSuccess - taunt_highFiveSuccessFull
	Scout	 - 125 - 125 - 125 - 125
	Soldier	 - 125 - 125 - 125 - 125
	Pyro	 - 121 - 121 - 125 - 125
	Demoman	 - 125 - 125 - 125 - 125
	Heavy	 - 142 - 137 - 113 - 124
	Engineer - N/A - N/A - N/A - N/A
	Medic	 - 127 - 127 - 120 - 120
	Sniper	 - 119 - 119 - 119 - 113
	Spy		 - 119 - 119 - 119 - 129
	
	TAUNT TIME (30fps)
	Class	 - taunt_highFiveFail - taunt_highFiveFailFull - taunt_highFiveSuccess - taunt_highFiveSuccessFull
	Scout	 - 4.2 - 4.2 - 4.2 - 4.2
	Soldier	 - 4.2 - 4.2 - 4.2 - 4.2
	Pyro	 - 4.0 - 4.0 - 4.2 - 4.2
	Demoman	 - 4.2 - 4.2 - 4.2 - 4.2
	Heavy	 - 4.7 - 4.6 - 3.8 - 4.2
	Engineer - N/A - N/A - N/A - N/A
	Medic	 - 4.2 - 4.2 - 4.0 - 4.0
	Medic	 - 4.2 - 4.2 - 4.0 - 4.0
	Sniper	 - 4.0 - 4.0 - 4.0 - 3.8
	Spy		 - 4.0 - 4.0 - 4.0 - 4.3
	
	Point of colision is always at 60 frames, or 2 seconds.
*/