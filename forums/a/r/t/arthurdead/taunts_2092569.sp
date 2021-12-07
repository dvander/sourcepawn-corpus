#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#pragma semicolon 1

#define DOSIDO_MUSIC "music/fortress_reel.wav"
#define DOSIDO_MUSIC_LOOP "music/fortress_reel_loop.wav"
#define DOSIDO_TAUNT_DANCE "taunt_dosido_dance"
#define DOSIDO_TAUNT_INTRO "taunt_dosido_intro"
#define DOSIDO_TAUNT_INTRO_TIME 3.0
#define DOSIDO_TAUNT_DANCE_TIME 6.0

new bool:IsTaunting[MAXPLAYERS+1];
new bool:IsTauntingIntro[MAXPLAYERS+1];
new ClientTauntEntity[MAXPLAYERS+1];
new Handle:CVarCooldownTime;
new Handle:CVarAllowEnemy;

public OnPluginStart()
{
	CVarCooldownTime = CreateConVar("sm_taunt_dosido_cooldown", "3.0", "Cooldown time for high-five taunts.", _, true, 0.0);
	CVarAllowEnemy = CreateConVar("sm_taunt_dosido_enemy", "0", "Allow people to high-five enemies.", _, true, 0.0, true, 1.0);
	RegConsoleCmd("+dosido", Command_PlusDoSido, "Dance With another player.");
	RegConsoleCmd("-dosido", Command_MinusDoSido, "Dance With another player.");
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_changeclass", Event_ClassChange);
}

public OnMapStart()
{
	PrecacheSound(DOSIDO_MUSIC);
	PrecacheSound(DOSIDO_MUSIC_LOOP);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsTauntingIntro[client] || IsTaunting[client] && ClientTauntEntity[client] != -1)
	{
		SetAlpha(client, 255);
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(ClientTauntEntity[client], "AddOutput");
		new String:SelfDeleteStr[PLATFORM_MAX_PATH];
		Format(SelfDeleteStr, PLATFORM_MAX_PATH, "OnUser1 !self:KillHierarchy::%f:1", DOSIDO_TAUNT_DANCE_TIME+0.1); 
		SetVariantString(SelfDeleteStr);
		AcceptEntityInput(ClientTauntEntity[client], "AddOutput");
		SetVariantString("");
		AcceptEntityInput(ClientTauntEntity[client], "FireUser1");
		AcceptEntityInput(ClientTauntEntity[client], "Kill");
		TF2_RemoveCondition(client, TFCond_Dazed);
	}
	return Plugin_Continue;
}

public Action:Event_ClassChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsTauntingIntro[client] || IsTaunting[client] && ClientTauntEntity[client] != -1)
	{
		SetAlpha(client, 255);
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(ClientTauntEntity[client], "AddOutput");
		new String:SelfDeleteStr[PLATFORM_MAX_PATH];
		Format(SelfDeleteStr, PLATFORM_MAX_PATH, "OnUser1 !self:KillHierarchy::%f:1", DOSIDO_TAUNT_DANCE_TIME+0.1); 
		SetVariantString(SelfDeleteStr);
		AcceptEntityInput(ClientTauntEntity[client], "AddOutput");
		SetVariantString("");
		AcceptEntityInput(ClientTauntEntity[client], "FireUser1");
		AcceptEntityInput(ClientTauntEntity[client], "Kill");
		TF2_RemoveCondition(client, TFCond_Dazed);
	}
}

public Action:Command_MinusDoSido(client, args)
{
	if(IsValidClient(client) && IsClientInGame(client) && IsPlayerAlive(client) && IsTauntingIntro[client] && IsValidEdict(ClientTauntEntity[client]) && IsValidEntity(ClientTauntEntity[client]))
	{
		SetAlpha(client, 255);
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(ClientTauntEntity[client], "AddOutput");
		new String:SelfDeleteStr[PLATFORM_MAX_PATH];
		Format(SelfDeleteStr, PLATFORM_MAX_PATH, "OnUser1 !self:KillHierarchy::%f:1", DOSIDO_TAUNT_DANCE_TIME+0.1); 
		SetVariantString(SelfDeleteStr);
		AcceptEntityInput(ClientTauntEntity[client], "AddOutput");
		SetVariantString("");
		AcceptEntityInput(ClientTauntEntity[client], "FireUser1");
		AcceptEntityInput(ClientTauntEntity[client], "Kill");
		TF2_RemoveCondition(client, TFCond_Dazed);
	}
	return Plugin_Handled;
}

