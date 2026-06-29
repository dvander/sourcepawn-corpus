#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define	HIDEHUD_WEAPONSELECTION			( 1<<0 )	// Hide ammo count & weapon selection
#define	HIDEHUD_FLASHLIGHT			( 1<<1 )
#define	HIDEHUD_ALL				( 1<<2 )
#define HIDEHUD_HEALTH				( 1<<3 )	// Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD			( 1<<4 )	// Hide when local player's dead
#define HIDEHUD_NEEDSUIT			( 1<<5 )	// Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS			( 1<<6 )	// Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT				( 1<<7 )	// Hide all communication elements (saytext, voice icon, etc)
#define	HIDEHUD_CROSSHAIR			( 1<<8 )	// Hide crosshairs
#define	HIDEHUD_VEHICLE_CROSSHAIR		( 1<<9 )	// Hide vehicle crosshair
#define HIDEHUD_INVEHICLE			( 1<<10 )
#define HIDEHUD_BONUS_PROGRESS			( 1<<11 )	// Hide bonus progress display (for bonus map challenges)
#define HIDEHUD_RADAR				( 1<<12 )	// Hide the radar

#define HIDEHUD_BITCOUNT			13

int botCounter;
public void OnPluginStart()
{
	RegAdminCmd("bot", Command_AddBot, ADMFLAG_ROOT); 
	RegAdminCmd("changelevel2", Command_Changelevel2, ADMFLAG_CHANGEMAP, "changelevel2 <map>");
	HookEvent("player_spawn", Event_Spawn);
	AddNormalSoundHook(CritWeaponSH);
}
public void OnMapStart()
{
	PrecacheModel("models/player/Gordon.mdl");
}
public Action:CritWeaponSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (IsValidEntity(entity)) {
		char classname[256];
		GetEntityClassname(entity, classname, sizeof(classname))
		if (StrEqual(classname, "env_microphone", false)) {
			EmitSoundToAll(sample);
			return Plugin_Changed;
		}
	}
}
public void OnEntityCreated(int entity, const char[] classname) {
	if (IsValidEntity(entity)) {
		if (StrEqual(classname, "headcrab", false) || StrEqual(classname, "zombie", false)) {
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeHeadcrabDamage);
		}
		else if (StrEqual(classname, "ai_script_conditions", false)) {
			CreateTimer(0.0, Timer_ScriptThink, entity, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
		else if (StrEqual(classname, "npc_sniper", false)) {
			AcceptEntityInput(entity, "Kill")
		}
	}
}
public Action Command_AddBot(int client, int args)
{
	// testing command for fake clients
	++botCounter;
	char name[256];
	Format(name, sizeof(name), "Bot0%i", botCounter)
	CreateFakeClient(name);
	return Plugin_Handled;
}

stock int GetRandomPlayer(int client)
{
    new iClients[MaxClients+1], iNumClients;
    for(new i=1; i<=MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && client != i)
        {
            iClients[iNumClients++] = i;
        }
    }
    new iRandomClient = iClients[GetRandomInt(0, iNumClients-1)]; 
	return iRandomClient;
}  

public GivePlayerWeapon(int client, const char[] wpn)
{
	new entity = GivePlayerItem(client, wpn);
	if (entity != -1) {
		EquipPlayerWeapon(client, entity);
	}
}

public Action Event_Spawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
            new random = GetRandomPlayer(client); 
			if (random != 0 && random != -1 && IsValidClient(random)) {
                new Float:TeleportOrigin[3];
                new Float:PlayerOrigin[3];
                GetClientAbsOrigin(random, PlayerOrigin);
                
                //Math
                TeleportOrigin[0] = PlayerOrigin[0];
                TeleportOrigin[1] = PlayerOrigin[1];
                TeleportOrigin[2] = (PlayerOrigin[2]);
                
                //Teleport
                TeleportEntity(client, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
			}
	// fixes no solid bug after death
	SetEntProp(client, Prop_Data, "m_usSolidFlags", 0)
	SetEntProp(client, Prop_Data, "m_CollisionGroup", 2)
	// fixes chat
	DispatchKeyValue( client, "effects", "0" );
	CreateTimer(0.1, Timer_UnhideChat, client);
	
}
// straight up copy of basecommand's map command but hey, it works
public Action Command_Changelevel2(int client, int args)
{
	char map[PLATFORM_MAX_PATH];
	char displayName[PLATFORM_MAX_PATH];
	GetCmdArg(1, map, sizeof(map));

	if (FindMap(map, displayName, sizeof(displayName)) == FindMap_NotFound)
	{
		ReplyToCommand(client, "%t", "Map was not found", map);
		return Plugin_Handled;
	}

	GetMapDisplayName(displayName, displayName, sizeof(displayName));

	ShowActivity2(client, "Changing map to ", map);

	DataPack dp;
	CreateDataTimer(3.0, Timer_ChangeMap2, dp);
	dp.WriteString(map);

	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakePlayerDamage);
	PrintToChat(client, "This server is running Damien's HL2 Misc Fixes and is in PRE-ALPHA stages! Expect bugs and some (rare) crashes!");
}

Action OnTakePlayerDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (IsValidClient(victim) && IsValidClient(attacker))
	{	
		if (victim != attacker)
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}
Action OnTakeHeadcrabDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (damagetype & DMG_BLAST) {
		return Plugin_Handled;
	}

	return Plugin_Changed;
}

bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
}

public Action Timer_ScriptThink(Handle timer, int entity)
{
	if (IsValidEntity(entity))
	{

		DispatchKeyValue( entity, "OnConditionsSatisfied", "" );
		AcceptEntityInput( entity, "Disable" );

	}
}
public Action Timer_UnhideChat(Handle timer, int client)
{
	SetEntProp(client, Prop_Data, "m_iHideHUD", 0);
	
	char name[256];
	GetCurrentMap(name,sizeof(name))
	for(int i=1;i<40;i++){
		GivePlayerAmmo(client,6000,i,true);
	}
	if (StrContains(name,"d1_trainstation_0") == -1 && StrContains(name,"d1_canals_0") == -1 && StrContains(name,"d1_eli_0") == -1)
	{
		GivePlayerWeapon(client,"weapon_physcannon");
	}
	if (StrContains(name,"d1_trainstation_0") == -1 || StrContains(name,"d1_trainstation_06") != -1) {

		GivePlayerWeapon(client,"weapon_smg1");
		GivePlayerWeapon(client,"weapon_crowbar");
		GivePlayerWeapon(client,"weapon_stunstick");
		GivePlayerWeapon(client,"weapon_pistol");
		GivePlayerWeapon(client,"weapon_357");
		GivePlayerWeapon(client,"weapon_ar2");
		GivePlayerWeapon(client,"weapon_shotgun");
		GivePlayerWeapon(client,"weapon_frag");
		GivePlayerWeapon(client,"weapon_crossbow");
		GivePlayerWeapon(client,"weapon_rpg");
		GivePlayerWeapon(client,"weapon_bugbait");
		GivePlayerWeapon(client,"item_suit");

	}
}
public Action Timer_ChangeMap2(Handle timer, DataPack dp)
{
	char map[PLATFORM_MAX_PATH];

	dp.Reset();
	dp.ReadString(map, sizeof(map));

	ServerCommand("changelevel %s", map);

	return Plugin_Stop;
}