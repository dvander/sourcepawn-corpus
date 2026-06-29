#pragma	semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define STRING_SIZE 128
#define CHARACTERS 8
#define	TEAM_SURVIVORS	2
#define	TEAM_INFECTED	3
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

#define MODEL_NICK "models/survivors/survivor_gambler.mdl"
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl"
#define MODEL_COACH "models/survivors/survivor_coach.mdl"
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl"

#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"

static int ExplosionSprite, IsGrab[MAXPLAYERS + 1] = {0, ...}, il4d2_heroic_pipe_key;
static ConVar l4d2_heroic_pipe_on, l4d2_heroic_pipe_grabbed, l4d2_heroic_pipe_incapped, l4d2_heroic_pipe_key, l4d2_heroic_pipe_debug, l4d2_heroic_pipe_radius, l4d2_heroic_pipe_power, l4d2_heroic_pipe_setup[CHARACTERS];
static bool bl4d2_heroic_pipe_grabbed, bl4d2_heroic_pipe_incapped, bl4d2_heroic_pipe_debug;

static Handle BoomTimers[MAXPLAYERS + 1] = {null, ...};
static char SOUND_BYE[CHARACTERS][STRING_SIZE];
static float Times[CHARACTERS];

static const char EXPLOSION_SOUND[] = 	"weapons/hegrenade/explode5.wav";
static const char SOUND_DIRECTORY[][] = 
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

