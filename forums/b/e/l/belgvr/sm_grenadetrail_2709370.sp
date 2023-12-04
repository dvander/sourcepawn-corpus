#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required;
#pragma semicolon 1;

#define PLUGIN_VERSION "1.0"

Handle hEnableTrail;
Handle hBeamHoldTime;
Handle hBeamStartWidth;
Handle hBeamEndWidth;
Handle hColorTrailRandom;
Handle hColorTrailTDM;
Handle hBeamRandomWidth;
Handle hTrailColorStatic;
Handle hTrailColorRebels;
Handle hTrailColorCombine;
Handle hTrailNewRenderMethod;
Handle hTrailMaterial;

float g_fBeamHoldTime;
float g_fBeamStartWidth;
float g_fBeamEndWidth;
bool g_bColorTrailRandom;
bool g_bColorTrailTDM;
bool g_bBeamRandomWidth;
char g_sTrailColorStatic[24];
char g_sTrailColorRebels[24];
char g_sTrailColorCombine[24];
char g_sTrailMaterial[24];
int g_iTrailNewRenderMethod;

public Plugin myinfo = {
	name = "belgvr's' Grenade Trails",
	author = "belgvr (mod from Scorp's Crossbow Trail that he inspired on Trailball by raziEil)",
	description = "Creates A Trail On Grenades",
	version = PLUGIN_VERSION,
	url = "http://oppressiveterritory.ddns.net"
};

