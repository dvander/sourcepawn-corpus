#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"

new g_ExplosionSprite[8];

new Handle:g_hFireworksTimer;
new Handle:g_hFireworksRoundend;
new Handle:g_hFireworksSound;
new Handle:g_hFireworksTimeout;
new String:g_sModels[][] = {
	"sprites/sprite_fire01.vmt",
	"sprites/blueglow1.vmt",
	"sprites/redglow1.vmt",
	"sprites/greenglow1.vmt",
	"sprites/yellowglow1.vmt",
	"sprites/purpleglow1.vmt",
	"sprites/orangeglow1.vmt",
	"sprites/glow1.vmt"
};
new String:g_sSounds[][] = {
	"ambient/explosions/exp1.wav",
	"ambient/explosions/explode_8.wav",
	"weapons/explode3.wav",
	"weapons/stinger_fire1.wav",
	"weapons/rpg/rocketfire1.wav",
	"weapons/mortar/mortar_explode1.wav",
	"weapons/mortar/mortar_explode2.wav",
	"weapons/mortar/mortar_explode3.wav",
	"weapons/mortar/mortar_shell_incomming1.wav"
};

new g_iPositionCount = -1;
new Float:g_fFrequency = 0.1;
new Float:g_fPositions[10][3]; // max 10 control points - I hope this will work with all maps

public Plugin:myinfo =
{
	name = "DOD:S Fireworks",
	author = "Silent_Water, playboycyberclub",
	description = "Fireworks plugin for DOD:S",
	version = PLUGIN_VERSION,
	url = "http://dodsplugins.com/"
};

