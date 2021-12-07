#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "DiogoOnAir" 
#define PLUGIN_VERSION "1.7"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <csgo_colors>
#include <clientprefs>
#include <cstrike>
#include <smlib>

#define g_WeaponParent FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");
#define m_flNextSecondaryAttack FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack")

#pragma newdecls required
#pragma tabsize 0

int voteyes = 0;
int voteno = 0;

bool InNoscope = false;
bool g_DuelMusic = false;
bool g_Deagle1TapDuel = false;
bool g_bBomb;

char g_PluginPrefix[64];

ConVar g_KnifeDuelPlayerSpeed;
ConVar g_KnifeDuelGravity;
ConVar g_hPluginPrefix;
ConVar g_MinPlayers; 
ConVar g_MaxDuelTime; 

Handle DuelTimer;
Handle g_DMPlayCookie;
Handle g_DMVolumeCookie;

public Plugin myinfo = 
{
	name = "1V1 Duel",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/diogo218dv"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("bomb_planted", BombPlanted);
	
	g_DMPlayCookie = RegClientCookie("DuelMusic", "", CookieAccess_Private);
	g_DMVolumeCookie = RegClientCookie("DuelMusic_volume", "Duel Music volume", CookieAccess_Private);
	
	RegConsoleCmd("sm_duelmusic", DuelMusic);
	SetCookieMenuItem(SoundCookieHandler, 0, "Duel Music");
	
	g_KnifeDuelPlayerSpeed = CreateConVar("duel_knifespeed", "1.8", "Define players speed when they are in a speed knife duel");
	g_KnifeDuelGravity = CreateConVar("duel_knifegravity", "0.3", "Define the players gravity when they are in a low gravity knife duel");
	g_MinPlayers = CreateConVar("duel_minplayers", "3", "Define the minimium players to enable the duel");
	g_hPluginPrefix = CreateConVar("duel_chatprefix", "{lime}Duel {default}|", "Determines the prefix used for chat messages", FCVAR_NOTIFY);
	g_MaxDuelTime = CreateConVar("duel_maxdueltime", "30.0", "Max time for a duel in seconds", FCVAR_NOTIFY);
	
	LoadTranslations("duel_phrases.txt");
	AutoExecConfig(true, "Duel");
	
	for (int i = 0; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void SoundCookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	DuelMusic(client, 0);
}

public Action DuelMusic(int client, int args)
{	
	int cookievalue = GetIntCookie(client, g_DMPlayCookie);
	Handle g_CookieMenu = CreateMenu(DeulMenuMenuHandler);
	SetMenuTitle(g_CookieMenu, "Deul Music");
	char Item[128];
	if(cookievalue == 0)
	{
		Format(Item, sizeof(Item), "%t %t", "DUELMUSIC_ON", "SELECTED"); 
		AddMenuItem(g_CookieMenu, "ON", Item);
		Format(Item, sizeof(Item), "%t", "DUELMUSIC_OFF"); 
		AddMenuItem(g_CookieMenu, "OFF", Item);
	}
	else
	{
		Format(Item, sizeof(Item), "%t", "DUELMUSIC_ON");
		AddMenuItem(g_CookieMenu, "ON", Item);
		Format(Item, sizeof(Item), "%t %t", "DUELMUSIC_OFF", "SELECTED"); 
		AddMenuItem(g_CookieMenu, "OFF", Item);
	}

	Format(Item, sizeof(Item), "%t", "VOLUME");
	AddMenuItem(g_CookieMenu, "volume", Item);


	SetMenuExitBackButton(g_CookieMenu, true);
	SetMenuExitButton(g_CookieMenu, true);
	DisplayMenu(g_CookieMenu, client, 30);
	return Plugin_Continue;
}

public int DeulMenuMenuHandler(Handle menu, MenuAction action, int client, int param2)
{
	Handle g_CookieMenu = CreateMenu(DeulMenuMenuHandler);
	if (action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		ShowCookieMenu(client);
	}
	else if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{
				SetClientCookie(client, g_DMPlayCookie, "0");
				DuelMusic(client, 0);
			}
			case 1:
			{
				SetClientCookie(client, g_DMPlayCookie, "1");
				DuelMusic(client, 0);
			}
			case 2: 
			{
				VolumeMenu(client);
			}			
		}
		CloseHandle(g_CookieMenu);
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void VolumeMenu(int client){
	

	float volumeArray[] = { 1.0, 0.75, 0.50, 0.25, 0.10 };
	float selectedVolume = GetClientVolume(client);

	Menu volumeMenu = new Menu(VolumeMenuHandler);
	volumeMenu.SetTitle("%t", "DMVOLUME");
	volumeMenu.ExitBackButton = true;

	for(int i = 0; i < sizeof(volumeArray); i++)
	{
		char strInfo[10];
		Format(strInfo, sizeof(strInfo), "%0.2f", volumeArray[i]);

		char display[20], selected[5];
		if(volumeArray[i] == selectedVolume)
			Format(selected, sizeof(selected), "%t", "SELECTED");

		Format(display, sizeof(display), "%s %s", strInfo, selected);

		volumeMenu.AddItem(strInfo, display);
	}

	volumeMenu.Display(client, MENU_TIME_FOREVER);
}

public int VolumeMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select){
		char sInfo[10];
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
		SetClientCookie(client, g_DMVolumeCookie, sInfo);
		VolumeMenu(client);
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		DuelMusic(client, 0);
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

//Hooks

public Action Event_WeaponFire(Event event,const char[] name,bool dontBroadcast)
{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		char weapon[32];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		if (StrEqual(weapon, "weapon_decoy"))
		{
			CreateTimer(1.0, GiveDecoy, client);
		}
		else 
			if (g_Deagle1TapDuel)
			{
		   		CreateTimer(0.05, RemoveDeagle, client);
				CreateTimer(0.5, GiveDeagle, client);
			}
}

public Action RemoveDeagle(Handle timer, any client)
{
	if (IsValidClient(client) && (IsPlayerAlive(client)))
	{
		Client_RemoveAllWeapons(client);
	}
}

public Action GiveDeagle(Handle timer, any client)
{
	if (IsValidClient(client) && (IsPlayerAlive(client)))
	{
		GivePlayerItem(client, "weapon_deagle");
	}
}

public Action GiveDecoy(Handle timer, any client)
{
	if (IsValidClient(client) && (IsPlayerAlive(client)))
	{
		GivePlayerItem(client, "weapon_decoy");
	}
}

public Action Event_PlayerHurt(Handle event, const char[] name,bool dontBroadcast)
{
	if (g_Deagle1TapDuel)
	{
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		bool headshot = GetEventBool(event, "headshot");
		int damage = GetEventInt(event, "dmg_health");

		if (!headshot && attacker != victim && victim != 0 && attacker != 0)
		{
			if (damage > 0)
			{
				SetEntityHealth(victim, 100);
			}
		}
	}
	return Plugin_Continue;
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/duel/sound1.mp3");
	AddFileToDownloadsTable("sound/duel/sound2.mp3");
	AddFileToDownloadsTable("sound/duel/sound3.mp3");
	AddFileToDownloadsTable("sound/duel/sound4.mp3");
	AddFileToDownloadsTable("sound/duel/sound5.mp3");
	PrecacheSound("duel/sound1.mp3");
	PrecacheSound("duel/sound2.mp3");
	PrecacheSound("duel/sound3.mp3");
	PrecacheSound("duel/sound4.mp3");
	PrecacheSound("duel/sound5.mp3");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThink, PreThink);
}

