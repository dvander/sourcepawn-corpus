#include <sourcemod>
#include <sdktools>

//Damage slides along y-axis from Y1 to Y2, 0.5 being centre (or -1)
#define y1 0.42
#define y2 0.385
#define PLUGIN_VERSION "1.1"

//Declare global vars
new Handle:cvar_pluginEnabled = INVALID_HANDLE;
new Handle:cvar_toggleSlide = INVALID_HANDLE;
new Handle:cvar_triggerList = INVALID_HANDLE;
new Handle:cvar_default = INVALID_HANDLE;
static g_players[MAXPLAYERS]
static g_displayEnabled[MAXPLAYERS]
static g_maxConcurrentUsers
//static bool:g_critical=false

//Plugin definitions
public Plugin:myinfo = 
{
 name = "Real-time Damage Display",
 author = "Wolfbane",
 description = "This plugin enables real-time damage display just above cross-hair location when dealing damage",
 version = PLUGIN_VERSION,
 url = "http://3-pg.com"
 }

 //Plugin start
 public OnPluginStart()
 {
 g_maxConcurrentUsers = GetClientCount(true)
 cvar_pluginEnabled = CreateConVar("realtimedamage_enabled", "1", "Displays damage inflicted on enemy. 0 - Disabled, 1 - Enabled", _, true, 0.0, true, 1.0)
 cvar_toggleSlide = CreateConVar("realtimedamage_slide", "1", "Animates damage display with an upward slide. 0 - Disable, 1 - Enable", _, true, 0.0, true, 1.0)
 cvar_default = CreateConVar("realtimedamage_default", "1", "The default setting for a player upon joining the server. 0 - Disabled, 1 - Enabled", _, false, 0.0, false, 1.0)
 cvar_triggerList = CreateConVar("realtimedamage_triggers", "showdamage displaydamage", "Allows custom keywords to trigger displaying damage (Def. !showdamage, /showdamage, !displaydamage, /displaydamage)", _, false, 0.0 , false, 1.0)
 
 //Initialize displayEnabled to default setting
 new def = GetConVarInt(cvar_default)
 for(new i =0; i< MAXPLAYERS; i++)
	g_displayEnabled[i] = def
 
 RegisterTriggers() //Registers triggers based on cvar_triggerList
 HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre)
 }
 
//This function will register say hooks based on the trigger cvar
public RegisterTriggers()
{
 decl string: triggers[64][64]
 decl String: cvarVal[512]
 GetConVarString(cvar_triggerList, cvarVal, 512)
 new count = ExplodeString(cvarVal, " ", triggers, 64, 64)
 for (new i=0; i<count; i++)
	RegConsoleCmd(triggers[i],PlayerTogglePlugin, "Allows player to toggle Real-Time Damage Display on or off for themselves. Provided admin has plugin enabled in cvar realtimedamage_enable", _)
}
  
 /*This keeps track of maximum concurrent users. This is because client ID's 
 are assigned at connect time but not re-assigned when someone leaves.
 Thus you might have users 1,2,3,4 - and when '2' leaves the client count 
 drops to 3, but iteration will still be 1,2,3 and will not reach '4' anymore */
 public OnClientPutInServer(client)
 {
 if (GetClientCount(true) > g_maxConcurrentUsers)
	g_maxConcurrentUsers = GetClientCount(true)
 }
 
 //Reset g_displayEnabled back to default
 public OnClientDisconnect(client)
 {
	g_displayEnabled[client] = GetConVarInt(cvar_default)
 }
 
 //Toggles a player's damage display mode
public Action:PlayerTogglePlugin(client,args)
{
	if(GetConVarInt(cvar_pluginEnabled)==0)
		{
			PrintToChat(client, "\x04*** The admin has disabled this command ***");
			return
		}	

	new player = g_displayEnabled[client]
	//Switch statements only allow one command
	switch (player)
	{
	case 0:
		PrintToChat(client, "\x04*** [ON] Real-time Damage Display [ON] ***"); 
	case 1:
		PrintToChat(client, "\x04*** [OFF] Real-time Damage Display [OFF] ***");                                                    
	}
	// 2 x switch should optimize to be slightly faster than one if-else branch(?)
	switch (player)
	{
	case 0:
		g_displayEnabled[client] = 1
	case 1:
		g_displayEnabled[client] = 0                                                
	}
}

 
 //This function executes on every game frame, and keeps track of players' health
 public OnGameFrame()
 {
	if(GetConVarInt(cvar_pluginEnabled)==0)
		return
	for(new i = 1 ; i <= g_maxConcurrentUsers; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
			g_players[i] = GetClientHealth(i)		
 }
 
 //This function triggers when a player is damaged
 //Calculates the amount and then calls DisplayDamage
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
 {	
	if(GetConVarInt(cvar_pluginEnabled)==0)
		return
	
	new attacker = GetEventInt(event, "attacker")
	new attackerClientId = GetClientOfUserId(attacker)
	if (g_displayEnabled[attackerClientId] == 0)
		return

	new bool:killShot
	if (attacker < 1)//ignore worldspawn id
		return

	new victim = GetEventInt(event, "userid")
	new damageTaken = g_players[GetClientOfUserId(victim)] - GetEventInt(event, "health")
	//Determine if enemy was killed
	if (GetEventInt(event, "health") == 0)
		killShot=true
	else
		killShot=false

	new Handle:pack
	CreateDataTimer(0.1,  DisplayDamage, pack)
	WritePackCell(pack, attackerClientId)
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
	
	/*Critical detection still in the works
	if (g_critical) //color pink to indicate crit
	{
	r = 215
	g = 0
	b = 70
	g_critical=false
	}*/
	
	if(kCheck != 0) //color red to indicate kill
	{	 
	r = 255
	g = 0
	b = 0
	}
	if ( GetConVarInt(cvar_toggleSlide) == 0) //slide up animation disabled
	{
		SetHudTextParams(-1.0, yVal, 1.2, r, g, b, 100, 0, 0.0, 0.0, 0.1)
		ShowHudText(attackerID,1,"%d", damage)
	}
	else if ( yVal <= y2 )//reached the top
		{
		SetHudTextParams(-1.0, yVal, 0.1, r, g, b, 100, 0, 0.0, 0.0, 0.1)
		ShowHudText(attackerID,1,"%d", damage)
		}
	else	
		{	
			SetHudTextParams(-1.0, yVal , 0.3, r, g, b, 100, 0, 0.0, 0.0, 0.0)
			ShowHudText(attackerID,1,"%d", damage)
			CreateDataTimer(0.1, DisplayDamage, pack)
			WritePackCell(pack, attackerID)
			WritePackCell(pack, damage)
			WritePackFloat(pack, (yVal-0.0035))
			WritePackCell(pack, kCheck)
		}
}