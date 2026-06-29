#define PLUGIN_VERSION "1.1"

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin:myinfo =
{
	name = "[HL2DM] Trail Ball Variation",
	author = "raziEiL [disawar1]",
	description = "Creates colored trails and attached to combine balls",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

enum Colors
{
	Static,
	Rebels,
	Combine
}

static		bool:g_bHook, String:g_sCvarColor[Colors][24], Float:g_fCvarLife, bool:g_bCvarRColors, bool:g_bCvarRWidth, Float:g_fCvarSWidth, Float:g_fCvarEWidth, bool:g_bTDMColors;

public OnPluginStart()
{
	CreateConVar("hl2dm_trail_ball_version", PLUGIN_VERSION,	"Trail Ball Variation plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	new Handle:hCvarRColor	= CreateConVar("hl2dm_trail_random_color",		"1",			"0=Disable, 1=Enable random trail colors.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	new Handle:hCvarColor	= CreateConVar("hl2dm_trail_static_color",		"64 137 59",	"The default trail color. Three values between 0-255 separated by spaces. RGB - Red Green Blue.", FCVAR_PLUGIN);
	new Handle:hCvarTDM		= CreateConVar("hl2dm_trail_tdm_color",			"0",			"Forced to use Team deathmatch colors.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	new Handle:hCvarRebels	= CreateConVar("hl2dm_trail_rebels_color",		"198 87 0",		"The default Rebels team trail color (Team deathmatch). Three values between 0-255 separated by spaces. RGB - Red Green Blue.", FCVAR_PLUGIN);
	new Handle:hCvarCombine	= CreateConVar("hl2dm_trail_combine_color",		"91 244 191",	"The default Combine team trail color (Team deathmatch). Three values between 0-255 separated by spaces. RGB - Red Green Blue.", FCVAR_PLUGIN);
	new Handle:hCvarLife		= CreateConVar("hl2dm_trail_life_time",			"2", 			"How long the trail is shown ('tail' length).", FCVAR_PLUGIN);
	new Handle:hCvarRWidth	= CreateConVar("hl2dm_trail_radom_width",		"0", 			"0=Disable, 1=Enable random width", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	new Handle:hCvarSWidth	= CreateConVar("hl2dm_trail_start_width",		"5", 			"The width of the beam to the beginning. Note: if 'hl2dm_trail_radom_width' = 1 the random value of start width will be between 1 and this convar.", FCVAR_PLUGIN);
	new Handle:hCvarEWidth	= CreateConVar("hl2dm_trail_end_width",			"5", 			"The width of the beam when it has full expanded. Note: if 'hl2dm_trail_radom_width' = 1 the random value of end width will be between 1 and this convar.", FCVAR_PLUGIN);
	AutoExecConfig(true, "trailball_variation");

	GetConVarString(hCvarColor, g_sCvarColor[Static], 24);
	GetConVarString(hCvarRebels, g_sCvarColor[Rebels], 24);
	GetConVarString(hCvarCombine, g_sCvarColor[Combine], 24);
	g_fCvarLife		= GetConVarFloat(hCvarLife);
	g_bCvarRColors	= GetConVarBool(hCvarRColor);
	g_bTDMColors		= GetConVarBool(hCvarTDM);
	g_bCvarRWidth	= GetConVarBool(hCvarRWidth);
	g_fCvarSWidth	= GetConVarFloat(hCvarSWidth);
	g_fCvarEWidth	= GetConVarFloat(hCvarEWidth);

	HookConVarChange(hCvarColor,		OnConvarChange_Color);
	HookConVarChange(hCvarRebels,	OnConvarChange_Rebels);
	HookConVarChange(hCvarCombine,	OnConvarChange_Combine);
	HookConVarChange(hCvarLife,		OnConvarChange_Life);
	HookConVarChange(hCvarRColor,	OnConvarChange_RColors);
	HookConVarChange(hCvarTDM,		OnConvarChange_TDMColors);
	HookConVarChange(hCvarRWidth,	OnConvarChange_RWidth);
	HookConVarChange(hCvarSWidth,	OnConvarChange_SWidth);
	HookConVarChange(hCvarEWidth,	OnConvarChange_EWidth);
}

public OnMapStart()
{
	g_bHook = true;
}

public OnMapEnd()
{
	g_bHook = false;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (g_bHook && StrEqual(classname, "prop_combine_ball"))
		CreateTimer(0.0, TV_t_DelayPostSpawn, EntIndexToEntRef(entity));
}

public Action:TV_t_DelayPostSpawn(Handle:timer, any:entity)
{
	if ((entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE && GetEntProp(entity, Prop_Data, "m_bWeaponLaunched"))
		CreateSpriteTrail(entity);
}

CreateSpriteTrail(target)
{
	new client = GetEntPropEnt(target, Prop_Send, "m_hOwnerEntity");
	if (!IsClientAndInGame(client)) return;

	decl Float:vOrigin[3], String:sTemp[64];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", vOrigin);

	if (g_bTDMColors)
		strcopy(sTemp, 64, GetClientTeam(client) == 3 ? g_sCvarColor[Rebels] : g_sCvarColor[Combine]);
	else if (g_bCvarRColors)
		FormatEx(sTemp, 64, "%d %d %d", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
	else
		strcopy(sTemp, 64, g_sCvarColor[Static]);

	new entity = CreateEntityByName("env_spritetrail");
	DispatchKeyValueVector(entity, "origin", vOrigin);
	DispatchKeyValue(entity, "spritename", "sprites/laser.vmt");
	DispatchKeyValue(entity, "rendermode", "5");
	DispatchKeyValue(entity, "renderamt", "255");
	DispatchKeyValueFloat(entity, "lifetime", g_fCvarLife);
	DispatchKeyValue(entity, "rendercolor", sTemp);
	DispatchKeyValueFloat(entity, "startwidth", g_bCvarRWidth ? GetRandomFloat(1.0, g_fCvarSWidth) : g_fCvarSWidth);
	DispatchKeyValueFloat(entity, "endwidth", g_bCvarRWidth ? GetRandomFloat(1.0, g_fCvarEWidth) : g_fCvarEWidth);
	DispatchSpawn(entity);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", target);
	AcceptEntityInput(entity, "ShowSprite");
}

bool:IsClientAndInGame(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

public OnConvarChange_Color(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue))
		GetConVarString(convar, g_sCvarColor[Static], 24);
}

public OnConvarChange_Rebels(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue))
		GetConVarString(convar, g_sCvarColor[Rebels], 24);
}

public OnConvarChange_Combine(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue))
		GetConVarString(convar, g_sCvarColor[Combine], 24);
}

public OnConvarChange_Life(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue))
		g_fCvarLife = GetConVarFloat(convar);
}

public OnConvarChange_RColors(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue))
		g_bCvarRColors = GetConVarBool(convar);
}

public OnConvarChange_TDMColors(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue))
		g_bTDMColors = GetConVarBool(convar);
}

public OnConvarChange_RWidth(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue))
		g_bCvarRWidth = GetConVarBool(convar);
}

public OnConvarChange_SWidth(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue))
		g_fCvarSWidth = GetConVarFloat(convar);
}

public OnConvarChange_EWidth(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue))
		g_fCvarEWidth = GetConVarFloat(convar);
}
