/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "L4D FF Announce Plugin",
	author = "Frustian",
	description = "Adds Friendly Fire Announcements",
	version = "1.4",
	url = ""
}
//cvar handles
new Handle:FFenabled;
new Handle:AnnounceType
//Various global variables
new DamageCache[MAXPLAYERS+1][MAXPLAYERS+1]; //Used to temporarily store Friendly Fire Damage between teammates
new Handle:FFTimer[MAXPLAYERS+1]; //Used to be able to disable the FF timer when they do more FF
new bool:FFActive[MAXPLAYERS+1]; //Stores whether players are in a state of friendly firing teammates
new Handle:directorready;
public OnPluginStart()
{
	CreateConVar("l4d_ff_announce_version", "1.4", "Версия плагина",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	FFenabled = CreateConVar("l4d_ff_announce_enable", "1", "Вкл/Выкл плагин",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	AnnounceType = CreateConVar("l4d_ff_announce_type", "1", "Как отображать дружественный урон (1:В чат; 2:Хинт сообщение; 3:По центру)",FCVAR_PLUGIN|FCVAR_SPONLY);
	HookEvent("player_hurt_concise", Event_HurtConcise, EventHookMode_Post);
	AutoExecConfig(true, "l4dffannounce");
	directorready = FindConVar("director_ready_duration");
}

public Action:Event_HurtConcise(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "attackerentid");
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!GetConVarInt(FFenabled) || !GetConVarInt(directorready) || attacker > MaxClients || attacker < 1 || !IsClientConnected(attacker) || !IsClientInGame(attacker) || IsFakeClient(attacker) || GetClientTeam(attacker) != 2 || !IsClientInGame(victim) || !IsClientConnected(victim) || GetClientTeam(victim) != 2)
		return;  //if director_ready_duration is 0, it usually means that the game is in a ready up state like downtown1's ready up mod.  This allows me to disable the FF messages in ready up.
	new damage = GetEventInt(event, "dmg_health");
	if (FFActive[attacker])  //If the player is already friendly firing teammates, resets the announce timer and adds to the damage
	{
		new Handle:pack;
		DamageCache[attacker][victim] += damage;
		KillTimer(FFTimer[attacker]);
		FFTimer[attacker] = CreateDataTimer(1.0, AnnounceFF, pack);
		WritePackCell(pack,attacker);
	}
	else //If it's the first friendly fire by that player, it will start the announce timer and store the damage done.
	{
		DamageCache[attacker][victim] = damage;
		new Handle:pack;
		FFActive[attacker] = true;
		FFTimer[attacker] = CreateDataTimer(1.0, AnnounceFF, pack);
		WritePackCell(pack,attacker);
		for (new i = 1; i < 19; i++)
		{
			if (i != attacker && i != victim)
			{
				DamageCache[attacker][i] = 0;
			}
		}
	}
}
public Action:AnnounceFF(Handle:timer, Handle:pack) //Called if the attacker did not friendly fire recently, and announces all FF they did
{
	decl String:victim[128];
	decl String:attacker[128];
	ResetPack(pack);
	new attackerc = ReadPackCell(pack);
	FFActive[attackerc] = false;
	if (IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
		GetClientName(attackerc, attacker, sizeof(attacker));
	else
		attacker = "Disconnected Player";
	for (new i = 1; i < MaxClients; i++)
	{
		if (DamageCache[attackerc][i] != 0 && attackerc != i)
		{
			if (IsClientInGame(i) && IsClientConnected(i))
			{
				GetClientName(i, victim, sizeof(victim));
				switch(GetConVarInt(AnnounceType))
				{
					case 1:
					{
						if (IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
							PrintToChat(attackerc, "\x01[\x04FF\x01] \x04Ты нанёс \x03%d \x04урона игроку \x05%s",DamageCache[attackerc][i],victim);
						if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
							PrintToChat(i, "[FF] Игрок %s нанёс тебе %d урона",attacker,DamageCache[attackerc][i]);
					}
					case 2:
					{
						if (IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
							PrintHintText(attackerc, "Ты нанёс %d урона игроку %s",DamageCache[attackerc][i],victim);
						if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
							PrintHintText(i, "Игрок %s нанёс тебе %d урона",attacker,DamageCache[attackerc][i]);
					}
					case 3:
					{
						if (IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
							PrintCenterText(attackerc, "Ты нанёс %d урона игроку %s",DamageCache[attackerc][i],victim);
						if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
							PrintCenterText(i, "Игрок %s нанёс тебе %d урона",attacker,DamageCache[attackerc][i]);
					}
				}
			}
			DamageCache[attackerc][i] = 0;
		}
	}
}