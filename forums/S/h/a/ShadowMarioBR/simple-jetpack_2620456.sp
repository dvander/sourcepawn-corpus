#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <tf2>

#define PLUGIN_VERSION "1.1.2"

Handle sm_jetpack_enabled;
Handle sm_jetpack_sound;
Handle sm_jetpack_fallspeed;
Handle sm_jetpack_jumpheight;
Handle sm_jetpack_downlimit;
Handle sm_jetpack_pitch;
Handle sm_jetpack_volume;
Handle sm_jetpack_particle;
Handle sm_jetpack_dod;

char jetSound[255]	= "ambient/sawblade.wav";

bool jetpackActivated[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Simple Jetpack",
	author = "Shadow Mario",
	description = "My first plugin with a result that i liked, it works like a Jetpack, even if it's kinda badly made.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=311494"
};

public void OnPluginStart()
{
	LoadTranslations("simple-jetpack.phrases");
	AutoExecConfig(true, "plugin.jetpack");
	
	// Create ConVars
	CreateConVar("sm_jetpack_version", PLUGIN_VERSION, "Version of Simple Jetpack", FCVAR_REPLICATED | FCVAR_NOTIFY);
	sm_jetpack_enabled = CreateConVar("sm_jetpack_enabled", "1", "Defines if the plugin is active", FCVAR_REPLICATED | FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_jetpack_sound = CreateConVar("sm_jetpack_soundfile", jetSound, "Sound file of the jetpack", _);
	sm_jetpack_fallspeed = CreateConVar("sm_jetpack_fallspeed", "12.0", "Falling speed while jetpack is active, the higher it is, the faster you will fall", _);
	sm_jetpack_jumpheight = CreateConVar("sm_jetpack_jumpheight", "5.0", "Jump height multiplier while jetpack is active", _);
	sm_jetpack_downlimit = CreateConVar("sm_jetpack_downlimit", "450.0", "limit of the Jetpack downward speed while Jetpack is enabled", _);
	sm_jetpack_volume = CreateConVar("sm_jetpack_soundvolume", "0.3", "Volume of the Jetpack sound", _, true, 0.0);
	sm_jetpack_pitch = CreateConVar("sm_jetpack_soundpitch", "140", "Pitching of the Jetpack sound", _, true, 0.0);
	sm_jetpack_particle = CreateConVar("sm_jetpack_particle", "1", "Jetpack leaves a Particle while flying", _, true, 0.0, true, 1.0);
	sm_jetpack_dod = CreateConVar("sm_jetpack_disableondeath", "1", "Disables Jetpack on Death", _, true, 0.0, true, 1.0);
	
	// Event Hooks
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	
	// Create ConCommands
	RegConsoleCmd("sm_jetpack", JetpackMenu, "Opens Simple Jetpack menu", FCVAR_GAMEDLL);
	RegConsoleCmd("+jetpack", JetpackOn, "Activates Jetpack", FCVAR_GAMEDLL);
	RegConsoleCmd("-jetpack", JetpackOff, "Deactivates Jetpack", FCVAR_GAMEDLL);
}

public void OnConfigsExecuted()
{
	GetConVarString(sm_jetpack_sound, jetSound, sizeof(jetSound));
	PrecacheSound(jetSound, true);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!GetConVarBool(sm_jetpack_enabled) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	if(IsClientInGame(client) && IsValidEntity(client) && client > -1 && client <= MaxClients)
	{
		float velocity[3], position[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		float fallspeed = GetConVarFloat(sm_jetpack_fallspeed);
		float jumpheight = GetConVarFloat(sm_jetpack_jumpheight);
		float downlimit = GetConVarFloat(sm_jetpack_downlimit);
		float soundvolume = GetConVarFloat(sm_jetpack_volume);
		int soundpitch = GetConVarInt(sm_jetpack_pitch);
		int particle = GetConVarInt(sm_jetpack_particle);
		int LastActivated[MAXPLAYERS+1] = 0;
		if(jetpackActivated[client])
		{
			if(buttons & IN_JUMP)
			{
				if(!(GetEntityFlags(client) & FL_ONGROUND))
				{
					EmitSoundToAll(jetSound, client, _, _, SND_CHANGEPITCH|SND_CHANGEVOL, (soundvolume + 0.2), (soundpitch + 20), client, position);
					velocity[2] += jumpheight;
					if(particle == 1)
					{
						TF2_AddCondition(client, TFCond_TeleportedGlow, 0.1);
					}
				}
				else if(GetEntityFlags(client) & FL_ONGROUND)
				{
					EmitSoundToAll(jetSound, client, _, _, SND_CHANGEPITCH|SND_CHANGEVOL, soundvolume, soundpitch, client, position);
				}
			}
			else if(!(buttons & IN_JUMP))
			{
				if(velocity[2] > (downlimit * -1.0))
				{
					velocity[2] -= fallspeed;
				}
				else if(velocity[2] < (downlimit * -1.0))
				{
					velocity[2] = (downlimit * -1.0);
				}
				EmitSoundToAll(jetSound, client, _, _, SND_CHANGEPITCH|SND_CHANGEVOL, soundvolume, soundpitch, client, position);
			}
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
			LastActivated[client] = true;
			SetEntityGravity(client, 0.001);
		}
		else if(!jetpackActivated[client])
		{
			if(LastActivated[client] == 1)
			{
				if(GetEntityGravity(client) == 0.0)
				{
					SetEntityGravity(client, 1.0);
				}
				LastActivated[client] = 0;
			}
			StopSound(client, SNDCHAN_AUTO, jetSound);
		}
	}
	return Plugin_Continue;
}

public Action JetpackMenu(int client, int args)
{
	Menu menu = new Menu(JetpackMenu_Handler, MENU_ACTIONS_ALL);
	char menuTitle[40], jetEnabled[24], jetDisabled[24];
	Format(menuTitle, sizeof(menuTitle), "%t", "MenuTitle");
	Format(jetEnabled, sizeof(jetEnabled), "%t", "JetEnabled");
	Format(jetDisabled, sizeof(jetDisabled), "%t", "JetDisabled");
	menu.SetTitle(menuTitle);
	menu.AddItem("jeton", jetEnabled);
	menu.AddItem("jetoff", jetDisabled);
	menu.ExitButton = true;
	menu.Display(client, 20);
	
	return Plugin_Handled;
}

public Action JetpackOn(int client, int args)
{
	if(IsValidEntity(client) && client > -1 && client <= MaxClients) jetpackActivated[client] = true;
}
public Action JetpackOff(int client, int args)
{
	if(IsValidEntity(client) && client > -1 && client <= MaxClients)
	{
		jetpackActivated[client] = false;
		SetEntityGravity(client, 1.0);
	}
}

public int JetpackMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "jeton"))
		{
			if(jetpackActivated[param1])
			{
				CPrintToChat(param1, "%t", "JetAlreadyEnabled");
			}
			else if(!jetpackActivated[param1])
			{
				jetpackActivated[param1] = true;
				CPrintToChat(param1, "%t", "JetEnabledMSG");
			}
		}
		else if (StrEqual(info, "jetoff"))
		{
			if(jetpackActivated[param1])
			{
				jetpackActivated[param1] = false;
				SetEntityGravity(param1, 1.0);
				CPrintToChat(param1, "%t", "JetDisabledMSG");
			}
			else if(!jetpackActivated[param1])
			{
				CPrintToChat(param1, "%t", "JetAlreadyDisabled");
			}
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int deathdisable = GetConVarInt(sm_jetpack_dod);
	if(IsClientInGame(client) && IsValidEntity(client) && client > -1 && client <= MaxClients && jetpackActivated[client] && deathdisable == 1)
	{
		jetpackActivated[client] = false;
		SetEntityGravity(client, 1.0);
		CPrintToChat(client, "%t", "JetDeath");
	}
	return Plugin_Continue;
}