#pragma	semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define STRING_SIZE 128
#define CHARACTERS 8
#define	TEAM_SURVIVORS	2
#define	TEAM_INFECTED	3
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

#define MODEL_NICK "models/survivors/survivor_gambler.mdl"
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl"
#define MODEL_COACH "models/survivors/survivor_coach.mdl"
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl"

#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"


static ExplosionSprite;
static Handle:l4d2_heroic_pipe_grabbed = INVALID_HANDLE;
static Handle:l4d2_heroic_pipe_incapped = INVALID_HANDLE;
static Handle:l4d2_heroic_pipe_key = INVALID_HANDLE;
static Handle:l4d2_heroic_pipe_debug = INVALID_HANDLE;
static Handle:l4d2_heroic_pipe_radius = INVALID_HANDLE;
static Handle:l4d2_heroic_pipe_power = INVALID_HANDLE;
static Handle:l4d2_heroic_pipe_setup[CHARACTERS];

static Handle:BoomTimers[MAXPLAYERS];
static String:SOUND_BYE[CHARACTERS][STRING_SIZE];
static Float:Times[CHARACTERS];
static IsGrab[MAXPLAYERS];

static const String:EXPLOSION_SOUND[] = 	"weapons/hegrenade/explode5.wav";
static const String:SOUND_DIRECTORY[][] = 
{
	"player/survivor/voice/gambler/",
	"player/survivor/voice/producer/",
	"player/survivor/voice/coach/",
	"player/survivor/voice/mechanic/",
	"player/survivor/voice/namvet/",
	"player/survivor/voice/teengirl/",
	"player/survivor/voice/biker/",
	"player/survivor/voice/manager/"
};

public Plugin:myinfo = 
{
	name = "Heroic pipe",
	author = "OIRV",
	description = "If you have a pipe bomb and you are incapped or grabbed for any SI, you can explode yourself",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart() 
{																								   
	CreateConVar("l4d2_heroic_pipe_version", PLUGIN_VERSION, "Heroic pipe version", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	l4d2_heroic_pipe_grabbed = CreateConVar("l4d2_heroic_pipe_grabbed","1", "Enable explosion when the player is incapped", CVAR_FLAGS);
	l4d2_heroic_pipe_incapped = CreateConVar("l4d2_heroic_pipe_incapped","1", "Enable explosion when the player is grabbed by any SI", CVAR_FLAGS);
	l4d2_heroic_pipe_key = CreateConVar("l4d2_heroic_pipe_key","32", "Key", CVAR_FLAGS);
	l4d2_heroic_pipe_debug = CreateConVar("l4d2_heroic_pipe_debug","0", "Display some info in the chat", CVAR_FLAGS);
	l4d2_heroic_pipe_radius = CreateConVar("l4d2_heroic_pipe_radius","250", "Sets the explosion radius", CVAR_FLAGS);
	l4d2_heroic_pipe_power = CreateConVar("l4d2_heroic_pipe_power","300", "Sets the explosion power", CVAR_FLAGS);
	
	l4d2_heroic_pipe_setup[0] = CreateConVar("l4d2_heroic_pipe_nick","taunt03.wav,2.0", "Setup for Nick", CVAR_FLAGS);
	l4d2_heroic_pipe_setup[1] = CreateConVar("l4d2_heroic_pipe_rochelle","battlecry02.wav,1.0", "Setup for Rochelle", CVAR_FLAGS);
	l4d2_heroic_pipe_setup[2] = CreateConVar("l4d2_heroic_pipe_coach","fall02.wav,1.6", "Setup for Coach", CVAR_FLAGS);
	l4d2_heroic_pipe_setup[3] = CreateConVar("l4d2_heroic_pipe_ellis","fall03.wav,1.6", "Setup for Ellis", CVAR_FLAGS);

	l4d2_heroic_pipe_setup[4] = CreateConVar("l4d2_heroic_pipe_bill","swears04.wav,1.8", "Setup for Bill", CVAR_FLAGS);
	l4d2_heroic_pipe_setup[5] = CreateConVar("l4d2_heroic_pipe_zoey","swear09.wav,1.0", "Setup for Zoey", CVAR_FLAGS);
	l4d2_heroic_pipe_setup[6] = CreateConVar("l4d2_heroic_pipe_francis","swear08.wav,2.0", "Setup for Francis", CVAR_FLAGS);
	l4d2_heroic_pipe_setup[7] = CreateConVar("l4d2_heroic_pipe_louis","taunt07.wav,2.2", "Setup for Louis", CVAR_FLAGS);

	AutoExecConfig(true, "l4d2_heroic_pipe");
	
	HookConVarChange(l4d2_heroic_pipe_setup[0], SetupNickChanged);
	HookConVarChange(l4d2_heroic_pipe_setup[1], SetupRochelleChanged);
	HookConVarChange(l4d2_heroic_pipe_setup[2], SetupCoachChanged);
	HookConVarChange(l4d2_heroic_pipe_setup[3], SetupEllisChanged);
	
	HookConVarChange(l4d2_heroic_pipe_setup[4], SetupBillChanged);
	HookConVarChange(l4d2_heroic_pipe_setup[5], SetupZoeyChanged);
	HookConVarChange(l4d2_heroic_pipe_setup[6], SetupFrancisChanged);
	HookConVarChange(l4d2_heroic_pipe_setup[7], SetupLouisChanged);

	HookEvent("jockey_ride", EventVictimGrabbed, EventHookMode_Pre);
	HookEvent("jockey_ride_end", EventVictimReleased, EventHookMode_Pre);
	HookEvent("tongue_grab", EventVictimGrabbed, EventHookMode_Pre);
	HookEvent("tongue_release", EventVictimReleased, EventHookMode_Pre);
	HookEvent("charger_pummel_start", EventVictimGrabbed, EventHookMode_Pre);
	HookEvent("charger_pummel_end", EventVictimReleased, EventHookMode_Pre);
	HookEvent("lunge_pounce", EventVictimGrabbed, EventHookMode_Pre);
	HookEvent("pounce_stopped", EventVictimReleased, EventHookMode_Pre);
	HookEvent("pounce_end", EventVictimReleased, EventHookMode_Pre);
	
	HookEvent("player_death", EventPlayerDeath);
	
	for(new i = 0; i < MAXPLAYERS;i++)
	{
		IsGrab[i] = 0;
	}
}
public OnMapStart() 
{
	ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");

	for(new i = 0; i < CHARACTERS; i++)
	{
		UpdateSetup(i);
	}

}
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetEventInt(event, "userid");
	new client = GetClientOfUserId(victim);
	

	if(client>0 && client <= MAXPLAYERS)
	{
		if(GetConVarInt(l4d2_heroic_pipe_debug))
		{
			PrintToChatAll("Client [%d] is dead", client);
		}
		IsGrab[client-1] = 0;
	}
		
	
}
public Action:EventVictimGrabbed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetEventInt(event, "victim");
	new client = GetClientOfUserId(victim);
	
	if(client>0 && client <= MAXPLAYERS)
	{
		if(GetConVarInt(l4d2_heroic_pipe_debug))
		{
			PrintToChatAll("Client [%d] grabbed",client);
		}

		IsGrab[client-1] = 1;
		
	}
	return Plugin_Continue;
}
public Action:EventVictimReleased(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetEventInt(event, "victim");
	new client = GetClientOfUserId(victim);
	
	if(client>0 && client <= MAXPLAYERS)
	{
		if(GetConVarInt(l4d2_heroic_pipe_debug))
		{
			PrintToChatAll("Client [%d] released",client);
		}
		IsGrab[client-1] = 0;
	}

	return Plugin_Continue;
}

