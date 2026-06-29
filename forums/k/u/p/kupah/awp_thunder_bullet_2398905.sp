/*
	Based on this plugins :
	Admin Smite 2.1 : https://forums.alliedmods.net/showthread.php?p=1086127
	Tracer Effects v 1.2.8 : https://forums.alliedmods.net/showthread.php?t=142046
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define SOUND "ambient/explosions/explode_9.wav"

int g_SmokeSprite;
int g_LightningSprite;

Handle Cvar_Enabled = null;
Handle Cvar_Sound = null;
Handle Cvar_Beam = null;
Handle Cvar_Sparks = null;
Handle Cvar_EnergySplash = null;
Handle Cvar_Smoke = null;

int Enabled;
int Sound;
int Beam;
int Sparks;
int EnergySplash;
int Smoke;

public Plugin myinfo = 
{
	name = "AWP Zeus lightning bullets",
	author = "Hipster/Panduh (AlliedMods: thetwistedpanda)/TheBadTurtle(kupah)",
	description = "AWP OF ZEUS!!!!",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=279827"
};

public void OnPluginStart() {
	HookEvent("bullet_impact", BulletImpact);

	Cvar_Enabled = CreateConVar("AWP_lightning_bullets_enable", "1", "Enables/disables lightning bullets");
	Enabled = GetConVarInt(Cvar_Enabled);
	
	Cvar_Sound = CreateConVar("AWP_lightning_bullets_sound", "1", "Enable/disable lightning bullets explode sound");
	Sound = GetConVarInt(Cvar_Sound);
	
	Cvar_Beam = CreateConVar("AWP_lightning_bullets_beam", "1", "Enable/disable lightning bullets beam");
	Beam = GetConVarInt(Cvar_Beam);
	
	Cvar_Sparks = CreateConVar("AWP_lightning_bullets_sparks", "1", "Enable/disable lightning bullets sparks");
	Sparks = GetConVarInt(Cvar_Sparks);
	
	Cvar_EnergySplash = CreateConVar("AWP_lightning_bullets_energy_splash", "1", "Enable/disable lightning bullets energy splash");
	EnergySplash = GetConVarInt(Cvar_EnergySplash);
	
	Cvar_Smoke = CreateConVar("AWP_lightning_bullets_smoke", "1", "Enable/disable lightning bullets smoke");
	Smoke = GetConVarInt(Cvar_Smoke);
	
	HookConVarChange(Cvar_Enabled, OnCvarChange);
	HookConVarChange(Cvar_Sound, OnCvarChange);
	HookConVarChange(Cvar_Beam, OnCvarChange);
	HookConVarChange(Cvar_Sparks, OnCvarChange);
	HookConVarChange(Cvar_EnergySplash, OnCvarChange);
	HookConVarChange(Cvar_Smoke, OnCvarChange);
	
	AutoExecConfig(true, "AWP_lightning_bullets");
}

public OnCvarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == Cvar_Enabled)
		Enabled = StringToInt(newvalue);
	if(cvar == Cvar_Sound)
		Sound = StringToInt(newvalue);
	if(cvar == Cvar_Beam)
		Beam = StringToInt(newvalue);
	if(cvar == Cvar_Sparks)
		Sparks = StringToInt(newvalue);
	if(cvar == Cvar_EnergySplash)
		EnergySplash = StringToInt(newvalue);
	if(cvar == Cvar_Smoke)
		Smoke = StringToInt(newvalue);
}

public void OnMapStart() {
	PrecacheSound(SOUND, true);
	g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
}

public int BulletImpact(Handle:event,const String:name[],bool:dontBroadcast) {
	if(Enabled == 1) {
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
			
		float fPosition[3];
		float fImpact[3];
		float fDifference[3];
			
		GetClientEyePosition(client, fPosition);
		fImpact[0] = GetEventFloat(event, "x");
		fImpact[1] = GetEventFloat(event, "y");
		fImpact[2] = GetEventFloat(event, "z");
		
		float fDistance = GetVectorDistance(fPosition, fImpact);
		float fPercent = (0.4 / (fDistance / 100.0));
		
		fDifference[0] = fPosition[0] + ((fImpact[0] - fPosition[0]) * fPercent);
		fDifference[1] = fPosition[1] + ((fImpact[1] - fPosition[1]) * fPercent) - 0.08;
		fDifference[2] = fPosition[2] + ((fImpact[2] - fPosition[2]) * fPercent);
			
		int color[4] =  { 255, 255, 255, 255 };
			
		float dir[3] = {0.0, 0.0, 0.0};
			
		if(Beam == 1) {
			TE_SetupBeamPoints(fDifference, fImpact, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
			TE_SendToAll();
		}
		if(Sparks == 1) {
			TE_SetupSparks(fImpact, dir, 5000, 1000);
			TE_SendToAll();
		}
		if(EnergySplash == 1) {
			TE_SetupEnergySplash(fImpact, dir, false);
			TE_SendToAll();
		}
		if(Smoke == 1) {
			TE_SetupSmoke(fImpact, g_SmokeSprite, 5.0, 10);
			TE_SendToAll();
		}
			
		if(Sound == 1)
			EmitAmbientSound(SOUND, fImpact, client, SNDLEVEL_RAIDSIREN);
	}
}