#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#define ACHIEVEMENT_SOUND	"misc/achievement_earned.wav"
#define ITEM_LOSE			"player/crit_hit_mini.wav"

#define ITEM_FIREWORKS		0
#define MAXCVARS			1

new g_Target			[MAXPLAYERS + 1];
new g_Ent				[MAXPLAYERS + 1];
new Handle:g_cvars[MAXCVARS];

public Plugin:myinfo = 
{
	name = "False Items + Achievements",
	author = "Jindo",
	description = "Can display false messages for finding/losing items and earning achievements.",
	version = "1.1.0",
	url = "http://www.topaz-games.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_item", Command_FakeItem, ADMFLAG_SLAY);
	RegAdminCmd("sm_achievement", Command_FakeAchievement, ADMFLAG_SLAY);
	RegAdminCmd("sm_buymsg", Command_FakeLose, ADMFLAG_SLAY);
	HookEvent("item_found", Event_Item_Found);
	g_cvars[ITEM_FIREWORKS] = CreateConVar("sm_enable_item_fireworks", "0", "Enables/disables the use of the firework effects when a real and/or fake item is found.");
	
	AutoExecConfig(true, "plugin.fakemessages");
}

public OnMapStart()
{
	InitPrecache();
}

InitPrecache()
{
	PrecacheSound(ACHIEVEMENT_SOUND, true);
	PrecacheSound(ITEM_LOSE, true);
}

StartLooper(client)
{
	if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		CreateTimer(0.01, Timer_Particles, client, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.5, Timer_Trophy, client, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(2.0, Timer_Particles, client, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(10.0, Timer_Delete, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Event_Item_Found(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_cvars[ITEM_FIREWORKS]))
	{
		
		new playerId = GetEventInt(event, "player");
		if (IsPlayerAlive(playerId) && IsClientConnected(playerId) && IsClientInGame(playerId))
		{
			StartLooper(playerId);
			new Float:playerPos[3] ;
			GetEntPropVector(playerId, Prop_Send, "m_vecOrigin", playerPos);
			EmitAmbientSound(ACHIEVEMENT_SOUND, playerPos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
		}
		
	}
}

public Action:Timer_Particles(Handle:timer, any:client)
{
	if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		AttachParticle(client, "mini_fireworks");
	}
	
	return Plugin_Handled;
}

public Action:Timer_Trophy(Handle:timer, any:client)
{
	if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		AttachParticle(client, "achieved");
	}
	
	return Plugin_Handled;
}

public Action:Timer_Delete(Handle:timer, any:client)
{
	DeleteParticle(g_Ent[client]);
	g_Ent[client] = 0;
	g_Target[client] = 0;
}

public Action:Command_FakeItem(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "\x04[SM]\x01 Usage: sm_fakeitem <target> <weapon_name>");
		return Plugin_Handled;
	}
	
	new String:player[64];
	GetCmdArg(1, player, sizeof(player));	
	new String:weapon[64];
	GetCmdArg(2, weapon, sizeof(weapon));
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i=0; i<target_count; i++)
	{
		ItemMessage(target_list[i], weapon);
	}
	
	return Plugin_Handled;
}

public Action:Command_FakeLose(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "\x04[SM]\x01 Usage: sm_fakelose <target> <weapon_name>");
		return Plugin_Handled;
	}
	
	new String:player[64];
	GetCmdArg(1, player, sizeof(player));	
	new String:weapon[64];
	GetCmdArg(2, weapon, sizeof(weapon));
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i=0; i<target_count; i++)
	{
		LoseMessage(target_list[i], weapon);
	}
	
	return Plugin_Handled;
}

public Action:Command_FakeAchievement(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "\x04[SM]\x01 Usage: sm_fakeachievement <target> <achievement_name>");
		return Plugin_Handled;
	}
	
	new String:player[64];
	GetCmdArg(1, player, sizeof(player));	
	new String:achieve[64];
	GetCmdArg(2, achieve, sizeof(achieve));
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i=0; i<target_count; i++)
	{
		AchievementMessage(target_list[i], achieve);
	}
	
	return Plugin_Handled;
}

stock ItemMessage(client, String:weapon[64])
{
	new String:message[200];
	Format(message, sizeof(message), "\x03%N\x01 has found: \x05%s", client, weapon);
	SayText2(client, message);
	
	if (GetConVarBool(g_cvars[ITEM_FIREWORKS]))
	{
		
		if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
		{
			StartLooper(client);
			new Float:playerPos[3] ;
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerPos);
			EmitAmbientSound(ACHIEVEMENT_SOUND, playerPos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
		}
	
	}
	
	return;
}

stock LoseMessage(client, String:weapon[64])
{
	new String:message[200];
	Format(message, sizeof(message), "\x03%N\x01 has bought a \x05%s", client, weapon);
	SayText2(client, message);
	if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		new Float:playerPos[3] ;
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerPos);
		EmitAmbientSound(ITEM_LOSE, playerPos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
	}
	return;
}

stock AchievementMessage(client, String:achievement[64])
{
	new String:message[200];
	Format(message, sizeof(message), "\x03%N\x01 has earned the achievement \x05%s", client, achievement);
	SayText2(client, message);
	if (IsPlayerAlive(client) && IsClientConnected(client) && IsClientInGame(client))
	{
		StartLooper(client);
		new Float:playerPos[3] ;
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerPos);
		EmitAmbientSound(ACHIEVEMENT_SOUND, playerPos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
	}
	return;
}

stock SayText2(author_index , const String:message[] ) {
    new Handle:buffer = StartMessageAll("SayText2");
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}

AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system");
	
	new String:tName[128];
	if (IsValidEdict(particle))
	{
		new Float:pos[3] ;
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 74
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetVariantString("flag");
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		g_Ent[ent] = particle;
		g_Target[ent] = 1;
	}
}

DeleteParticle(any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
    }
}