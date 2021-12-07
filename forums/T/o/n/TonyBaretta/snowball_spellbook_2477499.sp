#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <keyvalues>
#define MAX_BUTTONS 26
//#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.1"

ConVar g_hSnowBallSoundEnabled;
ConVar g_Cvar_Enabled;
ConVar g_hAmmoBall;
bool Snowball[MAXPLAYERS+1];
bool FirstSpawn[MAXPLAYERS+1];
int g_iPlayerLastButtons[MAXPLAYERS + 1];


public Plugin myinfo = 
{
	name = "snowballs spellbook",
	author = "TonyBaretta",
	description = "snowballs spellbook edition",
	version = VERSION,
	url = "https://forums.alliedmods.net/"
}
public void OnMapStart() 
{
	PrecacheSound("weapons/knife_swing.wav", true);
}
public void OnPluginStart()
{
	CreateConVar("snowballs_version", VERSION, "snowball version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_Cvar_Enabled = CreateConVar("snowballs_enabled", "1", "Enable snowball?", FCVAR_NONE, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_snowballme", Cmd_Toggle);
	AddNormalSoundHook(view_as<NormalSHook>(NoBallStunSound));
	g_hSnowBallSoundEnabled = CreateConVar("stunball_sound", "0", "Enables/disables stunball sound", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hAmmoBall = CreateConVar("snowball_ammo", "25", "number of snowballs aviable ", FCVAR_NONE);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
}
public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		Cmd_Toggle(client,false);
		FirstSpawn[client] = true;
	}
}
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int iAmmoBall = GetConVarInt(g_hAmmoBall);
	if(IsValidClient(client)){
		if(g_Cvar_Enabled && FirstSpawn[client]){
			PrintToChat(client,"\x04[Snowball] EQUIP THE SPELLBOOK and type !snowballme to get snowballs !");
			FirstSpawn[client] = false;
		}		
		if(Snowball[client] && g_Cvar_Enabled){
			int ent = -1;
			while ((ent = FindEntityByClassname(ent, "tf_weapon_spellbook")) != -1)
			{
				if(ent)
				{
					if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")==client)
					{
						SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 0);
						SetEntProp(ent, Prop_Send, "m_iSpellCharges", iAmmoBall);
						PrintToChat(client,"\x04[Snowball]\x02 Ammo Reloaded!");
					}
				}
			}
		}
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}
public Action OnPlayerRunCmd(int iClient,int &buttons,int &impulse, float vel[3], float angles[3],int &weapon,int &subtype,int &cmdnum,int &tickcount,int &seed,int mouse[2])
{
	for (int i = 0; i < MAX_BUTTONS; i++)
	{
		int button = (1 << i);

		if ((buttons & button))
		{
			if (!(g_iPlayerLastButtons[iClient] & button))
			{
				ClientOnButtonPress(iClient, button);
			}
		}
		else if ((g_iPlayerLastButtons[iClient] & button))
		{
			ClientOnButtonRelease(iClient, button);
		}
	}
	g_iPlayerLastButtons[iClient] = buttons;
	return Plugin_Continue;
}

public void ClientOnButtonPress(int iClient,int button)
{
	if (button == IN_ATTACK3)
	{
		KeyValues actionSlot = new KeyValues("use_action_slot_item_server");
		FakeClientCommandKeyValues(iClient, actionSlot);
		delete actionSlot;

	}
}

public void ClientOnButtonRelease(int iClient,int button)
{

}

public Action Cmd_Toggle(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "Stunball doesn't work from the console.");
		return Plugin_Handled;
	}
	Snowball[client] = !Snowball[client];
	int iAmmoBall = GetConVarInt(g_hAmmoBall);
	if(Snowball[client]){
		int SpellbookCheck = FindSpellbook(client);
		if(SpellbookCheck == -1){
			PrintToChat(client,"\x04[Snowball] EQUIP THE SPELLBOOK and type !snowballme to get snowballs !");
			Snowball[client] = false;
			return Plugin_Handled;
		}
		int ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_weapon_spellbook")) != -1)
		{
			if(ent)
			{
				if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")==client)
				{
					SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 0);
					SetEntProp(ent, Prop_Send, "m_iSpellCharges", iAmmoBall);
					PrintToChat(client,"\x04[Snowball]Snowball Enabled!, use attack3 button to shoot");
				}
			}
		}
		return Plugin_Handled;
	}
	if(!Snowball[client]){
		int ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_weapon_spellbook")) != -1)
		{
			if(ent)
			{
				if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")==client)
				{
					SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 0);
					SetEntProp(ent, Prop_Send, "m_iSpellCharges", 0);
					PrintToChat(client,"\x04[Snowball] Snowball Disabled!");
				}
			}
		}
	}	
	return Plugin_Handled;
}
public void OnEntityCreated(int entity, const char[] classname)
{
	if (GetConVarBool(g_Cvar_Enabled) && StrEqual(classname, "tf_projectile_spellfireball", false))
	{
		SDKHook(entity, SDKHook_Spawn, ProjectileFireball_OnSpawn);
	}
}