public Action PreThink(int client)
{
	if(IsPlayerAlive(client))
	{
		int  weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEdict(weapon))
			return Plugin_Continue;

		char item[64];
		GetEdictClassname(weapon, item, sizeof(item)); 
		if(InNoscope && StrEqual(item, "weapon_awp"))
		{
			SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 9999.9); 
		}
	}
	return Plugin_Continue;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    voteyes = 0;
	voteno = 0;
    InNoscope = false;
	g_bBomb = false;
    g_Deagle1TapDuel = false;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    if(g_DuelMusic)
    {
       for (int i = 0; i <= MaxClients; i++)
       {
        g_DuelMusic = false;
        StopSound(i, SNDCHAN_AUTO, "duel/sound1.mp3");
       }
    }
    delete DuelTimer;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if(AliveTPlayers() == 1 && AliveCTPlayers() == 1)
	{
		for (int i = 0; i <= MaxClients; i++)
		{
			if(GetRealClientCount() >= g_MinPlayers.IntValue && !g_bBomb)
			ShowDuelMenu(i);
		}
    }
}

//Duel

public void ShowDuelMenu(int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
        Menu menu = new Menu(DuelMenu);

		menu.SetTitle("Duel Menu");
		menu.AddItem("YES", "Yes");
		menu.AddItem("NO", "No");
		menu.ExitButton = false;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int DuelMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));

		    if (StrEqual(info, "YES"))
			{
				voteyes += 1;
				checkvotes();
			}
			else if (StrEqual(info, "NO"))
			{
				voteno += 1;
				checkvotes();
			}
		}

		case MenuAction_End:{delete menu;}
	}

	return 0;
}