public void OnPluginStart() {

	CreateConVar("sm_grenadetrail_version", PLUGIN_VERSION, "Grenade Trail Plugin Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	hEnableTrail                 = CreateConVar("sm_grenadetrail_enabled", "1", "Enable Trail");

	hTrailMaterial		         = CreateConVar("sm_grenadetrail_material", "sprites/smoke.vmt", "Trail Material. CAUTION: invalid material may cause clients to crash!!");
	hColorTrailRandom	         = CreateConVar("sm_grenadetrail_random_color", "1", "0=Disable, 1=Enable random trail colors.", _, true, 0.0, true, 1.0);
	hColorTrailTDM		         = CreateConVar("sm_grenadetrail_tdm_color", "0", "Forced to use Team deathmatch colors.", _, true, 0.0, true, 1.0);
	hTrailColorStatic	         = CreateConVar("sm_grenadetrail_static_color", "255 0 0", "The default trail color. Three values between 0-255 separated by spaces. RGB - Red Green Blue.");
	hTrailColorRebels	         = CreateConVar("sm_grenadetrail_rebels_color", "198 87 0", "The default Rebels team trail color (Team deathmatch). Three values between 0-255 separated by spaces. RGB - Red Green Blue.");
	hTrailColorCombine	         = CreateConVar("sm_grenadetrail_combine_color", "91 244 191", "The default Combine team trail color (Team deathmatch). Three values between 0-255 separated by spaces. RGB - Red Green Blue.");
	hBeamHoldTime		         = CreateConVar("sm_grenadetrail_life_time", "2.0", "How long the trail is shown ('tail' length).");
	hBeamRandomWidth	         = CreateConVar("sm_grenadetrail_random_width", "0", "0=Disable, 1=Enable random width", _, true, 0.0, true, 1.0);
	hBeamStartWidth	             = CreateConVar("sm_grenadetrail_start_width", "2.0", "The width of the beam to the beginning. Note: if 'sm_grenadetrail_random_width' = 1 the random value of start width will be between 1 and this convar.");
	hBeamEndWidth	             = CreateConVar("sm_grenadetrail_end_width", "5.0", "The width of the beam when it has full expanded. Note: if 'sm_grenadetrail_random_width' = 1 the random value of end width will be between 1 and this convar.");

	hTrailNewRenderMethod		 = CreateConVar("sm_grenadetrail_new_render_method", "1", "Use Beam Follow Render Method Instead Of 'env_spritetrail' Entity");

	AutoExecConfig(true, "sm_grenadetrail");

	GetConVarString(hTrailColorStatic, g_sTrailColorStatic, 24);
	GetConVarString(hTrailColorRebels, g_sTrailColorRebels, 24);
	GetConVarString(hTrailColorCombine, g_sTrailColorCombine, 24);
	GetConVarString(hTrailMaterial, g_sTrailMaterial, 24);

	g_fBeamHoldTime		     = GetConVarFloat(hBeamHoldTime);
	g_bColorTrailRandom	     = GetConVarBool(hColorTrailRandom);
	g_bColorTrailTDM		 = GetConVarBool(hColorTrailTDM);
	g_bBeamRandomWidth	     = GetConVarBool(hBeamRandomWidth);
	g_fBeamStartWidth	     = GetConVarFloat(hBeamStartWidth);
	g_fBeamEndWidth	         = GetConVarFloat(hBeamEndWidth);
	g_iTrailNewRenderMethod	 = GetConVarInt(hTrailNewRenderMethod);

	HookConVarChange(hTrailMaterial,	OnConvarChange);
	HookConVarChange(hTrailColorStatic,	OnConvarChange);
	HookConVarChange(hTrailColorRebels,	OnConvarChange);
	HookConVarChange(hTrailColorCombine, OnConvarChange);
	HookConVarChange(hBeamHoldTime, OnConvarChange);
	HookConVarChange(hColorTrailRandom,	OnConvarChange);
	HookConVarChange(hColorTrailTDM, OnConvarChange);
	HookConVarChange(hBeamRandomWidth,	OnConvarChange);
	HookConVarChange(hBeamStartWidth, OnConvarChange);
	HookConVarChange(hBeamEndWidth, OnConvarChange);
	HookConVarChange(hTrailNewRenderMethod, OnConvarChange);
}

public void OnConvarChange(Handle convar, const char [] oldValue, const char [] newValue) {
	GetConVarString(hTrailColorStatic, g_sTrailColorStatic, 24);
	GetConVarString(hTrailColorRebels, g_sTrailColorRebels, 24);
	GetConVarString(hTrailColorCombine, g_sTrailColorCombine, 24);
	GetConVarString(hTrailMaterial, g_sTrailMaterial, 24);

	g_fBeamHoldTime		     = GetConVarFloat(hBeamHoldTime);
	g_bColorTrailRandom	     = GetConVarBool(hColorTrailRandom);
	g_bColorTrailTDM		 = GetConVarBool(hColorTrailTDM);
	g_bBeamRandomWidth	     = GetConVarBool(hBeamRandomWidth);
	g_fBeamStartWidth	     = GetConVarFloat(hBeamStartWidth);
	g_fBeamEndWidth	         = GetConVarFloat(hBeamEndWidth);
	g_iTrailNewRenderMethod	 = GetConVarInt(hTrailNewRenderMethod);
}

// TRAILS ////
public void OnEntityCreated(int entity, const char [] classname) {
	if(!GetConVarInt(hEnableTrail))	{
		return;
	}

	if(StrEqual(classname, "npc_grenade_frag", false))
	{ RequestFrame(On_npc_grenade_frag_EntityCreatedNextFrame, entity); }
}

stock void On_npc_grenade_frag_EntityCreatedNextFrame(any entity) {
	if(IsValidEntity(entity)) {
		CreateSpriteTrail(entity);
	}
}

void CreateSpriteTrail(int target) {
	int client = GetEntPropEnt(target, Prop_Send, "m_hOwnerEntity");
	if (client == 0 || !IsClientInGame(client)) { return; }

	float vOrigin[3];
	char sThisColor[64];
	char sArgs[3][4];
	int iThisColor[4];

	GetEntPropVector(target, Prop_Send, "m_vecOrigin", vOrigin);

	if (g_bColorTrailTDM) {
		strcopy(sThisColor, 64, GetClientTeam(client) == 3 ? g_sTrailColorRebels : g_sTrailColorCombine);
	} else if (g_bColorTrailRandom) {
		FormatEx(sThisColor, 64, "%d %d %d", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
	} else {
		strcopy(sThisColor, 64, g_sTrailColorStatic);
	}

	if(g_iTrailNewRenderMethod) {

		// NEW BEAM RENDER
		int g_iBeamSpriteIndex = PrecacheModel(g_sTrailMaterial); // Trails
		ExplodeString(sThisColor, " ", sArgs, sizeof(sArgs), sizeof(sArgs[]), true);
		iThisColor[0] = StringToInt(sArgs[0]);
		iThisColor[1] = StringToInt(sArgs[1]);
		iThisColor[2] = StringToInt(sArgs[2]);
		iThisColor[3] = 255;
		TE_SetupBeamFollow(target, g_iBeamSpriteIndex,	0, g_fBeamHoldTime, g_bBeamRandomWidth ? GetRandomFloat(1.0, g_fBeamStartWidth) : g_fBeamStartWidth, g_bBeamRandomWidth ? GetRandomFloat(1.0, g_fBeamEndWidth) : g_fBeamEndWidth, 1, iThisColor);
		TE_SendToAll();

	} else {

		// OLD BEAM RENDER
		int entity = CreateEntityByName("env_spritetrail");
		if(IsValidEntity(entity)) {
			DispatchKeyValueVector(entity, "origin", vOrigin);
			DispatchKeyValue(entity, "spritename", g_sTrailMaterial);
			DispatchKeyValue(entity, "rendermode", "5");
			DispatchKeyValue(entity, "renderamt", "255");
			DispatchKeyValueFloat(entity, "lifetime", g_fBeamHoldTime);
			DispatchKeyValue(entity, "rendercolor", sThisColor);
			DispatchKeyValueFloat(entity, "startwidth", g_bBeamRandomWidth ? GetRandomFloat(1.0, g_fBeamStartWidth) : g_fBeamStartWidth);
			DispatchKeyValueFloat(entity, "endwidth", g_bBeamRandomWidth ? GetRandomFloat(1.0, g_fBeamEndWidth) : g_fBeamEndWidth);
			DispatchSpawn(entity);

			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", target);
			AcceptEntityInput(entity, "ShowSprite");
		}

	}

}
