#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool instagibEnabled = false; // Enable/disable Instagib mode

public Plugin myinfo =
{
	name = "Instagib",
	author = "Inpu",
	description = "Instagib for GmanMusk",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{

	PrecacheSound("misc/HitSoundInsta.mp3");
	PrecacheSound("misc/prepareforbattle.mp3");

	RegConsoleCmd("sm_instagib", ToggleInstagibMode);

    RegConsoleCmd("sm_instagibTry", TryActivateInstagib);

	HookEvent("player_death", OnPlayerDeath);

	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre); // http://wiki.alliedmods.net/Generic_Source_Server_Events#server_cvar

}

public Action:Event_ServerCvar(Handle:event, const String:name[], bool:dontBroadcast)
{
     return Plugin_Handled;
}

public Action:ToggleInstagibMode(client,args) {
  if (!instagibEnabled) {
        ActivateInstagib();
        PrintToChatAll("\x04[INSTAGIB] Mode enabled!");
    } else {
        PrintToChat(client, "[INSTAGIB] Mode is already enabled!");
    }
}

public Action:TryActivateInstagib(client,args) {

    SetRandomSeed( RoundFloat( GetEngineTime() ) );
    new number = GetRandomInt(1, 4);

    //PrintToChatAll("Number is \"%d\" ", number);

    if (instagibEnabled) {
        return;
    }



   if(number == 1){
     ActivateInstagib();
     PrintToChatAll("\x04ELON MUSK KILLED: INSTAGIB/DOUBLE JUMP enabled for 30 seconds!");
   }else{
       PrintToChatAll("\x04ELON MUSK KILLED: INSTAGIB/DOUBLE JUMP Activation FAILED, try again!");
   }

}


void ActivateInstagib() {
    instagibEnabled = true;
    EmitSoundToAll("misc/prepareforbattle.mp3");

    // Increase player speed
    SetPlayerSpeedMultiplier(true);

    // Schedule automatic deactivation after 30 seconds
    CreateTimer(30.0, DisableInstagibMode);
}

Action DisableInstagibMode(Handle timer) {
    if (!instagibEnabled) return Plugin_Continue;

    instagibEnabled = false;
    PrintToChatAll("\x04[INSTAGIB] Mode disabled!");

    SetPlayerSpeedMultiplier(false);
    return Plugin_Continue;
}

public OnClientPutInServer(client){
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

    SDKHook(client, SDKHook_PreThinkPost, ClassPreThinkPost);
}

void SetPlayerSpeedMultiplier(bool enable) {
    if (enable) {
        //ServerCommand("sv_maxspeed 600");
        ServerCommand("sv_gravity 200");
        ServerCommand("sm_doublejump_enabled 1");
        ServerCommand("sm_instaON");
    } else {
        //ServerCommand("sv_maxspeed 320");
        ServerCommand("sv_gravity 600");
       ServerCommand("sm_doublejump_enabled 0");
         ServerCommand("sm_instaOFF");
    }
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{

    if(instagibEnabled){
    	damage = 255.0;

    	  float customForce[3];
            customForce[0] = 500.0;  // Force sur l'axe X
            customForce[1] = 500.0;  // Force sur l'axe Y
            customForce[2] = 1000.0; // Force verticale sur Z

            // Appliquer la force directement à la victime
            ApplyForceToClient(victim, customForce);

    	return Plugin_Changed;
    }

    return Plugin_Continue;
}

void ApplyForceToClient(int client, float velocity[3])
{
    if (!IsValidClient(client)) return;

    float origin[3];
    GetClientAbsOrigin(client, origin);

    // Téléporter avec une vélocité définie
    TeleportEntity(client, origin, NULL_VECTOR, velocity);
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    if (!instagibEnabled) return;

    int victim = event.GetInt("userid");
    int attacker = event.GetInt("attacker");

    int victimID = GetClientOfUserId(victim);
    int attackerID = GetClientOfUserId(attacker);

    EmitSoundToClient(victimID, "misc/HitSoundInsta.mp3");
    EmitSoundToClient(attackerID, "misc/HitSoundInsta.mp3");
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

public ClassPreThinkPost(client)
{


    if (!instagibEnabled){
        //SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 200.0);
        //SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);

        new speed = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");
        if(speed == 400.0){
            SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 200.0);
        }

    }else{
        SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 400.0);
        //SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 2.0);
    }

}