public Plugin myinfo = 
{
	name = "Heroic pipe",
	author = "OIRV",
	description = "If you have a pipe bomb and you are incapped or grabbed for any SI, you can explode yourself",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart() 
{																								   
	CreateConVar("l4d2_heroic_pipe_version", PLUGIN_VERSION, "Heroic pipe version", CVAR_FLAGS|FCVAR_DONTRECORD);
	l4d2_heroic_pipe_on = CreateConVar("l4d2_heroic_pipe_on", "1", "Plugin On/Off", CVAR_FLAGS);
	l4d2_heroic_pipe_grabbed = CreateConVar("l4d2_heroic_pipe_grabbed", "1", "Enable explosion when the player is incapped", CVAR_FLAGS);
	l4d2_heroic_pipe_incapped = CreateConVar("l4d2_heroic_pipe_incapped", "1", "Enable explosion when the player is grabbed by any SI", CVAR_FLAGS);
	l4d2_heroic_pipe_key = CreateConVar("l4d2_heroic_pipe_key", "32", "Key", CVAR_FLAGS);
	l4d2_heroic_pipe_debug = CreateConVar("l4d2_heroic_pipe_debug", "0", "Display some info in the chat", CVAR_FLAGS);
	l4d2_heroic_pipe_radius = CreateConVar("l4d2_heroic_pipe_radius", "250.0", "Sets the explosion radius", CVAR_FLAGS);
	l4d2_heroic_pipe_power = CreateConVar("l4d2_heroic_pipe_power", "300.0", "Sets the explosion power", CVAR_FLAGS);

	l4d2_heroic_pipe_setup[0] = CreateConVar("l4d2_heroic_pipe_nick", "taunt03.wav, 2.0", "Setup for Nick", CVAR_FLAGS);
	l4d2_heroic_pipe_setup[1] = CreateConVar("l4d2_heroic_pipe_rochelle", "battlecry02.wav, 1.0", "Setup for Rochelle", CVAR_FLAGS);
	l4d2_heroic_pipe_setup[2] = CreateConVar("l4d2_heroic_pipe_coach", "fall02.wav, 1.6", "Setup for Coach", CVAR_FLAGS);
	l4d2_heroic_pipe_setup[3] = CreateConVar("l4d2_heroic_pipe_ellis", "fall03.wav, 1.6", "Setup for Ellis", CVAR_FLAGS);

	l4d2_heroic_pipe_setup[4] = CreateConVar("l4d2_heroic_pipe_bill", "swears04.wav, 1.8", "Setup for Bill", CVAR_FLAGS);
	l4d2_heroic_pipe_setup[5] = CreateConVar("l4d2_heroic_pipe_zoey", "swear09.wav, 1.0", "Setup for Zoey", CVAR_FLAGS);
	l4d2_heroic_pipe_setup[6] = CreateConVar("l4d2_heroic_pipe_francis", "swear08.wav, 2.0", "Setup for Francis", CVAR_FLAGS);
	l4d2_heroic_pipe_setup[7] = CreateConVar("l4d2_heroic_pipe_louis", "taunt07.wav, 2.2", "Setup for Louis", CVAR_FLAGS);

	l4d2_heroic_pipe_on.AddChangeHook(SetupPluginOn);
	l4d2_heroic_pipe_grabbed.AddChangeHook(SetupCharactersChanged);
	l4d2_heroic_pipe_incapped.AddChangeHook(SetupCharactersChanged);
	l4d2_heroic_pipe_key.AddChangeHook(SetupCharactersChanged);
	l4d2_heroic_pipe_debug.AddChangeHook(SetupCharactersChanged);
	l4d2_heroic_pipe_setup[0].AddChangeHook(SetupCharactersChanged);
	l4d2_heroic_pipe_setup[1].AddChangeHook(SetupCharactersChanged);
	l4d2_heroic_pipe_setup[2].AddChangeHook(SetupCharactersChanged);
	l4d2_heroic_pipe_setup[3].AddChangeHook(SetupCharactersChanged);
	l4d2_heroic_pipe_setup[4].AddChangeHook(SetupCharactersChanged);
	l4d2_heroic_pipe_setup[5].AddChangeHook(SetupCharactersChanged);
	l4d2_heroic_pipe_setup[6].AddChangeHook(SetupCharactersChanged);
	l4d2_heroic_pipe_setup[7].AddChangeHook(SetupCharactersChanged);

	LoadTranslations("l4d2_heroic_pipe.phrases");
	AutoExecConfig(true, "l4d2_heroic_pipe");

	for(int i = 0; i < MaxClients; i++) IsGrab[i] = 0;
}

public void OnMapStart() 
{
	ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	for(int i = 0; i < CHARACTERS; i++) UpdateSetup(i);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void IsAllowed()
{
	bool PluginOn = l4d2_heroic_pipe_on.BoolValue;
	if(PluginOn)
	{
		GetCvars();
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
	}
	else
	{
		UnhookEvent("jockey_ride", EventVictimGrabbed, EventHookMode_Pre);
		UnhookEvent("jockey_ride_end", EventVictimReleased, EventHookMode_Pre);
		UnhookEvent("tongue_grab", EventVictimGrabbed, EventHookMode_Pre);
		UnhookEvent("tongue_release", EventVictimReleased, EventHookMode_Pre);
		UnhookEvent("charger_pummel_start", EventVictimGrabbed, EventHookMode_Pre);
		UnhookEvent("charger_pummel_end", EventVictimReleased, EventHookMode_Pre);
		UnhookEvent("lunge_pounce", EventVictimGrabbed, EventHookMode_Pre);
		UnhookEvent("pounce_stopped", EventVictimReleased, EventHookMode_Pre);
		UnhookEvent("pounce_end", EventVictimReleased, EventHookMode_Pre);
		UnhookEvent("player_death", EventPlayerDeath);
	}
}

void GetCvars()
{
	bl4d2_heroic_pipe_grabbed = l4d2_heroic_pipe_grabbed.BoolValue;
	bl4d2_heroic_pipe_incapped = l4d2_heroic_pipe_incapped.BoolValue;
	il4d2_heroic_pipe_key = l4d2_heroic_pipe_key.IntValue;
	bl4d2_heroic_pipe_debug = l4d2_heroic_pipe_debug.BoolValue;
	UpdateSetup(0);
	UpdateSetup(1);
	UpdateSetup(2);
	UpdateSetup(3);
	UpdateSetup(4);
	UpdateSetup(5);
	UpdateSetup(6);
	UpdateSetup(7);
}

void SetupPluginOn(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void SetupCharactersChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	GetCvars();
}

void EventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && client <= MaxClients)
	{
		if(bl4d2_heroic_pipe_debug) CPrintToChatAll("%t", "Dead", client);
		IsGrab[client] = 0;
	}
}

Action EventVictimGrabbed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if(client > 0 && client <= MaxClients)
	{
		if(bl4d2_heroic_pipe_debug) CPrintToChatAll("%t", "Grabbed", client);
		IsGrab[client] = 1;
	}
	return Plugin_Continue;
}

Action EventVictimReleased(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if(client > 0 && client <= MaxClients)
	{
		if(bl4d2_heroic_pipe_debug) CPrintToChatAll("%t", "Released", client);
		IsGrab[client] = 0;
	}
	return Plugin_Continue;
}

void UpdateSetup(any id)
{
	static char setup[2][64], buffer[64];
	l4d2_heroic_pipe_setup[id].GetString(buffer, sizeof(buffer));
	ExplodeString(buffer, ",", setup, sizeof setup, sizeof setup[]);
	Format(SOUND_BYE[id], STRING_SIZE, "%s%s", SOUND_DIRECTORY[id],setup[0]);
	Times[id] = StringToFloat(setup[1]);	
	PrecacheSound(SOUND_BYE[id]);
}

