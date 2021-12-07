#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include <sdktools>
#include <franug_zp>
#include <zombiereloaded>
#include <sdkhooks>
#include <emitsoundany>
#include <cstrike>
#include <clientprefs>

// configuration part
#define ROUNDNAME "Nemesis" // Name of award
#define CHANCE 80 // Award price
#define TRANSLATIONS "plague_nemesis.phrases" // Set translations file for this subplugin
// end configuration

new Handle:AmmoTimer3;
new Handle:cvarInterval3;
new Float:FInterval3;
new Handle:cvarNemesisLife;
new iNemesisLife;
new Handle:cvarNemesisZombieSkin;
new String:SNemesisZombieSkin[64];

new VelocityOffset_0;
new VelocityOffset_1;
new BaseVelocityOffset;
new Handle:hPush;
new Float:fPush;
new Handle:hHeight;
new Float:fHeight;
new Nemesis;


new ISaveClassNemesis;

// dont touch
public OnPluginStart()
{
	CreateTimer(0.1, Lateload);
	RegAdminCmd("sm_nemesis", RondaA, ADMFLAG_CUSTOM2);
	HookEvent("round_start", InicioRonda);
	HookEvent("player_jump", EventPlayerJump);
	
	VelocityOffset_0=FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	if(VelocityOffset_0==-1)
	SetFailState("[BunnyHop] Error: Failed to find Velocity[0] offset, aborting");
	VelocityOffset_1=FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	if(VelocityOffset_1==-1)
	SetFailState("[BunnyHop] Error: Failed to find Velocity[1] offset, aborting");
	BaseVelocityOffset=FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	if(BaseVelocityOffset==-1)
	SetFailState("[BunnyHop] Error: Failed to find the BaseVelocity offset, aborting");
	
	// Create cvars
	hPush=CreateConVar("bunnyhop_push","1.0","The forward push when you jump (for nemesis)");
	hHeight=CreateConVar("bunnyhop_height","5.0","The upward push when you jump (for nemesis)");
	cvarInterval3 = CreateConVar("hp_interval", "1.0", "Show HP of survivor/nemesis each X second.", _, true, 1.0);
	cvarNemesisLife = CreateConVar("zr_nemesis_life", "1000", "Life/humans");
	cvarNemesisZombieSkin = CreateConVar("zr_nemesis_zombie_skin", "models/player/colateam/nemesis/nemesis.mdl", "Path to the Nemesis Skin, don't forgot to precache and add it to download !");
}

public Action:Lateload(Handle:timer)
{
	LoadTranslations(TRANSLATIONS); // translations to the local plugin
	ZP_LoadTranslations(TRANSLATIONS); // sent translations to the main plugin
	
	ZP_AddRound(ROUNDNAME, CHANCE); // add award to the main plugin
}

public CvarChanges(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarNemesisZombieSkin)
	{
		GetConVarString(cvarNemesisZombieSkin, SNemesisZombieSkin, sizeof(SNemesisZombieSkin));
	}
	else if (convar == hHeight)
	{
		fHeight = GetConVarFloat(hHeight);
	}
	else if (convar == hPush)
	{
		fPush = GetConVarFloat(hPush);
	}
	else if (convar == cvarNemesisLife)
	{
		iNemesisLife = GetConVarInt(cvarNemesisLife);
	}
	else if (convar == cvarInterval3)
	{
		FInterval3 = GetConVarFloat(cvarInterval3);
	}
}

public OnConfigsExecuted()
{
	GetConVarString(cvarNemesisZombieSkin, SNemesisZombieSkin, sizeof(SNemesisZombieSkin));
	fHeight = GetConVarFloat(hHeight);
	fPush = GetConVarFloat(hPush);
	iNemesisLife = GetConVarInt(cvarNemesisLife);
	FInterval3 = GetConVarFloat(cvarInterval3);
}

public OnPluginEnd()
{
	ZP_RemoveRound(ROUNDNAME); // remove award when the plugin is unloaded
}
// END dont touch part

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
    StopRound();
} 

public Action:unload(Handle:event, const String:name[], bool:dontBroadcast)
{
	StopRound();
}

