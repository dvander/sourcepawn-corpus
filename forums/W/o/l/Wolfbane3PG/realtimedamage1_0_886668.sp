#include <sourcemod>
#include <sdktools>

//Damage slides along y-axis from Y1 to Y2, 0.5 being centre (or -1)
#define y1 0.42
#define y2 0.385
#define PLUGIN_VERSION "1.0.0"

new Handle:cvar_pluginEnabled = INVALID_HANDLE;
new Handle:cvar_toggleAnimate = INVALID_HANDLE;
static players[MAXPLAYERS]
 
//Plugin definitions
public Plugin:myinfo = 
{
 name = "Real-time Damage Display",
 author = "Wolfbane",
 description = "This plugin enables real-time damage display just above cross-hair location when dealing damage to a foe",
 version = PLUGIN_VERSION,
 url = "http://3-pg.com"
 }

 //Plugin start
 public OnPluginStart()
 {
 cvar_pluginEnabled = CreateConVar("realtimedamage_enabled", "1", "Displays damage inflicted on enemy. 0 - Disabled, 1 - Enabled", _, true, 0.0, true, 1.0)
 cvar_toggleAnimate = CreateConVar("realtimedamage_animate", "1", "Animates damage display. 0 - Disable, 1 - Enable", _, true, 0.0, true, 1.0)
 
 HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre)
 CreateTimer(0.1, UpdateHealth, _, TIMER_REPEAT)
 }
 
 //This function keeps track of current players' health
public Action:UpdateHealth(Handle:timer)
 {	
	if(GetConVarInt(cvar_pluginEnabled)==0)
		return
	new num = GetClientCount(true)
	for(new i = 1 ; i <= num; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
			players[i] = GetClientHealth(i)
 }
 
 //This function triggers when a player is damaged
 //calculates the amount and then calls DisplayDamage
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
 {	
	if(GetConVarInt(cvar_pluginEnabled)==0)
		return
		
	new attacker = GetEventInt(event, "attacker")
	new bool:killShot
	if (attacker < 1)//ignore worldspawn id
		return

	new victim = GetEventInt(event, "userid")
	new damageTaken = players[GetClientOfUserId(victim)] - GetEventInt(event, "health")
	
	//Determine if enemy was killed
	if (GetEventInt(event, "health") == 0)
		killShot=true
	else
		killShot=false

	new Handle:pack
	CreateDataTimer(0.1,  DisplayDamage, pack)
	WritePackCell(pack, attacker)
	WritePackCell(pack, damageTaken)
	WritePackFloat(pack, y1)
	WritePackCell(pack, killShot)
}

//This function handles displaying the damage to the attacker
public Action:DisplayDamage(Handle:timer, Handle:pack)
{
	new attackerID, damage, Float:yVal, r=0, b=125, g=125
	new bool:kCheck
	ResetPack(pack)
	attackerID = ReadPackCell(pack)
	damage = ReadPackCell(pack)
	yVal = ReadPackFloat(pack)
	kCheck = ReadPackCell(pack)
	
	if(kCheck != 0) //color red to indicate kill
	{	 
	r = 255
	b = 0
	g = 0
	}
	
	if ( GetConVarInt(cvar_toggleAnimate) == 0)
	{
		SetHudTextParams(-1.0, yVal, 1.2, r, g, b, 100, 0, 0.0, 0.0, 0.1)
		ShowHudText(GetClientOfUserId(attackerID),1,"%d", damage)
	}
	else if ( yVal <= y2 )//reached the top
		{
		SetHudTextParams(-1.0, yVal, 0.1, r, g, b, 100, 0, 0.0, 0.0, 0.1)
		ShowHudText(GetClientOfUserId(attackerID),1,"%d", damage)
		}
	else	
		{	
			SetHudTextParams(-1.0, yVal , 0.3, r, g, b, 100, 0, 0.0, 0.0, 0.0)
			ShowHudText(GetClientOfUserId(attackerID),1,"%d", damage)
			CreateDataTimer(0.1, DisplayDamage, pack)
			WritePackCell(pack, attackerID)
			WritePackCell(pack, damage)
			WritePackFloat(pack, (yVal-0.0035))
			WritePackCell(pack, kCheck)
		}
}