int GetCharacterID(any client)
{
	int id = 0;
	char model[STRING_SIZE];
	GetClientModel(client, model, sizeof(model));

	if (StrEqual(model, MODEL_NICK, false)) id = 0;
	if (StrEqual(model, MODEL_ROCHELLE, false)) id = 1;
	if (StrEqual(model, MODEL_COACH, false)) id = 2;
	if (StrEqual(model, MODEL_ELLIS, false)) id = 3;
	if (StrEqual(model, MODEL_BILL, false)) id = 4;
	if (StrEqual(model, MODEL_ZOEY, false)) id = 5;
	if (StrEqual(model, MODEL_FRANCIS, false)) id = 6;
	if (StrEqual(model, MODEL_LOUIS, false)) id = 7;

	return id;
}

Action Boom(Handle timer, any client)
{
	int weapon_id = GetPlayerWeaponSlot(client, 2);
	if(IsValidEdict(weapon_id))
	{
		RemoveEdict(weapon_id);	
		Explosion(client);

		int flags = GetCommandFlags("explode");
		SetCommandFlags("explode", flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "explode");
		SetCommandFlags("explode", flags|FCVAR_CHEAT);

		if(bl4d2_heroic_pipe_debug) PrintToChat(client, "BOOM!");
	}
	KillBoomTimer(client);
	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		if(bl4d2_heroic_pipe_debug && buttons != 0) PrintToChat(client,"Key [%d]", buttons);

		int offset = GetEntSendPropOffs(client, "m_isIncapacitated"), is_incap = GetEntData(client, offset, 1), is_grab = IsGrab[client], proceed = 0;
		if(bl4d2_heroic_pipe_incapped && bl4d2_heroic_pipe_grabbed) proceed = is_incap || is_grab;
		else if(bl4d2_heroic_pipe_incapped && !bl4d2_heroic_pipe_grabbed) proceed = is_incap && !is_grab;
		else if(!bl4d2_heroic_pipe_incapped && bl4d2_heroic_pipe_grabbed)	proceed = !is_incap && is_grab;
 
		if((buttons & il4d2_heroic_pipe_key) && proceed)
		{
			int weapon_id = GetPlayerWeaponSlot(client, 2);	
			if(IsValidEdict(weapon_id))
			{
				char classname[64];
				GetEdictClassname(weapon_id, classname, sizeof(classname));
				if(StrEqual(classname, "weapon_pipe_bomb", false)) CreateBoomTimer(client);
			}	
		}
		else KillBoomTimer(client);
	}
	return Plugin_Continue;
}

void CreateBoomTimer(int client)
{
	if (BoomTimers[client] == null)
	{
		float origin[3];
		GetClientAbsOrigin(client, origin);
		int survivor = GetCharacterID(client);
		EmitSoundToAll(SOUND_BYE[survivor], 1, SNDCHAN_VOICE, SNDLEVEL_SCREAMING , SND_NOFLAGS, SNDVOL_NORMAL, 100, _, origin, NULL_VECTOR, false, 0.0);
		BoomTimers[client] = CreateTimer(Times[survivor], Boom, client);
		if(bl4d2_heroic_pipe_debug) CPrintToChatAll("%t", "BTS", client);
	}
}

void KillBoomTimer(int client)
{
	if (BoomTimers[client] != null)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				int survivor = GetCharacterID(client);				
				StopSound(i, SNDCHAN_VOICE, SOUND_BYE[survivor]);
			}
		}
		BoomTimers[client] = null;
		if(bl4d2_heroic_pipe_debug) CPrintToChatAll("%t", "BTA", client);
	}
}