public ZP_OnRoundSelected(const String:roundselected[])
{
	if(StrEqual(roundselected, ROUNDNAME))
	{
		// use your custom code here
		DoRound();
	}
}

DoRound()
{
	HookEvent("round_end",  unload);
	Nemesis = JugadorAleatorio();
	if(Nemesis < 0) return;
	CreateTimer(0.5, pasado);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/franug/zombie_plague/Nemesis/nemesis_pain1.mp3");
	AddFileToDownloadsTable("sound/franug/zombie_plague/Nemesis/nemesis_pain2.mp3");
	AddFileToDownloadsTable("sound/franug/zombie_plague/Nemesis/nemesis_pain3.mp3");
	PrecacheSoundAny("franug/zombie_plague/Nemesis/nemesis_pain1.mp3");
	PrecacheSoundAny("franug/zombie_plague/Nemesis/nemesis_pain2.mp3");
	PrecacheSoundAny("franug/zombie_plague/Nemesis/nemesis_pain3.mp3");
	AddFileToDownloadsTable("sound/franug/zombie_plague/Nemesis/nemesis1.mp3");
	AddFileToDownloadsTable("sound/franug/zombie_plague/Nemesis/nemesis2.mp3");
	PrecacheSoundAny("franug/zombie_plague/Nemesis/nemesis1.mp3");
	PrecacheSoundAny("franug/zombie_plague/Nemesis/nemesis2.mp3");
	AddFileToDownloadsTable("sound/franug/zombie_plague/Nemesis/gp_nms.mp3");
	PrecacheSoundAny("franug/zombie_plague/Nemesis/gp_nms.mp3");
}

public Action:pasado(Handle:timer)
{
	if(!IsClientInGame(Nemesis) || !IsPlayerAlive(Nemesis)) return;

	ISaveClassNemesis=GetZombieClass(Nemesis);
	ZR_SelectClientClass(Nemesis, ZR_GetClassByName("nemesis"));
	ZR_InfectClient(Nemesis);
	ZP_SetSpecial(Nemesis, true);

	new jugadores;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			jugadores++;
		}
	}

	PrintToChatAll(" \x04[SM_Franug-ZombiePlague] \x05%t","RONDA NEMESIS!");
	new vida_nemesis = (jugadores * iNemesisLife);
	new random = GetRandomInt(1, 2);
	switch(random)
	{
	case 1:
		{
			EmitSoundToAllAny("franug/zombie_plague/Nemesis/nemesis1.mp3");
		}
	case 2:
		{
			EmitSoundToAllAny("franug/zombie_plague/Nemesis/nemesis2.mp3");
		}
	}

	SetEntityHealth(Nemesis, vida_nemesis);
	DarLuz(Nemesis);
	SetEntityRenderColor(Nemesis, 255, 0, 0, 255);
	ServerCommand("zr_respawn 0");
	ServerCommand("zr_zspawn 0");
	//ServerCommand("zr_class_doublejump_max 5");
	EmitSoundToAllAny("franug/zombie_plague/Nemesis/gp_nms.mp3", SOUND_FROM_PLAYER, SNDCHAN_VOICE);
	
	if (AmmoTimer3 != INVALID_HANDLE) {
		KillTimer(AmmoTimer3);
	}
	
	AmmoTimer3 = CreateTimer(FInterval3, ResetAmmo3, _, TIMER_REPEAT);
}

public Action:ResetAmmo3(Handle:timer)
{
	if(IsValidClient(Nemesis) && IsPlayerAlive(Nemesis))
	{
		new vida_nemesiss = GetClientHealth(Nemesis);
		PrintHintTextToAll("%t","Vida del NEMESIS", vida_nemesiss);
	}
}

public Action:InicioRonda(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Nemesis != 0)
	{
		Nemesis = false;
	}
	ServerCommand("zr_respawn 1");
	ServerCommand("zr_zspawn 1");
}

public OnClientDisconnect(client)
{
	if(Nemesis == client)
	{
		ServerCommand("mp_restartgame 2");
		Nemesis = 0;
		ZP_SetSpecial(Nemesis, false);
		PrintToChatAll("\x04[SM_Franug-ZombiePlague] \x05%t","El jugador NEMESIS se ha desconectado");
	}
}

