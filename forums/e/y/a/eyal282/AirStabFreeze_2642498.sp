#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

new const String:PLUGIN_VERSION[] = "1.0";

new KnifeStreak[MAXPLAYERS+1], Float:MaxNextKnifeCheck[MAXPLAYERS+1];

new Handle:hcv_MaxStreak = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Air Stab Freeze",
	author = "Eyal282",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{	
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	
	hcv_MaxStreak = CreateConVar("air_stab_freeze_max_streak", "6");
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	KnifeStreak[client] = 0;
	MaxNextKnifeCheck[client] = 0.0;
}

public Action:Event_PlayerHurt(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	KnifeStreak[attacker] = 0;
	MaxNextKnifeCheck[attacker] = 0.0;
}

public Action:Event_WeaponFire(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	RequestFrame(Frame_EventWeaponFire, GetEventInt(hEvent, "userid"));
}

public Frame_EventWeaponFire(UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
	
	new target = GetClientAimTarget(client, true);
	
	if(target > 0 && GetClientTeam(client) != GetClientTeam(target)) // If the client is actively trying to stab someone.
		return;
	
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(weapon == -1)
		return;
		
	new String:Classname[50];
	GetEdictClassname(weapon, Classname, sizeof(Classname));
	
	if(!StrEqual(Classname, "weapon_knife"))
		return;
	
	if(GetGameTime() <= MaxNextKnifeCheck[client])
		KnifeStreak[client]++;
		
	else
	{
		KnifeStreak[client] = 0;
		PrintToChat(client, "%.2f", MaxNextKnifeCheck[client] - GetGameTime());
	}
	MaxNextKnifeCheck[client] = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
	
	if(KnifeStreak[client] >= GetConVarInt(hcv_MaxStreak)-1)
	{
		new Float:Origin[3]; //  Making sure that the client won't ever block fall damage with this technique
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);
		Origin[0] = 0.0;
		Origin[1] = 0.0;
		PrintCenterText(client, "Your speed was punished for using a speeding technique that doesn't f***ing work!!!");
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Origin);
		KnifeStreak[client] = 0;
	}
}