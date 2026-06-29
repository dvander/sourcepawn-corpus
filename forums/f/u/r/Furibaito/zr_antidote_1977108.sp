/*
 * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 * 
 *  ZR Antidote by Furibaito
 *
 *  zr_antidote.sp - Source file
 *
 * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 */

// Includes
#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>
#pragma semicolon 1

// Version and description
#define VERSION "1.0"
#define DESC "Zombies could buy an antidote to turn themselves to human. Made by Furibaito."

new UserMsg:g_FadeUserMsgId;

public Plugin:myinfo = 
{
	name = "[ZR] Antidote",
	author = "Furibaito",
	description = DESC,
	version = VERSION,
	url = "www.sourcemod.net"
};

#define FFADE_IN 0x0001
#define FFADE_OUT 0x0002
#define FFADE_PURGE 0x0010

new Handle:hEnable;
new Handle:hPrice;
new Handle:hCommand;
new Handle:hWeaponSet;
// new Handle:hMotherZombieAllow;
new Handle:hSoundPath;
new Handle:hFadeLengthX;
new Handle:hFadeColor;

new Enable;
new Price;
new String:Command[32];
new String:WeaponSet[128];
// new MotherZombieAllow;
new String:SoundPath[64];
new FadeLengthX;
new String:FadeColor[16];

public OnPluginStart()
{
	AddCommandListener(PlayerSay, "say");
	AddCommandListener(PlayerSay, "say_team");
	
	CreateConVar("zr_antidote_version", VERSION, DESC, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hEnable = CreateConVar("zr_antidote_enable", "1", "Enable or disable antidote plugin on Zombie:Reloaded");
	hPrice = CreateConVar("zr_antidote_price", "10000", "What is the price of an Antidote.");
	hCommand = CreateConVar("zr_antidote_command", "!antidote", "Command in chat to buy an antidote");
	hWeaponSet = CreateConVar("zr_antidote_weapons", "weapon_mp5navy;weapon_usp;weapon_hegrenade", "What weapons will be given to those players just used an antidote? Separates with semi-colons( ; ) and dont put any empty spaces.");
	// hMotherZombieAllow = CreateConVar("zr_antidote_allow_mzombie", "0", "Allow or disallow mother zombies to buy an antidote.");
	hSoundPath = CreateConVar("zr_antidote_sound", "items/battery_pickup.wav", "Path to the sound played when a zombie using an Antidote. 0 = Disable sound. The default is from HL2.");
	hFadeLengthX = CreateConVar("zr_antidote_fade_length", "300", "The length (in milliseconds) of the fade when a zombie using an Antidote. Set 0 to disable fade.");
	hFadeColor = CreateConVar("zr_antidote_fade_color", "255 255 255 255", "The color R G B A value of the fade, set \"0 0 0 0\" to disable fade.");
	
	Enable = GetConVarInt(hEnable);
	Price = GetConVarInt(hPrice);
	GetConVarString(hCommand, Command, sizeof(Command));
	GetConVarString(hWeaponSet, WeaponSet, sizeof(WeaponSet));
	// MotherZombieAllow = GetConVarInt(hMotherZombieAllow);
	GetConVarString(hSoundPath, SoundPath, sizeof(SoundPath));
	FadeLengthX = RoundToNearest((GetConVarInt(hFadeLengthX)) / 2.0);
	GetConVarString(hFadeColor, FadeColor, sizeof(FadeColor));
	
	HookConVarChange(hEnable, OnConVarChange);
	HookConVarChange(hPrice, OnConVarChange);
	HookConVarChange(hCommand, OnConVarChange);
	// HookConVarChange(hMotherZombieAllow, OnConVarChange);
	HookConVarChange(hSoundPath, OnConVarChange);
	HookConVarChange(hFadeLengthX, OnConVarChange);
	HookConVarChange(hFadeColor, OnConVarChange);
	
	g_FadeUserMsgId = GetUserMessageId("Fade");
}

public OnConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == hEnable)
	{
		Enable = StringToInt(newVal);
	}
	
	else if (cvar == hPrice)
	{
		Price = StringToInt(newVal);
	}
	
	else if (cvar == hCommand)
	{
		// The auto-update of string cvar doesn't work whis way. Anyone knows why?
		SetConVarString(cvar, newVal);
	}
	
	// else if (cvar == hMotherZombieAllow)
	// {
		// MotherZombieAllow = StringToInt(newVal);
	// }
	
	else if (cvar == hSoundPath)
	{
		SetConVarString(cvar, newVal);
	}
	
	else if (cvar == hFadeLengthX)
	{
		FadeLengthX = RoundToNearest((StringToInt(newVal) / 2.0));
	}
	
	else if (cvar == hFadeColor)
	{
		SetConVarString(cvar, newVal);
	}
}