public IsValidClient( client ) 
{ 
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
	return false; 
	
	return true; 
}

JugadorAleatorio()
{
	new clients[MaxClients+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && IsPlayerAlive(i))
	clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
} 

public Action:EventPlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (Nemesis == client) saltoalto13(client);
}

saltoalto13(client)
{
	new Float:finalvec[3];
	finalvec[0]=GetEntDataFloat(client,VelocityOffset_0)*fPush/2.0;
	finalvec[1]=GetEntDataFloat(client,VelocityOffset_1)*fPush/2.0;
	finalvec[2]=fHeight*50.0;
	SetEntDataVector(client,BaseVelocityOffset,finalvec,true);
	new Float:pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	new number = GetRandomInt(1, 3);
	switch (number)
	{
	case 1:
		{
			EmitSoundToAllAny("franug/zombie_plague/Nemesis/nemesis_pain1.mp3", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
		}
	case 2:
		{
			EmitSoundToAllAny("franug/zombie_plague/Nemesis/nemesis_pain2.mp3", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
		}
	case 3:
		{
			EmitSoundToAllAny("franug/zombie_plague/Nemesis/nemesis_pain3.mp3", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos);
		}
	}
}

public Action:RondaA(client, args)
{
	ZP_ChooseRound(ROUNDNAME);
}

GetZombieClass(client)
{
	new String:buff[4];
	GetClientCookie(client, FindClientCookie("zr_zombieclass"), buff, sizeof(buff));
	return StringToInt(buff)-1;//-1 car commence à compter à 1
}

StopRound()
{
	if (Nemesis>0)
	{
		if (IsClientInGame(Nemesis) && IsPlayerAlive(Nemesis))
		{
			ZR_SelectClientClass(Nemesis, ISaveClassNemesis);
		}
		for (new i = 1; i <= MaxClients; i++){
			if (IsClientInGame(i) && IsPlayerAlive(i)){
				ZP_SetSpecial(i, false);
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		Nemesis=0;
	}
}

DarLuz(ent)
{
	decl String:tName[128];
	Format(tName, sizeof(tName), "lighttarget%i", ent);
	DispatchKeyValue(ent, "targetname", tName);
						
	decl String:light_name[128];
	Format(light_name, sizeof(light_name), "light%i", ent);
						
	new luz = CreateEntityByName("light_dynamic");
						
						
	DispatchKeyValue(luz,"targetname", light_name);
	DispatchKeyValue(luz, "parentname", tName);
	DispatchKeyValue(luz, "inner_cone", "0");
	DispatchKeyValue(luz, "cone", "100");
	DispatchKeyValue(luz, "brightness", "1");
	DispatchKeyValueFloat(luz, "spotlight_radius", 300.0);
						
	DispatchKeyValue(luz, "pitch", "200");
	DispatchKeyValue(luz, "style", "5");
	DispatchKeyValue(luz, "classname", "luzxd");
	DispatchKeyValue(luz, "_light", "255 0 0 255");
	DispatchKeyValueFloat(luz, "distance", 300.0);
	DispatchSpawn(luz);
						
	new Float:ClientsPos[3];
	GetClientAbsOrigin(ent, ClientsPos);
	//Entity_GetAbsOrigin(ent, ClientsPos);
	//ClientsPos[2] += 90.0;
	TeleportEntity(luz, ClientsPos, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(tName);
	AcceptEntityInput(luz, "SetParent");
	SetEntPropEnt(ent, Prop_Send, "m_hEffectEntity", luz);
	//Entity_SetParent(luz, ent);
	AcceptEntityInput(luz, "TurnOn");
}

public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
	if(attacker != 0 && Nemesis == attacker)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (Nemesis>0 && IsValidClient(attacker))
	{
		new WeaponIndex = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEdict(WeaponIndex) || !IsValidEdict(WeaponIndex)) return Plugin_Continue;
		
		new String:weapon[32];
		GetClientWeapon(attacker,weapon, sizeof(weapon));
		if (ZR_IsClientZombie(attacker) && attacker==Nemesis){ 
			damage = 3000.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}