public Action:Command_PlusDoSido(client, args)
{
	if(IsValidClient(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new client2 = GetClientAimTarget(client, true);
		if(IsValidClient(client2) && IsPlayerAlive(client2) && IsClientInGame(client2))
		{
			if(IsTaunting[client] || IsTaunting[client2] || 
			TF2_IsPlayerInCondition(client, TFCond_Taunting) ||
			TF2_IsPlayerInCondition(client, TFCond_Zoomed) ||
			TF2_IsPlayerInCondition(client, TFCond_Slowed) ||
			TF2_IsPlayerInCondition(client, TFCond_Cloaked) ||
			TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
			TF2_IsPlayerInCondition(client, TFCond_Dazed) ||
			TF2_IsPlayerInCondition(client, TFCond_Charging) ||
			TF2_IsPlayerInCondition(client2, TFCond_Taunting) ||
			TF2_IsPlayerInCondition(client2, TFCond_Zoomed) ||
			TF2_IsPlayerInCondition(client2, TFCond_Slowed) ||
			TF2_IsPlayerInCondition(client2, TFCond_Cloaked) ||
			TF2_IsPlayerInCondition(client2, TFCond_Ubercharged) ||
			TF2_IsPlayerInCondition(client2, TFCond_Dazed) ||
			TF2_IsPlayerInCondition(client2, TFCond_Charging))
			{
				return Plugin_Handled;
			}
			if(GetClientTeam(client) != GetClientTeam(client2) && !GetConVarBool(CVarAllowEnemy))
			{
				PrintToChat(client, "[SM] Target must be on your team");
			}
			if(GetClientAimTarget(client2, true) != client)
			{
				PrintToChat(client, "[SM] Target must be looking at you");
			}
			new Float:clientPos[3], Float:client2Pos[3];
			GetClientEyePosition(client, clientPos);
			GetClientEyePosition(client2, client2Pos);
			if (clientPos[2] - client2Pos[2] > 10 || clientPos[2] - client2Pos[2] < -10)
			{
				PrintToChat(client, "[SM] Target must be level with you");
			}
			new Float:DistanceApart = GetVectorDistance(clientPos, client2Pos, false);
			if (DistanceApart < 56 || DistanceApart > 72)
			{
				PrintToChat(client, "[SM] Target get is too close or too far away (%f)", DistanceApart);
			}
			if(IsTauntingIntro[client2])
			{
				SetAlpha(client, 0);
				SetAlpha(client2, 0);
				TF2_StunPlayer(client, DOSIDO_TAUNT_DANCE_TIME, 1.0, TF_STUNFLAGS_LOSERSTATE);
				TF2_StunPlayer(client2, DOSIDO_TAUNT_DANCE_TIME, 1.0, TF_STUNFLAGS_LOSERSTATE);
				AttachNewPlayerModel(client, DOSIDO_TAUNT_DANCE);
				AttachNewPlayerModel(client2, DOSIDO_TAUNT_DANCE);
				CreateTimer(DOSIDO_TAUNT_DANCE_TIME, Timer_DoSido, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(DOSIDO_TAUNT_DANCE_TIME, Timer_DoSido, client2, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			SetAlpha(client, 0);
			TF2_StunPlayer(client, 999999.0, 1.0, TF_STUNFLAGS_LOSERSTATE);
			AttachNewPlayerModel2(client, DOSIDO_TAUNT_INTRO);
		}
		SetAlpha(client, 0);
		TF2_StunPlayer(client, 999999.0, 1.0, TF_STUNFLAGS_LOSERSTATE);
		AttachNewPlayerModel2(client, DOSIDO_TAUNT_INTRO);
	}
	return Plugin_Handled;
}

public AttachNewPlayerModel2(client, String:Animation[PLATFORM_MAX_PATH])
{	
	IsTauntingIntro[client] = true;
	new Model = CreateEntityByName("prop_dynamic");
	if(Model != -1)
	{
		new Float:pos[3];
		new Float:angles[3];
		new String:ClientModel[PLATFORM_MAX_PATH];
		new String:Skin[PLATFORM_MAX_PATH];
		GetClientModel(client, ClientModel, PLATFORM_MAX_PATH);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(Model, pos, NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		angles[2] = 0.0;
		IntToString(GetClientTeam(client)-2, Skin, PLATFORM_MAX_PATH);
		DispatchKeyValue(Model, "skin", Skin);
		DispatchKeyValue(Model, "model", ClientModel);
		DispatchKeyValue(Model, "DefaultAnim", Animation);	
		DispatchKeyValueVector(Model, "angles", angles);
		DispatchSpawn(Model);
		SetVariantString(Animation);
		AcceptEntityInput(Model, "SetAnimation");
		ClientTauntEntity[client] = Model;
	}
}

public AttachNewPlayerModel(client, String:Animation[PLATFORM_MAX_PATH])
{	
	IsTaunting[client] = true;
	new Model = CreateEntityByName("prop_dynamic");
	if(Model != -1)
	{
		new Float:pos[3];
		new Float:angles[3];
		new String:ClientModel[PLATFORM_MAX_PATH];
		new String:Skin[PLATFORM_MAX_PATH];
		GetClientModel(client, ClientModel, PLATFORM_MAX_PATH);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(Model, pos, NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		angles[2] = 0.0;
		IntToString(GetClientTeam(client)-2, Skin, PLATFORM_MAX_PATH);
		DispatchKeyValue(Model, "skin", Skin);
		DispatchKeyValue(Model, "model", ClientModel);
		DispatchKeyValue(Model, "DefaultAnim", Animation);	
		DispatchKeyValueVector(Model, "angles", angles);
		DispatchSpawn(Model);
		SetVariantString(Animation);
		AcceptEntityInput(Model, "SetAnimation");
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(Model, "AddOutput");
		new String:SelfDeleteStr[PLATFORM_MAX_PATH];
		Format(SelfDeleteStr, PLATFORM_MAX_PATH, "OnUser1 !self:KillHierarchy::%f:1", DOSIDO_TAUNT_DANCE_TIME+0.1); 
		SetVariantString(SelfDeleteStr);
		AcceptEntityInput(Model, "AddOutput");
		SetVariantString("");
		AcceptEntityInput(Model, "FireUser1");
		ClientTauntEntity[client] = Model;
	}
}

stock SetAlpha(target, alpha)
{
	SetWeaponsAlpha(target,alpha);
	SetWearablesAlpha(target, alpha);
	SetEntityRenderMode(target, RENDER_TRANSCOLOR);
	SetEntityRenderColor(target, 255, 255, 255, alpha);
}

stock SetWeaponsAlpha(target, alpha)
{
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

stock SetWearablesAlpha(target, alpha)
{
	if(IsPlayerAlive(target))
	{
		new Float:pos[3], Float:wearablepos[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
		new wearable= -1;
		while ((wearable= FindEntityByClassname(wearable, "tf_wearable")) != -1)
		{
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos);
			if (GetVectorDistance(pos, wearablepos, true) < 2)
			{
				SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wearable, 255, 255, 255, alpha);
			}
		}
		while ((wearable= FindEntityByClassname(wearable, "tf_wearable_item_demoshield")) != -1)
		{
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos);
			if (GetVectorDistance(pos, wearablepos, true) < 2)
			{
				SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wearable, 255, 255, 255, alpha);
			}
		}
	}
}

public Action:Timer_DoSido(Handle:timer, any:client)
{
	if(IsValidClient(client))
	{
		SetAlpha(client, 255);
		CreateTimer(GetConVarFloat(CVarCooldownTime), Timer_DoSidoCooldown, client, TIMER_FLAG_NO_MAPCHANGE);
		if(IsPlayerAlive(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
}

public Action:Timer_DoSidoCooldown(Handle:timer, any:client)
{
	if(IsValidClient(client))
	{
		IsTaunting[client] = false;
	}
}

stock bool:IsValidClient(client)
{
	if(client >= 1 && client <= MaxClients)
	{
		return true;
	}
	return false;
}