public void checkvotes()
{
  	if(voteno > 0)
  	{
  		NoDuel();
    }
    else if(voteyes == 2)
    {
    	int randomnumber = GetRandomInt(1, 5);
    	if(randomnumber == 1)
    	{
    		AWNoscope();
        }
        else if(randomnumber == 2)
    	{
    		KnifeLowGravity();
        }
        else if(randomnumber == 3)
    	{
    		SpeedKnife();
        }
        else if(randomnumber == 4)
    	{
    		Decoy1HP();
        }
        else if(randomnumber == 5)
    	{
    		DEAGLE1TAP();
        }
    }
}

//Some Stocks and Actions


public Action AWNoscope()
{ 
	RemoveWeapons();
	for (int i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			InNoscope = true;
			Client_RemoveAllWeapons(i);
			char weapon = GivePlayerItem(i, "weapon_awp");
			SetEntProp(weapon, Prop_Data, "m_iClip1", 1000);
		}  
		DuelPlayMusic();
		g_DuelMusic = true;
		GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
		CGOPrintToChatAll("%t", "AwNoscope", g_PluginPrefix);
		float waittime = g_MaxDuelTime.FloatValue;
		DuelTimer = CreateTimer(waittime, DuelTimerFunc);
	}
}

public Action KnifeLowGravity()
{ 
	RemoveWeapons();
	for (int i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			Client_RemoveAllWeapons(i);
			GivePlayerItem(i, "weapon_knife");
			SetGravity(i, g_KnifeDuelGravity.FloatValue); 
		}
		DuelPlayMusic();
		g_DuelMusic = true;
		GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
		CGOPrintToChatAll("%t", "KnifeLowGravity", g_PluginPrefix);
		float waittime = g_MaxDuelTime.FloatValue;
		DuelTimer = CreateTimer(waittime, DuelTimerFunc);
	}	
}

public Action SpeedKnife()
{ 
	RemoveWeapons();
	for (int i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			Client_RemoveAllWeapons(i);
			GivePlayerItem(i, "weapon_knife");
			SetSpeed(i, g_KnifeDuelPlayerSpeed.FloatValue);
		}
		DuelPlayMusic();
		g_DuelMusic = true;
		GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
		CGOPrintToChatAll("%t", "SpeedKnife", g_PluginPrefix);
		float waittime = g_MaxDuelTime.FloatValue;
		DuelTimer = CreateTimer(waittime, DuelTimerFunc);
	}
}

public Action Decoy1HP()
{ 
	RemoveWeapons();
	for (int i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			Client_RemoveAllWeapons(i);
			SetEntityHealth(i, 1);
			GivePlayerItem(i, "weapon_decoy");
			SetGravity(i, g_KnifeDuelGravity.FloatValue); 
		}
		DuelPlayMusic();
		g_DuelMusic = true;
		GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
		CGOPrintToChatAll("%t", "Decoy1HP", g_PluginPrefix);
		float waittime = g_MaxDuelTime.FloatValue;
		DuelTimer = CreateTimer(waittime, DuelTimerFunc);
	}	
}