public Action ProjectileFireball_OnSpawn(int entity)
{
	if (IsValidEntity(entity))
	{
		float vPosition[3];
		float vAngles[3];
		float flSpeed = 1500.0;
		float vVelocity[3];
		float vBuffer[3];
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(IsValidClient(owner)){
			GetClientEyePosition(owner, vPosition);
			GetClientEyeAngles(owner, vAngles);
		}
		// Is the owner a player?
		if (owner > 0 && owner <= MaxClients && Snowball[owner])
		{
			AcceptEntityInput(entity, "Kill");
			
			int iBall = CreateEntityByName("tf_projectile_stun_ball");
			if(IsValidEntity(iBall))
			{					
				GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					
				vVelocity[0] = vBuffer[0]*flSpeed;
				vVelocity[1] = vBuffer[1]*flSpeed;
				vVelocity[2] = vBuffer[2]*flSpeed;
				SetEntPropVector(iBall, Prop_Data, "m_vecVelocity", vVelocity);
				SetEntPropEnt(iBall, Prop_Send, "m_hOwnerEntity", owner);
				SetEntProp(iBall, Prop_Send, "m_iTeamNum", GetClientTeam(owner));
				SetVariantString("OnUser3 !self:FireUser4::3.0:1");
				AcceptEntityInput(iBall, "AddOutput");
				HookSingleEntityOutput(iBall, "OnUser4", BallBreak, false);
				AcceptEntityInput(iBall, "FireUser3");
				DispatchSpawn(iBall);
				EmitSoundToClient(owner, "weapons/knife_swing.wav");
				TeleportEntity(iBall, vPosition, vAngles, vVelocity);
				CreateParticle(iBall, "xms_icicle_melt", true, 3.0);
				SetEntityRenderColor(iBall, 190, 251, 250, 255);
			}
		}
	}
}
public void BallBreak(const char[] output, int caller, int activator, float delay){

	if(caller == -1){
		return;
	}	
	AcceptEntityInput(caller, "Kill");
}
public Action NoBallStunSound(int clients[64], int numClients, char Pathname[PLATFORM_MAX_PATH], int entity, int channel, float volume, int level, int pitch, int flags) 
{
	if(!g_hSnowBallSoundEnabled.IntValue){
		if(StrContains(Pathname, "pl_impact_stun.wav", false) != -1)return Plugin_Stop;
		if(StrContains(Pathname, "sf13_spell_bombhead01.mp3", false) != -1)return Plugin_Stop;
		if(StrContains(Pathname, "pyro_sf13_spell_generic07.mp3", false) != -1)return Plugin_Stop;
		if(StrContains(Pathname, "spell_fireball_cast.wav", false) != -1)return Plugin_Stop;
		else
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if((IsValidClient(client)) && (IsPlayerAlive(client))){
		if(condition == TFCond_Dazed)
		{
			SetEntityRenderColor(client, 0, 193, 255, 255);
			CreateParticle(client, "xms_icicle_impact_dryice", true, 1.0);
		}
	}
}
public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if((IsValidClient(client)) && (IsPlayerAlive(client))){
		if(condition == TFCond_Dazed)
		{
			SetEntityRenderColor(client, 255, 255, 255, 255);
		}
	}
}
stock int CreateParticle(int iEntity, char[] sParticle, bool bAttach = false, float time)
{
	int iParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(iParticle))
	{
		float fPosition[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition);
		
		TeleportEntity(iParticle, fPosition, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(iParticle, "effect_name", sParticle);
		
		if (bAttach)
		{
			SetVariantString("!activator");
			AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);			
		}

		DispatchSpawn(iParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
		CreateTimer(time, DeleteParticle, iParticle)
	}
	return iParticle;
}
public Action DeleteParticle(Handle timer, any particle)
{
	if (IsValidEntity(particle))
	{
		char classN[64];
		GetEdictClassname(particle, classN, sizeof(classN));
		if (StrEqual(classN, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}
}
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}
stock int FindSpellbook(int client)	//GetPlayerWeaponSlot was giving me some issues
{
	int i = -1;
	while ((i = FindEntityByClassname(i, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWeapon"))
		{
			return i;
		}
	}
	return -1;
}