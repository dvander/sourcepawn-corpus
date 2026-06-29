/* 
  First Blood Rewards
  Author(s): -MCG-Retsam
  File: firstblood_rewards.sp
  Description: Player who gets first kill is awarded with a menu of choices of abilities.
  
  0.2	- Added cvar for random reward instead of menu. Fixed up a few things.
  0.1	- Initial Release
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.2"

//Rewards
#define NO_EFFECT       0
#define REWARD_BEGIN		1
#define REWARD_CRITS 		1
#define REWARD_GOD  		2
#define REWARD_INVIS 		3
#define REWARD_FIREAMMO 		4
#define REWARD_VAMPIRE 		5
#define REWARD_HEALTH 		6
#define REWARD_SENTRY 		7
#define REWARD_END			7

//Define Invis stuff
#define INVIS					{255,255,255,0}
#define NORMAL					{255,255,255,255}

//Sounds
#define FIRST_BLOOD2 	"vo/announcer_am_firstblood02.wav"
#define FB_MENU "buttons/button3.wav"
#define REWARD_HPSOUND "items/medshot4.wav"
#define REWARD_INVISON "player/spy_cloak.wav"
#define REWARD_INVISOFF "player/spy_uncloak.wav"
#define REWARD_SENTRYDROP "items/spawn_item.wav"
#define REWARD_FIRESOUND "ambient/fire/gascan_ignite1.wav"

new g_iFirstkill;
new Handle:g_fbrenabled = INVALID_HANDLE;
new Handle:g_firstbloodMsg = INVALID_HANDLE;
new Handle:g_firstbloodSound = INVALID_HANDLE;
new Handle:g_firstbloodTimer = INVALID_HANDLE;
new Handle:g_ArenaFBCvar = INVALID_HANDLE;
new Handle:g_critsTime 		= INVALID_HANDLE;
new Handle:g_godTime 		= INVALID_HANDLE;
new Handle:g_invisTime 		= INVALID_HANDLE;
new Handle:g_fireammoTime 		= INVALID_HANDLE;
new Handle:g_vampTime 		= INVALID_HANDLE;
new Handle:g_vampAmount 		= INVALID_HANDLE;
new Handle:g_hpbuffamount 		= INVALID_HANDLE;
new Handle:g_sentryTime 		= INVALID_HANDLE;
new Handle:g_fbrewardsMode 		= INVALID_HANDLE;
new Handle:g_RewardTimerHandle[MAXPLAYERS+1] = INVALID_HANDLE;
new bool:IsFbcEnabled = true;
new bool:IsFBarenaEnabled = true;
new bool:gCanBeRun = false;

new vleechAmount;
new CTimerCount[MAXPLAYERS+1];
new buildsg[MAXPLAYERS+1];
new clientReward[MAXPLAYERS+1];
new clientStatus[MAXPLAYERS+1];

//new rewardPool[TOTAL_REWARDS];
//new rewardPoolNum = TOTAL_REWARDS;

new c_ownerOffset;

static const TFClass_VampireMaxHP[TFClassType] = 
{
  50, 175, 175, 250, 225,
  200, 350, 225, 175, 175
};

public Plugin:myinfo = 
{
	name = "First Blood Rewards",
	author = "-MCG-Retsam",
	description = "Player who gets first blood gets a popup menu to choose a reward",
	version = PLUGIN_VERSION,
	url = "www.multiclangaming.net"
};

public OnPluginStart()
{
  CreateConVar("sm_fbrewards_version", PLUGIN_VERSION, "FirstBlood Rewards version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  
  g_fbrenabled = CreateConVar("sm_fbrewards_enabled", "1", "Enable/Disable first blood rewards plugin. (1/0 = yes/no)");
  g_fbrewardsMode = CreateConVar("sm_fbrewards_mode", "1", "Mode for first blood rewards. (1/2) 1=menu popup 2=random");
  g_firstbloodMsg = CreateConVar("sm_fbrewards_msgs", "1", "Display first blood reward messages/info? (1/0 = yes/no)");
  g_firstbloodSound = CreateConVar("sm_fbrewards_emitsound", "1", "Emit the first blood sound file files? (1/0 = yes/no)");
  g_firstbloodTimer = CreateConVar("sm_fbrewards_timer", "1", "Enable the center screen timer countdown? (1/0 = yes/no)");
  g_ArenaFBCvar    = CreateConVar("sm_arenafirstblood","0","Enable tf2 first blood cvar in arena mode? (1/0 = yes/no)");
  g_critsTime = CreateConVar("sm_fbrewards_crits_period", "15.0", "Period in seconds for crits duration.");
  g_godTime = CreateConVar("sm_fbrewards_god_period", "20.0", "Period in seconds for godmode duration.");
  g_invisTime = CreateConVar("sm_fbrewards_invis_period", "25.0", "Period in seconds for invis duration.");
  g_fireammoTime = CreateConVar("sm_fbrewards_fireammo_period", "60.0", "Period in seconds for fire ammo duration.");
  g_vampTime = CreateConVar("sm_fbrewards_vampire_period", "100.0", "Period in seconds for vampire life leech duration.");
  g_vampAmount = CreateConVar("sm_fbrewards_vampire_amount", "12.0", "Health amount leeched per hit for vampire.");
  g_hpbuffamount = CreateConVar("sm_fbrewards_health_amount", "600.0", "Health amount for health buff reward.");
  g_sentryTime = CreateConVar("sm_fbrewards_sentry_period", "120", "Period in seconds before sentry is auto-destroyed.");
  
  HookConVarChange(g_fbrenabled, CvarEnableChanged);
  if(GetConVarInt(g_fbrenabled) == 1)
  {
    HookEvent("player_death", hook_Playersdying, EventHookMode_Post);
    HookEvent("player_hurt", hook_PlayerGotHurt);
    
    //Round Start Events
    HookEvent("teamplay_round_start", hook_RoundStartEvents, EventHookMode_Post);
    HookEvent("teamplay_round_active", hook_RoundStartEvents, EventHookMode_Post);
    HookEvent("teamplay_restart_round", hook_RoundStartEvents, EventHookMode_Post);
    HookEvent("teamplay_setup_finished", hook_RoundStartEvents, EventHookMode_Post);
    
    //Round END Events
    HookEvent("teamplay_round_win", hook_RoundEndEvents, EventHookMode_PostNoCopy);
    HookEvent("teamplay_game_over", hook_RoundEndEvents, EventHookMode_PostNoCopy);
  }	
  
  vleechAmount = 0;
  c_ownerOffset = FindSendPropInfo("CTFWearableItem", "m_hOwnerEntity");

  AutoExecConfig(true, "plugin.firstbloodrewards");
}

public OnClientPostAdminCheck(client)
{
  CTimerCount[client] = 0;
  clientReward[client] = 0;
  clientStatus[client] = 0;
  buildsg[client] = 0;
}

public OnClientDisconnect(client)
{
  if(g_RewardTimerHandle[client] != INVALID_HANDLE)
  {
        KillTimer(g_RewardTimerHandle[client]);
        g_RewardTimerHandle[client] = INVALID_HANDLE;
  }
  
  CTimerCount[client] = 0;
  clientReward[client] = 0;
  clientStatus[client] = 0;
  buildsg[client] = 0;
}

public OnConfigsExecuted()
{
	IsFbcEnabled = GetConVarBool(g_fbrenabled);
	IsFBarenaEnabled = GetConVarBool(g_ArenaFBCvar);
	
  HookConVarChange(g_ArenaFBCvar, ConVarChange_ArenaFBCvar);
  
  PrecacheSound(FIRST_BLOOD2, true);
  PrecacheSound(FB_MENU, true);
  PrecacheSound(REWARD_HPSOUND, true);
  PrecacheSound(REWARD_SENTRYDROP, true);
  PrecacheSound(REWARD_INVISON, true);
  PrecacheSound(REWARD_INVISOFF, true);
  PrecacheSound(REWARD_FIRESOUND, true);
  
  ArenaCvar_Check();
}

public ArenaCvar_Check()
{
  if(!IsFBarenaEnabled)
  {
        ServerCommand ("sm_cvar tf_arena_first_blood 0");
  }      
}

public ConVarChange_ArenaFBCvar(Handle:convar, const String:oldValue[], const String:newValue[])
{
      	if (newValue[0] == '0')
        {
                ServerCommand ("sm_cvar tf_arena_first_blood 0");
        }
        else
        {
                ServerCommand ("sm_cvar tf_arena_first_blood 1.0");
        }
} 

public Action:hook_RoundStartEvents(Handle:event, const String:name[], bool:dontBroadcast)
{
        gCanBeRun = false;

        if(StrEqual(name, "teamplay_round_active", false))
        {
            gCanBeRun = true;
            g_iFirstkill = 0;
            //PrintToChatAll("[teamplay_round_active being fired]");
        }
        else if(StrEqual(name, "teamplay_setup_finished"))
        {
            for(new client = 1; client <= MaxClients ; client++)
            {
                ResetRewards(client);
            }
            gCanBeRun = true;
            g_iFirstkill = 0;
            //PrintToChatAll("[teamplay_setup_finished being fired]");        
        }
        return Plugin_Continue;
}

public Action:hook_RoundEndEvents(Handle:event, const String:name[], bool:dontBroadcast)
{
    gCanBeRun = false;
}

public OnMapStart()
{
	new Handle:cvarArena = FindConVar("tf_gamemode_arena");
	if(GetConVarBool(cvarArena))
	   IsFbcEnabled = false;

  gCanBeRun = false;
  g_iFirstkill = 0;
}

public Action:hook_PlayerGotHurt(Handle:event,  const String:name[], bool:dontBroadcast)
{
  new kk_client = GetClientOfUserId(GetEventInt(event, "attacker"));
  
  if(clientReward[kk_client] == REWARD_FIREAMMO && IsPlayerAlive(kk_client))
  {
      new vv_client = GetClientOfUserId(GetEventInt(event,"userid"));
      if(kk_client > 0){
          if(kk_client != vv_client){
              new m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond");
              new cond = GetEntData(vv_client, m_nPlayerCond);
              if(vv_client > 0 && IsPlayerAlive(vv_client)){
                  
                  if(cond != 131072){
                      TF2_IgnitePlayer(vv_client, vv_client);
                      PrintHintText(vv_client, "You were set on fire by %N", kk_client);
                      //PrintToChatAll("[Victim being set on fire]");
                  }                      
              }  
          }  
      }
  }
  if(clientReward[kk_client] == REWARD_VAMPIRE && IsPlayerAlive(kk_client))
  {
      new vv_client = GetClientOfUserId(GetEventInt(event,"userid"));
      if(kk_client > 0){
          if(kk_client != vv_client){
              if(vv_client > 0 && IsPlayerAlive(vv_client)){
                  new TFClassType:class = TF2_GetPlayerClass(kk_client);    
   
                  new health = GetClientHealth(kk_client);
                  if(health + 15 >= TFClass_VampireMaxHP[class]){
                      //do nothing (continue; doesnt work?)
                  }
                  else{
                      SetEntityHealth(kk_client, health + vleechAmount);
                  }
              }  
          }  
      }
  } 
  return Plugin_Continue;   
}

public Action:hook_Playersdying(Handle:event, const String:name[], bool:dontBroadcast)
{		
	if(!IsFbcEnabled || !gCanBeRun)
      return Plugin_Continue;
  
  //get killer id
	new killer = GetEventInt(event, "attacker"), 
	k_client = GetClientOfUserId(killer), 	// killer index
	victim = GetEventInt(event, "userid"),	
	v_client = GetClientOfUserId(victim),	// victim index
	bool:suicide = false;					// suicide
	  	
	if (GetEventInt(event, "death_flags") & 32) // dead ringer kill print message but really do nothing
	{
		if (!IsValidClient(k_client))
				return Plugin_Continue;
	}
	
	if(k_client == v_client || !IsValidClient(k_client))
		suicide = true;
	
	if (!suicide)
	{
    if (g_iFirstkill <= 1)
      FirstBloodChk(k_client, v_client);
  }
  
  if(clientReward[v_client] != 0){
    if(g_RewardTimerHandle[v_client] != INVALID_HANDLE)
    {
          KillTimer(g_RewardTimerHandle[v_client]);
          g_RewardTimerHandle[v_client] = INVALID_HANDLE;
		}

    if(clientReward[v_client] == REWARD_INVIS)
      Colorize(v_client, NORMAL);
    else if(clientReward[v_client] == REWARD_GOD)
      SetEntProp(v_client, Prop_Data, "m_takedamage", 2, 1);
      
    CTimerCount[v_client] = 0;
    clientReward[v_client] = 0;
    clientStatus[v_client] = 0;
    vleechAmount = 0;
    
    new String:nm[255];
    Format(nm, sizeof(nm), "\x01[FBR] \x03%N's\x01 died and lost their \x05reward\x01", v_client);
    SayText2All(v_client, nm);
  }
  return Plugin_Continue;
}

FirstBloodChk(k_client, v_client)
{
	new Handle:cvarArena = FindConVar("tf_gamemode_arena");
	if (IsValidClient(k_client) && !GetConVarBool(cvarArena) && gCanBeRun && g_iFirstkill++ == 0)
	{
		decl String:FirstBlood[125], String:killerName[32], String:victimName[32];
		if (IsFakeClient(k_client))
			Format(killerName, sizeof(killerName), "A Bot");
		else
			GetClientName(k_client, killerName, sizeof(killerName));
    if (IsFakeClient(v_client))
			Format(victimName, sizeof(victimName), "A Bot");
    else
			GetClientName(v_client, victimName, sizeof(victimName));
      
    if(GetConVarInt(g_firstbloodMsg) == 1)
    {
      Format(FirstBlood, sizeof(FirstBlood), "\x01[FBR] \x03%s \x01got \x04first blood \x01from killing \x04%s\x01, and is being \x05rewarded\x01!", killerName, victimName);
      SayText2All(k_client, FirstBlood);
    }
    
    if(GetConVarInt(g_firstbloodSound) == 1)
    {
      EmitSoundToAll(FIRST_BLOOD2, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
    }
    
    if(GetConVarInt(g_fbrewardsMode) == 2){
      clientReward[k_client] = 0;
      
      new randomreward = GetRandomInt(REWARD_BEGIN, REWARD_END);
      
      
      switch(randomreward)
      {
        case REWARD_CRITS:
              RewardCrits(k_client);
        case REWARD_GOD:
              RewardGodmode(k_client);
        case REWARD_INVIS:
              RewardInvis(k_client);
        case REWARD_FIREAMMO:
              RewardFireammo(k_client);
        case REWARD_VAMPIRE:
              RewardVampire(k_client);
        case REWARD_HEALTH:
              RewardHealthBuff(k_client);
        case REWARD_SENTRY:
              RewardBuildSentry(k_client);
      }
    }
    else{
      CreateTimer(1.0, FBmenu, k_client);
    }
  }
}

public Action:FBmenu(Handle:Timer, any:client)
{
        clientStatus[client] = 1;
        clientReward[client] = 0;
        
        PrintCenterText(client, "Choose a reward!");
        PrintToChat(client, "\x01**You have 12 seconds to choose a \x05reward\x01**");
                
        CreateFBRMenu(client);
        CreateTimer(13.0, FBRFailSelect, client);
}

public CreateFBRMenu(client)
{
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return;
        
        EmitSoundToClient(client, FB_MENU);
        new Handle:fBMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), fn_MenuSelectMenuHandler);
        SetMenuTitle(fBMenu,"Select a Reward!");
      	AddMenuItem(fBMenu,"Option 1", "Crits [15 seconds]");
        AddMenuItem(fBMenu,"Option 2", "Godmode [20 seconds]");
        AddMenuItem(fBMenu,"Option 3", "Invisibility [25 seconds]");
      	AddMenuItem(fBMenu,"Option 4", "Fire Ammo [60 seconds]");
      	AddMenuItem(fBMenu,"Option 5", "Vampire [100 seconds]");
      	AddMenuItem(fBMenu,"Option 6", "Health Boost [default: +600]");
      	AddMenuItem(fBMenu,"Option 7", "Drop a lvl1 Sentry [120 seconds]");
      	DisplayMenu(fBMenu,client,12);
}

public fn_MenuSelectMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
  if(param1 > 0)
  {
    if(!IsPlayerAlive(param1)){
      PrintCenterText(param1, "You must be alive to select a roll!");
      PrintToChat(param1, "You must be alive to select a roll!");
      action = MenuAction_Cancel;
    }
    if(IsPlayerAlive(param1) && clientStatus[param1] == 0){
      PrintCenterText(param1, "Sorry, reward menu has expired!");
      PrintToChat(param1, "Sorry, reward menu has expired!");
      action = MenuAction_Cancel;
    }
  }    
  switch (action)
  {
    case MenuAction_Select:
    {
      new String:name[32];
      GetClientName(param1, name, sizeof(name));
      switch (param2)
      {
        case 0:{
          RewardCrits(param1);
        }
        case 1:{
          RewardGodmode(param1);
        }
        case 2:{
          RewardInvis(param1);
        }
        case 3:{
          RewardFireammo(param1);
        }
        case 4:{
          RewardVampire(param1);
        }
        case 5:{
          RewardHealthBuff(param1);
        }
        case 6:{
          RewardBuildSentry(param1);
        }
      }
    }
    case MenuAction_Cancel:{
    
    }
    case MenuAction_End:{
      CloseHandle(menu);
    }
  }
}

public Action:FBRFailSelect(Handle:Timer, any:client)
{
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

        if(clientStatus[client] == 1)
        {
                PrintToChat(client, "\x01[FBR] You failed to select a reward. :(");
                clientStatus[client] = 0;
        }
}

public RewardCrits(client)
{
        clientReward[client] = REWARD_CRITS;
        clientStatus[client] = 2;

        if(GetConVarInt(g_firstbloodMsg) == 1){
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[FBR] \x03%N\x01 has received reward: \x05Crits", client);
            SayText2All(client, nm);
        }
        
        if(g_RewardTimerHandle[client] != INVALID_HANDLE)
        {
              KillTimer(g_RewardTimerHandle[client]);
              g_RewardTimerHandle[client] = INVALID_HANDLE;
        }

        CTimerCount[client] = 0;
        if(GetConVarInt(g_firstbloodTimer) == 1)
        {
          PrintCenterText(client, "%i", GetConVarInt(g_critsTime));
          g_RewardTimerHandle[client] = CreateTimer(1.0, TimerRepeatCrits, client, TIMER_REPEAT);
        }  
                
        CreateTimer(GetConVarFloat(g_critsTime), RewardCritsOff, client);
}

public Action:TimerRepeatCrits(Handle:Timer, any:client)
{
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;
        
        CTimerCount[client]++;
        
        if(clientReward[client] == REWARD_CRITS)
        {
          PrintCenterText(client, "%i", GetConVarInt(g_critsTime) - CTimerCount[client]);
        }
        
        return Plugin_Continue;
}

public Action:RewardCritsOff(Handle:Timer, any:client)
{
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return;
        
        if(clientReward[client] == REWARD_CRITS)
        {
          if(GetConVarInt(g_firstbloodMsg) == 1)
          {
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[FBR] \x03%N's\x01 reward \x05crits \x01wore off.", client);
            SayText2All(client, nm);        
          }
          ResetRewards(client);
        }
}

public RewardGodmode(client)
{
        clientReward[client] = REWARD_GOD;
        clientStatus[client] = 2;

        if(GetConVarInt(g_firstbloodMsg) == 1){
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[FBR] \x03%N\x01 has received reward: \x05Godmode", client);
            SayText2All(client, nm);
        }
        
        if(g_RewardTimerHandle[client] != INVALID_HANDLE)
        {
              KillTimer(g_RewardTimerHandle[client]);
              g_RewardTimerHandle[client] = INVALID_HANDLE;
        }

        SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
        
        CTimerCount[client] = 0;
        if(GetConVarInt(g_firstbloodTimer) == 1)
        {
          PrintCenterText(client, "%i", GetConVarInt(g_godTime));
          g_RewardTimerHandle[client] = CreateTimer(1.0, TimerRepeatGod, client, TIMER_REPEAT);
        }  
                
        CreateTimer(GetConVarFloat(g_godTime), RewardGodOff, client);
}

public Action:TimerRepeatGod(Handle:Timer, any:client)
{
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;
                
        CTimerCount[client]++;
        
        if(clientReward[client] == REWARD_GOD)
        {
          PrintCenterText(client, "%i", GetConVarInt(g_godTime) - CTimerCount[client]);
        }
        
        return Plugin_Continue;
}

public Action:RewardGodOff(Handle:Timer, any:client)
{
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return;
        
        SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
        if(clientReward[client] == REWARD_GOD)
        {
          if(GetConVarInt(g_firstbloodMsg) == 1)
          {
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[FBR] \x03%N's\x01 reward \x05godmode \x01wore off.", client);
            SayText2All(client, nm);        
          }
          ResetRewards(client);
        }
}

public RewardInvis(client)
{
        clientReward[client] = REWARD_INVIS;
        clientStatus[client] = 2;

        if(GetConVarInt(g_firstbloodMsg) == 1){
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[FBR] \x03%N\x01 has received reward: \x05Invisibility", client);
            SayText2All(client, nm);
        }
        
        if(g_RewardTimerHandle[client] != INVALID_HANDLE)
        {
              KillTimer(g_RewardTimerHandle[client]);
              g_RewardTimerHandle[client] = INVALID_HANDLE;
        }

        Colorize(client, INVIS);
        EmitSoundToAll(REWARD_INVISON, client, _, _, _, 1.0);
        
        CTimerCount[client] = 0;
        if(GetConVarInt(g_firstbloodTimer) == 1)
        {
          PrintCenterText(client, "%i", GetConVarInt(g_invisTime));
          g_RewardTimerHandle[client] = CreateTimer(1.0, TimerRepeatInvis, client, TIMER_REPEAT);
        }  
                
        CreateTimer(GetConVarFloat(g_invisTime), RewardInvisOff, client);
}

public Action:TimerRepeatInvis(Handle:Timer, any:client)
{
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;
        
        CTimerCount[client]++;
        
        if(clientReward[client] == REWARD_INVIS)
        {
          PrintCenterText(client, "%i", GetConVarInt(g_invisTime) - CTimerCount[client]);
        }
        
        return Plugin_Continue;
}

public Action:RewardInvisOff(Handle:Timer, any:client)
{
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return;
        
        Colorize(client, NORMAL);
        if(clientReward[client] == REWARD_INVIS)
        {
          EmitSoundToAll(REWARD_INVISOFF, client, _, _, _, 1.0);
          if(GetConVarInt(g_firstbloodMsg) == 1)
          {
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[FBR] \x03%N's\x01 reward \x05invisibility \x01wore off.", client);
            SayText2All(client, nm);        
          }
          ResetRewards(client);
        }
}

public RewardFireammo(client)
{
        clientReward[client] = REWARD_FIREAMMO;
        clientStatus[client] = 2;

        if(GetConVarInt(g_firstbloodMsg) == 1){
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[FBR] \x03%N\x01 has received reward: \x05Fire Ammo", client);
            SayText2All(client, nm);
        }
        
        EmitSoundToAll(REWARD_FIRESOUND, client, _, _, _, 1.0);
        
        if(g_RewardTimerHandle[client] != INVALID_HANDLE)
        {
              KillTimer(g_RewardTimerHandle[client]);
              g_RewardTimerHandle[client] = INVALID_HANDLE;
        }

        CTimerCount[client] = 0;
        if(GetConVarInt(g_firstbloodTimer) == 1)
        {
          PrintCenterText(client, "%i", GetConVarInt(g_fireammoTime));
          g_RewardTimerHandle[client] = CreateTimer(1.0, TimerRepeatFire, client, TIMER_REPEAT);
        }  
                
        CreateTimer(GetConVarFloat(g_fireammoTime), RewardFireammoOff, client);
}

public Action:TimerRepeatFire(Handle:Timer, any:client)
{
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;
        
        CTimerCount[client]++;
        
        if(clientReward[client] == REWARD_FIREAMMO)
        {
          PrintCenterText(client, "%i", GetConVarInt(g_fireammoTime) - CTimerCount[client]);
        }
        
        return Plugin_Continue;
}

public Action:RewardFireammoOff(Handle:Timer, any:client)
{
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return;
        
        if(clientReward[client] == REWARD_FIREAMMO)
        {
          if(GetConVarInt(g_firstbloodMsg) == 1)
          {
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[FBR] \x03%N's\x01 reward \x05fireammo \x01wore off.", client);
            SayText2All(client, nm);        
          }
          ResetRewards(client);
        }
}

public RewardVampire(client)
{
        clientReward[client] = REWARD_VAMPIRE;
        clientStatus[client] = 2;
        vleechAmount = 0;

        if(GetConVarInt(g_firstbloodMsg) == 1){
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[FBR] \x03%N\x01 has received reward: \x05Vampire", client);
            SayText2All(client, nm);
        }
        
        if(g_RewardTimerHandle[client] != INVALID_HANDLE)
        {
              KillTimer(g_RewardTimerHandle[client]);
              g_RewardTimerHandle[client] = INVALID_HANDLE;
        }

        vleechAmount = GetConVarInt(g_vampAmount);
        CTimerCount[client] = 0;
        PrintCenterText(client, "Vampire duration: %i seconds", GetConVarInt(g_vampTime));
                        
        CreateTimer(GetConVarFloat(g_vampTime), RewardVampireOff, client);
}

public Action:RewardVampireOff(Handle:Timer, any:client)
{
        if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return;
        
        if(clientReward[client] == REWARD_VAMPIRE)
        {
          if(GetConVarInt(g_firstbloodMsg) == 1)
          {
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[FBR] \x03%N's\x01 reward \x05vampire \x01wore off.", client);
            SayText2All(client, nm);        
          }
          ResetRewards(client);
        }
}

public RewardHealthBuff(client)
{
        clientReward[client] = REWARD_HEALTH;
        clientStatus[client] = 2;

        if(GetConVarInt(g_firstbloodMsg) == 1){
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[FBR] \x03%N\x01 has received reward: \x05Health", client);
            SayText2All(client, nm);
        }
        
        if(g_RewardTimerHandle[client] != INVALID_HANDLE)
        {
              KillTimer(g_RewardTimerHandle[client]);
              g_RewardTimerHandle[client] = INVALID_HANDLE;
        }

        new health = GetClientHealth(client);
        new hpbuffamount = GetConVarInt(g_hpbuffamount);
        if(health > 0){
            SetEntityHealth(client, health + hpbuffamount);
        }
        EmitSoundToAll(REWARD_HPSOUND, client, _, _, _, 1.0);
        
        PrintCenterText(client, "Health Buffed!");
        if(GetConVarInt(g_firstbloodMsg) == 1){
            PrintToChat(client, "\x01+\x04%d health", hpbuffamount);
        }
        ResetRewards(client);
}

public RewardBuildSentry(client)
{
        clientReward[client] = REWARD_SENTRY;
        clientStatus[client] = 2;
        buildsg[client] = 0;

        if(g_RewardTimerHandle[client] != INVALID_HANDLE)
        {
              KillTimer(g_RewardTimerHandle[client]);
              g_RewardTimerHandle[client] = INVALID_HANDLE;
        }

        new sentryduration = GetConVarInt(g_sentryTime);
        
        if(GetConVarInt(g_firstbloodMsg) == 1){
            new String:nm[255];
            Format(nm, sizeof(nm), "\x01[FBR] You have \x0315 seconds \x01to drop the sentry. The sentry is auto-destroyed after \x03%d \x01seconds.", sentryduration); 
            SayText2One(client, client, nm);
        }
        g_RewardTimerHandle[client] = CreateTimer(0.3, TimerBuildSentry, client, TIMER_REPEAT);     
        CreateTimer(15.0, RewardBuildSentryOff, client);
        CreateTimer(GetConVarFloat(g_sentryTime), DestroySentry, client);
}

public Action:TimerBuildSentry(Handle:Timer, any:client)
{
    if(clientReward[client] == REWARD_SENTRY && IsPlayerAlive(client)) 
    {
        PrintCenterText(client,"+ATTACK2(ALT FIRE) to drop a sentry!");
        if(GetClientButtons(client) & IN_ATTACK2)
        {    
            new Float:vicorigvec[3];
            new Float:angl[3];
            GetClientAbsOrigin(client, Float:vicorigvec);
            GetClientAbsAngles(client, Float:angl); 
            buildsg[client] = BuildSentry(client, vicorigvec, angl, 1);
            clientReward[client] = 0;
        }
    }
    else{
      KillTimer(g_RewardTimerHandle[client]);
      g_RewardTimerHandle[client] = INVALID_HANDLE;
    }
    return Plugin_Continue;
} 

public Action:RewardBuildSentryOff(Handle:Timer, any:client)
{
        if(!IsClientInGame(client))
        return;
        
        if(clientStatus[client] == 2)
        {
          ResetRewards(client);
        }
}

public Action:DestroySentry(Handle:Timer, any:client)
{
        if(IsValidEntity(buildsg[client])){
            DestroyBuilding(buildsg[client]);
            if(IsClientInGame(client))  
                buildsg[client] = 0;
        }    
}

public ResetRewards(client)
{
        if(g_RewardTimerHandle[client] != INVALID_HANDLE)
        {
                KillTimer(g_RewardTimerHandle[client]);
                g_RewardTimerHandle[client] = INVALID_HANDLE;
        }
                
        if(clientReward[client] == REWARD_GOD)
            SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
        else if(clientReward[client] == REWARD_INVIS)
            Colorize(client, NORMAL);
       
        CTimerCount[client] = 0;
        clientReward[client] = 0;
        clientStatus[client] = 0;
        vleechAmount = 0;
}

public Colorize(client, color[4])
{
	new maxents = GetMaxEntities();
	// Colorize player and weapons
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	

	for(new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
	
		if(weapon > -1 )
		{
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, color[0], color[1],color[2], color[3]);
		}
	}
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	// Colorize any wearable items
	for(new i=MaxClients+1; i <= maxents; i++)
	{
		if(!IsValidEntity(i)) continue;
		
		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		
		if(strcmp(netclass, "CTFWearableItem") == 0)
		{
			if(GetEntDataEnt2(i, c_ownerOffset) == client)
			{
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	return;
}

stock BuildSentry(iBuilder, Float:fOrigin[3], Float:fAngle[3], iLevel=1)
{
        new Float:fBuildMaxs[3];
        fBuildMaxs[0] = 24.0;
        fBuildMaxs[1] = 24.0;
        fBuildMaxs[2] = 66.0;
    
        new Float:fMdlWidth[3];
        fMdlWidth[0] = 1.0;
        fMdlWidth[1] = 0.5;
        fMdlWidth[2] = 0.0;
        
        new String:sModel[64];
        new iTeam = GetClientTeam(iBuilder);
        new iShells, iHealth, iRockets;
        
        if(iLevel == 1)
        {
            sModel = "models/buildables/sentry1.mdl";
            iShells = 200;
            iHealth = 300;
        }
        else if(iLevel == 2)
        {
            sModel = "models/buildables/sentry2.mdl";
            iShells = 120;
            iHealth = 180;
        }
        else if(iLevel == 3)
        {
            sModel = "models/buildables/sentry3.mdl";
            iShells = 144;
            iHealth = 216;
            iRockets = 20;
        }
                 
        new iSentry = CreateEntityByName("obj_sentrygun");
        
        if(IsValidEdict(iSentry)){
          DispatchSpawn(iSentry);
            
          TeleportEntity(iSentry, fOrigin, fAngle, NULL_VECTOR);
            
          SetEntityModel(iSentry,sModel);
            
          SetEntProp(iSentry, Prop_Data, "m_CollisionGroup", 5); //players can walk through sentry so they dont get stuck
            
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_flAnimTime"),                 51, 4 , true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nNewSequenceParity"),         4, 4 , true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nResetEventsParity"),         4, 4 , true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iAmmoShells") ,               iShells, 4, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iMaxHealth"),                 iHealth, 4, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iHealth"),                    iHealth, 4, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bBuilding"),                  0, 2, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bPlacing"),                   0, 2, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bDisabled"),                  0, 2, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iObjectType"),                3, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iState"),                     1, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iUpgradeMetal"),              0, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bHasSapper"),                 0, 2, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nSkin"),                     (iTeam-2), 1, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bServerOverridePlacement"),     1, 1, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iUpgradeLevel"),             iLevel, 4, true);
          SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iAmmoRockets"),                 iRockets, 4, true);
           
          SetEntDataEnt2(iSentry, FindSendPropOffs("CObjectSentrygun","m_nSequence"), 0, true);
          SetEntDataEnt2(iSentry, FindSendPropOffs("CObjectSentrygun","m_hBuilder"),     iBuilder, true);
            
          SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flCycle"),                     0.0, true);
          SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flPlaybackRate"),             1.0, true);
          SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flPercentageConstructed"),     1.0, true);
            
          SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecOrigin"),             fOrigin, true);
          SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_angRotation"),         fAngle, true);
          SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecBuildMaxs"),         fBuildMaxs, true);
          SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_flModelWidthScale"),     fMdlWidth, true);
        	
          SetVariantInt(iTeam);
          AcceptEntityInput(iSentry, "TeamNum", -1, -1, 0);
        
          SetVariantInt(iTeam);
          AcceptEntityInput(iSentry, "SetTeam", -1, -1, 0);
          EmitSoundToAll(REWARD_SENTRYDROP, iSentry, _, _, _, 0.75); 
        }
  return iSentry;
}

stock DestroyBuilding(building)
{
	SetVariantInt(1000);
	AcceptEntityInput(building, "RemoveHealth");
}

stock bool:IsValidClient(client)
{
	if (client
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& !IsFakeClient(client))
		return true;
	else
		return false;
}

stock SayText2All(author, const String:message[]) {
    new Handle:buffer = StartMessageAll("SayText2");
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}

stock SayText2One( client_index , author_index , const String:message[] ) {
    new Handle:buffer = StartMessageOne("SayText2", client_index);
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
        if(clientReward[client] == REWARD_CRITS && IsFbcEnabled)
        {
                //PrintToChatAll("Crits = On");
                result = true;
                return Plugin_Handled;
        }
	
	return Plugin_Continue;
}

public CvarEnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (IsFbcEnabled)
  {
    UnhookEvent("player_death", hook_Playersdying, EventHookMode_Post);
    UnhookEvent("player_hurt", hook_PlayerGotHurt);
    UnhookEvent("teamplay_round_start", hook_RoundStartEvents, EventHookMode_Post);
    UnhookEvent("teamplay_round_active", hook_RoundStartEvents, EventHookMode_Post);
    UnhookEvent("teamplay_restart_round", hook_RoundStartEvents, EventHookMode_Post);
    UnhookEvent("teamplay_setup_finished", hook_RoundStartEvents, EventHookMode_Post);
    UnhookEvent("teamplay_round_win", hook_RoundEndEvents, EventHookMode_PostNoCopy);
    UnhookEvent("teamplay_game_over", hook_RoundEndEvents, EventHookMode_PostNoCopy);
    IsFbcEnabled = false;
    gCanBeRun = false;
	} else {
    HookEvent("player_death", hook_Playersdying, EventHookMode_Post);
    HookEvent("player_hurt", hook_PlayerGotHurt);
    HookEvent("teamplay_round_start", hook_RoundStartEvents, EventHookMode_Post);
    HookEvent("teamplay_round_active", hook_RoundStartEvents, EventHookMode_Post);
    HookEvent("teamplay_restart_round", hook_RoundStartEvents, EventHookMode_Post);
    HookEvent("teamplay_setup_finished", hook_RoundStartEvents, EventHookMode_Post);
    HookEvent("teamplay_round_win", hook_RoundEndEvents, EventHookMode_PostNoCopy);
    HookEvent("teamplay_game_over", hook_RoundEndEvents, EventHookMode_PostNoCopy);
    IsFbcEnabled = true;
    gCanBeRun = true;
	}
}