public Action DEAGLE1TAP()
{ 
	RemoveWeapons();
	for (int i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			Client_RemoveAllWeapons(i);
			SetEntityHealth(i, 100);
			GivePlayerItem(i, "weapon_deagle");
		}
		DuelPlayMusic();
		g_DuelMusic = true;
		g_Deagle1TapDuel = true;
		GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
		CGOPrintToChatAll("%t", "Deagle1tap", g_PluginPrefix);
		float waittime = g_MaxDuelTime.FloatValue;
		DuelTimer = CreateTimer(waittime, DuelTimerFunc);
	}
}

public Action NoDuel()
{ 
	GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
    CGOPrintToChatAll("%t", "DuelCancelled", g_PluginPrefix);
}

public Action RemoveWeapons()
{ 
	char weapon[64];
	int maxent = GetMaxEntities();
	for (int i=GetMaxClients();i< maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if (( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ))
				RemoveEdict(i);
		}
	}	
	return Plugin_Continue;
}

public Action DuelTimerFunc(Handle timer) 
{ 
    if(AliveTPlayers() == 1 && AliveCTPlayers() == 1)
	{
		CS_TerminateRound(7.0, CSRoundEnd_Draw);
	}
	DuelTimer = null;
}  
   

public Action DuelPlayMusic()
{
	for (int  i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && GetIntCookie(i, g_DMPlayCookie) == 0)
		{
			float selectedVolume = GetClientVolume(i);
			int number = GetRandomInt(1, 5);
			if(number == 1)
			{
				EmitSoundToClient(i, "duel/sound1.mp3", _, SNDCHAN_AUTO, _, _, selectedVolume, _, _, _, _, _, _);  
		    }
			else if(number == 2)
			{
				EmitSoundToClient(i, "duel/sound2.mp3", _, SNDCHAN_AUTO, _, _, selectedVolume, _, _, _, _, _, _);  
		    }
		    else if(number == 3)
			{
				EmitSoundToClient(i, "duel/sound3.mp3", _, SNDCHAN_AUTO, _, _, selectedVolume, _, _, _, _, _, _);  
		    }
		    else if(number == 4)
			{
				EmitSoundToClient(i, "duel/sound4.mp3", _, SNDCHAN_AUTO, _, _, selectedVolume, _, _, _, _, _, _);  
		    }
		    else if(number == 5)
			{
				EmitSoundToClient(i, "duel/sound5.mp3", _, SNDCHAN_AUTO, _, _, selectedVolume, _, _, _, _, _, _);  
		    }
	    }
	}
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

public int AliveTPlayers()
{
	int g_Terrorists = 0;
	for (int  i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			g_Terrorists++;
		}
	}
	return g_Terrorists;
}

public int AliveCTPlayers()
{
	int g_CTerrorists = 0;
	for (int  i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
		{
			g_CTerrorists++;
		}
	}
	return g_CTerrorists;
}

public void SetSpeed(int client, float speed)
{
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);
}

public void SetGravity(int client, float amount)
{
    SetEntityGravity(client, amount / GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue"));
}

stock int GetRealClientCount()
{
    int iClients = 0;

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i)) {
            iClients++;
        }
    }

    return iClients;
}  

int GetIntCookie(int client, Handle handle)
{
	char sCookieValue[11];
	GetClientCookie(client, handle, sCookieValue, sizeof(sCookieValue));
	return StringToInt(sCookieValue);
}

float GetClientVolume(int client){
	float defaultVolume = 0.75;

	char sCookieValue[11];
	GetClientCookie(client, g_DMVolumeCookie, sCookieValue, sizeof(sCookieValue));

	if(StrEqual(sCookieValue, "") || StrEqual(sCookieValue, "0"))
		Format(sCookieValue , sizeof(sCookieValue), "%0.2f", defaultVolume);

	return StringToFloat(sCookieValue);
}

public Action BombPlanted(Event hEvent, const char[] name, bool dontBroadcast) 
{
	g_bBomb = true;
} 