public UpdateSetup(any:id)
{
	static String:setup[2][64];
	static String:buffer[64];
	
	GetConVarString(l4d2_heroic_pipe_setup[id], buffer, sizeof(buffer));
	ExplodeString(buffer, ",", setup, sizeof setup, sizeof setup[]);		
	 		
	Format(SOUND_BYE[id], STRING_SIZE, "%s%s", SOUND_DIRECTORY[id],setup[0]);
	
	Times[id] = StringToFloat(setup[1]);	
	
	if (!IsSoundPrecached(SOUND_BYE[id]))
	{
		PrecacheSound(SOUND_BYE[id]);
	}
}
public GetCharacterID(any:client)
{
	new id = 0;
	decl String:model[STRING_SIZE];
	GetClientModel(client, model, sizeof(model));
	
	if (StrEqual(model, MODEL_NICK, false))
		id = 0;
	if (StrEqual(model, MODEL_ROCHELLE, false))
		id = 1;
	if (StrEqual(model, MODEL_COACH, false))
		id = 2;
	if (StrEqual(model, MODEL_ELLIS, false))
		id = 3;
		
	if (StrEqual(model, MODEL_BILL, false))
		id = 4;
	if (StrEqual(model, MODEL_ZOEY, false))
		id = 5;
	if (StrEqual(model, MODEL_FRANCIS, false))
		id = 6;
	if (StrEqual(model, MODEL_LOUIS, false))
		id = 7;
		
	return id;
}
public Action:Boom(Handle:timer, any:client)
{
	new weapon_id = GetPlayerWeaponSlot(client, 2);
	if(IsValidEdict(weapon_id))
	{
		RemoveEdict(weapon_id);	
		Explosion(client);
		
		new flags = GetCommandFlags("explode");
		SetCommandFlags("explode", flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "explode");
		SetCommandFlags("explode", flags|FCVAR_CHEAT);
		
		if(GetConVarInt(l4d2_heroic_pipe_debug))
		{
			PrintToChat(client, "BOOM!"); 
		}
	}
	KillBoomTimer(client);
	
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	decl String:classname[64];
	
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		if(GetConVarInt(l4d2_heroic_pipe_debug) && buttons!=0)
		{
			PrintToChat(client,"Key [%d]", buttons);
		}
		
		new offset = GetEntSendPropOffs(client, "m_isIncapacitated");
		new is_incap = GetEntData(client,offset,1);
		new is_grab = IsGrab[client-1];
		new proceed = 0;
		
		if(GetConVarInt(l4d2_heroic_pipe_incapped) && GetConVarInt(l4d2_heroic_pipe_grabbed))
		{
			proceed = is_incap || is_grab;
		}
		else		
		if(GetConVarInt(l4d2_heroic_pipe_incapped) && !GetConVarInt(l4d2_heroic_pipe_grabbed))
		{
			proceed = is_incap && !is_grab;
		}
		else
		if(!GetConVarInt(l4d2_heroic_pipe_incapped) && GetConVarInt(l4d2_heroic_pipe_grabbed))		
		{
			proceed = !is_incap && is_grab;
		}		
 		
		if((buttons & GetConVarInt(l4d2_heroic_pipe_key)) && proceed)
		{
			new weapon_id = GetPlayerWeaponSlot(client, 2);	
			
			if(IsValidEdict(weapon_id))
			{
				GetEdictClassname(weapon_id, classname, sizeof(classname));
				
				if(StrEqual(classname, "weapon_pipe_bomb", false))
				{
					CreateBoomTimer(client);			
				}

			}
			
		}
		else
		{
			KillBoomTimer(client);
		}
		 
	}
	
	
	return Plugin_Continue;
}
public CreateBoomTimer(client)
{
	if (BoomTimers[client-1] == INVALID_HANDLE)
	{
		decl Float:origin[3];
		GetClientAbsOrigin(client, origin);
			
		
		new survivor = GetCharacterID(client);
		
		EmitSoundToAll(SOUND_BYE[survivor], 1, SNDCHAN_VOICE, SNDLEVEL_SCREAMING , SND_NOFLAGS, SNDVOL_NORMAL, 100, _, origin, NULL_VECTOR, false, 0.0);
		BoomTimers[client-1] = CreateTimer(Times[survivor], Boom, client);	
		
		if(GetConVarInt(l4d2_heroic_pipe_debug))
		{
			PrintToChatAll("Client [%d]: Boom Timer Started", client);
		}
	}	
}
public KillBoomTimer(client)
{
	if (BoomTimers[client-1] != INVALID_HANDLE)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if (IsClientInGame(i))
			{
				new survivor = GetCharacterID(client);				
				StopSound(i, SNDCHAN_VOICE, SOUND_BYE[survivor]);
			}
		} 
		KillTimer(BoomTimers[client-1]);
		BoomTimers[client-1] = INVALID_HANDLE;
		
		if(GetConVarInt(l4d2_heroic_pipe_debug))
		{
			PrintToChatAll("Client [%d]: Boom Timer Aborted", client);	
		}
	}
}
public Explosion(target) 
{ 
	decl String:radius[64];
	decl String:power[64];
 
	GetConVarString(l4d2_heroic_pipe_radius, radius, sizeof(radius));
	GetConVarString(l4d2_heroic_pipe_power, power, sizeof(radius));
	
	decl Float:origin[3];
	GetClientAbsOrigin(target, origin);	

	new exEntity = CreateEntityByName("env_explosion");
	
 	DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
	DispatchKeyValue(exEntity, "iMagnitude", "600");
	DispatchKeyValue(exEntity, "iRadiusOverride", radius);
	DispatchKeyValue(exEntity, "spawnflags", "828");
	DispatchSpawn(exEntity);
	TeleportEntity(exEntity, origin, NULL_VECTOR, NULL_VECTOR);
	
	new exPhys = CreateEntityByName("env_physexplosion");
	
	DispatchKeyValue(exPhys, "radius", radius);
	DispatchKeyValue(exPhys, "magnitude", power);
	DispatchSpawn(exPhys);
	TeleportEntity(exPhys, origin, NULL_VECTOR, NULL_VECTOR);
	
	AcceptEntityInput(exPhys, "Explode"); 
	AcceptEntityInput(exEntity, "Explode");
  
	TE_SetupExplosion(origin, ExplosionSprite, StringToFloat(power), 1, 0, StringToInt(radius), 5000);
	TE_SendToAll(); 
 
	EmitSoundToAll(EXPLOSION_SOUND);
}
public SetupNickChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateSetup(0);
}
public SetupRochelleChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateSetup(1);
}
public SetupCoachChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateSetup(2);
}
public SetupEllisChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateSetup(3);
}
public SetupBillChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateSetup(4);
}
public SetupZoeyChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateSetup(5);
}
public SetupFrancisChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateSetup(6);
}
public SetupLouisChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateSetup(7);
}