public OnPluginStart()
{
	HookEvent("dod_round_win",RoundEnd);
	HookEvent("dod_round_start",RoundStart);
	CreateConVar("sm_dod_fireworks", PLUGIN_VERSION, "", FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_hFireworksTimeout = CreateConVar("sm_fireworks_timeout","60");
	g_hFireworksSound = CreateConVar("sm_fireworks_sound","1");
	g_hFireworksRoundend = CreateConVar("sm_fireworks_roundend","1");
	RegAdminCmd( "sm_fireworks_start", fireworks_start, ADMFLAG_CUSTOM2, "Fires fireworks into the sky." );
	RegAdminCmd( "sm_fireworks_stop", fireworks_stop, ADMFLAG_CUSTOM2, "Cancel fireworks." );
	g_hFireworksTimer = INVALID_HANDLE;

	AutoExecConfig(true, "dod_fireworks");
}

public Action:find_positions(Handle:timer)
{
	new Float:cpoint[3];
	new i = -1;
	g_iPositionCount = 0;
	while ( ((i = FindEntityByClassname(i, "dod_control_point")) != -1) && (g_iPositionCount<10) ){
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", cpoint);
		g_fPositions[g_iPositionCount][0] = cpoint[0];
		g_fPositions[g_iPositionCount][1] = cpoint[1];
		g_fPositions[g_iPositionCount][2] = cpoint[2];
		g_iPositionCount++;
	}

	// if no control points are defined use spawn points instead (fallback)
	if (g_iPositionCount == 0) {
		i = -1;
		while ( ((i = FindEntityByClassname(i, "info_player_allies")) != -1) && (g_iPositionCount<5) ) {
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", cpoint);
			g_fPositions[g_iPositionCount][0] = cpoint[0];
			g_fPositions[g_iPositionCount][1] = cpoint[1];
			g_fPositions[g_iPositionCount][2] = cpoint[2];
			g_iPositionCount++;
		}
		i = -1;
		while ( ((i = FindEntityByClassname(i, "info_player_axis")) != -1) && (g_iPositionCount<10) ) {
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", cpoint);
			g_fPositions[g_iPositionCount][0] = cpoint[0];
			g_fPositions[g_iPositionCount][1] = cpoint[1];
			g_fPositions[g_iPositionCount][2] = cpoint[2];
			g_iPositionCount++;
		}
	}
	if (g_iPositionCount < 3)
		g_fFrequency = 0.2;
	return Plugin_Continue;
}

public OnMapStart()
{
	for (new i=0; i<sizeof(g_sModels); i++) {
		g_ExplosionSprite[i] = PrecacheModel(g_sModels[i]);
	}
	for (new j=0; j<sizeof(g_sSounds); j++) {
		PrecacheSound(g_sSounds[j], true);
	}
	CreateTimer(0.1, find_positions, _);
}

public OnMapEnd() {
	CreateTimer(0.1, fireworks_timeout, _);
}

public RoundEnd(Handle: event , const String: name[] , bool: dontBroadcast)
{
	new enabled = GetConVarInt(g_hFireworksRoundend);
	new Float:timeout = GetConVarFloat(g_hFireworksTimeout);
	if((enabled == 1) && (g_hFireworksTimer == INVALID_HANDLE))
	{
		g_hFireworksTimer = CreateTimer(g_fFrequency, fireworks_event, _, TIMER_REPEAT);
		CreateTimer(timeout, fireworks_timeout, _);
	}
	return;
}

public RoundStart(Handle: event , const String: name[] , bool: dontBroadcast)
{
	if (g_hFireworksTimer != INVALID_HANDLE)
	{
		KillTimer(g_hFireworksTimer);
		g_hFireworksTimer = INVALID_HANDLE;
	}
	return;
}

public Action:fireworks_start(client, args )
{
	find_positions(INVALID_HANDLE);
	if(g_hFireworksTimer != INVALID_HANDLE)
	{
		PrintToConsole(client,"[Fireworks] is already running");
		return Plugin_Handled;
	}

	new String:Admin[64];
	GetClientName(client,Admin,sizeof(Admin));

	g_hFireworksTimer = CreateTimer(g_fFrequency, fireworks_event, _, TIMER_REPEAT);
	PrintToChatAll("[Fireworks] Launching!!!");
	PrintToServer("[Fireworks] %s has fired some fireworks.", Admin);
	if(g_hFireworksTimer != INVALID_HANDLE)
	{
		new Float:timeout = GetConVarFloat(g_hFireworksTimeout);
		CreateTimer(timeout, fireworks_timeout, _);
	}
	return Plugin_Handled;
}

public Action:fireworks_stop( client, args )
{
	if(g_hFireworksTimer == INVALID_HANDLE)
	{
		PrintToConsole(client,"[Fireworks] is not in running");
		return Plugin_Handled;
	}
	if (g_hFireworksTimer != INVALID_HANDLE)
	{
		KillTimer(g_hFireworksTimer);
		g_hFireworksTimer = INVALID_HANDLE;
	}
	new String:Admin[64];
	GetClientName(client,Admin,sizeof(Admin));
	PrintToChatAll("[Fireworks] canceled :(");
	PrintToServer("[Fireworks] %s has canceled the fireworks.", Admin);

	return Plugin_Handled;
}

public Action:fireworks_timeout(Handle:timer)
{
	if (g_hFireworksTimer != INVALID_HANDLE)
	{
		KillTimer(g_hFireworksTimer);
		g_hFireworksTimer = INVALID_HANDLE;
	}

	return;
}

public Action:fireworks_event(Handle:timer)
{
	new Float:rorigin[3];

	rorigin[0] = GetRandomFloat(-400.0,400.0);
	rorigin[1] = GetRandomFloat(-400.0,400.0);
	rorigin[2] = GetRandomFloat(-50.0,50.0);

	rorigin[0] = rorigin[0] * -1;
	if (g_iPositionCount > 0)
	{
		new rpos = GetRandomInt(0,g_iPositionCount-1);
		new Float:rdistance[3];
		rorigin[0] = g_fPositions[rpos][0];
		rorigin[1] = g_fPositions[rpos][1];
		rorigin[2] = g_fPositions[rpos][2];
		rorigin[2] = rorigin[2] + 300.0;
		rdistance[0] = GetRandomFloat(-300.0,300.0);
		rdistance[1] = GetRandomFloat(-300.0,300.0);
		rdistance[2] = GetRandomFloat(-100.0,200.0);
		rorigin[0] += rdistance[0];
		rorigin[1] += rdistance[1];
		rorigin[2] += rdistance[2];
	}
	new rand = GetRandomInt(0,2);
	switch(rand)
	{
		case 0: {
			explode(rorigin);
			sphere(rorigin);
		}
		case 1: {
			spark(rorigin);
			explode(rorigin);
			sphere(rorigin);
		}
		case 2: {
			explode(rorigin);
		}
	}
}

public explode(Float:vec[3])
{
	new sound = GetConVarInt(g_hFireworksSound);
	new Float:normal[3]={0.0, 0.0, 1.0};
	new mag = 1000, Float:scale = 10.0;
	mag = 5000;
	scale = GetRandomFloat(1.0,12.0);
	if(sound == 1)
	{
		new randsnd = GetRandomInt(0,sizeof(g_sSounds)-1);
		EmitSoundFromOrigin(g_sSounds[randsnd], vec);
	}
	TE_SetupExplosion(vec, g_ExplosionSprite[0], scale, 1, 0, 0, mag, normal, '-');
	TE_SendToAll();
}

public spark(Float:vec[3])
{
	new Float:direction[3];
	new mag = 1000, trail = 5;
	mag = GetRandomInt(500,2000);
	trail = GetRandomInt(2,10);
	direction[0] = 0.0;
	direction[1] = 0.0;
	direction[2] = 0.0;
	TE_SetupSparks(vec, direction, mag, trail);
	TE_SendToAll();
}

public sphere(Float:vec[3])
{
	new Float:rpos[3], Float:radius, Float:phi, Float:theta, Float:live, Float: size, Float:delay;
	new Float:direction[3];
	new Float:spos[3];
	new bright = 255;
	direction[0] = 0.0;
	direction[1] = 0.0;
	direction[2] = 0.0;
	radius = GetRandomFloat(75.0,125.0);
	new randmod = GetRandomInt(1,sizeof(g_sModels)-1);
	for (new i=0;i<50;i++) {
		delay = GetRandomFloat(0.0,0.5);
		bright = GetRandomInt(128,255);
		live = 2.0 + delay;
		size = GetRandomFloat(0.5,0.7);
		phi = GetRandomFloat(0.0,6.283185);
		theta = GetRandomFloat(0.0,6.283185);
		spos[0] = radius*Sine(phi)*Cosine(theta);
		spos[1] = radius*Sine(phi)*Sine(theta);
		spos[2] = radius*Cosine(phi);
		rpos[0] = vec[0] + spos[0];
		rpos[1] = vec[1] + spos[1];
		rpos[2] = vec[2] + spos[2];
		TE_SetupGlowSprite(rpos, g_ExplosionSprite[randmod],live, size, bright);
		TE_SendToAll(delay);
	}
}

public EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}