public OnMapStart()
{
	new String:SoundPathDL[64];
	Format(SoundPathDL, sizeof(SoundPathDL), "sound/%s", SoundPath);
	AddFileToDownloadsTable(SoundPathDL);
	PrecacheSound(SoundPath);
}

public Action:PlayerSay(client, const String:command[], argc)
{
	new String:Text[10];
	GetCmdArg(1, Text, sizeof(Text));
	
	if (StrEqual(Text, Command, false))
	{
		if (!Enable)
		{
			PrintToChat(client, "\x04[ZR] \x03Antidotes \x01is disabled.");
		}
		
		if (ZR_IsClientZombie(client))
		{
			new Cash = GetEntProp(client, Prop_Send, "m_iAccount");
			if (Cash >= Price)
			{
				// Get zombie count
				new ZombieCount;
				for (new x = 1; x <= MaxClients; x++)
				{
					if (IsClientInGame(x))
					{
						if (GetClientTeam(x) == 2)
							ZombieCount++;
					}
				}
				
				// If the number of zombie is more than 1 (Prevents round ending)
				if (ZombieCount > 1)
				{
					// Turn the zombie to human
					ZR_HumanClient(client, false, false);
					PrintToChat(client, "\x04[ZR] \x01You have bought an \x03Antidote\x01 for \x03$%i\x01.", Price);
					
					// Fade the client
					new String:ColorArray[4][4];
					ExplodeString(FadeColor, " ", ColorArray, 4, 4);
					
					new R = StringToInt(ColorArray[0]);
					new G = StringToInt(ColorArray[1]);
					new B = StringToInt(ColorArray[2]);
					new A = StringToInt(ColorArray[3]);
					
					Fade(client, FadeLengthX, FadeLengthX, FFADE_PURGE|FFADE_IN, R, G, B, A);
					EmitSoundToAll(SoundPath, client, SNDCHAN_AUTO, 90);
					
					// Substract the cash
					Cash -= Price;
					SetEntProp(client, Prop_Send, "m_iAccount", Cash);
					
					// Give them weapons
					new String:WeaponArray[10][32];
					ExplodeString(WeaponSet, ";", WeaponArray, 10, 32, false); 
					for (new i = 0; i < 10; i++)
					{
						if (WeaponArray[i][0] != 0)
						{
							GivePlayerItem(client, WeaponArray[i]);
						}
					}
				}
				else
				{
					PrintToChat(client, "\x04[ZR] \x01You are the only zombie in the game. Unable to buy an antidote.");
				}
			}
			else
			{
				PrintToChat(client, "\x04[ZR] \x01You doesn't have enough cash to buy an \x03Antidote\x01! The price is \x03$%i\x01!", Price);
			}
		}
		else
		{
			PrintToChat(client, "\x04[ZR] \x01 Only zombies can buy an \x03Antidote\x01!");
		}
	}
}

Fade(client, hold, length, type, r, g, b, a)
{
	new clients[2];
	clients[0] = client;
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	if (message !=INVALID_HANDLE)
	{
		if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
		{
			new Color[4];
			Color[0] = r;
			Color[1] = g;
			Color[2] = b;
			Color[3] = a;
			PbSetInt(message, "duration", length);
			PbSetInt(message, "hold_time", hold);
			PbSetInt(message, "flags", type);
			PbSetColor(message, "clr", Color);
		}
		
		else
		{
			BfWriteShort(message, length);
			BfWriteShort(message, hold);
			BfWriteShort(message, type);
			BfWriteByte(message, r);
			BfWriteByte(message, g);
			BfWriteByte(message, b);
			BfWriteByte(message, a);
			EndMessage();
		}
	}
}