void Explosion(int target) 
{
	char radius[64], power[64];
	l4d2_heroic_pipe_radius.GetString(radius, sizeof(radius));
	l4d2_heroic_pipe_power.GetString(power, sizeof(radius));

	float origin[3];
	GetClientAbsOrigin(target, origin);	

	int exEntity = CreateEntityByName("env_explosion");
 	DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
	DispatchKeyValue(exEntity, "iMagnitude", "600");
	DispatchKeyValue(exEntity, "iRadiusOverride", radius);
	DispatchKeyValue(exEntity, "spawnflags", "828");
	DispatchSpawn(exEntity);
	TeleportEntity(exEntity, origin, NULL_VECTOR, NULL_VECTOR);

	int exPhys = CreateEntityByName("env_physexplosion");
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

/**************************************************************************
 *                                                                        *
 *          	 	     	 New color inc   				    	      *
 *                          Author: Ernecio (updated by pan0s)            *
 *                           Version: 1.0.1                               *
 *                                                                        *
 **************************************************************************/
enum
{
	SERVER_INDEX	= 0,
	NO_INDEX		= -1,
	NO_PLAYER		= -2,
	BLUE_INDEX		= 2,
	RED_INDEX		= 3,
}

stock const char CTag[][] 				= { "{DEFAULT}", "{ORANGE}", "{CYAN}", "{RED}", "{BLUE}", "{GREEN}" };
stock const char CTagCode[][] 			= { "\x01", "\x04", "\x03", "\x03", "\x03", "\x05" };
stock const bool CTagReqSayText2[]	 	= { false, false, true, true, true, false };
stock const int CProfile_TeamIndex[] 	= { NO_INDEX, NO_INDEX, SERVER_INDEX, RED_INDEX, BLUE_INDEX, NO_INDEX };

/**
 * @note Prints a message to a specific client in the chat area.
 * @note Supports color tags.
 *
 * @param client 		Client index.
 * @param sMessage 		Message (formatting rules).
 * @return 				No return
 *
 * On error/Errors:   If the client is not connected an error will be thrown.
 */
stock void CPrintToChat(int client, const char[] sMessage, any ...)
{
	if( client <= 0 || client > MaxClients )
		ThrowError( "Invalid client index %d", client);

	if( !IsClientInGame(client) )
		ThrowError( "Client %d is not in game", client);

	static char sBuffer[250];
	static char sCMessage[250];
	SetGlobalTransTarget(client);
	Format(sBuffer, sizeof(sBuffer), "\x01%s", sMessage);
	VFormat( sCMessage, sizeof( sCMessage ), sBuffer, 3);

	int index = CFormat(sCMessage, sizeof(sCMessage));
	if( index == NO_INDEX )
		PrintToChat(client, sCMessage);
	else
		CSayText2(client, index, sCMessage);
}

/**
 * @note Prints a message to all clients in the chat area.
 * @note Supports color tags.
 *
 * @param client		Client index.
 * @param sMessage 		Message (formatting rules)
 * @return 				No return
 */
stock void CPrintToChatAll(const char[] sMessage, any ...)
{
	static char sBuffer[250];

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(sBuffer, sizeof(sBuffer), sMessage, 2);
			CPrintToChat(i, sBuffer);
		}
	}
}

/**
 * @note Replaces color tags in a string with color codes
 *
 * @param sMessage    String.
 * @param maxlength   Maximum length of the string buffer.
 * @return			  Client index that can be used for SayText2 author index
 *
 * On error/Errors:   If there is more then one team color is used an error will be thrown.
 */
stock int CFormat(char[] sMessage, int maxlength)
{
	int iRandomPlayer = NO_INDEX;

	for( int i = 0; i < sizeof(CTagCode); i++ )											//	Para otras etiquetas de color se requiere un bucle.
	{
		if( StrContains( sMessage, CTag[i]) == -1 ) 										//	Si no se encuentra la etiqueta, omitir.
			continue;
		else if( !CTagReqSayText2[i] )
			ReplaceString(sMessage, maxlength, CTag[i], CTagCode[i]); 					//	Si la etiqueta no necesita Saytext2 simplemente reemplazará.
		else																				//	La etiqueta necesita Saytext2.
		{
			if( iRandomPlayer == NO_INDEX )													//	Si no se especificó un cliente aleatorio para la etiqueta, reemplaca la etiqueta y busca un cliente para la etiqueta.
			{
				iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i]); 			//	Busca un cliente válido para la etiqueta, equipo de infectados oh supervivientes.
				if( iRandomPlayer == NO_PLAYER )
					ReplaceString(sMessage, maxlength, CTag[i], CTagCode[5]);	 			//	Si no se encuentra un cliente valido, reemplasa la etiqueta con una etiqueta de color verde.
				else
					ReplaceString(sMessage, maxlength, CTag[i], CTagCode[i]); 				// 	Si el cliente fue encontrado simplemente reemplasa.
			}
			else 																			//	Si en caso de usar dos colores de equipo infectado y equipo de superviviente juntos se mandará un mensaje de error.
				ThrowError("Using two team colors in one message is not allowed"); 			//	Si se ha usadó una combinación de colores no validad se registrara en la carpeta logs.
		}
	}

	return iRandomPlayer;
}

/**
 * @note Founds a random player with specified team
 *
 * @param color_team  Client team.
 * @return			  Client index or NO_PLAYER if no player found
 */
stock int CFindRandomPlayerByTeam(int color_team)
{
	if( color_team == SERVER_INDEX )
		return 0;
	else
		for( int i = 1; i <= MaxClients; i++ )
			if( IsClientInGame(i) && GetClientTeam(i) == color_team )
				return i;

	return NO_PLAYER;
}

/**
 * @note Sends a SayText2 usermessage to a client
 *
 * @param sMessage 		Client index
 * @param maxlength 	Author index
 * @param sMessage 		Message
 * @return 				No return.
 */
stock void CSayText2(int client, int author, const char[] sMessage)
{
	Handle hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, sMessage);
	EndMessage();
}
